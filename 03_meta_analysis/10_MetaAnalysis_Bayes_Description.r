# EBF Bayesian Hierarchical Meta-Analysis Paper - Descriptive Analysis

#####################################################################

# -----------------------------
# Install + load packages
# -----------------------------
pkgs <- c(
  "tidyverse", "haven", "stringr",
  "rjags", "R2jags", "coda", "lattice",
  "writexl", "readr", "janitor"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

# -----------------------------
# File path
# -----------------------------
data_path <- file.path("..", "data", "derived", "Bayesian_Meta-Analysis_dataset.dta")

# -----------------------------
# Helper functions
# -----------------------------
logit <- function(p) log(p / (1 - p))
clamp01 <- function(p, eps = 1e-6) pmin(pmax(p, eps), 1 - eps)
to_num <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))

clean_text <- function(x) {
  x %>%
    as.character() %>%
    stringr::str_squish() %>%
    na_if("")
}

safe_pull_count <- function(df, type_value, value_col) {
  out <- df %>%
    filter(survey_type == type_value) %>%
    pull({{ value_col }})
  if (length(out) == 0) 0 else out
}

# -----------------------------
# Read dataset
# -----------------------------
dat <- haven::read_dta(data_path)

# -----------------------------
# Clean key columns directly from original dataset
# -----------------------------
dat <- dat %>%
  mutate(
    study_clean      = clean_text(Study),
    country_clean    = clean_text(Country),
    region_clean     = clean_text(UNICEF_region),
    level_type_clean = clean_text(District_City_Country),
    geo_unit_clean   = clean_text(Specify_city_district_country)
  ) %>%
  mutate(
    level_type_clean = stringr::str_to_title(level_type_clean)
  )

# -----------------------------
# OPTIONAL: inspect original column names
# -----------------------------
cat("\n==============================\n")
cat("COLUMN NAMES IN DATASET\n")
cat("==============================\n")
print(names(dat))

# -----------------------------
# Count unique values in ORIGINAL dataset
# -----------------------------
n_countries_original <- dat %>%
  filter(!is.na(country_clean)) %>%
  summarise(n = n_distinct(country_clean)) %>%
  pull(n)

n_regions_original <- dat %>%
  filter(!is.na(region_clean)) %>%
  summarise(n = n_distinct(region_clean)) %>%
  pull(n)

n_level_types_original <- dat %>%
  filter(!is.na(level_type_clean)) %>%
  summarise(n = n_distinct(level_type_clean)) %>%
  pull(n)

cat("\n==============================\n")
cat("UNIQUE COUNTS IN ORIGINAL DATASET\n")
cat("==============================\n")
cat("Unique countries in original Country column:", n_countries_original, "\n")
cat("Unique regions in original UNICEF region column:", n_regions_original, "\n")
cat("Unique values in original District/City/Country column:", n_level_types_original, "\n")

cat("\nBreakdown of original District/City/Country values:\n")
print(dat %>% count(level_type_clean, sort = TRUE))

