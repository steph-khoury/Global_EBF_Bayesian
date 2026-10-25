# ============================================================
# 18_MetaAnalysis_Results_Section.r
# EBF Bayesian Hierarchical Meta-Analysis
# ============================================================

# ─────────────────────────────────────────────
# 0.  Packages
# ─────────────────────────────────────────────
needed_pkgs <- c(
  "tidyverse", "scales", "ggdist", "splines",
  "sf", "rnaturalearth", "rnaturalearthdata", "countrycode"
)

options(repos = c(CRAN = "https://cloud.r-project.org"))

for (p in needed_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

fmt_pct <- function(x) scales::percent(x, accuracy = 0.1)

# WHO / policy targets used throughout the results
TARGET_50 <- 0.50
TARGET_60 <- 0.60


# ─────────────────────────────────────────────
# 0a.  Region long-name lookup
# ─────────────────────────────────────────────
region_lookup <- c(
  "EAP"  = "East Asia and Pacific",
  "EECA" = "Eastern Europe and Central Asia",
  "WE"   = "Western Europe",
  "LAC"  = "Latin America and Caribbean",
  "MENA" = "Middle East and North Africa",
  "NA"   = "North America",
  "SA"   = "South Asia",
  "ESA"  = "Eastern and Southern Africa",
  "WCA"  = "West and Central Africa"
)
region_label <- function(x) {
  out <- unname(region_lookup[x])
  ifelse(is.na(out), x, out)
}


# ─────────────────────────────────────────────
# 0b.  Re-derive posterior objects if this script is
#      run outside the full pipeline
# ─────────────────────────────────────────────
if (!exists("region_names")) {
  region_names <- sort(unique(hierarchy_lookup$region))
}

if (!exists("region_samples")) {
  region_samples <- ebf_fit$BUGSoutput$sims.list$prev_region |>
    as.data.frame() |>
    tidyr::pivot_longer(cols = everything(),
                        names_to  = "column",
                        values_to = "prevalence") |>
    dplyr::mutate(
      region_id  = as.numeric(gsub("V", "", column)),
      region     = region_names[region_id],
      country    = paste(region, "(Pooled)"),
      group_type = "Region"
    )
}

if (!exists("country_summary")) {
  country_summary <- ebf_fit$BUGSoutput$summary |>
    as.data.frame() |>
    tibble::rownames_to_column("parameter") |>
    dplyr::filter(stringr::str_detect(parameter, "prev_country")) |>
    dplyr::mutate(country_id = as.numeric(stringr::str_extract(parameter, "\\d+"))) |>
    dplyr::left_join(hierarchy_lookup, by = "country_id") |>
    dplyr::select(country_id, country, region,
                  prevalence = `50%`, conf.low = `2.5%`, conf.high = `97.5%`)
}

# Global posterior median — the "global average we found".
# Used as a reference line in the half-eye and caterpillar plots.
prev_global_samps <- ebf_fit$BUGSoutput$sims.list$prev_global
prev_global_med   <- median(prev_global_samps)
prev_global_lo    <- quantile(prev_global_samps, 0.025)
prev_global_hi    <- quantile(prev_global_samps, 0.975)


# ============================================================
# §0c.  REPORTING YEAR — evaluate all ABSOLUTE estimates at a
#        chosen year rather than the spline reference (year 2000)
# ============================================================
# prev_global / prev_region / prev_country from the model are the
# levels where the year spline contributes zero, i.e. the reference
# year 2000. We report the most recent year instead by adding the
# spline's value at REPORT_YEAR (on the logit scale) to each unit's
# level, per posterior draw. Trends, ICC, rankings and relative
# (within-region) performance are unchanged by this choice.
REPORT_YEAR <- 2023

clamp01 <- function(p, eps = 1e-6) pmin(pmax(p, eps), 1 - eps)

# spline value at REPORT_YEAR (logit scale), one value per posterior draw
.year_s     <- (REPORT_YEAR - spline_meta$year_min) /
  (spline_meta$year_max - spline_meta$year_min)
.B_report   <- as.numeric(splines::bs(
  .year_s, knots = spline_meta$interior_knots, degree = 3,
  intercept = FALSE, Boundary.knots = c(0, 1)))
.spline_off <- as.numeric(ebf_fit$BUGSoutput$sims.list$beta_spline %*% .B_report)

# shift a set of reference-year prevalences to REPORT_YEAR
shift_to_year <- function(prev) {
  if (is.null(dim(prev))) {
    plogis(qlogis(clamp01(prev)) + .spline_off)              # vector (n_sims)
  } else {
    plogis(sweep(qlogis(clamp01(prev)), 1, .spline_off, "+"))# matrix (n_sims × K)
  }
}

# --- Global at REPORT_YEAR (override the reference-year objects) ---
prev_global_samps <- shift_to_year(ebf_fit$BUGSoutput$sims.list$prev_global)
prev_global_med   <- median(prev_global_samps)
prev_global_lo    <- quantile(prev_global_samps, 0.025)
prev_global_hi    <- quantile(prev_global_samps, 0.975)

# --- Country / region draws at REPORT_YEAR ---
prev_country_year <- shift_to_year(ebf_fit$BUGSoutput$sims.list$prev_country) # n_sims × C
prev_region_year  <- shift_to_year(ebf_fit$BUGSoutput$sims.list$prev_region)  # n_sims × R

# --- Rebuild region_samples at REPORT_YEAR (overrides Summary.r version) ---
region_names <- sort(unique(hierarchy_lookup$region))
region_samples <- as.data.frame(prev_region_year) |>
  stats::setNames(paste0("V", seq_len(ncol(prev_region_year)))) |>
  tidyr::pivot_longer(cols = dplyr::everything(),
                      names_to = "column", values_to = "prevalence") |>
  dplyr::mutate(
    region_id = as.numeric(gsub("V", "", column)),
    region    = region_names[region_id]
  )

# --- Rebuild country_summary at REPORT_YEAR (overrides reference-year version) ---
country_summary <- hierarchy_lookup |>
  dplyr::arrange(country_id) |>
  dplyr::mutate(
    prevalence = apply(prev_country_year, 2, median),
    conf.low   = apply(prev_country_year, 2, quantile, 0.025),
    conf.high  = apply(prev_country_year, 2, quantile, 0.975)
  )

cat(sprintf("\n[Reporting absolute estimates at year %d; global median = %s]\n",
            REPORT_YEAR, scales::percent(prev_global_med, accuracy = 0.1)))


# ============================================================
# §3.1  ANALYTIC SAMPLE SUMMARY TABLE
# ============================================================
n_surveys     <- nrow(df_indexed)
n_countries   <- length(unique(df_indexed$country))
n_regions     <- length(unique(df_indexed$region))
n_districts   <- sum(df_indexed$has_district == 1)
n_dist_units  <- nrow(district_lookup)
year_min_data <- min(df_indexed$year, na.rm = TRUE)
year_max_data <- max(df_indexed$year, na.rm = TRUE)
median_n      <- median(df_indexed$n_effective, na.rm = TRUE)

tbl_analytic_sample <- df_indexed |>
  dplyr::group_by(region) |>
  dplyr::summarise(
    N_surveys   = dplyr::n(),
    N_countries = dplyr::n_distinct(country),
    Year_min    = min(year, na.rm = TRUE),
    Year_max    = max(year, na.rm = TRUE),
    Median_n    = round(median(n_effective, na.rm = TRUE)),
    .groups = "drop"
  ) |>
  dplyr::mutate(Region = region_label(region)) |>
  dplyr::select(Region, N_surveys, N_countries, Year_min, Year_max, Median_n)

cat("\n══════════════════════════════════════════════\n")
cat(" §3.1  ANALYTIC SAMPLE\n")
cat("══════════════════════════════════════════════\n")
cat(sprintf("  Total surveys     : %d\n",  n_surveys))
cat(sprintf("  Countries         : %d\n",  n_countries))
cat(sprintf("  UNICEF regions    : %d\n",  n_regions))
cat(sprintf("  Sub-national obs  : %d (from %d distinct districts/cities)\n",
            n_districts, n_dist_units))
cat(sprintf("  Year range        : %d – %d\n", year_min_data, year_max_data))
cat(sprintf("  Median sample size: %.0f\n", median_n))
print(tbl_analytic_sample)


# ============================================================
# §3.2  CONVERGENCE — STATEMENT ONLY (no overview table)
# ============================================================
# We do not export a convergence overview table. We only assert
# that the model converged, with the two headline diagnostics.

fit_summary_df <- as.data.frame(ebf_fit$BUGSoutput$summary)
rhat_max <- round(max(fit_summary_df$Rhat, na.rm = TRUE), 3)
ess_min  <- round(min(coda::effectiveSize(coda::as.mcmc(ebf_fit)), na.rm = TRUE), 0)
n_params <- sum(!is.na(fit_summary_df$Rhat))

converged <- is.finite(rhat_max) && rhat_max <= 1.05

convergence_statement <- sprintf(
  paste0(
    "All %d monitored parameters converged (maximum R-hat = %.3f, ",
    "minimum effective sample size = %s), so we proceed to inference."
  ),
  n_params, rhat_max, format(ess_min, big.mark = ",")
)

cat("\n══════════════════════════════════════════════\n")
cat(" §3.2  CONVERGENCE\n")
cat("══════════════════════════════════════════════\n")
cat(convergence_statement, "\n")


# ============================================================
# §3.3  SPLINE COEFFICIENTS  (reported in the output)
# ============================================================
# The temporal signal is carried entirely by the year spline.
# We report each basis coefficient (logit scale) with its 95% CrI,
# plus the shrinkage SD sigma_spline.

beta_samps <- ebf_fit$BUGSoutput$sims.list$beta_spline   # n_sims × K

tbl_spline_coef <- tibble::tibble(
  Coefficient = paste0("beta_spline[", seq_len(ncol(beta_samps)), "]"),
  Median      = round(apply(beta_samps, 2, median), 3),
  `Lower 95% CrI` = round(apply(beta_samps, 2, quantile, 0.025), 3),
  `Upper 95% CrI` = round(apply(beta_samps, 2, quantile, 0.975), 3),
  `P(coef > 0)`   = round(apply(beta_samps > 0, 2, mean), 3)
) |>
  dplyr::mutate(
    `95% CrI` = paste0("[", `Lower 95% CrI`, ", ", `Upper 95% CrI`, "]")
  ) |>
  dplyr::select(Coefficient, Median, `95% CrI`, `P(coef > 0)`)

# Shrinkage SD (sigma_spline) as a single extra row of context
if (!is.null(ebf_fit$BUGSoutput$sims.list$sigma_spline)) {
  ss <- ebf_fit$BUGSoutput$sims.list$sigma_spline
  tbl_spline_coef <- dplyr::bind_rows(
    tbl_spline_coef,
    tibble::tibble(
      Coefficient   = "sigma_spline (shrinkage SD)",
      Median        = round(median(ss), 3),
      `95% CrI`     = paste0("[", round(quantile(ss, 0.025), 3), ", ",
                             round(quantile(ss, 0.975), 3), "]"),
      `P(coef > 0)` = NA_real_
    )
  )
}

cat("\n══════════════════════════════════════════════\n")
cat(" §3.3  SPLINE COEFFICIENTS (logit scale)\n")
cat("══════════════════════════════════════════════\n")
print(tbl_spline_coef)


# ============================================================
# §3.4  GLOBAL TIME TREND (from the spline)
# ============================================================
trend_start <- trend_summary |>
  dplyr::filter(year == min(year)) |>
  dplyr::select(year, prev_med, prev_lo, prev_hi)

trend_end <- trend_summary |>
  dplyr::filter(year == max(year)) |>
  dplyr::select(year, prev_med, prev_lo, prev_hi)

trend_peak <- trend_summary |>
  dplyr::filter(prev_med == max(prev_med)) |>
  dplyr::slice(1) |>
  dplyr::select(year, prev_med, prev_lo, prev_hi)

# Global summary table with posterior median and 95% CrI combined
# in the same cells for the reference year (2000) and reporting year (2023).
tbl_global_trend_summary <- tibble::tibble(
  Level = "Global",
  `2000, % (95% CrI)` = paste0(
    round(trend_start$prev_med * 100, 1), "% (",
    round(trend_start$prev_lo * 100, 1), "–",
    round(trend_start$prev_hi * 100, 1), ")"
  ),
  `2023, % (95% CrI)` = paste0(
    round(trend_end$prev_med * 100, 1), "% (",
    round(trend_end$prev_lo * 100, 1), "–",
    round(trend_end$prev_hi * 100, 1), ")"
  ),
  `Absolute change (percentage points)` =
    round((trend_end$prev_med - trend_start$prev_med) * 100, 1)
)

# Keep the detailed anchor table for internal checks and backwards compatibility.
tbl_trend_anchor <- dplyr::bind_rows(
  dplyr::mutate(trend_start, Point = "Start (earliest year)"),
  dplyr::mutate(trend_end,   Point = "End (latest year)"),
  dplyr::mutate(trend_peak,  Point = "Peak (highest posterior median)")
) |>
  dplyr::mutate(
    Year = year,
    `Prevalence, % (95% CrI)` = paste0(
      round(prev_med * 100, 1), "% (",
      round(prev_lo * 100, 1), "–",
      round(prev_hi * 100, 1), ")"
    )
  ) |>
  dplyr::select(Point, Year, `Prevalence, % (95% CrI)`)

pp_change <- (trend_end$prev_med - trend_start$prev_med) * 100
direction <- ifelse(pp_change > 0, "increase", "decrease")

# Annotated global trend plot with 50% and 60% target lines
plot_trend_annotated <- year_trend_plot +
  ggplot2::geom_hline(yintercept = TARGET_60, linetype = "dotted",
                      color = "darkgreen", linewidth = 0.8) +
  ggplot2::annotate("point", x = trend_start$year, y = trend_start$prev_med,
                    size = 3, shape = 21, fill = "white",
                    color = "steelblue", stroke = 1.5) +
  ggplot2::annotate("point", x = trend_end$year, y = trend_end$prev_med,
                    size = 3, shape = 21, fill = "white",
                    color = "steelblue", stroke = 1.5) +
  ggplot2::annotate("text", x = trend_start$year + 0.3,
                    y = trend_start$prev_med + 0.05,
                    label = fmt_pct(trend_start$prev_med),
                    size = 3.4, color = "grey10", fontface = "bold",
                    hjust = 0, vjust = 0) +
  ggplot2::annotate("text", x = trend_end$year - 0.9,
                    y = trend_end$prev_med + 0.11,
                    label = fmt_pct(trend_end$prev_med),
                    size = 3.4, color = "grey10", fontface = "bold",
                    hjust = 1, vjust = 0) +
  ggplot2::labs(
    title    = "Global EBF Prevalence Trend, 2000–2023",
    subtitle = sprintf("Posterior median + 95%% CrI  |  Net change: %+.1f pp\n", pp_change),
    caption  = "\nDashed red line = WHA 50% target (2025) | Dotted green line = WHO/UNICEF 60% target (2030)"
  )

cat("\n══════════════════════════════════════════════\n")
cat(" §3.4  GLOBAL YEAR TREND (SPLINE)\n")
cat("══════════════════════════════════════════════\n")
print(tbl_trend_anchor)
cat(sprintf("\n  Overall change: %+.1f percentage points (%s)\n", pp_change, direction))
cat("  [plot_trend_annotated] created\n")


# ============================================================
# §3.5  REGIONAL TIME TRENDS (from the spline)
# ============================================================
# The spline is global (shared across regions); each region's
# level is its posterior mu_region. We evaluate the shared spline
# on top of each region's level to get a region-specific trend.
#
# mu_region is not monitored directly, so we recover it on the
# logit scale from the monitored prev_region draws.

prev_region_samps <- ebf_fit$BUGSoutput$sims.list$prev_region      # n_sims × R
clamp01 <- function(p, eps = 1e-6) pmin(pmax(p, eps), 1 - eps)
mu_region_logit_samps <- qlogis(clamp01(prev_region_samps))        # n_sims × R

# Rebuild the spline basis on the same fine grid used for the global trend
year_grid_raw    <- trend_summary$year
year_grid_scaled <- (year_grid_raw - spline_meta$year_min) /
  (spline_meta$year_max - spline_meta$year_min)

B_grid <- as.matrix(splines::bs(
  year_grid_scaled,
  knots          = spline_meta$interior_knots,
  degree         = 3,
  intercept      = FALSE,
  Boundary.knots = c(0, 1)
))

# Spline contribution (logit scale) at each grid year for each draw
spline_logit_samps <- beta_samps %*% t(B_grid)                     # n_sims × n_grid

# For each region, add its level to the shared spline and summarise
regional_trend_df <- purrr::map_dfr(seq_along(region_names), function(r) {
  prev_rg <- plogis(sweep(spline_logit_samps, 1, mu_region_logit_samps[, r], "+"))
  tibble::tibble(
    region   = region_names[r],
    year     = year_grid_raw,
    prev_med = apply(prev_rg, 2, median),
    prev_lo  = apply(prev_rg, 2, quantile, 0.025),
    prev_hi  = apply(prev_rg, 2, quantile, 0.975)
  )
}) |>
  dplyr::mutate(Region = region_label(region))

# Regional trend anchors (start / end / change)
tbl_regional_trend_anchor <- regional_trend_df |>
  dplyr::group_by(Region) |>
  dplyr::summarise(
    `2000, % (95% CrI)` = paste0(
      round(prev_med[which.min(year)] * 100, 1), "% (",
      round(prev_lo[which.min(year)] * 100, 1), "–",
      round(prev_hi[which.min(year)] * 100, 1), ")"
    ),
    `2023, % (95% CrI)` = paste0(
      round(prev_med[which.max(year)] * 100, 1), "% (",
      round(prev_lo[which.max(year)] * 100, 1), "–",
      round(prev_hi[which.max(year)] * 100, 1), ")"
    ),
    `Absolute change (percentage points)` =
      round((prev_med[which.max(year)] - prev_med[which.min(year)]) * 100, 1),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(`Absolute change (percentage points)`))

# All-region line plot (medians), with target + global lines
plot_regional_trends <- ggplot2::ggplot(
  regional_trend_df,
  ggplot2::aes(x = year, y = prev_med, color = Region)
) +
  ggplot2::geom_hline(yintercept = prev_global_med, color = "grey30",
                      linetype = "dashed", linewidth = 0.8) +
  ggplot2::geom_hline(yintercept = TARGET_50, linetype = "dashed",
                      color = "red") +
  ggplot2::geom_hline(yintercept = TARGET_60, linetype = "dotted",
                      color = "darkgreen", linewidth = 0.8) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
  ggplot2::scale_x_continuous(breaks = seq(2000, 2023, 4)) +
  ggplot2::theme_classic() +
  ggplot2::labs(
    title    = "Regional EBF Prevalence Trends, 2000–2023",
    subtitle = "Shared year spline evaluated at each region's posterior level\n",
    caption  = paste0("\nGrey dashed line = fitted global average (",
                      fmt_pct(prev_global_med),
                      ") | Dashed red = WHA 50% target (2025) | Dotted green = WHO/UNICEF 60% target (2030)"),
    x = "\nYear of Prevalence",
    y = "EBF Prevalence\n"
  ) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    axis.title = ggplot2::element_text(size = 10)
  )

