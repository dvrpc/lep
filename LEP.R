getwd()

#census keys
census_api_key("219399afeaa3b3c28f7b5351b56bb92d7d0f576d", overwrite = TRUE)
ckey <- "219399afeaa3b3c28f7b5351b56bb92d7d0f576d"

#grab that data!
pumas <- get_acs(geography = "public use microdata area",
                    variables = c16001, 
                    survey = "acs5", 
                    year = lep_year,
                    state = lep_states,
                    output = "wide",
                    geometry = TRUE,
                    cache = TRUE)


tracts <- get_acs(geography = "tract",
                 variables = c16001, 
                 survey = "acs5", 
                 year = lep_year,
                 state = lep_states,
                 output = "wide",
                 geometry = TRUE,
                 cache = TRUE)

pumas2 <- get_acs(geography = "public use microdata area",
                 variables = b16001, 
                 survey = "acs5", 
                 year = lep_year,
                 state = lep_states,
                 output = "wide",
                 geometry = TRUE,
                 cache = TRUE)

#filter
tracts <- filter(tracts, as.numeric(substr(tracts$GEOID, start = 1, stop = 5)) %in% lep_counties)
pumas <- filter(pumas, pumas$GEOID %in% puma_Codes)
pumas2 <- filter(pumas2, pumas2$GEOID %in% puma_Codes)

#change classes

#export
write_csv(pumas, here("pumasLEP.csv"))
write_csv(tracts, here("tractsLEP.csv"))
write_csv(pumas2, here("longGrainLEP.csv"))

#get spatial
st_write(pumas2, here("longGrain.shp"))
st_write(pumas, here("pumas.shp"))
st_write(tracts, here("tracts.shp"))