# -----------------------------
# Build raw_df for analysis
# -----------------------------
raw_df <- dat %>%
  mutate(
    Sample_size = to_num(Sample_size),
    Estimate      = to_num(Estimate),
    Lower_bound = to_num(Lower_bound),
    Upper_bound = to_num(Upper_bound),
    Standard_Errors__SE_ = to_num(Standard_Errors__SE_),
    
    study      = study_clean,
    level_type = level_type_clean,
    country    = country_clean,
    region     = region_clean,
    geo_unit   = geo_unit_clean
  ) %>%
  filter(
    !is.na(Estimate),
    (
      (!is.na(Standard_Errors__SE_) & Standard_Errors__SE_ > 0) |
        (!is.na(Lower_bound) & !is.na(Upper_bound) & Upper_bound >= Lower_bound)
    )
  ) %>%
  transmute(
    # Survey identifier: one DHS/MICS/Other survey at country-year level
    survey_id = paste(
      study,
      country,
      Year_of_Prevalence,
      sep = "_"
    ),
    
    # Datapoint identifier: one observation within a survey
    datapoint_id = paste(
      study,
      country,
      Year_of_Prevalence,
      level_type,
      geo_unit,
      sep = "_"
    ),
    
    study,
    year = as.numeric(Year_of_Prevalence),
    
    level_type, country, region, geo_unit,
    
    n_total     = Sample_size,
    n_effective = Sample_size,
    
    percent = clamp01(Estimate / 100),
    
    lb   = Lower_bound / 100,
    ub   = Upper_bound / 100,
    se_p = Standard_Errors__SE_ / 100
  ) %>%
  mutate(
    lb = ifelse(is.na(lb), NA_real_, clamp01(lb)),
    ub = ifelse(is.na(ub), NA_real_, clamp01(ub)),
    survey_type = case_when(
      str_detect(study, regex("\\bDHS\\b|Demographic and Health Survey", ignore_case = TRUE)) ~ "DHS",
      str_detect(study, regex("\\bMICS\\b|Multiple Indicator Cluster Survey", ignore_case = TRUE)) ~ "MICS",
      TRUE ~ "Other"
    )
  ) %>%
  filter(
    !is.na(percent),
    !is.na(country),
    !is.na(region),
    !is.na(level_type)
  )

cat("\n==============================\n")
cat("ROWS AFTER ANALYSIS FILTERING\n")
cat("==============================\n")
cat("Rows after initial filtering (kept only if SE or CI present):", nrow(raw_df), "\n")
cat("Counts by level_type:\n")
print(table(raw_df$level_type, useNA = "ifany"))
cat("Rows missing sample size but kept due to SE or CI:", sum(is.na(raw_df$n_total)), "\n")

# -----------------------------
# Optional check: rows without uncertainty after filtering
# -----------------------------
rows_without_uncertainty <- raw_df %>%
  filter(
    is.na(se_p) &
      (is.na(lb) | is.na(ub))
  )

cat("\nRows remaining without usable uncertainty information:", nrow(rows_without_uncertainty), "\n")

# -----------------------------
# Count unique surveys and datapoints
# -----------------------------
n_unique_surveys <- raw_df %>%
  summarise(n = n_distinct(survey_id)) %>%
  pull(n)

n_unique_datapoints <- raw_df %>%
  summarise(n = n_distinct(datapoint_id)) %>%
  pull(n)

n_duplicate_rows <- nrow(raw_df) - n_unique_datapoints

cat("\n==============================\n")
cat("SURVEYS vs DATAPOINTS\n")
cat("==============================\n")
cat("Total rows in analysis dataset:", nrow(raw_df), "\n")
cat("Number of unique surveys (DHS/MICS country-year):", n_unique_surveys, "\n")
cat("Number of unique datapoints:", n_unique_datapoints, "\n")
cat("Duplicate rows (same datapoint listed more than once):", n_duplicate_rows, "\n")

# -----------------------------
# Survey counts by type
# -----------------------------
surveys_by_type <- raw_df %>%
  distinct(survey_id, survey_type) %>%
  count(survey_type, name = "n_surveys") %>%
  arrange(desc(n_surveys))

datapoints_by_type <- raw_df %>%
  distinct(datapoint_id, survey_type) %>%
  count(survey_type, name = "n_datapoints") %>%
  arrange(desc(n_datapoints))

cat("\n==============================\n")
cat("DHS vs MICS vs OTHER\n")
cat("==============================\n")
cat("\nNumber of surveys by type:\n")
print(surveys_by_type)

cat("\nNumber of datapoints by type:\n")
print(datapoints_by_type)

# -----------------------------
# Optional: duplicated surveys
# -----------------------------
duplicated_surveys <- raw_df %>%
  count(survey_id, study, country, year, survey_type, name = "n_rows") %>%
  filter(n_rows > 1) %>%
  arrange(desc(n_rows), survey_type, country, year)

