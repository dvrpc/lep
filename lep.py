import os
import requests
import duckdb
import json

year = 2024
groups = {
    "C16001": ["tract", "public use microdata area"],
    "B16001": "public use microdata area",
}
county_names = {
    "34005": "Burlington",
    "34007": "Camden",
    "34015": "Gloucester",
    "34021": "Mercer",
    "42017": "Bucks",
    "42029": "Chester",
    "42045": "Delaware",
    "42091": "Montgomery",
    "42101": "Philadelphia",
}
census_url = f"https://api.census.gov/data/{year}/acs/acs5"
census_key = ""

con = duckdb.connect(database=":memory:")
con.execute("INSTALL httpfs; LOAD httpfs;")


def get_field_map(census_url):
    """
    get actual names for census field codes and cleans field names
    """
    print(f"Grabbing variables...\n")
    variables = requests.get(census_url + "/variables.json")
    var_data = variables.json()
    field_map = {}
    for key, value in var_data["variables"].items():
        if "label" in value:
            new_name = (
                value["label"]
                .replace("Estimate!!Total:!!", "")
                .replace("!!", "")
                .replace(':Speak English "very well"', "_w")
                .replace(':Speak English less than "very well"', "_lim")
                .replace(",", "_")
                .replace(":", "")
                .replace("(incl.", "")
                .replace(")", "")
                .replace(" ", "_")
                .replace("__", "_")
                .replace("-", "_")
                .lower()
            )
            field_map[key] = new_name
            if key.endswith("E"):
                moe_key = key[:-1] + "M"  # replace 'E' with 'M'
                field_map[moe_key] = new_name + "_moe"
    return field_map


def acs_tables(api_url, params, group, geo):
    """
    gets census data from api and loads into duckdb
    """
    # census api response to json
    response = requests.get(api_url, params=params).json()
    header_row = response[0]
    data_rows = response[1:]

    filtered_header = []
    for field in header_row:
        # keep GEO_ID or any field that doesn't end with these suffixes
        if "GEO_ID" in field or not any(
            field.endswith(suffix) for suffix in ("EA", "M", "MA", "NAME")
        ):
            filtered_header.append(field)

    field_types = {}
    for field in filtered_header:
        idx = header_row.index(field)
        if idx < len(data_rows[0]):
            sample_value = data_rows[0][idx]
            # try to convert to int - if it fails, it's probably a string
            try:
                int(sample_value)
                field_types[field] = "INT"
            except (ValueError, TypeError):
                field_types[field] = "VARCHAR"

    # build table creation fields with proper types
    table_fields = []
    field_names = []
    for field in filtered_header:
        clean_name = field_map.get(field, field).replace(" ", "_")
        field_names.append(clean_name)
        field_type = field_types.get(field, "VARCHAR")  # default to VARCHAR if unsure
        table_fields.append(f"{clean_name} {field_type}")

    # create the table
    table_name = geo.replace(" ", "_")
    create_statement = (
        f'CREATE TABLE "{table_name}_{group}" ({", ".join(table_fields)})'
    )
    con.execute(create_statement)

    # insert data
    print(f"Loading census table {table_name}_{group} to duckdb...\n")
    insert_statement = f'INSERT INTO "{table_name}_{group}" VALUES ({", ".join(["?" for _ in field_names])})'

    for record in data_rows:
        # filter and prepare values
        values = []
        for field in filtered_header:
            idx = header_row.index(field)
            if idx < len(record):
                values.append(record[idx])
            else:
                values.append(None)

        con.execute(insert_statement, values)


def run_sql(sql, geo):
    """
    runs calcs for output
    """
    geo = geo.replace(" ", "_")
    with open(sql, "r") as file:
        sql = file.read()
        sql = sql.replace("table_name", geo)
        con.execute(sql)


