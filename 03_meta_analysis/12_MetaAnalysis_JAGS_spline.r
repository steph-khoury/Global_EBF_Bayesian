# EBF Bayesian Hierarchical Meta-Analysis — JAGS WITH YEAR SPLINE

# ============================================================
# JAGS model definition
# ============================================================
ebf_model <- '
model {

  # ----------------------------------------------------------
  # Observation model
  # ----------------------------------------------------------
  for (i in 1:N_studies) {

    y_logit[i] ~ dnorm(theta[i], prec_sampling[i])

    prec_sampling[i] <- 1 / pow(se_logit[i], 2)

    # Latent study mean: accounts for study-level variation beyond
    # sampling error (e.g. interviewer bias, question wording).
    # Keeps credible intervals honest and prevents the spline from
    # chasing individual outlier surveys.
    theta[i] ~ dnorm(mu_eff[i], prec_study)

    # Linear predictor = country mean + district deviation + year spline
    mu_eff[i] <- mu_country[study_country[i]] +
                 (has_district[i] * mu_district_delta[study_district[i]]) +
                 inprod(B_spline[i,], beta_spline[])
  }

  # ----------------------------------------------------------
  # Spline coefficients
  #   Shrinkage prior: each beta_spline[k] ~ N(0, sigma_spline^2)
  #   This acts as a ridge / random-walk smoother depending on the
  #   basis choice, and prevents over-fitting with sparse years.
  # ----------------------------------------------------------
  for (k in 1:N_spline_cols) {
    beta_spline[k] ~ dnorm(0, prec_spline)
  }

  sigma_spline ~ dunif(0, 2)
  prec_spline  <- 1 / pow(sigma_spline, 2)

  # ----------------------------------------------------------
  # District-level deviations
  # ----------------------------------------------------------
  for (d in 1:N_districts) {
    mu_district_delta[d] ~ dnorm(0, prec_district)
  }

  # ----------------------------------------------------------
  # Country-level effects nested in regions
  # ----------------------------------------------------------
  for (j in 1:N_countries) {
    mu_country[j] ~ dnorm(mu_region[region_map[j]], prec_country)
    prev_country[j] <- ilogit(mu_country[j])
  }

  # ----------------------------------------------------------
  # Region-level effects
  # ----------------------------------------------------------
  for (k in 1:N_regions) {
    mu_region[k] ~ dnorm(mu_global, prec_region)
    prev_region[k] <- ilogit(mu_region[k])
  }

  # ----------------------------------------------------------
  # Global mean at the reference year 2000 (spline term = 0)
  # ----------------------------------------------------------
  mu_global ~ dnorm(0, 0.01)
  prev_global <- ilogit(mu_global)

  # ----------------------------------------------------------
  # Priors on SD / variance parameters
  # ----------------------------------------------------------
  tau_study      ~ dunif(0, 2)
  prec_study     <- 1 / pow(tau_study, 2)

  # Half-normal prior on sigma_district: T(0,) truncates to positive values.
  # dunif(0,2) was too flat and allowed sigma_district to collapse near zero
  # when non-district observations (has_district=0) provided no upward signal.
  # Half-normal with SD 0.5 (precision 4) keeps mass near zero (consistent with weak district effects)
  # but allows the chain to find larger values if the district data supports it.
  sigma_district ~ dnorm(0, 4) T(0,)
  sigma_country  ~ dunif(0, 2)
  sigma_region   ~ dunif(0, 2)

  prec_district <- 1 / pow(sigma_district, 2)
  prec_country  <- 1 / pow(sigma_country, 2)
  prec_region   <- 1 / pow(sigma_region, 2)
}
'

writeLines(ebf_model, con = "ebf_model_spline.jags")

# ============================================================
# Parameters to monitor
# ============================================================
ebf_params <- c(
  "prev_country", "prev_region", "prev_global",
  "sigma_district", "sigma_country", "sigma_region",
  "tau_study",
  "beta_spline", "sigma_spline"
)

# ============================================================
# Run JAGS — parallelised across 4 chains simultaneously
# ============================================================
set.seed(1552)

