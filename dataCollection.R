getwd()

vars2020 <- load_variables(2021, "acs5")

# census keys
Sys.getenv("CENSUS_API_KEY")

# grab that data!
pumas <- get_acs(geography = "public use microdata area", variables = c16001, survey = "acs5", year = lep_year, state = lep_states, output = "wide",
  geometry = FALSE, cache = TRUE)


tracts <- get_acs(geography = "tract", variables = c16001, survey = "acs5", year = lep_year, state = lep_states, output = "wide", geometry = FALSE,
  cache = TRUE)

pumas2 <- get_acs(geography = "public use microdata area", variables = b16001, survey = "acs5", year = lep_year, state = lep_states, output = "wide",
  geometry = TRUE, cache = TRUE)

# filter
tracts <- filter(tracts, as.numeric(substr(tracts$GEOID, start = 1, stop = 5)) %in% lep_counties)
pumas <- filter(pumas, pumas$GEOID %in% puma_Codes)
pumas2 <- filter(pumas2, pumas2$GEOID %in% puma_Codes)
# pumas3 <- left_join(pumas, pumas2, by = 'GEOID')

# change names
tracts <- tracts %>%
  rename_at(vars(oldnames), ~newnames)
pumas <- pumas %>%
  rename_at(vars(oldnames), ~newnames)
# pumas2 <- pumas2 %>% rename_at(vars(oldnames), ~ newnames) pumas3 <- pumas3 %>% rename_at(vars(oldnames), ~ newnames)

# add 5% of total pop
tracts$pop5pct_e <- (0.05 * tracts$tt_pop_e)
pumas$pop5pct_e <- (0.05 * pumas$tt_pop_e)

# total lep pop
tracts$tt_pop_lep_e <- tracts$span_lim_e + tracts$fre_lim_e + tracts$ger_lim_e + tracts$rus_lim_e + tracts$ind_lim_e + tracts$kor_lim_e + tracts$chi_lim_e +
  tracts$viet_lim_e + tracts$tag_lim_e + tracts$pac_lim_e + tracts$arb_lim_e + tracts$oth_lim_e

pumas$tt_pop_lep_e <- pumas$span_lim_e + pumas$fre_lim_e + pumas$ger_lim_e + pumas$rus_lim_e + pumas$ind_lim_e + pumas$kor_lim_e + pumas$chi_lim_e +
  pumas$viet_lim_e + pumas$tag_lim_e + pumas$pac_lim_e + pumas$arb_lim_e + pumas$oth_lim_e
# tag limited eng pops over 5 percent

# total lep pop
tracts$tt_pop_lep_e <- tracts$span_lim_e + tracts$fre_lim_e + tracts$ger_lim_e + tracts$rus_lim_e + tracts$ind_lim_e + tracts$kor_lim_e + tracts$chi_lim_e +
  tracts$viet_lim_e + tracts$tag_lim_e + tracts$pac_lim_e + tracts$arb_lim_e + tracts$oth_lim_e

pumas$tt_pop_lep_e <- pumas$span_lim_e + pumas$fre_lim_e + pumas$ger_lim_e + pumas$rus_lim_e + pumas$ind_lim_e + pumas$kor_lim_e + pumas$chi_lim_e +
  pumas$viet_lim_e + pumas$tag_lim_e + pumas$pac_lim_e + pumas$arb_lim_e + pumas$oth_lim_e
# tag limited eng pops over 5 percent

# tracts
tracts$splime_5p <- tracts$pop5pct_e < tracts$span_lim_e
tracts$frlime_5p <- tracts$pop5pct_e < tracts$fre_lim_e
tracts$gelime_5p <- tracts$pop5pct_e < tracts$ger_lim_e
tracts$rulime_5p <- tracts$pop5pct_e < tracts$rus_lim_e
tracts$inlime_5p <- tracts$pop5pct_e < tracts$ind_lim_e
tracts$kolime_5p <- tracts$pop5pct_e < tracts$kor_lim_e
tracts$chlime_5p <- tracts$pop5pct_e < tracts$chi_lim_e
tracts$vilime_5p <- tracts$pop5pct_e < tracts$viet_lim_e
tracts$talime_5p <- tracts$pop5pct_e < tracts$tag_lim_e
tracts$palime_5p <- tracts$pop5pct_e < tracts$pac_lim_e
tracts$arlime_5p <- tracts$pop5pct_e < tracts$arb_lim_e
tracts$otlime_5p <- tracts$pop5pct_e < tracts$oth_lim_e