def load_dvrpc_geoids_from_json():
    """
    gets dvrpc region only geoids for filtering purposes
    """
    print("Loading DVRPC region geoids...\n")

    # URLs for tract and PUMA geoids
    tract_url = "https://arcgis.dvrpc.org/portal/rest/services/demographics/census_tracts_2020/FeatureServer/0/query?where=dvrpc_reg=%27y%27&outFields=geoid&returnGeometry=false&f=json"
    puma_url = "https://arcgis.dvrpc.org/portal/rest/services/demographics/census_pumas_2020/FeatureServer/0/query?where=dvrpc_reg=%27y%27&outFields=geoid20&returnGeometry=false&f=json"

    tract_response = requests.get(tract_url)
    tract_data = tract_response.json()

    puma_response = requests.get(puma_url)
    puma_data = puma_response.json()

    con.execute("DROP TABLE IF EXISTS census_tracts_2020;")
    con.execute("CREATE TABLE census_tracts_2020 (geoid VARCHAR, dvrpc_reg VARCHAR);")

    con.execute("DROP TABLE IF EXISTS census_pumas_2020;")
    con.execute("CREATE TABLE census_pumas_2020 (geoid20 VARCHAR, dvrpc_reg VARCHAR);")

    for feature in tract_data.get("features", []):
        geoid = feature.get("attributes", {}).get("geoid")
        if geoid:
            con.execute(f"INSERT INTO census_tracts_2020 VALUES ('{geoid}', 'y');")

    for feature in puma_data.get("features", []):
        geoid = feature.get("attributes", {}).get("geoid20")
        if geoid:
            con.execute(f"INSERT INTO census_pumas_2020 VALUES ('{geoid}', 'y');")


def filter_output_by_geoids():
    print("Filtering output to DVRPC region...\n")

    con.execute(
        """
    CREATE TABLE tract_lep_dvrpc AS
    SELECT tl.*
    FROM tract_lep tl
    JOIN census_tracts_2020 cp ON "right"(tl.geography::text, 11) = cp.geoid::text
    WHERE cp.dvrpc_reg::text = 'y'::text
    """
    )

    con.execute(
        """
    CREATE TABLE public_use_microdata_area_lep_dvrpc AS
    SELECT lp.*
    FROM public_use_microdata_area_lep lp
    JOIN census_pumas_2020 cp ON "right"(lp.geography::text, 7) = cp.geoid20::text
    WHERE cp.dvrpc_reg::text = 'y'::text
    """
    )


def generate_filtered_puma_summary():
    """
    puma summary
    """
    print("Generating summary PUMA LEP data for DVRPC region only...\n")

    con.execute(
        """
    CREATE TABLE public_use_microdata_area_B16001_dvrpc AS
    SELECT b.*
    FROM public_use_microdata_area_B16001 b
    JOIN census_pumas_2020 cp ON "right"(b.geography::text, 7) = cp.geoid20::text
    WHERE cp.dvrpc_reg::text = 'y'::text
    """
    )

    # list of columns with _lim
    lim_columns = con.execute(
        """
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'public_use_microdata_area_B16001_dvrpc'
    AND column_name LIKE '%_lim'
    """
    ).fetchall()

    # create results table
    con.execute("DROP TABLE IF EXISTS long_puma_lep_results;")
    con.execute(
        """
    CREATE TABLE long_puma_lep_results (
        language VARCHAR,
        lep_total INTEGER,
        percent_of_total_population DOUBLE,
        percent_of_lep_population DOUBLE
    );
    """
    )

    # calc total pop from filtered table
    total_population = con.execute(
        """
    SELECT SUM(estimatetotal)
    FROM public_use_microdata_area_B16001_dvrpc
    """
    ).fetchone()[0]

    # Initialize total LEP counter
    total_lep = 0

    # each _lim column, calc the sum from filtered table and insert into the results table
    for column in lim_columns:
        column_name = column[0]

        lep_count = con.execute(
            f"""
        SELECT SUM({column_name})
        FROM public_use_microdata_area_B16001_dvrpc
        """
        ).fetchone()[0]

        if lep_count is not None:
            # add to total lep
            total_lep += lep_count

            con.execute(
                f"""
            INSERT INTO long_puma_lep_results (language, lep_total)
            VALUES ('{column_name}', {lep_count});
            """
            )

    # update percent
    if total_lep > 0:
        con.execute(
            f"""
        UPDATE long_puma_lep_results
        SET percent_of_total_population = (lep_total * 100.0 / {total_population}),
            percent_of_lep_population = (lep_total * 100.0 / {total_lep})
        """
        )

    # order nice
    con.execute(
        """
    CREATE TABLE long_puma_lep_results_ordered AS
    SELECT *
    FROM long_puma_lep_results
    ORDER BY lep_total DESC;
    """
    )

    con.execute("DROP TABLE long_puma_lep_results;")
    con.execute(
        "ALTER TABLE long_puma_lep_results_ordered RENAME TO long_puma_lep_results;"
    )


