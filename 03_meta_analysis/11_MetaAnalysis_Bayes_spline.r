# EBF Bayesian Hierarchical Meta-Analysis — WITH YEAR SPLINE

# -----------------------------
# Install + load packages
# -----------------------------
# Set CRAN mirror for non-interactive knitting/sourcing
options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- c("tidyverse", "haven", "stringr", "writexl", "readr", "R2jags", "splines")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

# -----------------------------
# File path  (edit as needed)
# -----------------------------
data_path <- file.path("..", "data", "derived", "Bayesian_Meta-Analysis_dataset.dta")   

# -----------------------------
# Helper functions
# -----------------------------
logit    <- function(p) log(p / (1 - p))
clamp01  <- function(p, eps = 1e-6) pmin(pmax(p, eps), 1 - eps)
to_num   <- function(x) suppressWarnings(as.numeric(gsub(",", "", as.character(x))))
clean_text <- function(x) {
  x %>%
    as.character() %>%
    stringr::str_squish() %>%
    dplyr::na_if("")
}

# -----------------------------
# Read dataset
# -----------------------------
dat <- haven::read_dta(data_path)

# -----------------------------
# Clean key columns
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
# Build raw_df
# -----------------------------
raw_df <- dat %>%
  mutate(
    Sample_size           = to_num(Sample_size),
    Estimate              = to_num(Estimate),
    Lower_bound           = to_num(Lower_bound),
    Upper_bound           = to_num(Upper_bound),
    Standard_Errors__SE_  = to_num(Standard_Errors__SE_),
    
    study      = study_clean,
    level_type = level_type_clean,
    country    = country_clean,
    region     = region_clean,
    location   = geo_unit_clean
  ) %>%
  mutate(
    location = stringr::str_replace_all(location, '["""]', ""),
    location = stringr::str_replace_all(location, "\\s+", " "),
    location = ifelse(location == "", NA_character_, location)
  ) %>%
  filter(
    !is.na(Estimate),
    (
      (!is.na(Standard_Errors__SE_) & Standard_Errors__SE_ > 0) |
        (!is.na(Lower_bound) & !is.na(Upper_bound) & Upper_bound >= Lower_bound) |
        (!is.na(Sample_size) & Sample_size > 0)
    )
  ) %>%
  transmute(
    study_id = paste0(study, "_", year <- as.numeric(Year_of_Prevalence), "_", row_number()),
    study    = study,
    year     = as.numeric(Year_of_Prevalence),
    
    level_type,
    country,
    region,
    location,
    
    n_total     = Sample_size,
    n_effective = Sample_size,
    
    percent = clamp01(Estimate / 100),
    
    lb   = Lower_bound / 100,
    ub   = Upper_bound / 100,
    se_p = Standard_Errors__SE_ / 100
  ) %>%
  mutate(
    lb = ifelse(is.na(lb), NA_real_, clamp01(lb)),
    ub = ifelse(is.na(ub), NA_real_, clamp01(ub))
  ) %>%
  filter(
    !is.na(percent),
    !is.na(year),
    !is.na(country), country != "",
    !is.na(region),  region  != "",
    !is.na(level_type), level_type != ""
  )

cat("Rows after initial filtering:", nrow(raw_df), "\n")

# -----------------------------
# Compute y_logit + se_logit
# -----------------------------
df <- raw_df %>%
  mutate(
    district = case_when(
      level_type %in% c("District", "City") & !is.na(location) & location != "" ~ location,
      TRUE ~ NA_character_
    ),
    
    y_logit = logit(percent),
    
    se_logit_raw = dplyr::case_when(
      !is.na(se_p) & se_p > 0 ~ se_p / (percent * (1 - percent)),
      !is.na(lb) & !is.na(ub) & ub >= lb ~ (logit(ub) - logit(lb)) / (2 * 1.96),
      !is.na(n_effective) & n_effective > 0 ~ sqrt(1 / (n_effective * percent * (1 - percent))),
      TRUE ~ NA_real_
    )
  ) %>%
  mutate(
    se_logit = pmax(se_logit_raw, 0.10)
  ) %>%
  filter(is.finite(y_logit), is.finite(se_logit), se_logit > 0, !is.na(year))