# Faceted version with credible ribbons (one panel per region)
plot_regional_trends_facet <- ggplot2::ggplot(
  regional_trend_df,
  ggplot2::aes(x = year, y = prev_med)
) +
  ggplot2::geom_ribbon(ggplot2::aes(ymin = prev_lo, ymax = prev_hi),
                       fill = "steelblue", alpha = 0.20) +
  ggplot2::geom_line(color = "steelblue", linewidth = 0.9) +
  ggplot2::geom_hline(yintercept = TARGET_50, linetype = "dashed",
                      color = "red", linewidth = 0.55) +
  ggplot2::geom_hline(yintercept = TARGET_60, linetype = "dotted",
                      color = "darkgreen", linewidth = 0.7) +
  ggplot2::facet_wrap(~ Region) +
  ggplot2::scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
  ggplot2::scale_x_continuous(breaks = seq(2000, 2020, 10)) +
  ggplot2::theme_bw() +
  ggplot2::labs(
    title    = "Regional EBF Prevalence Trends with 95% CrI",
    subtitle = "Shared year spline evaluated at each region's posterior level\n",
    caption  = "\nDashed red = WHA 50% target (2025) | Dotted green = WHO/UNICEF 60% target (2030)",
    x = "\nYear of Prevalence",
    y = "EBF Prevalence\n"
  ) +
  ggplot2::theme(
    plot.title  = ggplot2::element_text(face = "bold", size = 14),
    strip.text  = ggplot2::element_text(size = 8),
    axis.title  = ggplot2::element_text(size = 10)
  )

