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
con.execute("INSTALL httpfs; LOAD httpfs;")


def get_field_map(census_url):
    """
    get actual names for census field codes and cleans field names
    """
    print(f"Grabbing variables...\n")
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
        if 'GEO_ID' in field or not any(field.endswith(suffix) for suffix in ('EA', 'M', 'MA', 'NAME')):
            filtered_header.append(field)

    field_types = {}
    for field in filtered_header:
        idx = header_row.index(field)
        if idx < len(data_rows[0]):
            sample_value = data_rows[0][idx]
            # try to convert to int - if it fails, it's probably a string
            try:
                int(sample_value)
                field_types[field] = 'INT'
            except (ValueError, TypeError):
                field_types[field] = 'VARCHAR'
    
    # build table creation fields with proper types
    table_fields = []
    field_names = []
    for field in filtered_header:
        clean_name = field_map.get(field, field).replace(' ', '_')
        field_names.append(clean_name)
        field_type = field_types.get(field, 'VARCHAR') # default to VARCHAR if unsure
        table_fields.append(f"{clean_name} {field_type}")
    
    # create the table
    table_name = geo.replace(' ', '_')
    create_statement = f'CREATE TABLE "{table_name}_{group}" ({", ".join(table_fields)})'
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
    geo = geo.replace(' ', '_')
    with open(sql, 'r') as file:
         sql = file.read()
         sql = sql.replace('table_name', geo)
         con.execute(sql)


os.makedirs('output', exist_ok=True)

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

print(f"Generating output...\n")
con.execute("COPY public_use_microdata_area_lep TO 'output/lep_puma.csv' WITH (HEADER, DELIMITER ',');")
con.execute("COPY tract_lep TO 'output/lep_tract.csv' WITH (HEADER, DELIMITER ',');")

con.close()