#===============================#
# IntraClass Correlation Coefficient
#===============================#

calculate_ebf_icc <- function(jags_fit) {
  s_dist    <- jags_fit$BUGSoutput$sims.list$sigma_district
  s_country <- jags_fit$BUGSoutput$sims.list$sigma_country
  s_region  <- jags_fit$BUGSoutput$sims.list$sigma_region
  
  # Denominator is the geographic hierarchy only (district, country, region).
  # tau_study is residual between-observation heterogeneity, not a structural
  # level of the hierarchy, and is reported separately below.
  total_hier_var <- s_dist^2 + s_country^2 + s_region^2
  
  get_stats <- function(v) {
    c(
      median = median(v),
      lower  = unname(quantile(v, 0.025)),
      upper  = unname(quantile(v, 0.975))
    )
  }
  
  rbind(
    Region   = get_stats(s_region^2  / total_hier_var),
    Country  = get_stats(s_country^2 / total_hier_var),
    District = get_stats(s_dist^2    / total_hier_var)
  )
}

icc_table <- calculate_ebf_icc(ebf_fit)

icc_plot_data <- as.data.frame(icc_table) |>
  tibble::rownames_to_column("Level") |>
  dplyr::mutate(
    Level = dplyr::recode(Level, "District" = "Subnational"),
    Level = factor(Level, levels = c("Region", "Country", "Subnational"))
  )
icc_plot <- icc_plot_data |>
  ggplot2::ggplot(ggplot2::aes(x = Level, y = median, fill = Level)) +
  ggplot2::geom_col(alpha = 0.8, width = 0.7) +
  ggplot2::geom_errorbar(
    ggplot2::aes(ymin = lower, ymax = upper),
    width = 0.2,
    color = "grey30"
  ) +
  ggplot2::scale_y_continuous(labels = scales::percent) +
  ggplot2::scale_fill_brewer(palette = "Set2") +
  ggplot2::theme_classic() +
  ggplot2::labs(
    title = "Variance Decomposition (Intraclass Correlation)",
    subtitle = "Proportion of hierarchical variation explained by each level\n",
    caption = "\nError bars represent 95% Bayesian credible intervals",
    x = "\nHierarchical Level",
    y = "Contribution to Hierarchical Variance (%)\n"
  ) +
  ggplot2::theme(
    legend.position = "none",
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    axis.title = ggplot2::element_text(size = 10)
  )

# ============================================================
# END