cat("\nSurveys appearing more than once:\n")
print(duplicated_surveys, n = Inf)

# -----------------------------
# Optional: duplicated datapoints
# -----------------------------
duplicated_datapoints <- raw_df %>%
  count(datapoint_id, study, country, year, level_type, geo_unit, survey_type, name = "n_rows") %>%
  filter(n_rows > 1) %>%
  arrange(desc(n_rows), survey_type, country, year)

cat("\nDatapoints appearing more than once:\n")
print(duplicated_datapoints, n = Inf)

# -----------------------------
# Count unique values in analysis dataset
# -----------------------------
n_countries_analysis <- raw_df %>%
  summarise(n = n_distinct(country)) %>%
  pull(n)

n_regions_analysis <- raw_df %>%
  summarise(n = n_distinct(region)) %>%
  pull(n)

n_level_types_analysis <- raw_df %>%
  summarise(n = n_distinct(level_type)) %>%
  pull(n)

cat("\n==============================\n")
cat("UNIQUE COUNTS IN ANALYSIS DATASET (raw_df)\n")
cat("==============================\n")
cat("Unique countries in analysis dataset:", n_countries_analysis, "\n")
cat("Unique regions in analysis dataset:", n_regions_analysis, "\n")
cat("Unique values in analysis District/City/Country column:", n_level_types_analysis, "\n")

# -----------------------------
# Compare original vs analysis
# -----------------------------
countries_original <- dat %>%
  filter(!is.na(country_clean)) %>%
  distinct(country = country_clean)

countries_analysis <- raw_df %>%
  distinct(country)

dropped_countries <- countries_original %>%
  anti_join(countries_analysis, by = "country") %>%
  arrange(country)

regions_original <- dat %>%
  filter(!is.na(region_clean)) %>%
  distinct(region = region_clean)

regions_analysis <- raw_df %>%
  distinct(region)

dropped_regions <- regions_original %>%
  anti_join(regions_analysis, by = "region") %>%
  arrange(region)

levels_original <- dat %>%
  filter(!is.na(level_type_clean)) %>%
  distinct(level_type = level_type_clean)

levels_analysis <- raw_df %>%
  distinct(level_type)

dropped_level_types <- levels_original %>%
  anti_join(levels_analysis, by = "level_type") %>%
  arrange(level_type)

cat("\n==============================\n")
cat("DROPPED VALUES AFTER ANALYSIS FILTERS\n")
cat("==============================\n")
cat("Countries in original data but not in analysis dataset:", nrow(dropped_countries), "\n")
cat("Regions in original data but not in analysis dataset:", nrow(dropped_regions), "\n")
cat("Level types in original data but not in analysis dataset:", nrow(dropped_level_types), "\n")

if (nrow(dropped_countries) > 0) {
  cat("\nDropped countries:\n")
  print(dropped_countries, n = Inf)
}

if (nrow(dropped_regions) > 0) {
  cat("\nDropped regions:\n")
  print(dropped_regions, n = Inf)
}

if (nrow(dropped_level_types) > 0) {
  cat("\nDropped level types:\n")
  print(dropped_level_types, n = Inf)
}

# -----------------------------
# Descriptive summaries
# -----------------------------
cat("\n==============================\n")
cat("DESCRIPTIVE SUMMARIES\n")
cat("==============================\n\n")

# Create output folder
output_dir <- "summary_tables"
if (!dir.exists(output_dir)) dir.create(output_dir)