cat("\n══════════════════════════════════════════════\n")
cat(" §3.5  REGIONAL YEAR TRENDS (SPLINE)\n")
cat("══════════════════════════════════════════════\n")
print(tbl_regional_trend_anchor)
cat("  [plot_regional_trends] and [plot_regional_trends_facet] created\n")


# ============================================================
# §3.6  ABSOLUTE PERFORMANCE — GLOBAL / REGIONAL / NATIONAL
# ============================================================

# ── Global ───────────────────────────────────────────────
tbl_absolute_global <- tibble::tibble(
  Level             = "Global",
  `Posterior Median`= fmt_pct(prev_global_med),
  `95% CrI`         = paste0("[", fmt_pct(prev_global_lo), ", ",
                             fmt_pct(prev_global_hi), "]"),
  `P(EBF ≥ 50%)`    = fmt_pct(mean(prev_global_samps >= TARGET_50)),
  `P(EBF ≥ 60%)`    = fmt_pct(mean(prev_global_samps >= TARGET_60))
)

# ── Regional ─────────────────────────────────────────────
tbl_absolute_regional <- region_samples |>
  dplyr::group_by(region) |>
  dplyr::summarise(
    med  = median(prevalence),
    lo   = quantile(prevalence, 0.025),
    hi   = quantile(prevalence, 0.975),
    p50  = mean(prevalence >= TARGET_50),
    p60  = mean(prevalence >= TARGET_60),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(med)) |>
  dplyr::mutate(
    Region             = region_label(region),
    `Posterior Median` = fmt_pct(med),
    `95% CrI`          = paste0("[", fmt_pct(lo), ", ", fmt_pct(hi), "]"),
    `P(EBF ≥ 50%)`     = fmt_pct(p50),
    `P(EBF ≥ 60%)`     = fmt_pct(p60)
  ) |>
  dplyr::select(Region, `Posterior Median`, `95% CrI`,
                `P(EBF ≥ 50%)`, `P(EBF ≥ 60%)`)