cat("Rows used in model:", nrow(df), "\n")

# -----------------------------
# Indices: district, country, region
# -----------------------------
hierarchy_lookup <- df %>%
  distinct(country, region) %>%
  arrange(country) %>%
  mutate(
    country_id = row_number(),
    region_id  = as.numeric(factor(region, levels = sort(unique(region))))
  )

district_lookup <- df %>%
  filter(!is.na(district), district != "") %>%
  distinct(district, country) %>%
  arrange(district) %>%
  left_join(hierarchy_lookup %>% select(country, country_id), by = "country") %>%
  mutate(district_id = row_number())

df_indexed <- df %>%
  left_join(hierarchy_lookup, by = c("country", "region")) %>%
  left_join(district_lookup %>% select(district, district_id), by = "district") %>%
  mutate(
    has_district     = ifelse(is.na(district_id), 0L, 1L),
    district_id_jags = ifelse(is.na(district_id), 1L, district_id)
  )

# ============================================================
# YEAR SPLINE  — cubic B-spline on year of prevalence
# ============================================================
N_KNOTS <- 3

year_obs   <- df_indexed$year
year_min   <- min(year_obs)
year_max   <- max(year_obs)

year_scaled <- (year_obs - year_min) / (year_max - year_min)

knot_probs     <- seq(0, 1, length.out = N_KNOTS + 2)[c(-1, -(N_KNOTS + 2))]
interior_knots <- quantile(year_scaled, probs = knot_probs)

B_raw <- splines::bs(
  year_scaled,
  knots      = interior_knots,
  degree     = 3,
  intercept  = FALSE,
  Boundary.knots = c(0, 1)
)

B_spline      <- as.matrix(B_raw)
N_spline_cols <- ncol(B_spline)

df_indexed$year_scaled <- year_scaled

cat(sprintf(
  "\nYear spline: %d interior knots, %d basis columns, year range %d-%d\n",
  N_KNOTS, N_spline_cols, year_min, year_max
))

spline_meta <- list(
  N_KNOTS        = N_KNOTS,
  N_spline_cols  = N_spline_cols,
  interior_knots = interior_knots,
  year_min       = year_min,
  year_max       = year_max,
  B_spline       = B_spline
)

# ============================================================
# Build JAGS data list
# ============================================================
ebf_data <- list(
  y_logit        = df_indexed$y_logit,
  se_logit       = df_indexed$se_logit,
  study_country  = df_indexed$country_id,
  study_district = df_indexed$district_id_jags,
  has_district   = df_indexed$has_district,
  B_spline       = B_spline,
  N_spline_cols  = N_spline_cols,
  N_studies      = nrow(df_indexed),
  N_districts    = nrow(district_lookup),
  region_map     = hierarchy_lookup$region_id,
  N_countries    = nrow(hierarchy_lookup),
  N_regions      = max(hierarchy_lookup$region_id)
)

cat("N_studies  :", ebf_data$N_studies, "\n")
cat("N_countries:", ebf_data$N_countries, "\n")
cat("N_regions  :", ebf_data$N_regions, "\n")
cat("N_districts:", ebf_data$N_districts, "\n")
cat("N_spline_cols:", ebf_data$N_spline_cols, "\n")

# ============================================================
# Verify all required objects exist before JAGS script runs
# ============================================================
required_objects <- c(
  "raw_df", "df", "df_indexed", "hierarchy_lookup",
  "ebf_data", "spline_meta"
)

missing_objects <- required_objects[!vapply(required_objects, exists, logical(1))]
if (length(missing_objects) > 0) {
  stop(paste("Missing objects:", paste(missing_objects, collapse = ", ")))
}

cat("\nAll required objects created successfully.\n")

#--------------------------------------------------------------------------#
### END ###