# 1. Overall summary
summary_overall <- tibble(
  total_rows_analysis = nrow(raw_df),
  total_unique_surveys = n_unique_surveys,
  total_unique_datapoints = n_unique_datapoints,
  duplicate_rows = n_duplicate_rows,
  
  n_surveys_DHS = safe_pull_count(surveys_by_type, "DHS", n_surveys),
  n_surveys_MICS = safe_pull_count(surveys_by_type, "MICS", n_surveys),
  n_surveys_other = safe_pull_count(surveys_by_type, "Other", n_surveys),
  
  n_datapoints_DHS = safe_pull_count(datapoints_by_type, "DHS", n_datapoints),
  n_datapoints_MICS = safe_pull_count(datapoints_by_type, "MICS", n_datapoints),
  n_datapoints_other = safe_pull_count(datapoints_by_type, "Other", n_datapoints),
  
  total_countries_original = n_countries_original,
  total_countries_analysis = n_countries_analysis,
  
  total_regions_original = n_regions_original,
  total_regions_analysis = n_regions_analysis,
  
  total_level_types_original = n_level_types_original,
  total_level_types_analysis = n_level_types_analysis,
  
  rows_missing_sample_size = sum(is.na(raw_df$n_total))
)

# 2. Original unique countries
unique_countries_original <- dat %>%
  filter(!is.na(country_clean)) %>%
  distinct(country = country_clean) %>%
  arrange(country)

# 3. Original unique regions
unique_regions_original <- dat %>%
  filter(!is.na(region_clean)) %>%
  distinct(region = region_clean) %>%
  arrange(region)

# 4. Original unique level types
unique_level_types_original <- dat %>%
  filter(!is.na(level_type_clean)) %>%
  distinct(level_type = level_type_clean) %>%
  arrange(level_type)

# 5. Countries per region
countries_per_region <- raw_df %>%
  distinct(region, country) %>%
  count(region, name = "n_countries") %>%
  arrange(desc(n_countries), region)

# 6. Overall observations by level
obs_by_level <- raw_df %>%
  count(level_type, name = "n_observations") %>%
  arrange(desc(n_observations))

# 7. Observations per country
obs_per_country <- raw_df %>%
  count(country, name = "n_observations") %>%
  arrange(desc(n_observations), country)

# 8. Observations per region
obs_per_region <- raw_df %>%
  count(region, name = "n_observations") %>%
  arrange(desc(n_observations), region)

# 9. For each country: Country / District / City counts
level_per_country <- raw_df %>%
  count(country, level_type, name = "n") %>%
  tidyr::pivot_wider(
    names_from = level_type,
    values_from = n,
    values_fill = 0
  ) %>%
  mutate(total = rowSums(across(where(is.numeric)))) %>%
  arrange(desc(total), country)

# 10. For each region: Country / District / City counts
level_per_region <- raw_df %>%
  count(region, level_type, name = "n") %>%
  tidyr::pivot_wider(
    names_from = level_type,
    values_from = n,
    values_fill = 0
  ) %>%
  mutate(total = rowSums(across(where(is.numeric)))) %>%
  arrange(desc(total), region)

# 11. Number of unique countries contributing each level
countries_by_level <- raw_df %>%
  distinct(level_type, country) %>%
  count(level_type, name = "n_countries") %>%
  arrange(desc(n_countries))

# 12. Number of unique regions contributing each level
regions_by_level <- raw_df %>%
  distinct(level_type, region) %>%
  count(level_type, name = "n_regions") %>%
  arrange(desc(n_regions))

# 13. Country x Region lookup
country_region_lookup <- raw_df %>%
  distinct(country, region) %>%
  arrange(region, country)

# 14. Original countries dropped from analysis
dropped_countries_tbl <- dropped_countries

# 15. Original regions dropped from analysis
dropped_regions_tbl <- dropped_regions

# 16. Original level types dropped from analysis
dropped_level_types_tbl <- dropped_level_types

# 17. Original country-region lookup
country_region_lookup_original <- dat %>%
  filter(!is.na(country_clean), !is.na(region_clean)) %>%
  distinct(country = country_clean, region = region_clean) %>%
  arrange(region, country)

