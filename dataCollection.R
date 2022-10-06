getwd()

vars2020 <- load_variables(2020, "acs5")

#census keys
census_api_key("insert key", overwrite = TRUE)
ckey <- "insert key"

#grab that data!
pumas <- get_acs(geography = "public use microdata area",
                 variables = c16001, 
                 survey = "acs5", 
                 year = lep_year,
                 state = lep_states,
                 output = "wide",
                 geometry = FALSE,
                 cache = TRUE)


tracts <- get_acs(geography = "tract",
                  variables = c16001, 
                  survey = "acs5", 
                  year = lep_year,
                  state = lep_states,
                  output = "wide",
                  geometry = FALSE,
                  cache = TRUE)

pumas2 <- get_acs(geography = "public use microdata area",
                  variables = b16001, 
                  survey = "acs5", 
                  year = lep_year,
                  state = lep_states,
                  output = "wide",
                  geometry = FALSE,
                  cache = TRUE)

#filter
tracts <- filter(tracts, as.numeric(substr(tracts$GEOID, start = 1, stop = 5)) %in% lep_counties)
pumas <- filter(pumas, pumas$GEOID %in% puma_Codes)
pumas2 <- filter(pumas2, pumas2$GEOID %in% puma_Codes)


pumas3 <- left_join(pumas, pumas2, by = "GEOID")

#change names
tracts <- tracts %>% rename_at(vars(oldnames), ~ newnames)
pumas <- pumas %>% rename_at(vars(oldnames), ~ newnames)
pumas2 <- pumas2 %>% rename_at(vars(oldnames), ~ newnames)


#export
write_csv(pumas, here("pumasLEP.csv"))
write_csv(tracts, here("tractsLEP.csv"))
write_csv(pumas2, here("longGrainLEP.csv"))
write_csv(vars2020, here("lep2020_vars.csv"))

#get spatial
st_write(pumas2, here("longGrain.shp"))
st_write(pumas, here("pumas.shp"))
st_write(tracts, here("tracts.shp"))