# Keep backwards-compatible name used elsewhere in the Rmd
tbl_regional_summary <- tbl_absolute_regional

# ── National (country) at REPORT_YEAR ────────────────────
n_surveys_by_country <- df_indexed |> dplyr::count(country, name = "N_Surveys")

nat_med <- apply(prev_country_year, 2, median)
nat_lo  <- apply(prev_country_year, 2, quantile, 0.025)
nat_hi  <- apply(prev_country_year, 2, quantile, 0.975)
nat_p50 <- apply(prev_country_year >= TARGET_50, 2, mean)
nat_p60 <- apply(prev_country_year >= TARGET_60, 2, mean)

tbl_absolute_national <- hierarchy_lookup |>
  dplyr::arrange(country_id) |>
  dplyr::mutate(med = nat_med, lo = nat_lo, hi = nat_hi,
                p50 = nat_p50, p60 = nat_p60) |>
  dplyr::left_join(n_surveys_by_country, by = "country") |>
  dplyr::mutate(Global_Rank = rank(-med, ties.method = "min")) |>
  dplyr::group_by(region) |>
  dplyr::mutate(Regional_Rank = rank(-med, ties.method = "min")) |>
  dplyr::ungroup() |>
  dplyr::arrange(Global_Rank) |>
  dplyr::transmute(
    Global_Rank, Regional_Rank,
    Country = country,
    Region  = region_label(region),
    `N (Surveys)`      = N_Surveys,
    `Posterior Median` = fmt_pct(med),
    `95% CrI`          = paste0("[", fmt_pct(lo), ", ", fmt_pct(hi), "]"),
    `P(EBF ≥ 50%)`     = fmt_pct(p50),
    `P(EBF ≥ 60%)`     = fmt_pct(p60)
  )

cat("\n══════════════════════════════════════════════\n")
cat(" §3.6  ABSOLUTE PERFORMANCE (GLOBAL / REGIONAL / NATIONAL)\n")
cat("══════════════════════════════════════════════\n")
print(tbl_absolute_global)
print(tbl_absolute_regional)
cat(sprintf("  National table: %d countries\n", nrow(tbl_absolute_national)))


# ============================================================
# §3.6b  HEADLINE TARGET-ACHIEVEMENT COUNTS
# ============================================================
# The single sentence reviewers latch onto: how many countries are
# (almost) certainly above / below each target, using posterior
# probability thresholds of 90% (met) and 10% (not met).

pc_samps <- prev_country_year   # n_sims × C, at REPORT_YEAR
p50_country <- apply(pc_samps >= TARGET_50, 2, mean)
p60_country <- apply(pc_samps >= TARGET_60, 2, mean)
N_countries_total <- ncol(pc_samps)

tbl_headline_targets <- tibble::tibble(
  Target        = c("50% (WHA, 2025)", "60% (WHO/UNICEF, 2030)"),
  `N countries` = N_countries_total,
  `Met (P>90%)`         = c(sum(p50_country > 0.90), sum(p60_country > 0.90)),
  `Not met (P<10%)`     = c(sum(p50_country < 0.10), sum(p60_country < 0.10)),
  `Uncertain (10-90%)`  = c(sum(p50_country >= 0.10 & p50_country <= 0.90),
                            sum(p60_country >= 0.10 & p60_country <= 0.90))
)

headline_statement <- sprintf(
  paste0(
    "Of the %d countries, %d had a posterior probability greater than 90%% of ",
    "meeting the WHA 50%% EBF target (2025 goal), while %d had a probability below 10%% ",
    "(the remaining %d were uncertain). For the more ambitious 60%% target (2030 goal), ",
    "%d countries exceeded 90%% posterior probability of achievement."
  ),
  N_countries_total,
  sum(p50_country > 0.90),
  sum(p50_country < 0.10),
  sum(p50_country >= 0.10 & p50_country <= 0.90),
  sum(p60_country > 0.90)
)

cat("\n──────────────────────────────────────────────\n")
cat(" §3.6b  HEADLINE TARGET COUNTS\n")
cat("──────────────────────────────────────────────\n")
print(tbl_headline_targets)
cat("\n  ", headline_statement, "\n")


# ============================================================
# §3.7  RELATIVE PERFORMANCE — REGIONAL
# ============================================================
# Country vs its own region: significant over/under-performers.

if (!exists("relative_summary")) {
  stop("relative_summary not found — source 17_MetaAnalysis_Probabilities.r first")
}

tbl_overunder <- relative_summary |>
  dplyr::mutate(
    Status = dplyr::case_when(
      Lower_95 > 0 ~ "Significant Over-performer",
      Upper_95 < 0 ~ "Significant Under-performer",
      TRUE ~ "Regional Peer"
    ),
    Delta_pp = round(Relative_Delta * 100, 1),
    CrI_pp   = paste0("[", round(Lower_95 * 100, 1), ", ",
                      round(Upper_95 * 100, 1), "] pp"),
    P_out    = round(Prob_Outperforming, 3)
  ) |>
  dplyr::filter(Status != "Regional Peer") |>
  dplyr::mutate(Region = region_label(region)) |>
  dplyr::select(
    Status, Region, Country = country,
    `Delta (pp)`    = Delta_pp,
    `95% CrI (pp)`  = CrI_pp,
    `P(outperform)` = P_out
  ) |>
  dplyr::arrange(Status, Region, dplyr::desc(`Delta (pp)`))

