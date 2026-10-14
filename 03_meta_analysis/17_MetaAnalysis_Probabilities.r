#===============================#
# Probability Plots
#===============================#

# Set CRAN mirror for non-interactive knitting/sourcing
options(repos = c(CRAN = "https://cloud.r-project.org"))

needed_pkgs <- c("tidyverse")
for (p in needed_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

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

# ------------------------------------------------------------------
# Report all year-dependent quantities at REPORT_YEAR (not the spline
# reference year 2000). Country and region posterior draws are shifted
# to REPORT_YEAR by adding the spline value at that year (logit scale).
# Keep this consistent with 18_MetaAnalysis_Results_Section.r.
# ------------------------------------------------------------------
REPORT_YEAR <- 2023
clamp01 <- function(p, eps = 1e-6) pmin(pmax(p, eps), 1 - eps)
.year_s     <- (REPORT_YEAR - spline_meta$year_min) /
  (spline_meta$year_max - spline_meta$year_min)
.B_report   <- as.numeric(splines::bs(
  .year_s, knots = spline_meta$interior_knots, degree = 3,
  intercept = FALSE, Boundary.knots = c(0, 1)))
.spline_off <- as.numeric(ebf_fit$BUGSoutput$sims.list$beta_spline %*% .B_report)
shift_to_year <- function(prev) {
  if (is.null(dim(prev))) plogis(qlogis(clamp01(prev)) + .spline_off)
  else plogis(sweep(qlogis(clamp01(prev)), 1, .spline_off, "+"))
}
prev_country_year <- shift_to_year(ebf_fit$BUGSoutput$sims.list$prev_country)
prev_region_year  <- shift_to_year(ebf_fit$BUGSoutput$sims.list$prev_region)

region_levels_present <- sort(unique(as.character(hierarchy_lookup$region)))

n_counts <- df_indexed |>
  dplyr::group_by(country_id, country) |>
  dplyr::summarise(N_Surveys = dplyr::n(), .groups = "drop")

country_summary <- hierarchy_lookup |>
  dplyr::arrange(country_id) |>
  dplyr::mutate(
    prevalence = apply(prev_country_year, 2, median),
    conf.low   = apply(prev_country_year, 2, quantile, 0.025),
    conf.high  = apply(prev_country_year, 2, quantile, 0.975)
  ) |>
  dplyr::select(country_id, country, region, prevalence, conf.low, conf.high)

prob_target_df <- tibble::tibble(
  country_id = seq_len(ncol(prev_country_year)),
  Prob_Target = apply(prev_country_year >= 0.50, 2, mean)
)

league_table_final <- hierarchy_lookup |>
  dplyr::left_join(
    country_summary |>
      dplyr::select(country_id, prevalence, conf.low, conf.high),
    by = "country_id"
  ) |>
  dplyr::left_join(n_counts |> dplyr::select(country_id, N_Surveys), by = "country_id") |>
  dplyr::left_join(prob_target_df, by = "country_id") |>
  dplyr::group_by(region) |>
  dplyr::mutate(Regional_Rank = rank(dplyr::desc(prevalence), ties.method = "first")) |>
  dplyr::ungroup() |>
  dplyr::arrange(dplyr::desc(prevalence)) |>
  dplyr::mutate(Global_Rank = dplyr::row_number()) |>
  dplyr::select(
    Global_Rank, Regional_Rank,
    Country = country, Region = region,
    `N (Surveys)` = N_Surveys,
    `Posterior Median` = prevalence,
    Lower = conf.low, Upper = conf.high,
    `Target Probability` = Prob_Target
  )

league_table <- league_table_final |>
  dplyr::mutate(
    `Posterior Median` = scales::percent(`Posterior Median`, accuracy = 0.1),
    `95% Credible Interval` = sprintf(
      "[%s, %s]",
      scales::percent(Lower, accuracy = 0.1),
      scales::percent(Upper, accuracy = 0.1)
    ),
    `Target Probability` = scales::percent(`Target Probability`, accuracy = 0.1)
  ) |>
  dplyr::select(
    Global_Rank, Country, `N (Surveys)`,
    `Posterior Median`, `95% Credible Interval`, `Target Probability`
  )

target_plot_data <- league_table_final |>
  dplyr::mutate(
    Certainty_Level = dplyr::case_when(
      `Target Probability` >= 0.90 ~ "High Confidence (>90%)",
      `Target Probability` <= 0.10 ~ "Low Confidence (<10%)",
      TRUE ~ "Moderate / Uncertain"
    ),
    Certainty_Level = factor(
      Certainty_Level,
      levels = c("Low Confidence (<10%)", "Moderate / Uncertain", "High Confidence (>90%)")
    )
  )

target_plot <- target_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = `Target Probability`, y = reorder(Country, `Target Probability`))) +
  ggplot2::geom_segment(
    ggplot2::aes(x = 0, xend = `Target Probability`, yend = Country),
    color = "grey70",
    linewidth = 1.2
  ) +
  ggplot2::geom_point(ggplot2::aes(color = Certainty_Level), size = 2.5) +
  ggplot2::geom_text(
    ggplot2::aes(label = scales::percent(`Target Probability`, accuracy = 1)),
    hjust = -0.5,
    size = 3.5
  ) +
  ggplot2::scale_color_manual(values = c(
    "Low Confidence (<10%)" = "#d7191c",
    "Moderate / Uncertain" = "#fdae61",
    "High Confidence (>90%)" = "#1a9641"
  )) +
  ggplot2::scale_x_continuous(
    labels = scales::percent,
    limits = c(0, 1.15),
    breaks = seq(0, 1, 0.25)
  ) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title = paste0("Probability of Meeting the 50% EBF Target (WHA, 2025) in ", REPORT_YEAR, "\n"),
    x = "",
    y = NULL,
    color = "Assessment:"
  ) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    axis.text.y = ggplot2::element_text(size = 10, face = "italic"),
    legend.position = "bottom"
  )