# 18. Compare original vs analysis counts side-by-side
comparison_counts <- tibble(
  variable = c("Country", "Region", "District/City/Country"),
  n_unique_original = c(
    n_countries_original,
    n_regions_original,
    n_level_types_original
  ),
  n_unique_analysis = c(
    n_countries_analysis,
    n_regions_analysis,
    n_level_types_analysis
  ),
  n_dropped = n_unique_original - n_unique_analysis
)

# 19. Surveys by type
surveys_by_type_tbl <- surveys_by_type

# 20. Datapoints by type
datapoints_by_type_tbl <- datapoints_by_type

# 21. Duplicated surveys
duplicate_surveys_tbl <- duplicated_surveys

# 22. Duplicated datapoints
duplicate_datapoints_tbl <- duplicated_datapoints

# 23. Datapoints per survey
datapoints_per_survey <- raw_df %>%
  distinct(survey_id, datapoint_id, survey_type, study, country, year) %>%
  count(survey_id, survey_type, study, country, year, name = "n_datapoints") %>%
  arrange(desc(n_datapoints), survey_type, country, year)

# -----------------------------
# Print to console
# -----------------------------
cat("Overall summary:\n")
print(summary_overall, width = Inf)

cat("\nComparison counts:\n")
print(comparison_counts)

cat("\nOriginal unique countries:\n")
print(unique_countries_original, n = Inf)

cat("\nOriginal unique regions:\n")
print(unique_regions_original, n = Inf)

cat("\nOriginal unique level types:\n")
print(unique_level_types_original, n = Inf)

cat("\nCountries per region:\n")
print(countries_per_region)

cat("\nObservations by level:\n")
print(obs_by_level)

cat("\nObservations per country:\n")
print(obs_per_country)

cat("\nObservations per region:\n")
print(obs_per_region)

cat("\nCountry-level breakdown:\n")
print(level_per_country)

cat("\nRegion-level breakdown:\n")
print(level_per_region)

cat("\nUnique countries by level:\n")
print(countries_by_level)

cat("\nUnique regions by level:\n")
print(regions_by_level)

cat("\nCountry-region lookup (analysis):\n")
print(country_region_lookup, n = Inf)

cat("\nDropped countries:\n")
print(dropped_countries_tbl, n = Inf)

cat("\nDropped regions:\n")
print(dropped_regions_tbl, n = Inf)

cat("\nDropped level types:\n")
print(dropped_level_types_tbl, n = Inf)

cat("\nSurvey counts by type:\n")
print(surveys_by_type_tbl)

cat("\nDatapoint counts by type:\n")
print(datapoints_by_type_tbl)

cat("\nDuplicate surveys:\n")
print(duplicate_surveys_tbl, n = Inf)

cat("\nDuplicate datapoints:\n")
print(duplicate_datapoints_tbl, n = Inf)

cat("\nDatapoints per survey:\n")
print(datapoints_per_survey, n = Inf)

# -----------------------------
# Export tables
# -----------------------------
summary_tables <- list(
  summary_overall = summary_overall,
  comparison_counts = comparison_counts,
  
  unique_countries_original = unique_countries_original,
  unique_regions_original = unique_regions_original,
  unique_level_types_original = unique_level_types_original,
  
  countries_per_region = countries_per_region,
  observations_by_level = obs_by_level,
  observations_per_country = obs_per_country,
  observations_per_region = obs_per_region,
  
  level_per_country = level_per_country,
  level_per_region = level_per_region,
  
  countries_by_level = countries_by_level,
  regions_by_level = regions_by_level,
  
  country_region_lookup_analysis = country_region_lookup,
  country_region_lookup_original = country_region_lookup_original,
  
  dropped_countries = dropped_countries_tbl,
  dropped_regions = dropped_regions_tbl,
  dropped_level_types = dropped_level_types_tbl,
  
  surveys_by_type = surveys_by_type_tbl,
  datapoints_by_type = datapoints_by_type_tbl,
  duplicate_surveys = duplicate_surveys_tbl,
  duplicate_datapoints = duplicate_datapoints_tbl,
  datapoints_per_survey = datapoints_per_survey
)