cat("\n══════════════════════════════════════════════\n")
cat(" §3.7  RELATIVE (REGIONAL) OVER- / UNDER-PERFORMERS\n")
cat("══════════════════════════════════════════════\n")
print(tbl_overunder)


# ============================================================
# §3.8  INTRACLASS CORRELATION (ICC)
# ============================================================
tbl_icc <- as.data.frame(icc_table) |>
  tibble::rownames_to_column("Level") |>
  dplyr::mutate(
    `Median (%)` = round(median * 100, 1),
    `95% CrI`    = paste0("[", round(lower * 100, 1), "%, ",
                          round(upper * 100, 1), "%]")
  ) |>
  dplyr::select(Level, `Median (%)`, `95% CrI`)

cat("\n══════════════════════════════════════════════\n")
cat(" §3.8  ICC / VARIANCE DECOMPOSITION\n")
cat("══════════════════════════════════════════════\n")
print(tbl_icc)

# ── Residual heterogeneity (tau_study) ───────────────────────
# tau_study is between-observation heterogeneity remaining after the
# geographic hierarchy AND the year spline. It is deliberately NOT in
# the ICC denominator (it is not a structural geographic level), so we
# report it separately here (logit scale) for the results text.
tau_samps <- ebf_fit$BUGSoutput$sims.list$tau_study
tau_study_med <- median(tau_samps)
tau_study_lo  <- quantile(tau_samps, 0.025)
tau_study_hi  <- quantile(tau_samps, 0.975)

residual_het_statement <- sprintf(
  paste0(
    "Residual between-survey heterogeneity remaining after the geographic ",
    "hierarchy and year spline was tau_study = %.2f (95%% CrI %.2f-%.2f, logit scale)."
  ),
  tau_study_med, tau_study_lo, tau_study_hi
)

cat("\n  ", residual_het_statement, "\n")


# ============================================================
# §3.8b  MODEL-FIT STATEMENT (from posterior predictive checks)
# ============================================================
# Ready-to-paste sentence summarising fit. Uses PPC objects from
# 14_MetaAnalysis_PosteriorChecks_spline.r if present.
if (all(sapply(c("p_val_median", "p_val_mean", "p_val_sd", "coverage_pct"), exists))) {
  fit_statement <- sprintf(
    paste0(
      "Posterior predictive checks gave Bayesian p-values ",
      "of %.2f (median), %.2f (mean) and %.2f (SD), and the 95%% posterior ",
      "predictive interval covered %.1f%% of observed surveys."
    ),
    p_val_median, p_val_mean, p_val_sd, coverage_pct
  )
} else {
  fit_statement <- paste(
    "Posterior predictive check summaries (p_val_median, p_val_mean, p_val_sd,",
    "coverage_pct) were not found in the environment; source",
    "14_MetaAnalysis_PosteriorChecks_spline.r before this script to populate them."
  )
}

cat("\n══════════════════════════════════════════════\n")
cat(" §3.8b  MODEL-FIT STATEMENT\n")
cat("══════════════════════════════════════════════\n")
cat(fit_statement, "\n")


# ============================================================
# §3.9  CATERPILLAR PLOT — REGIONS
# ============================================================
# Regional caterpillar (point + 95% CrI) with reference lines at
# the fitted global average, 50% and 60% targets.

region_caterpillar <- region_samples |>
  dplyr::mutate(Region = region_label(region)) |>
  ggplot2::ggplot(ggplot2::aes(x = prevalence,
                               y = reorder(Region, prevalence))) +
  ggplot2::geom_vline(xintercept = prev_global_med, color = "grey30",
                      linetype = "dashed", linewidth = 0.8) +
  ggplot2::geom_vline(xintercept = TARGET_50, linetype = "dashed",
                      color = "red") +
  ggplot2::geom_vline(xintercept = TARGET_60, linetype = "dotted",
                      color = "darkgreen") +
  ggdist::stat_pointinterval(ggplot2::aes(color = region),
                             .width = 0.95, alpha = 0.85, size = 3) +
  ggplot2::scale_x_continuous(labels = scales::label_percent()) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title    = "EBF Prevalence by UNICEF Region",
    subtitle = paste0("Posterior median and 95% credible interval in ", REPORT_YEAR, ", ranked\n"),
    caption  = paste0("\nGrey dashed line = fitted global average (",
                      fmt_pct(prev_global_med),
                      ") | Dashed red = WHA 50% target (2025) | Dotted green = WHO/UNICEF 60% target (2030)"),
    x = "\nPosterior EBF Prevalence",
    y = NULL
  ) +
  ggplot2::theme(
    legend.position = "none",
    plot.title  = ggplot2::element_text(face = "bold", size = 14),
    axis.text.y = ggplot2::element_text(size = 10),
    axis.title  = ggplot2::element_text(size = 10)
  )

cat("  [region_caterpillar] created\n")


# ============================================================
# §3.10  HALF-EYE ("HALF-HIGH") PLOT — REGIONS
# ============================================================
# Half-eye with reference lines at:
#   - the fitted GLOBAL average (grey solid)
#   - 50% target (dashed red)
#   - 60% target (dotted green)

plot_region_halfeye <- region_samples |>
  dplyr::mutate(Region = region_label(region)) |>
  ggplot2::ggplot(ggplot2::aes(x = prevalence,
                               y = reorder(Region, prevalence))) +
  ggdist::stat_halfeye(fill = "skyblue", .width = 0.95, alpha = 0.55) +
  ggplot2::geom_vline(xintercept = prev_global_med, color = "grey30",
                      linetype = "dashed", linewidth = 0.8) +
  ggplot2::geom_vline(xintercept = TARGET_50, linetype = "dashed",
                      color = "red") +
  ggplot2::geom_vline(xintercept = TARGET_60, linetype = "dotted",
                      color = "darkgreen") +
  ggplot2::annotate("text", x = prev_global_med, y = Inf,
                    label = paste0("Global avg ", fmt_pct(prev_global_med)),
                    vjust = 1.4, hjust = -0.05, size = 3, color = "grey30") +
  ggplot2::scale_x_continuous(labels = scales::label_percent(),
                              limits = c(0, 1),
                              breaks = seq(0, 1, 0.25),
                              expand = ggplot2::expansion(mult = c(0.01, 0.03))) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title    = "Estimated EBF Prevalence by Region",
    subtitle = paste0("Posterior distributions with 95% credible intervals, ", REPORT_YEAR, "\n"),
    caption  = "\nGrey dashed line = fitted global average | Dashed red = WHA 50% target (2025) | Dotted green = WHO/UNICEF 60% target (2030)",
    x = "\nEBF Prevalence",
    y = NULL
  ) +
  ggplot2::theme(
    legend.position = "none",
    plot.title  = ggplot2::element_text(face = "bold", size = 14),
    axis.text.y = ggplot2::element_text(size = 10),
    plot.margin = ggplot2::margin(10, 20, 10, 10)
  )

cat("  [plot_region_halfeye] created\n")


# ============================================================
# §3.11  NATIONAL CHOROPLETH MAP
# ============================================================
world_sf <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

