getwd()

vars2020 <- load_variables(2020, "acs5")

#census keys
census_api_key("insert_api_key", overwrite = TRUE)
ckey <- "insert_api_key"

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

#add 5% of total pop
tracts$pop5pct_E <- (.05 * tracts$TT_POP_E)
pumas$pop5pct_E <- (.05 * pumas$TT_POP_E)
#pumas2$pop5pct_E <- (.05 * pumas2$TT_POP_E)
tracts$TT_POP_LEP_E <- with(tracts, sum(Span_Lim_E, FRE_Lim_E, GER_Lim_E, RUS_Lim_E, IND_Lim_E, KOR_Lim_E,
                               CHI_Lim_E, Viet_Lim_E, TAG_Lim_E, PAC_Li_E, ARB_Lim_E, OTH_Lim_E))
pumas$TT_POP_LEP_E <- with(pumas, sum(Span_Lim_E, FRE_Lim_E, GER_Lim_E, RUS_Lim_E, IND_Lim_E, KOR_Lim_E,
                                        CHI_Lim_E, Viet_Lim_E, TAG_Lim_E, PAC_Li_E, ARB_Lim_E, OTH_Lim_E))
#export
write_csv(pumas, here("pumasLEP.csv"))
write_csv(tracts, here("tractsLEP.csv"))
write_csv(pumas2, here("longGrainLEP.csv"))
write_csv(vars2020, here("lep2020_vars.csv"))

#get spatial
st_write(pumas2, here("longGrain.shp"))
st_write(pumas, here("pumas.shp"))
st_write(tracts, here("tracts.shp"))