excel_file <- file.path(output_dir, "descriptive_summary_tables.xlsx")
writexl::write_xlsx(summary_tables, path = excel_file)

readr::write_csv(summary_overall,                  file.path(output_dir, "overall_summary.csv"))
readr::write_csv(comparison_counts,               file.path(output_dir, "comparison_counts.csv"))
readr::write_csv(unique_countries_original,       file.path(output_dir, "unique_countries_original.csv"))
readr::write_csv(unique_regions_original,         file.path(output_dir, "unique_regions_original.csv"))
readr::write_csv(unique_level_types_original,     file.path(output_dir, "unique_level_types_original.csv"))
readr::write_csv(countries_per_region,            file.path(output_dir, "countries_per_region.csv"))
readr::write_csv(obs_by_level,                    file.path(output_dir, "observations_by_level.csv"))
readr::write_csv(obs_per_country,                 file.path(output_dir, "observations_per_country.csv"))
readr::write_csv(obs_per_region,                  file.path(output_dir, "observations_per_region.csv"))
readr::write_csv(level_per_country,               file.path(output_dir, "level_per_country.csv"))
readr::write_csv(level_per_region,                file.path(output_dir, "level_per_region.csv"))
readr::write_csv(countries_by_level,              file.path(output_dir, "countries_by_level.csv"))
readr::write_csv(regions_by_level,                file.path(output_dir, "regions_by_level.csv"))
readr::write_csv(country_region_lookup,           file.path(output_dir, "country_region_lookup_analysis.csv"))
readr::write_csv(country_region_lookup_original,  file.path(output_dir, "country_region_lookup_original.csv"))
readr::write_csv(dropped_countries_tbl,           file.path(output_dir, "dropped_countries.csv"))
readr::write_csv(dropped_regions_tbl,             file.path(output_dir, "dropped_regions.csv"))
readr::write_csv(dropped_level_types_tbl,         file.path(output_dir, "dropped_level_types.csv"))
readr::write_csv(surveys_by_type_tbl,             file.path(output_dir, "surveys_by_type.csv"))
readr::write_csv(datapoints_by_type_tbl,          file.path(output_dir, "datapoints_by_type.csv"))
readr::write_csv(duplicate_surveys_tbl,           file.path(output_dir, "duplicate_surveys.csv"))
readr::write_csv(duplicate_datapoints_tbl,        file.path(output_dir, "duplicate_datapoints.csv"))
readr::write_csv(datapoints_per_survey,           file.path(output_dir, "datapoints_per_survey.csv"))

# -----------------------------
# Studies overview table
# -----------------------------
# One row per unique study x level x geo_unit x year combination,
# showing level type, location name, year, and UNICEF region.
studies_overview <- dat %>%
  mutate(
    study_clean      = clean_text(Study),
    level_type_clean = stringr::str_to_title(clean_text(District_City_Country)),
    geo_unit_clean   = clean_text(Specify_city_district_country),
    country_clean2   = clean_text(Country),
    region_clean     = clean_text(UNICEF_region),
    year             = as.numeric(Year_of_Prevalence)
  ) %>%
  distinct(
    Study         = study_clean,
    Level         = level_type_clean,
    geo_unit      = geo_unit_clean,
    country       = country_clean2,
    Year          = year,
    UNICEF_Region = region_clean
  ) %>%
  mutate(
    Location = ifelse(
      Level %in% c("City", "District"),
      paste0(geo_unit, ", ", country),
      geo_unit
    )
  ) %>%
  select(Study, Level, Location, Year, UNICEF_Region) %>%
  mutate(UNICEF_Region = ifelse(is.na(UNICEF_Region), "NA", UNICEF_Region)) %>%
  arrange(UNICEF_Region, Location, Year, Study)