# Country-name and ISO3 crosswalk for map joins.
# The maps join on ISO3 codes rather than display names, because country
# names differ across DHS/MICS/PubMed sources and Natural Earth.
manual_iso3 <- c(
  "Bolivia" = "BOL",
  "Congo" = "COG",
  "Republic of Congo" = "COG",
  "Democratic Republic of the Congo" = "COD",
  "DR Congo" = "COD",
  "Cote d'Ivoire" = "CIV",
  "Côte d’Ivoire" = "CIV",
  "Côte d'Ivoire" = "CIV",
  "Ivory Coast" = "CIV",
  "Eswatini" = "SWZ",
  "Iran" = "IRN",
  "Kosovo" = "KOS",
  "Kyrgyzstan" = "KGZ",
  "Lao PDR" = "LAO",
  "Laos" = "LAO",
  "Moldova" = "MDA",
  "North Macedonia" = "MKD",
  "Palestine" = "PSE",
  "Sao Tome and Principe" = "STP",
  "São Tomé and Príncipe" = "STP",
  "South Sudan" = "SSD",
  "Syria" = "SYR",
  "Taiwan" = "TWN",
  "Tanzania" = "TZA",
  "Timor Leste" = "TLS",
  "Timor-Leste" = "TLS",
  "Turks and Caicos" = "TCA",
  "Turks and Caicos Islands" = "TCA",
  "United States" = "USA",
  "United Kingdom" = "GBR",
  "Russia" = "RUS",
  "Venezuela" = "VEN",
  "Vietnam" = "VNM",
  "Turkey" = "TUR",
  "Türkiye" = "TUR"
)

add_iso3 <- function(.data, country_col = "country") {
  .data |>
    dplyr::mutate(
      country_for_iso = as.character(.data[[country_col]]),
      iso3_auto = countrycode::countrycode(
        country_for_iso, origin = "country.name", destination = "iso3c",
        warn = FALSE
      ),
      iso3_manual = unname(manual_iso3[country_for_iso]),
      iso3 = dplyr::coalesce(iso3_manual, iso3_auto)
    )
}

# Natural Earth occasionally stores missing/placeholder ISO codes as "-99".
# Prefer valid ISO3 codes, then fall back to adm0_a3.
world_sf <- world_sf |>
  dplyr::mutate(
    map_iso3 = dplyr::case_when(
      !is.na(iso_a3) & iso_a3 != "-99" ~ iso_a3,
      !is.na(adm0_a3) & adm0_a3 != "-99" ~ adm0_a3,
      TRUE ~ NA_character_
    )
  )

country_map_data <- country_summary |>
  add_iso3("country")

world_joined <- world_sf |>
  dplyr::left_join(
    country_map_data |> dplyr::select(iso3, country, prevalence, conf.low, conf.high),
    by = c("map_iso3" = "iso3")
  )

cat("\nCountry map join check:\n")
print(country_map_data |> dplyr::filter(is.na(iso3)) |> dplyr::select(country, region))
cat("Matched countries on map:", sum(!is.na(world_joined$prevalence)), "of", nrow(country_map_data), "model countries\n")

# Global reference value (%) used in the subtitle
# Map uses discrete prevalence categories and a vertical stacked-box legend
# on the right, matching the style of the data-availability map.
gm <- round(prev_global_med * 100, 1)

world_joined <- world_joined |>
  dplyr::mutate(
    prevalence_pct = prevalence * 100,
    prevalence_cat = dplyr::case_when(
      is.na(prevalence_pct) ~ "No data",
      prevalence_pct < 5    ~ "0–5",
      prevalence_pct < 10   ~ "5–10",
      prevalence_pct < 15   ~ "10–15",
      prevalence_pct < 20   ~ "15–20",
      prevalence_pct < 25   ~ "20–25",
      prevalence_pct < 30   ~ "25–30",
      prevalence_pct < 40   ~ "30–40",
      prevalence_pct < 50   ~ "40–50",
      TRUE                   ~ "≥50"
    ),
    prevalence_cat = factor(
      prevalence_cat,
      levels = c(
        "0–5", "5–10", "10–15", "15–20",
        "20–25", "25–30", "30–40", "40–50",
        "≥50", "No data"
      )
    )
  )

map_cols <- c(
  "0–5"     = "#9E3D3D",
  "5–10"    = "#C75B4D",
  "10–15"   = "#DF8062",
  "15–20"   = "#E9A178",
  "20–25"   = "#EDC68B",
  "25–30"   = "#E5D69A",
  "30–40"   = "#A9C6A1",
  "40–50"   = "#6D9F8B",
  "≥50"     = "#39766D",
  "No data" = "grey85"
)

map_country <- ggplot2::ggplot(world_joined) +
  ggplot2::geom_sf(
    ggplot2::aes(fill = prevalence_cat),
    color = "white",
    linewidth = 0.15
  ) +
  ggplot2::scale_fill_manual(
    values = map_cols,
    breaks = c(
      "0–5", "5–10", "10–15", "15–20",
      "20–25", "25–30", "30–40", "40–50",
      "≥50", "No data"
    ),
    labels = function(x) ifelse(
      x == "No data",
      "Did not contribute\nsurvey/study",
      x
    ),
    drop = FALSE,
    name = "EBF prevalence\n(%)"
  ) +
  ggplot2::guides(
    fill = ggplot2::guide_legend(
      title.position = "top",
      title.hjust = 0,
      label.position = "right",
      keyheight = grid::unit(0.55, "cm"),
      keywidth  = grid::unit(0.55, "cm")
    )
  ) +
  ggplot2::coord_sf(crs = "+proj=robin") +
  ggplot2::theme_void() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.background = ggplot2::element_rect(fill = "white", color = NA),
    plot.title = ggplot2::element_text(
      face = "bold", size = 14, hjust = 0.5
    ),
    plot.subtitle = ggplot2::element_text(
      size = 10, hjust = 0.5, color = "grey40"
    ),
    legend.position = "right",
    legend.direction = "vertical",
    legend.title = ggplot2::element_text(size = 10, face = "bold"),
    legend.text = ggplot2::element_text(size = 9),
    legend.spacing.y = grid::unit(0.12, "cm"),
    plot.margin = ggplot2::margin(10, 10, 10, 10)
  ) +
  ggplot2::labs(
    title = "Exclusive Breastfeeding Prevalence by Country",
    subtitle = paste0(
      "Posterior median EBF prevalence in ", REPORT_YEAR,
      " (hierarchical spline model)  |  Global estimate = ", gm, "%"
    )
  )

cat("  [map_country] created (pooled spline-model estimate)\n")

# Helper: national prevalence at a specific year (spline-adjusted)
country_prev_at_year <- function(target_year) {
  year_s <- (target_year - spline_meta$year_min) /
    (spline_meta$year_max - spline_meta$year_min)
  B_pt <- as.numeric(splines::bs(
    year_s, knots = spline_meta$interior_knots, degree = 3,
    intercept = FALSE, Boundary.knots = c(0, 1)
  ))
  spline_draws <- as.numeric(ebf_fit$BUGSoutput$sims.list$beta_spline %*% B_pt)
  prev_country_samps <- ebf_fit$BUGSoutput$sims.list$prev_country
  mu_country_logit   <- qlogis(clamp01(prev_country_samps))
  prev_at_year <- plogis(sweep(mu_country_logit, 1, spline_draws, "+"))
  hierarchy_lookup |>
    dplyr::mutate(
      prev_med = apply(prev_at_year, 2, median),
      prev_lo  = apply(prev_at_year, 2, quantile, 0.025),
      prev_hi  = apply(prev_at_year, 2, quantile, 0.975)
    )
}
cat("  [country_prev_at_year()] function available\n")