def generate_county_summary():
    """
    county tract summary
    """
    print("Generating county summary from tract data...\n")

    con.execute(
        """
    CREATE TABLE county_lep_summary AS
    WITH county_totals AS (
        -- Calculate total population over 5 years of age by county
        SELECT 
            t.state,
            t.county,
            SUM(t.estimatetotal) AS population_over_5_years,
            -- Sum all language fields ending with _lim
            SUM(t.tt_pop_lep_e) AS persons_defined_as_lep
        FROM 
            tract_lep_dvrpc t
        GROUP BY 
            t.state, t.county
    )
    SELECT
        CASE
            WHEN state = '34' AND county = '005' THEN 'Burlington'
            WHEN state = '34' AND county = '007' THEN 'Camden'
            WHEN state = '34' AND county = '015' THEN 'Gloucester'
            WHEN state = '34' AND county = '021' THEN 'Mercer'
            WHEN state = '42' AND county = '017' THEN 'Bucks'
            WHEN state = '42' AND county = '029' THEN 'Chester'
            WHEN state = '42' AND county = '045' THEN 'Delaware'
            WHEN state = '42' AND county = '091' THEN 'Montgomery'
            WHEN state = '42' AND county = '101' THEN 'Philadelphia'
        END AS county,
        population_over_5_years,
        persons_defined_as_lep,
        ROUND(persons_defined_as_lep * 100.0 / population_over_5_years, 1) || '%' AS percentage_of_lep_persons
    FROM 
        county_totals
    ORDER BY
        -- Order NJ counties first, then PA counties
        CASE WHEN state = '34' THEN 0 ELSE 1 END,
        county;
    """
    )

    # add region total
    con.execute(
        """
    INSERT INTO county_lep_summary
    SELECT
        'DVRPC Region' AS county,
        SUM(population_over_5_years) AS population_over_5_years,
        SUM(persons_defined_as_lep) AS persons_defined_as_lep,
        ROUND(SUM(persons_defined_as_lep) * 100.0 / SUM(population_over_5_years), 1) || '%' AS percentage_of_lep_persons
    FROM 
        county_lep_summary;
    """
    )


os.makedirs("output", exist_ok=True)

field_map = get_field_map(census_url)

for group, geo in groups.items():
    if isinstance(geo, list):
        for option in geo:
            params = {
                "get": f"group({group})",
                "for": f"{option}:*",
                "in": f"state:34,42",
                "key": census_key,
            }
            table_name = f"{option}_{group}"
            acs_tables(census_url, params, group, option)
            run_sql("sql/lep.sql", option)

    else:
        params = {
            "get": f"group({group})",
            "for": f"{geo}:*",
            "in": f"state:34,42",
            "key": census_key,
        }
        table_name = f"{geo}_{group}"
        acs_tables(census_url, params, group, geo)

print(f"Generating output...\n")

load_dvrpc_geoids_from_json()
filter_output_by_geoids()

generate_filtered_puma_summary()
generate_county_summary()

# all results to CSV
con.execute(
    "COPY tract_lep_dvrpc TO 'output/lep_tract_dvrpc.csv' WITH (HEADER, DELIMITER ',');"
)
con.execute(
    "COPY public_use_microdata_area_lep_dvrpc TO 'output/lep_puma_dvrpc.csv' WITH (HEADER, DELIMITER ',');"
)
con.execute(
    "COPY long_puma_lep_results TO 'output/puma_lep_summary.csv' WITH (HEADER, DELIMITER ',');"
)
con.execute(
    "COPY county_lep_summary TO 'output/county_lep_summary.csv' WITH (HEADER, DELIMITER ',');"
)

con.close()