# pumas
pumas$splime_5p <- pumas$pop5pct_e < pumas$span_lim_e
pumas$frlime_5p <- pumas$pop5pct_e < pumas$fre_lim_e
pumas$gelime_5p <- pumas$pop5pct_e < pumas$ger_lim_e
pumas$rulime_5p <- pumas$pop5pct_e < pumas$rus_lim_e
pumas$inlime_5p <- pumas$pop5pct_e < pumas$ind_lim_e
pumas$kolime_5p <- pumas$pop5pct_e < pumas$kor_lim_e
pumas$chlime_5p <- pumas$pop5pct_e < pumas$chi_lim_e
pumas$vilime_5p <- pumas$pop5pct_e < pumas$viet_lim_e
pumas$talime_5p <- pumas$pop5pct_e < pumas$tag_lim_e
pumas$palime_5p <- pumas$pop5pct_e < pumas$pac_lim_e
pumas$arlime_5p <- pumas$pop5pct_e < pumas$arb_lim_e


# id new lep areas
lep_puma_2020 <- read_csv("C:\\Users\\jdobkin\\Documents\\scratch\\lep_puma_2020.csv")
lep_tracts_2020 <- read_csv("C:\\Users\\jdobkin\\Documents\\scratch\\lep_tracts_2020.csv")

# pumas
lep_puma_2020$geoid10 <- as.character(lep_puma_2020$geoid10)
combo_pumas <- pumas %>%
  left_join(lep_puma_2020, by = c(GEOID = "geoid10"))

combo_pumas$change_tag <- combo_pumas %>%
  mutate(change_tag = case_when((combo_pumas$splime_5p.x == TRUE & splime_5p.y == FALSE) ~ "Spainish", (combo_pumas$frlime_5p.x == TRUE & frlime_5p.y ==
    FALSE) ~ "French, Haitian, or Cajun", (combo_pumas$gelime_5p.x == TRUE & gelime_5p.y == FALSE) ~ "German or other West Germanic", (combo_pumas$rulime_5p.x ==
    TRUE & rulime_5p.y == FALSE) ~ "Russian, Polish, or other Slavic", (combo_pumas$inlime_5p.x == TRUE & inlime_5p.y == FALSE) ~ "Other Indo-European ",
    (combo_pumas$kolime_5p.x == TRUE & kolime_5p.y == FALSE) ~ "Korean", (combo_pumas$chlime_5p.x == TRUE & chlime_5p.y == FALSE) ~ "Chinese",
    (combo_pumas$vilime_5p.x == TRUE & vilime_5p.y == FALSE) ~ "Vietnamese", (combo_pumas$talime_5p.x == TRUE & talime_5p.y == FALSE) ~ "Tagalog",
    (combo_pumas$palime_5p.x == TRUE & palime_5p.y == FALSE) ~ "Other Asian and Pacific Island", (combo_pumas$arlime_5p.x == TRUE & arlime_5p.y ==
      FALSE) ~ "Arabic", TRUE ~ "no change"))

changed_pumas <- dplyr::filter(combo_pumas, !grepl("no change", change_tag))

# tracts