cat("\n==============================\n")
cat("STUDIES OVERVIEW TABLE\n")
cat("==============================\n")
print(studies_overview, n = Inf)

readr::write_csv(studies_overview, file.path(output_dir, "studies_overview.csv"))

summary_tables[["studies_overview"]] <- studies_overview
writexl::write_xlsx(summary_tables, path = excel_file)

cat("\nStudies overview table added to:", normalizePath(output_dir), "\n")
cat("Excel workbook updated:", normalizePath(excel_file), "\n")

# =============================================================
# Figure 2 — Density Map: Number of Datapoints per Country
# Shows total data coverage (n observations) per country
# across all data sources (DHS, MICS, published studies)
# =============================================================

# -----------------------------
# Additional packages for map
# -----------------------------
map_pkgs <- c("sf", "rnaturalearth", "rnaturalearthdata", "RColorBrewer")
for (p in map_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

# -----------------------------
# Count total datapoints per country
# Uses country column which includes subnational observations
# assigned to their parent country
# -----------------------------
country_counts <- raw_df %>%
  count(country, name = "n_datapoints") %>%
  arrange(desc(n_datapoints))

cat("\n==============================\n")
cat("DENSITY MAP: DATAPOINTS PER COUNTRY\n")
cat("==============================\n")
cat("Countries with data:", nrow(country_counts), "\n")
cat("Range of datapoints per country:",
    min(country_counts$n_datapoints), "to",
    max(country_counts$n_datapoints), "\n")
cat("\nTop 20 countries by number of observations:\n")
print(country_counts %>% head(20))

# -----------------------------
# Load world map
# -----------------------------
world <- ne_countries(scale = "medium", returnclass = "sf")

# Keep every name-like column the installed rnaturalearth version offers.
# Different package versions use different country names ("Ivory Coast"
# vs "Cote d'Ivoire", "S. Sudan" vs "South Sudan", etc.), which is what
# previously caused matched countries to render as grey.
name_cols <- intersect(c("name", "name_long", "admin", "brk_name",
                         "sovereignt", "name_en"), names(world))
world <- world %>% select(all_of(name_cols), geometry)

# -----------------------------
# Version-proof country matching
# -----------------------------
# Normalise names: transliterate accents (Côte -> Cote), lowercase,
# collapse punctuation/hyphens to spaces, drop a leading "the".
norm_name <- function(x) {
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", " ", x)
  x <- gsub("^the ", "", x)
  trimws(x)
}

# Counting is per OBSERVATION (row), unchanged from the original figure.
# (country_counts is created above.)

# Extra aliases for dataset names whose map name differs beyond
# accents/punctuation, across old and new rnaturalearth versions.
extra_aliases <- list(
  "St. Lucia"             = "Saint Lucia",
  "Turks and Caicos"      = c("Turks and Caicos Is.", "Turks and Caicos Islands"),
  "United States"         = "United States of America",
  "North Macedonia"       = "Macedonia",
  "Eswatini"              = "Swaziland",
  "Cote d'Ivoire"         = "Ivory Coast",
  "Lao PDR"               = "Laos",
  "Turkey"                = "Turkiye",
  "Republic of the Congo" = c("Republic of Congo", "Congo")
)

alias_df <- country_counts %>%
  dplyr::mutate(alias = purrr::map(country, function(cc) {
    unique(norm_name(c(cc, extra_aliases[[cc]])))
  })) %>%
  tidyr::unnest(alias) %>%
  dplyr::distinct(alias, n_datapoints)

count_vec <- stats::setNames(alias_df$n_datapoints, alias_df$alias)

# Normalise every candidate name column of the map, then take the first
# column that produces a match for each country polygon.
world_norms <- sf::st_drop_geometry(world)[, name_cols, drop = FALSE]
world_norms[] <- lapply(world_norms, norm_name)

world_data <- world
world_data$n_datapoints <- apply(world_norms, 1, function(a) {
  a <- unique(a[!is.na(a) & a != ""])
  hits <- count_vec[a]
  hits <- hits[!is.na(hits)]
  if (length(hits)) unname(hits[1]) else NA_real_
})

# -----------------------------
# Verification — read this output every run!
# -----------------------------
world_alias_set <- unique(unlist(world_norms))
unmatched <- country_counts$country[!purrr::map_lgl(
  country_counts$country,
  function(cc) any(norm_name(c(cc, extra_aliases[[cc]])) %in% world_alias_set)
)]

cat("\nDataset countries matched to map:",
    nrow(country_counts) - length(unmatched), "of", nrow(country_counts), "\n")
if (length(unmatched) > 0) {
  cat("NOT matched (will wrongly show as grey - fix extra_aliases!):\n")
  print(unmatched)
} else {
  cat("All dataset countries matched successfully.\n")
}

# -----------------------------
# Categorise counts (same breaks as the original figure)
# -----------------------------
world_data <- world_data %>%
  mutate(
    n_cat = case_when(
      is.na(n_datapoints) ~ "No data",
      n_datapoints == 1   ~ "1",
      n_datapoints <= 3   ~ "2-3",
      n_datapoints <= 5   ~ "4-5",
      n_datapoints <= 10  ~ "6-10",
      n_datapoints <= 20  ~ "11-20",
      TRUE                ~ "21+"
    ),
    n_cat = factor(n_cat, levels = c("1","2-3","4-5","6-10","11-20","21+","No data"))
  )

cat("\nCategory counts:\n")
print(table(world_data$n_cat, useNA = "always"))

# -----------------------------
# Plot — same palette and layout as the original manuscript figure,
# with the updated legend title and no-data label.
# -----------------------------
fig2_cols <- c(
  "1"       = "#C6DBEF",
  "2-3"     = "#9ECAE1",
  "4-5"     = "#6BAED6",
  "6-10"    = "#3182BD",
  "11-20"   = "#08519C",
  "21+"     = "#08306B",
  "No data" = "grey85"   # same no-data grey as Figure 6 / Supp Figure 1
)

density_map <- ggplot(world_data) +
  geom_sf(aes(fill = n_cat), colour = "white", linewidth = 0.15) +
  scale_fill_manual(
    values = fig2_cols,
    breaks = c("1","2-3","4-5","6-10","11-20","21+","No data"),
    labels = function(x) ifelse(x == "No data",
                                "Did not contribute\nsurvey/study", x),
    drop   = FALSE,
    name   = "Number of\nsurveys/studies"
  ) +
  guides(
    fill = guide_legend(
      title.position = "top",
      title.hjust    = 0,
      label.position = "right",
      keyheight      = grid::unit(0.55, "cm"),
      keywidth       = grid::unit(0.55, "cm")
    )
  ) +
  # Robinson projection + theme copied from Figure 6 (map_country) so all
  # three maps in the manuscript share the same look.
  coord_sf(crs = "+proj=robin") +
  theme_void() +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.position  = "right",
    legend.direction = "vertical",
    legend.title     = element_text(size = 10, face = "bold"),
    legend.text      = element_text(size = 9),
    legend.spacing.y = grid::unit(0.12, "cm"),
    plot.margin      = margin(10, 10, 10, 10)
  )

# -----------------------------
# Save
# -----------------------------
ggsave(
  filename = "Figure2_density_map.png",
  plot     = density_map,
  width    = 14,
  height   = 8,
  dpi      = 300,
  bg       = "white"
)


cat("\nFigure 2 density map saved as Figure2_density_map.png\n")

# Also add country counts to summary tables export
summary_tables[["datapoints_per_country_map"]] <- country_counts
writexl::write_xlsx(summary_tables, path = excel_file)
cat("Country counts added to summary tables Excel file.\n")