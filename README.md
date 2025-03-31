# Limited English Proficiency (LEP) Calculations and Outputs

This project automates DVRPC's Limited English Proficiency (LEP) analysis, including data download, processing, and output of geospatial datasets. This analysis is based on the [US Census American Community Survey 5 Year Estimates](https://www.census.gov/data/developers/data-sets/acs-5year.html) for Tract and Public Use Microdata Area (PUMAs) geographies.


### Run
1. Clone the repo
    ``` cmd
    git clone https://github.com/dvrpc/lep.git
    ```
2. Create a Python virtual environment with dependencies

    Working in the repo directory from your terminal:

   ```
   cd \lep
   ```
    - create new venv
    ```cmd
    python -m venv venv
    ```
    - activate venv
    ```
    .\venv\scripts\activate
    ```
    - install requirements
    ```
    pip install -r requirements.txt
    ```
3. Modify `year` variable in `lep.py` to accommodate most recent 5 year period.

4. Start the process
    ```
    python lep.py
    ```

## Output
```
./output/lep_puma.geojson
./output/lep_tract.geojson
./output/long_puma_calcs.csv
```