# build lim eng tags for tracts
lep_tracts_2020$splime_5p <- lep_tracts_2020$pop5pct_e < tracts$span_lim_e
lep_tracts_2020$frlime_5p <- lep_tracts_2020$pop5pct_e < tracts$fre_lim_e
lep_tracts_2020$gelime_5p <- lep_tracts_2020$pop5pct_e < tracts$ger_lim_e
lep_tracts_2020$rulime_5p <- lep_tracts_2020$pop5pct_e < tracts$rus_lim_e
lep_tracts_2020$inlime_5p <- lep_tracts_2020$pop5pct_e < tracts$ind_lim_e
lep_tracts_2020$kolime_5p <- lep_tracts_2020$pop5pct_e < tracts$kor_lim_e
lep_tracts_2020$chlime_5p <- lep_tracts_2020$pop5pct_e < tracts$chi_lim_e
lep_tracts_2020$vilime_5p <- lep_tracts_2020$pop5pct_e < tracts$viet_lim_e
lep_tracts_2020$talime_5p <- lep_tracts_2020$pop5pct_e < tracts$tag_lim_e
lep_tracts_2020$palime_5p <- lep_tracts_2020$pop5pct_e < tracts$pac_lim_e
lep_tracts_2020$arlime_5p <- lep_tracts_2020$pop5pct_e < tracts$arb_lim_e
lep_tracts_2020$otlime_5p <- lep_tracts_2020$pop5pct_e < tracts$oth_lim_e

lep_tracts_2020$geoid <- as.character(lep_tracts_2020$geoid)
combo_tracts <- tracts %>%
  left_join(lep_tracts_2020, by = c(GEOID = "geoid"))
drops <- c("geometry")
combo_tracts <- combo_tracts[, !(names(combo_tracts) %in% drops)]

combo_tracts$change_tag <- combo_tracts %>%
  mutate(change_tag = case_when((combo_tracts$splime_5p.x == TRUE & splime_5p.y == FALSE) ~ "Spainish", (combo_tracts$frlime_5p.x == TRUE &
    frlime_5p.y == FALSE) ~ "French, Haitian, or Cajun", (combo_tracts$gelime_5p.x == TRUE & gelime_5p.y == FALSE) ~ "German or other West Germanic",
    (combo_tracts$rulime_5p.x == TRUE & rulime_5p.y == FALSE) ~ "Russian, Polish, or other Slavic", (combo_tracts$inlime_5p.x == TRUE & inlime_5p.y ==
      FALSE) ~ "Other Indo-European ", (combo_tracts$kolime_5p.x == TRUE & kolime_5p.y == FALSE) ~ "Korean", (combo_tracts$chlime_5p.x ==
      TRUE & chlime_5p.y == FALSE) ~ "Chinese", (combo_tracts$vilime_5p.x == TRUE & vilime_5p.y == FALSE) ~ "Vietnamese", (combo_tracts$talime_5p.x ==
      TRUE & talime_5p.y == FALSE) ~ "Tagalog", (combo_tracts$palime_5p.x == TRUE & palime_5p.y == FALSE) ~ "Other Asian and Pacific Island",
    (combo_tracts$arlime_5p.x == TRUE & arlime_5p.y == FALSE) ~ "Arabic", TRUE ~ "no change"))
# rewrite as str_detect
changed_tract <- combo_tracts %>%
  filter(str_detect(change_tag, "Spainish|French, Haitian, or Cajun|German or other West Germanic|Russian, Polish, or other Slavic|Other Indo-European |Korean|Chinese|Vietnamese|Tagalog|Other Asian and Pacific Island|Arabic"))
dplyr::filter(combo_tracts, !grepl("no change", change_tag))


combo_tracts$change_tag <- as.character(combo_tracts$change_tag)
changed_tract <- combo_tracts %>%
  dplyr::select(change_tag)
changed_tract %>%
  pull(change_tag$NAME, change_tag$NAME, change_tag$change_tag)
change_tag <- as.data.frame(changed_tract$change_tag$change_tag)
change_tract_list <- cbind(geoid, name)
change_tract_list <- cbind(change_tract_list, change_tag)
change_tract_list %>%
  filter(change_tract_list, !grepl("no change", `changed_tract$change_tag$change_tag`))

# export
write_csv(pumas, here("pumasLEP2.csv"))

write_csv(tracts, here("tractsLEP.csv"))
write_csv(pumas2, here("longGrainLEP.csv"))
write_csv(vars2020, here("lep2020_vars.csv"))
write_csv(change_tract_list, here("changed_tracts.csv"))

# get spatial
st_write(pumas2, here("longForm.shp"))
st_write(pumas, here("pumas.shp"))
st_write(tracts, here("tracts.shp"))