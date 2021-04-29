# Dependencies
library(plyr); library(here); library(sf); library(summarytools); library(survey); library(srvyr); library(sjmisc)
library(tidycensus); library(tidyverse); library(tigris); library(dplyr); library(descr); library(sp); library(rgdal); library(raster)

getwd()

census_api_key("INSERT_API_KEY_HERE", overwrite = TRUE)

lep_year <- 2019
lep_states <- c("PA", "NJ")
lep_counties <-c(34005, 34007, 34015, 34021, 42017, 42029, 42045, 42091, 42101)
puma_Codes <- c(4203001,
                4203002,
                4203003,
                4203004,
                4203101,
                4203102,
                4203103,
                4203104,
                4203105,
                4203106,
                4203202,
                4203203,
                4203204,
                4203205,
                4203206,
                4203207,
                4203208,
                4203210,
                4203211,
                4203301,
                4203302,
                4203304,
                4203402,
                4203404,
                4203201,
                4203209,
                4203303,
                4203401,
                4203403,
                3402101,
                3402102,
                3402103,
                3402104,
                3402201,
                3402001,
                3402003,
                3402202,
                3402301,
                3402302,
                3402303,
                3402002
) 


vari <- c("C16001_001",
          "C16001_002",
          "C16001_003",
          "C16001_004",
          "C16001_005",
          "C16001_006",
          "C16001_007",
          "C16001_008",
          "C16001_009",
          "C16001_010",
          "C16001_011",
          "C16001_012",
          "C16001_013",
          "C16001_014",
          "C16001_015",
          "C16001_016",
          "C16001_017",
          "C16001_018",
          "C16001_019",
          "C16001_020",
          "C16001_021",
          "C16001_022",
          "C16001_023",
          "C16001_024",
          "C16001_025",
          "C16001_026",
          "C16001_027",
          "C16001_028",
          "C16001_029",
          "C16001_030",
          "C16001_031",
          "C16001_032",
          "C16001_033",
          "C16001_034",
          "C16001_035",
          "C16001_036",
          "C16001_037",
          "C16001_038"
          )

pumas <- get_acs(geography = "public use microdata area",
                    variables = vari, 
                    survey = "acs5", 
                    year = lep_year,
                    state = lep_states,
                    output = "wide",
                    geometry = TRUE,
                    cache = TRUE)


tracts <- get_acs(geography = "tract",
                 variables = vari, 
                 survey = "acs5", 
                 year = lep_year,
                 state = lep_states,
                 output = "wide",
                 geometry = TRUE,
                 cache = TRUE)

test1 <- rename(pumas, C16001_001E = 'Estimate_Total')

names <- v15 <- load_variables(2019, "acs5", cache = TRUE)


tracts <- filter(tracts, as.numeric(substr(tracts$GEOID, start = 1, stop = 5)) %in% lep_counties)

pumas <- filter(pumas, pumas$GEOID %in% puma_Codes)


## EXPORT

write_csv(pumas, here("pumas.csv"))
write_csv(tracts, here("tracts.csv"))

