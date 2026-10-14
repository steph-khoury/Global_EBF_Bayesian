# EBF Bayesian Hierarchical Meta-Analysis — POSTERIOR PREDICTIVE CHECKS (SPLINE)

# Set CRAN mirror for non-interactive knitting/sourcing
options(repos = c(CRAN = "https://cloud.r-project.org"))

needed_pkgs <- c("bayesplot", "patchwork", "ggplot2", "dplyr", "grid", "splines")
for (p in needed_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

safe_clamp01 <- function(p, eps = 1e-6) pmin(pmax(p, eps), 1 - eps)

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

region_levels_present <- sort(unique(as.character(df_indexed$region)))

# ============================================================
# JAGS model with PPC — includes year spline
# FIX: y_logit_rep[i] ~ dnorm(mu_eff[i], prec_study)
# ============================================================
ebf_model_ppc <- '
model {
  for (i in 1:N_studies) {

    y_logit[i] ~ dnorm(theta[i], prec_sampling[i])

    prec_sampling[i] <- 1 / pow(se_logit[i], 2)

    theta[i] ~ dnorm(mu_eff[i], prec_study)

    mu_eff[i] <- mu_country[study_country[i]] +
                 (has_district[i] * mu_district_delta[study_district[i]]) +
                 inprod(B_spline[i,], beta_spline[])

    y_logit_rep[i] ~ dnorm(mu_eff[i], prec_study)
  }

  for (k in 1:N_spline_cols) {
    beta_spline[k] ~ dnorm(0, prec_spline)
  }
  sigma_spline ~ dunif(0, 2)
  prec_spline  <- 1 / pow(sigma_spline, 2)

  for (d in 1:N_districts) {
    mu_district_delta[d] ~ dnorm(0, prec_district)
  }

  for (j in 1:N_countries) {
    mu_country[j] ~ dnorm(mu_region[region_map[j]], prec_country)
    prev_country[j] <- ilogit(mu_country[j])
  }

  for (k in 1:N_regions) {
    mu_region[k] ~ dnorm(mu_global, prec_region)
    prev_region[k] <- ilogit(mu_region[k])
  }

  mu_global ~ dnorm(0, 0.01)
  prev_global <- ilogit(mu_global)

  tau_study      ~ dunif(0, 2)
  prec_study     <- 1 / pow(tau_study, 2)
  sigma_district ~ dnorm(0, 4) T(0,)
  sigma_country  ~ dunif(0, 2)
  sigma_region   ~ dunif(0, 2)

  prec_district <- 1 / pow(sigma_district, 2)
  prec_country  <- 1 / pow(sigma_country, 2)
  prec_region   <- 1 / pow(sigma_region, 2)
}
'

ebf_params_ppc <- c(
  "prev_country", "prev_region", "mu_global",
  "sigma_district", "sigma_country", "sigma_region",
  "tau_study", "sigma_spline", "beta_spline",
  "theta", "mu_eff", "y_logit_rep"
)

ebf_fit_ppc <- R2jags::jags(
  data               = ebf_data,
  model.file         = textConnection(ebf_model_ppc),
  parameters.to.save = ebf_params_ppc,
  n.chains           = 3,
  n.iter             = 44000,
  n.burnin           = 4000,
  n.thin             = 5
)

y_obs <- df_indexed$y_logit
y_rep <- ebf_fit_ppc$BUGSoutput$sims.list$y_logit_rep

# ============================================================
# Density overlay
# Now draws from mu_eff + prec_study so blue curves have
# realistic spread and are visible alongside the black curve
# ============================================================
ppc_dens <- bayesplot::ppc_dens_overlay(
  y_obs,
  y_rep[1:min(100, nrow(y_rep)), ]
) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title   = "Posterior Predictive Density Overlay",
    caption = "\nObserved y (black curve) | Replicated y (light blue curves)",
    x       = "\nEBF Prevalence (Logit)"
  ) +
  ggplot2::theme(legend.position = "none",
                 plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

# ============================================================
# Bayesian p-values
# ============================================================
p_val_median <- mean(apply(y_rep, 1, median) > median(y_obs))
p_val_mean   <- mean(apply(y_rep, 1, mean)   > mean(y_obs))
p_val_sd     <- mean(apply(y_rep, 1, sd)     > sd(y_obs))

cat("Bayesian p-value (median) =", round(p_val_median, 3), "\n")
cat("Bayesian p-value (mean) =",   round(p_val_mean,   3), "\n")
cat("Bayesian p-value (sd) =",     round(p_val_sd,     3), "\n")

bayesplot::color_scheme_set("teal")
p_median <- bayesplot::ppc_stat(y = y_obs, yrep = y_rep, stat = "median")
p_mad    <- bayesplot::ppc_stat(y = y_obs, yrep = y_rep, stat = "mad")
pp_median_plot <- p_median / p_mad +
  patchwork::plot_annotation(
    title    = "Test Statistics: Median and MAD",
    subtitle = paste0("Bayesian p-value (median) = ", round(p_val_median, 3))
  )

bayesplot::color_scheme_set("brightblue")
p_mean <- bayesplot::ppc_stat(y = y_obs, yrep = y_rep, stat = "mean")
p_sd   <- bayesplot::ppc_stat(y = y_obs, yrep = y_rep, stat = "sd")
pp_mean_plot <- p_mean / p_sd +
  patchwork::plot_annotation(
    title    = "Test Statistics: Mean and SD",
    subtitle = paste0("Bayesian p-value (mean) = ", round(p_val_mean, 3))
  )

bayesplot::color_scheme_set()

# ============================================================
# Interval coverage
# ============================================================
low_95  <- apply(y_rep, 2, quantile, probs = 0.025)
high_95 <- apply(y_rep, 2, quantile, probs = 0.975)

is_covered   <- (y_obs >= low_95 & y_obs <= high_95)
coverage_pct <- mean(is_covered) * 100

outliers <- which(!is_covered)
cat("Coverage =", round(coverage_pct, 1), "%\n")
cat("Uncovered study indices:",
    if (length(outliers) == 0) "none" else paste(outliers, collapse = ", "), "\n")

# Point 3 fix: table of uncovered studies so we can identify which surveys
# fall outside the predicted range and whether they have district-level data
if (length(outliers) > 0) {
  uncovered_studies <- df_indexed[outliers, ] %>%
    dplyr::select(study, country, region, year, percent,
                  has_district, district, level_type) %>%
    dplyr::mutate(
      observed_logit = y_obs[outliers],
      pred_lo_95     = low_95[outliers],
      pred_hi_95     = high_95[outliers],
      has_district   = ifelse(has_district == 1, "Yes", "No")
    ) %>%
    dplyr::arrange(region, country)
  cat("\n--- Uncovered studies (outside 95% predictive interval) ---\n")
  print(as.data.frame(uncovered_studies))
} else {
  uncovered_studies <- NULL
  cat("All studies within 95% predictive interval.\n")
}

ppc_int <- bayesplot::ppc_intervals(
  y    = y_obs,
  yrep = y_rep,
  x    = order(y_obs)    # sort by observed value so intervals fan out properly
) +
  ggplot2::labs(
    title    = "Posterior Predictive Checks",
    subtitle = paste0("Actual Coverage: ", round(coverage_pct, 1), "%"),
    caption  = "\nObserved y (black dots) sorted by observed value, with 95% predictive intervals",
    x        = "\nObservations (sorted by observed logit prevalence)",
    y        = "Observed or Predicted y (Logit)\n"
  ) +
  ggplot2::theme(legend.position = "none",
                 plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

# ============================================================
# Diagnostic data frame 
# ============================================================
posterior_mu_eff <- apply(ebf_fit_ppc$BUGSoutput$sims.list$mu_eff, 2, median)
posterior_theta  <- apply(ebf_fit_ppc$BUGSoutput$sims.list$theta,  2, median)

posterior_regions_prob  <- apply(ebf_fit_ppc$BUGSoutput$sims.list$prev_region, 2, median)
posterior_regions_prob  <- safe_clamp01(posterior_regions_prob)
posterior_regions_logit <- log(posterior_regions_prob / (1 - posterior_regions_prob))

diag_df <- df_indexed %>%
  dplyr::mutate(
    model_logit  = posterior_mu_eff,
    theta_logit  = posterior_theta,
    has_district = factor(ifelse(has_district == 0, "No", "Yes"), levels = c("No", "Yes")),
    residual     = y_logit - theta_logit,
    std_residual = residual / se_logit,
    abs_residual = abs(residual),
    region_logit = posterior_regions_logit[region_id]
  )

# ============================================================
# Standard residual plot
# ============================================================
resid_plot <- diag_df %>%
  ggplot2::ggplot(ggplot2::aes(x = model_logit, y = std_residual)) +
  ggplot2::geom_point(alpha = 0.4) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  ggplot2::theme_classic() +
  ggplot2::labs(
    title = "Standardized Residuals vs Fitted",
    y = "Residuals (SD units)",
    x = "Posterior (Logit)\n"
  ) +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

# ============================================================
# Residuals vs Year — checks whether spline absorbed
# temporal structure
# ============================================================
resid_year_plot <- diag_df %>%
  ggplot2::ggplot(ggplot2::aes(x = year, y = std_residual)) +
  ggplot2::geom_point(alpha = 0.35, aes(color = region)) +
  ggplot2::geom_smooth(method = "loess", span = 0.6, se = TRUE,
                       color = "black", linewidth = 0.8) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  ggplot2::scale_x_continuous(breaks = seq(2000, 2023, 4)) +
  ggplot2::theme_classic() +
  ggplot2::labs(
    title    = "Standardized Residuals vs Year",
    subtitle = "Remaining trend after spline adjustment\n",
    caption  = "\nSmooth loess line (black). Residual pattern here means spline may need more knots.",
    x        = "\nYear of Prevalence",
    y        = "Standardized Residual\n",
    color    = "Region"
  ) +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10),
                 legend.position = "bottom")

