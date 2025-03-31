import os
import requests
import duckdb

year = 2023
groups = {
    "C16001": ["tract", "public use microdata area"],
    "B16001": "public use microdata area"
}
census_url = f"https://api.census.gov/data/{year}/acs/acs5"
census_key = ""

con = duckdb.connect(database=':memory:')
con.execute("INSTALL spatial; LOAD spatial; INSTALL httpfs; LOAD httpfs;")


def get_field_map(census_url):
    """
    get actual names for census field codes and cleans field names
    """
    variables = requests.get(census_url + "/variables.json")
    var_data = variables.json()
    field_map = {}
    for key, value in var_data['variables'].items():
        if 'label' in value:
            new_name = value['label'].replace("Estimate!!Total:!!", "").replace("!!", "").replace(':Speak English "very well"', "_w").replace(':Speak English less than "very well"', "_lim").replace(",", "_").replace(":", "").replace("(incl.", "").replace(")", "").replace(" ", "_").replace("__", "_").replace("-", "_").lower()
            field_map[key] = new_name
            if key.endswith('E'):
                moe_key = key[:-1] + 'M'  # replace 'E' with 'M'
                field_map[moe_key] = new_name + '_moe'
    print(f"Grabbed variables...\n")
    return field_map
    

def acs_tables(api_url, params, group, geo):
    """
    gets census data from api and loads into duckdb
    """    
    # census api response to json
    response = requests.get(api_url, params=params).json()
    header_row = response[0]

    # filter fields
    filtered_header = []
    for field in header_row:
        if group.startswith('C'):
            if not field.endswith(('EA', 'M', 'MA', 'NAME', 'GEO_ID')):
                filtered_header.append(field)
        else:
            if not field.endswith(('EA', 'MA', 'NAME', 'GEO_ID')):
                filtered_header.append(field)
                
    # filter records
    filtered_records = []
    for record in response[1:]:
        filtered_record = {}
        for field, value in zip(header_row, record):
            if field in filtered_header:
                filtered_record[field] = value
        filtered_records.append(filtered_record)       

    # table name based on geo
    table_name = geo.replace(' ', '_')

    # field names replace spaces with underscores or remove spaces
    field_names = [field_map.get(field, field).replace(' ', '_') for field in filtered_header]

    # create the table with modified field names
    con.execute(f'CREATE TABLE "{table_name}_{group}" ({", ".join([f"{field.replace(' ', '_')} INT" for field in field_names])})')

    print(f"Loading census table {table_name}_{group} to duckdb...\n")
    # insert statement with modified field names
    insert_statement = f'INSERT INTO "{table_name}_{group}" VALUES ({", ".join(["?" for _ in field_names])})'
    for record in filtered_records:
        values = [record.get(field, None) for field in filtered_header]
        con.execute(insert_statement, values)


def run_sql(sql, geo):
    """
    runs calcs for output
    """
    geo = geo.replace(' ', '_')
    with open(sql, 'r') as file:
         sql = file.read()
         sql = sql.replace('table_name', geo)
         con.execute(sql)

os.makedirs('output', exist_ok=True)

# load gis census boundary to DuckDB
print(f"Loading gis data to duckdb...\n")
con.execute("CREATE TABLE public_use_microdata_area_geom AS SELECT statefp20 as statefp, pumace20 as public_use_microdata_areace, geoid20 as geoid, geom FROM ST_Read('https://arcgis.dvrpc.org/portal/rest/services/Demographics/census_pumas_2020/FeatureServer/0/query?where=dvrpc_reg=%27y%27&outfields=statefp20,pumace20,geoid20&outsr=26918&f=geojson');")
con.execute("CREATE TABLE tract_geom AS SELECT * FROM ST_Read('https://arcgis.dvrpc.org/portal/rest/services/Demographics/census_tracts_2020/FeatureServer/0/query?where=dvrpc_reg=%27y%27&outfields=statefp,tractce,geoid&outsr=26918&f=geojson');")

field_map = get_field_map(census_url)

for group, geo in groups.items():
    if isinstance(geo, list):
        for option in geo:
            params = {
                    "get": f"group({group})",
                    "for": f"{option}:*",
                    "in": f"state:34,42",
                    "key": census_key
                }
            table_name = f'{option}_{group}'
            acs_tables(census_url, params, group, option)
            run_sql('sql/lep.sql', option)

    else:
        params = {
                "get": f"group({group})",
                "for": f"{geo}:*",
                "in": f"state:34,42",
                "key": census_key
            }
        table_name = f'{geo}_{group}'
        acs_tables(census_url, params, group, geo)

print(f"Generating geojson output...\n")
con.execute("COPY public_use_microdata_area_gis TO 'output/lep_puma.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSON');")
con.execute("COPY tract_gis TO 'output/lep_tract.geojson' WITH (FORMAT GDAL, DRIVER 'GeoJSON');")

print(f"PUMA summary...\n")
with open('sql/long_puma_calcs.sql', 'r') as file:
    sql = file.read()
    con.sql(sql).write_csv("output/long_puma_calcs.csv")