country_samples_prob <- prev_country_year
region_samples_prob  <- prev_region_year
region_indices <- hierarchy_lookup$region_id

delta_samples <- matrix(
  NA_real_,
  nrow = nrow(country_samples_prob),
  ncol = ncol(country_samples_prob)
)

for (j in seq_len(ncol(country_samples_prob))) {
  delta_samples[, j] <- country_samples_prob[, j] - region_samples_prob[, region_indices[j]]
}

relative_summary <- hierarchy_lookup |>
  dplyr::mutate(
    Relative_Delta = apply(delta_samples, 2, median),
    Lower_95 = apply(delta_samples, 2, quantile, 0.025),
    Upper_95 = apply(delta_samples, 2, quantile, 0.975),
    Prob_Outperforming = apply(delta_samples > 0, 2, mean)
  ) |>
  dplyr::arrange(dplyr::desc(Relative_Delta))

relative_sum.f <- function(searchterm) {
  relative_summary |>
    dplyr::filter(region == searchterm) |>
    dplyr::mutate(
      Regional_Rank = rank(dplyr::desc(Relative_Delta), ties.method = "first"),
      Label = sprintf(
        "%+.1f%% (%+.1f to %+.1f)",
        Relative_Delta * 100,
        Lower_95 * 100,
        Upper_95 * 100
      ),
      Status = dplyr::case_when(
        Lower_95 > 0 ~ "Significant Over-performer",
        Upper_95 < 0 ~ "Significant Under-performer",
        TRUE ~ "Regional Peer"
      )
    ) |>
    dplyr::select(Regional_Rank, country, region, Label, Prob_Outperforming, Status) |>
    dplyr::arrange(Regional_Rank)
}

relative_plot.f <- function(searchterm) {
  summary_sub <- relative_summary |>
    dplyr::filter(region == searchterm)
  
  ggplot2::ggplot(summary_sub, ggplot2::aes(x = Relative_Delta, y = reorder(country, Relative_Delta))) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "darkgrey") +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = Lower_95, xmax = Upper_95),
      width = 0.2,
      color = "grey40"
    ) +
    ggplot2::geom_point(ggplot2::aes(color = Relative_Delta > 0), size = 3) +
    ggplot2::labs(
      title = paste("Region-Relative Performance (EBF) -", region_label(searchterm)),
      subtitle = "\n",
      caption = "\nDots = posterior median | Dashed vertical line = regional benchmark",
      x = "\nPercentage points above/below region",
      y = NULL
    ) +
    ggplot2::theme_minimal() +
    ggplot2::scale_color_manual(values = c("TRUE" = "#21918c", "FALSE" = "#440154")) +
    ggplot2::scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::theme(
      legend.position = "none",
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.title = ggplot2::element_text(size = 10)
    )
}

#----------------------------------------------------------------#
### END ###