getwd()

vars2020 <- load_variables(2020, "acs5")

#census keys
census_api_key("", overwrite = TRUE)
ckey <- ""

# Loop through each year
for (year in years) {
  vars <- load_variables(year, "acs5")
  
  # Get data for pumas
  pumas <- get_acs(geography = "public use microdata area",
                   variables = c16001, 
                   survey = "acs5", 
                   year = lep_year,
                   state = lep_states,
                   output = "wide",
                   geometry = FALSE,
                   cache = TRUE)
  
  # Get data for tracts
  tracts <- get_acs(geography = "tract",
                    variables = c16001, 
                    survey = "acs5", 
                    year = lep_year,
                    state = lep_states,
                    output = "wide",
                    geometry = FALSE,
                    cache = TRUE)
  
  # Get data for pumas2
  pumas2 <- get_acs(geography = "public use microdata area",
                    variables = b16001, 
                    survey = "acs5", 
                    year = lep_year,
                    state = lep_states,
                    output = "wide",
                    geometry = FALSE,
                    cache = TRUE)
  
  # Filtering
  tracts <- filter(tracts, as.numeric(substr(tracts$GEOID, start = 1, stop = 5)) %in% lep_counties)
  pumas <- filter(pumas, pumas$GEOID %in% puma_Codes)
  pumas2 <- filter(pumas2, pumas2$GEOID %in% puma_Codes)
  
  # Joining data
  pumas3 <- left_join(pumas, pumas2, by = "GEOID")
  
  # Renaming columns
  oldnames <- c("old_column_names") # Replace with actual column names
  newnames <- c("new_column_names") # Replace with desired new column names
  
  tracts <- tracts %>% rename_at(vars(oldnames), ~ newnames)
  pumas <- pumas %>% rename_at(vars(oldnames), ~ newnames)
  pumas2 <- pumas2 %>% rename_at(vars(oldnames), ~ newnames)
  
  # Adding calculations
  tracts$pop5pct_E <- (.05 * tracts$TT_POP_E)
  pumas$pop5pct_E <- (.05 * pumas$TT_POP_E)
  
  tracts$TT_POP_LEP_E <- with(tracts, sum(Span_Lim_E, FRE_Lim_E, GER_Lim_E, RUS_Lim_E, IND_Lim_E, KOR_Lim_E,
                                          CHI_Lim_E, Viet_Lim_E, TAG_Lim_E, PAC_Li_E, ARB_Lim_E, OTH_Lim_E))
  pumas$TT_POP_LEP_E <- with(pumas, sum(Span_Lim_E, FRE_Lim_E, GER_Lim_E, RUS_Lim_E, IND_Lim_E, KOR_Lim_E,
                                        CHI_Lim_E, Viet_Lim_E, TAG_Lim_E, PAC_Li_E, ARB_Lim_E, OTH_Lim_E))
  
  # Export data
  write_csv(pumas, here(paste0("pumasLEP_", year, ".csv")))
  write_csv(tracts, here(paste0("tractsLEP_", year, ".csv")))
  write_csv(pumas2, here(paste0("longGrainLEP_", year, ".csv")))
  write_csv(vars, here(paste0("lep", year, "_vars.csv")))
  
  # Export shapefiles
  st_write(pumas2, here(paste0("longGrain_", year, ".shp")))
  st_write(pumas, here(paste0("pumas_", year, ".shp")))
  st_write(tracts, here(paste0("tracts_", year, ".shp")))
}