# Longer run + JAGS-specific seed to improve reproducibility and mixing,
# especially for slower variance parameters such as sigma_district.
ebf_fit <- R2jags::jags.parallel(
  jags.seed          = 1552,
  data               = ebf_data,
  model.file         = "ebf_model_spline.jags",
  parameters.to.save = ebf_params,
  n.chains           = 4,
  n.iter             = 300000,
  n.burnin           = 60000,
  n.thin             = 5
)

# Save the fitted model object so future changes to maps/tables/figures
# can reuse the same posterior draws without rerunning JAGS.
if (!dir.exists("model_outputs")) dir.create("model_outputs")
saveRDS(ebf_fit, file = file.path("model_outputs", "ebf_fit_final.rds"))

cat("\nJAGS run complete.\n")
print(ebf_fit, intervals = c(0.025, 0.975))

# ============================================================
# Post-processing: predicted year trend on a fine grid
# ============================================================
# Reconstruct the B-spline basis on a fine year grid for plotting.

library(splines)

year_grid_raw <- seq(spline_meta$year_min, spline_meta$year_max, by = 0.5)
year_grid_scaled <- (year_grid_raw - spline_meta$year_min) /
  (spline_meta$year_max - spline_meta$year_min)

B_grid <- splines::bs(
  year_grid_scaled,
  knots          = spline_meta$interior_knots,
  degree         = 3,
  intercept      = FALSE,
  Boundary.knots = c(0, 1)
)
B_grid <- as.matrix(B_grid)

# Posterior samples of beta_spline: rows = MCMC draws, cols = basis columns
beta_samps <- ebf_fit$BUGSoutput$sims.list$beta_spline  # n_sims × N_spline_cols

# Spline contribution at each grid point for each MCMC draw: n_sims × n_grid
trend_logit_samps <- beta_samps %*% t(B_grid)   # n_sims × n_grid

# Summarise: median + 95% CrI of the SPLINE TERM (logit scale, centred at 0)
trend_summary <- data.frame(
  year       = year_grid_raw,
  year_scaled = year_grid_scaled,
  trend_med  = apply(trend_logit_samps, 2, median),
  trend_lo   = apply(trend_logit_samps, 2, quantile, 0.025),
  trend_hi   = apply(trend_logit_samps, 2, quantile, 0.975)
)

# Convert to prevalence scale (adding global mean):
mu_global_samps <- ebf_fit$BUGSoutput$sims.list$prev_global  # already on prob scale
# We need mu_global on logit scale:
mu_global_logit_samps <- log(mu_global_samps / (1 - mu_global_samps))

prev_trend_samps <- plogis(
  sweep(trend_logit_samps, 1, mu_global_logit_samps, "+")  # add global mean to each draw
)

trend_summary$prev_med <- apply(prev_trend_samps, 2, median)
trend_summary$prev_lo  <- apply(prev_trend_samps, 2, quantile, 0.025)
trend_summary$prev_hi  <- apply(prev_trend_samps, 2, quantile, 0.975)

# ============================================================
# Trend plot
# ============================================================
library(ggplot2)

year_trend_plot <- ggplot(trend_summary, aes(x = year)) +
  geom_ribbon(aes(ymin = prev_lo, ymax = prev_hi), fill = "steelblue", alpha = 0.25) +
  geom_line(aes(y = prev_med), color = "steelblue", linewidth = 1) +
  geom_point(
    data = df_indexed,
    aes(x = year, y = percent),
    alpha = 0.25, size = 1.5, color = "grey40"
  ) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "red") +
  scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(2000, 2023, 4)) +
  theme_classic() +
  labs(
    title    = "Global EBF Trend over Time (Spline on Logit Scale)",
    subtitle = "Posterior median + 95% credible interval\n",
    caption  = "\nGrey dots = observed studies | Dashed red line = WHO 50% target\nTrend is the spline term evaluated at the global mean prevalence",
    x        = "\nYear of Prevalence",
    y        = "EBF Prevalence\n"
  ) +
  theme(
    plot.title  = element_text(face = "bold", size = 14),
    axis.title  = element_text(size = 10)
  )

cat("\nYear trend plot created: 'year_trend_plot'\n")

#--------------------------------------------------------------------------#
### END ###