# ============================================================
# Observation-level diagnostic plots
# ============================================================
diag_plot_obs <- diag_df %>%
  ggplot2::ggplot(ggplot2::aes(x = y_logit, y = model_logit, color = has_district)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
  ggplot2::geom_point(alpha = 0.6, size = 2) +
  ggplot2::theme_classic() +
  ggplot2::labs(
    title = "Observation-Level Diagnostic Scatter Plot\n",
    color = "Has District",
    x = "\nObserved (Logit)",
    y = "Posterior (Logit)\n"
  ) +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

# Point 4 fix: many studies have NA n_effective (SE or CI was used instead of N).
# Use n_effective where available, otherwise fall back to 1/se_logit^2 as a
# precision proxy so every study appears in the plot.
diag_df <- diag_df %>%
  dplyr::mutate(
    plot_x      = dplyr::coalesce(n_effective, 1 / se_logit^2),
    x_is_sample = !is.na(n_effective)
  )

pool_neff_obs <- diag_df %>%
  ggplot2::ggplot(ggplot2::aes(x = plot_x, y = abs_residual)) +
  ggplot2::geom_point(ggplot2::aes(color = has_district, shape = x_is_sample),
                      size = 2, alpha = 0.6) +
  ggplot2::geom_smooth(se = FALSE, color = "grey") +
  ggplot2::geom_vline(
    xintercept = median(diag_df$plot_x, na.rm = TRUE),
    linetype = "dashed", alpha = 0.5
  ) +
  ggplot2::scale_shape_manual(
    values = c("TRUE" = 16, "FALSE" = 1),
    labels = c("TRUE" = "Sample size", "FALSE" = "Precision proxy (1/SE²)"),
    name   = "X axis source"
  ) +
  ggplot2::theme_classic() +
  ggplot2::labs(
    title   = "Observation-Level Pooling Diagnostic Plot\n",
    caption = "\nFilled circles = actual sample size | Open circles = precision proxy (1/SE²)\nDashed line = median x value",
    color   = "Has District",
    x       = "\nSample Size or Precision Proxy",
    y       = "Absolute residual\n"
  ) +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

# ============================================================
# Region-level diagnostic plots
# ============================================================
diag_plot_region <- diag_df %>%
  ggplot2::ggplot(ggplot2::aes(x = y_logit, y = model_logit, color = region)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
  ggplot2::geom_point(ggplot2::aes(shape = has_district), alpha = 0.7, size = 2.5) +
  ggplot2::theme_classic() +
  ggplot2::facet_wrap(~region) +
  ggplot2::labs(
    title = "Region-level Diagnostic Scatter Plot\n",
    x = "\nObserved (Logit)", y = "Posterior (Logit)\n", shape = "Has District"
  ) +
  ggplot2::guides(color = "none") +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

diag_plot_region_wdist <- diag_df %>%
  dplyr::filter(has_district == "Yes") %>%
  ggplot2::ggplot(ggplot2::aes(x = y_logit, y = model_logit, color = region)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
  ggplot2::geom_point(alpha = 0.7, size = 2.5) +
  ggplot2::theme_classic() +
  ggplot2::facet_wrap(~region) +
  ggplot2::labs(
    title    = "Region-level Diagnostic Scatter Plot",
    subtitle = "Observations with district/city information\n",
    x = "\nObserved (Logit)", y = "Posterior (Logit)\n"
  ) +
  ggplot2::theme(legend.position = "none",
                 plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

diag_plot_region_wodist <- diag_df %>%
  dplyr::filter(has_district == "No") %>%
  ggplot2::ggplot(ggplot2::aes(x = y_logit, y = model_logit, color = region)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
  ggplot2::geom_point(alpha = 0.7, size = 2.5, shape = 17) +
  ggplot2::theme_classic() +
  ggplot2::facet_wrap(~region) +
  ggplot2::labs(
    title    = "Region-level Diagnostic Scatter Plot",
    subtitle = "Observations without district/city information\n",
    x = "\nObserved (Logit)", y = "Posterior (Logit)\n"
  ) +
  ggplot2::theme(legend.position = "none",
                 plot.title = ggplot2::element_text(face = "bold", size = 14),
                 axis.title = ggplot2::element_text(size = 10))

#--------------------------------------------------------------------------#
### END ###