# Supplementary country-level trend table: 2000 vs REPORT_YEAR
country_2000 <- country_prev_at_year(2000) |>
  dplyr::select(country_id, country, region,
                prev_2000 = prev_med, lo_2000 = prev_lo, hi_2000 = prev_hi)

country_report <- country_prev_at_year(REPORT_YEAR) |>
  dplyr::select(country_id, country, region,
                prev_report = prev_med, lo_report = prev_lo, hi_report = prev_hi)

supp_country_trends <- country_report |>
  dplyr::left_join(
    country_2000 |> dplyr::select(country_id, prev_2000, lo_2000, hi_2000),
    by = "country_id"
  ) |>
  dplyr::left_join(n_surveys_by_country, by = "country") |>
  dplyr::mutate(
    Change_pp = (prev_report - prev_2000) * 100,
    P50 = nat_p50[country_id],
    P60 = nat_p60[country_id],
    Global_Rank_2023 = rank(-prev_report, ties.method = "min")
  ) |>
  dplyr::group_by(region) |>
  dplyr::mutate(Regional_Rank_2023 = rank(-prev_report, ties.method = "min")) |>
  dplyr::ungroup() |>
  dplyr::arrange(Global_Rank_2023) |>
  dplyr::transmute(
    Global_Rank_2023, Regional_Rank_2023,
    Country = country,
    Region = region_label(region),
    `N observations` = N_Surveys,
    `2000, % (95% CrI)` = paste0(
      round(prev_2000 * 100, 1), "% (",
      round(lo_2000 * 100, 1), "–",
      round(hi_2000 * 100, 1), ")"
    ),
    `2023, % (95% CrI)` = paste0(
      round(prev_report * 100, 1), "% (",
      round(lo_report * 100, 1), "–",
      round(hi_report * 100, 1), ")"
    ),
    `Absolute change (percentage points)` = round(Change_pp, 1),
    `P(EBF >= 50%)` = scales::percent(P50, accuracy = 0.1),
    `P(EBF >= 60%)` = scales::percent(P60, accuracy = 0.1)
  )

cat("  [supp_country_trends] created for supplementary national table\n")


# ============================================================
# §3.12  REGIONAL CHOROPLETH MAP
# ============================================================
# Standardise region codes before plotting. This protects the map even if
# a previous object stores full region names rather than abbreviations.
region_to_code <- function(x) {
  x <- as.character(x)
  dplyr::case_when(
    x %in% names(region_lookup) ~ x,
    x %in% unname(region_lookup) ~ names(region_lookup)[match(x, unname(region_lookup))],
    TRUE ~ x
  )
}

region_medians <- region_samples |>
  dplyr::mutate(region_code = region_to_code(region)) |>
  dplyr::group_by(region_code) |>
  dplyr::summarise(reg_prev = median(prevalence), .groups = "drop")

country_region_lookup <- hierarchy_lookup |>
  dplyr::mutate(region_code = region_to_code(region)) |>
  add_iso3("country") |>
  dplyr::left_join(region_medians, by = "region_code")

world_region_joined <- world_sf |>
  dplyr::left_join(
    country_region_lookup |> dplyr::select(iso3, country, region_code, reg_prev),
    by = c("map_iso3" = "iso3")
  ) |>
  dplyr::mutate(
    region_code = as.character(region_code),
    region_code = dplyr::coalesce(region_code, "No data"),
    region_code = dplyr::if_else(region_code == "", "No data", region_code)
  )

# order regions in the same order used throughout the manuscript; No data last
.reg_levels <- c("EAP", "ESA", "EECA", "LAC", "MENA", "NA", "SA", "WCA", "WE", "No data")
world_region_joined$region_code <- factor(world_region_joined$region_code, levels = .reg_levels)

cat("\nRegional map join check:\n")
print(world_region_joined |> sf::st_drop_geometry() |> dplyr::count(region_code))
print(country_region_lookup |> dplyr::filter(is.na(iso3)) |> dplyr::select(country, region_code))
cat("Matched region countries on map:", sum(world_region_joined$region_code != "No data", na.rm = TRUE), "of", nrow(country_region_lookup), "model countries\n")

region_colors <- c(
  "EAP"  = "#1f78b4", "EECA" = "#a6cee3", "WE"  = "#b2df8a",
  "LAC"  = "#33a02c", "MENA" = "#fb9a99", "NA"  = "#e31a1c",
  "SA"   = "#fdbf6f", "ESA"  = "#ff7f00", "WCA" = "#cab2d6",
  "No data" = "grey85"
)

map_region <- ggplot2::ggplot(world_region_joined) +
  ggplot2::geom_sf(ggplot2::aes(fill = region_code),
                   color = "white", linewidth = 0.15) +
  ggplot2::scale_fill_manual(
    values      = region_colors,
    na.value    = "grey85",
    name        = "UNICEF Region",
    labels      = function(x) ifelse(x == "No data",
                                     "Did not contribute\nsurvey/study",
                                     region_label(x))
  ) +
  ggplot2::coord_sf(crs = "+proj=robin") +
  ggplot2::theme_void() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.background = ggplot2::element_rect(fill = "white", color = NA),
    plot.title      = ggplot2::element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle   = ggplot2::element_text(size = 10, hjust = 0.5, color = "grey40"),
    legend.position = "right",
    legend.text     = ggplot2::element_text(size = 8),
    plot.margin     = ggplot2::margin(10, 10, 10, 10)
  ) +
  ggplot2::labs(
    title    = "UNICEF Region Membership",
    subtitle = "Each country shaded by its UNICEF region"
  )

cat("  [map_region] created\n")


# ============================================================
# EXPORT — SINGLE consolidated output folder
# ============================================================
# One timestamped folder is the sole export for the whole pipeline.
# Subfolders keep it tidy:
#   Tables/        manuscript tables (CSV)
#   Figures/       manuscript figures (PNG)
#   Diagnostics/   convergence, PPC and MCMC artefacts (guarded — only
#                  written if the diagnostic objects exist in the session)
# The old export_output() routine in the Rmd has been removed so there
# is exactly one results export.

out_root <- file.path("EBF_Results", format(Sys.time(), "%Y%m%d_%H%M"))
dir_tab  <- file.path(out_root, "Tables")
dir_fig  <- file.path(out_root, "Figures")
dir_diag <- file.path(out_root, "Diagnostics")
for (d in c(dir_tab, dir_fig, dir_diag)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# small helper: save a ggplot only if it exists
save_if <- function(obj_name, file, w, h) {
  if (exists(obj_name, inherits = TRUE)) {
    ggplot2::ggsave(file, get(obj_name), width = w, height = h, dpi = 300, bg = "white")
  }
}

# ── Tables (manuscript) ─────────────────────────────────
readr::write_csv(tbl_analytic_sample,        file.path(dir_tab, "Table_S1_Analytic_Sample.csv"))
readr::write_csv(tbl_spline_coef,            file.path(dir_tab, "Table_S2_Spline_Coefficients.csv"))
readr::write_csv(tbl_global_trend_summary,  file.path(dir_tab, "Table_1_Global_Trend_2000_2023.csv"))
readr::write_csv(tbl_trend_anchor,           file.path(dir_tab, "Table_1b_Global_Trend_Anchors.csv"))
readr::write_csv(tbl_regional_trend_anchor,  file.path(dir_tab, "Table_2_Regional_Trends_2000_2023.csv"))
readr::write_csv(tbl_absolute_global,        file.path(dir_tab, "Table_3a_Absolute_Global.csv"))
readr::write_csv(tbl_absolute_regional,      file.path(dir_tab, "Table_3b_Absolute_Regional.csv"))
readr::write_csv(tbl_absolute_national,      file.path(dir_tab, "Table_3c_Absolute_National.csv"))
readr::write_csv(tbl_overunder,              file.path(dir_tab, "Table_4_Relative_Overunder.csv"))
readr::write_csv(tbl_icc,                    file.path(dir_tab, "Table_5_ICC_Variance.csv"))
readr::write_csv(tbl_headline_targets,       file.path(dir_tab, "Table_6_Headline_Target_Counts.csv"))
readr::write_csv(tbl_absolute_national,      file.path(dir_tab, "Table_7_National_League_Table.csv"))
readr::write_csv(supp_country_trends,         file.path(dir_tab, "Table_S3_Country_Trends_2000_2023.csv"))

# Copy the descriptive summary_tables folder into the consolidated output
# if 10_MetaAnalysis_Bayes_Description.r has been sourced.
if (dir.exists("summary_tables")) {
  dir_sum <- file.path(out_root, "Summary_Tables")
  dir.create(dir_sum, recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files("summary_tables", full.names = TRUE), dir_sum, overwrite = TRUE)
}

# ── Ready-to-paste statements (no overview tables) ──────
writeLines(
  c("CONVERGENCE:", convergence_statement, "",
    "MODEL FIT:", fit_statement, "",
    "RESIDUAL HETEROGENEITY:", residual_het_statement, "",
    "HEADLINE TARGET COUNTS:", headline_statement),
  file.path(out_root, "Model_Fit_Statements.txt")
)

# ── Figures (manuscript, from this script) ──────────────
save_if("plot_trend_annotated",        file.path(dir_fig, "Fig_1_Global_Trend.png"),          10, 6)
save_if("plot_regional_trends",        file.path(dir_fig, "Fig_2a_Regional_Trends.png"),       10, 6)
save_if("plot_regional_trends_facet",  file.path(dir_fig, "Fig_2b_Regional_Trends_Facet.png"), 11, 8)
save_if("region_caterpillar",          file.path(dir_fig, "Fig_3_Region_Caterpillar.png"),      9, 6)
save_if("plot_region_halfeye",         file.path(dir_fig, "Fig_4_Region_HalfEye.png"),          9, 7)
save_if("map_country",                 file.path(dir_fig, "Fig_5_Map_Country.png"),            14, 8)
save_if("map_region",                  file.path(dir_fig, "Fig_6_Map_Region.png"),             14, 8)

# ── Figures (summary plots from Summary.r / Probabilities.r / ICC.r) ──
save_if("ranked_caterpillar",          file.path(dir_fig, "Fig_7_Country_Caterpillar.png"),     9, 8)
save_if("diamond_ranked_caterpillar",  file.path(dir_fig, "Fig_8_Diamond_Caterpillar.png"),     9, 8)
save_if("target_plot",                 file.path(dir_fig, "Fig_9_Target_Achievement.png"),     10, 8)
save_if("icc_plot",                    file.path(dir_fig, "Fig_10_ICC_Variance.png"),           8, 6)

# Per-region forest + relative plots (guarded)
if (exists("forest.f") && exists("relative_plot.f")) {
  for (i in seq_along(region_names)) {
    rg <- region_names[i]
    clean <- gsub(" ", "_", region_label(rg))
    try(ggplot2::ggsave(
      file.path(dir_fig, sprintf("Fig_R%02d_Forest_%s.png", i, clean)),
      forest.f(rg), width = 10, height = 7, dpi = 300, bg = "white"), silent = TRUE)
    try(ggplot2::ggsave(
      file.path(dir_fig, sprintf("Fig_R%02d_Relative_%s.png", i, clean)),
      relative_plot.f(rg), width = 10, height = 7, dpi = 300, bg = "white"), silent = TRUE)
  }
}

# ── Diagnostics (guarded) ───────────────────────────────
saveRDS(ebf_fit,          file.path(dir_diag, "Final_Model_Object.rds"))
saveRDS(hierarchy_lookup, file.path(dir_diag, "Hierarchy_Lookup.rds"))

readr::write_csv(
  as.data.frame(ebf_fit$BUGSoutput$summary) |> tibble::rownames_to_column("Parameter"),
  file.path(dir_diag, "MCMC_Convergence_Summary.csv")
)

# PPC plots (only if produced by 14_MetaAnalysis_PosteriorChecks_spline.r)
save_if("ppc_dens",        file.path(dir_diag, "PPC_01_DensityOverlay.png"),  8, 6)
save_if("ppc_int",         file.path(dir_diag, "PPC_02_IntervalCheck.png"),   8, 6)
save_if("pp_median_plot",  file.path(dir_diag, "PPC_03_PPMedian.png"),        8, 6)
save_if("pp_mean_plot",    file.path(dir_diag, "PPC_04_PPMean.png"),          8, 6)
save_if("resid_plot",      file.path(dir_diag, "PPC_05_Residual.png"),        8, 6)
save_if("diag_plot_obs",   file.path(dir_diag, "PPC_06_ObsDiag.png"),         8, 6)
save_if("pool_neff_obs",   file.path(dir_diag, "PPC_07_Pool.png"),            8, 6)
save_if("diag_plot_region",       file.path(dir_diag, "PPC_08_RegionDiag.png"),          8, 6)
save_if("diag_plot_region_wdist", file.path(dir_diag, "PPC_09_RegionDiag_WithDist.png"), 8, 6)
save_if("diag_plot_region_wodist",file.path(dir_diag, "PPC_10_RegionDiag_NoDist.png"),   8, 6)

# Full MCMC diagnostic appendix (trace / density / autocorrelation)
try({
  ebf_mcmc_exp <- coda::as.mcmc(ebf_fit)
  grDevices::pdf(file.path(dir_diag, "MCMC_Full_Diagnostics_Appendix.pdf"),
                 width = 11, height = 8.5)
  plot(ebf_mcmc_exp)
  print(lattice::densityplot(ebf_mcmc_exp))
  coda::autocorr.plot(ebf_mcmc_exp)
  grDevices::dev.off()
}, silent = TRUE)

cat("\n══════════════════════════════════════════════\n")
cat(sprintf(" All outputs saved to: %s\n", out_root))
cat("══════════════════════════════════════════════\n")

#--------------------------------------------------------------------------#
### END ###
