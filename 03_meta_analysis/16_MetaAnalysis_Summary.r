#===============================#
# Posterior Summary Plots
#===============================#

# Set CRAN mirror for non-interactive knitting/sourcing
options(repos = c(CRAN = "https://cloud.r-project.org"))

needed_pkgs <- c("tidyverse", "ggdist")
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

region_levels_present <- sort(unique(as.character(hierarchy_lookup$region)))

country_samples <- ebf_fit$BUGSoutput$sims.list$prev_country |>
  as.data.frame() |>
  tidyr::pivot_longer(cols = everything(), names_to = "column", values_to = "prevalence") |>
  dplyr::mutate(country_id = as.numeric(gsub("V", "", column))) |>
  dplyr::left_join(hierarchy_lookup, by = "country_id") |>
  dplyr::mutate(group_type = "Country") |>
  dplyr::select(-c(region_id, country_id, column))

ranked_caterpillar <- country_samples |>
  ggplot2::ggplot(ggplot2::aes(x = prevalence, y = reorder(country, prevalence))) +
  ggplot2::geom_vline(xintercept = 0.5, linetype = "dashed", color = "red") +
  ggdist::stat_pointinterval(ggplot2::aes(color = region), .width = 0.95, alpha = 0.75, size = 2) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title = "EBF Prevalence by Country",
    subtitle = "Ranked from lowest to highest\n",
    caption = "\nDashed red line indicates WHO 50% target\nPoints represent country medians",
    x = "\nPosterior Prevalence Estimate",
    y = NULL
  ) +
  ggplot2::scale_x_continuous(labels = scales::label_percent()) +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 9),
    legend.position = "none",
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    axis.title = ggplot2::element_text(size = 10)
  )

region_names <- sort(unique(hierarchy_lookup$region))

region_samples <- ebf_fit$BUGSoutput$sims.list$prev_region |>
  as.data.frame() |>
  tidyr::pivot_longer(cols = everything(), names_to = "column", values_to = "prevalence") |>
  dplyr::mutate(
    region_id = as.numeric(gsub("V", "", column)),
    region = region_names[region_id],
    country = paste(region, "(Pooled)"),
    group_type = "Region"
  )

combined_samples <- dplyr::bind_rows(country_samples, region_samples)

diamond_ranked_caterpillar <- combined_samples |>
  ggplot2::ggplot(ggplot2::aes(x = prevalence, y = reorder(country, prevalence))) +
  ggplot2::geom_vline(xintercept = 0.5, linetype = "dashed", color = "red") +
  ggdist::stat_pointinterval(
    data = dplyr::filter(combined_samples, group_type == "Region"),
    ggplot2::aes(color = region),
    .width = 0.95, alpha = 0.75, shape = 23, size = 6
  ) +
  ggdist::stat_pointinterval(
    data = dplyr::filter(combined_samples, group_type == "Country"),
    ggplot2::aes(color = region),
    .width = 0.95, alpha = 0.75, size = 2
  ) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title = "EBF Prevalence by Country with Regional Pooled Diamonds",
    subtitle = "Ranked from lowest to highest\n",
    caption = "\nDashed red line indicates WHO 50% target\nPoints represent country medians\nDiamonds represent regional estimates",
    x = "\nPosterior Prevalence Estimate",
    y = NULL
  ) +
  ggplot2::scale_x_continuous(labels = scales::label_percent()) +
  ggplot2::theme(
    legend.position = "none",
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    axis.title = ggplot2::element_text(size = 10)
  )

country_summary <- ebf_fit$BUGSoutput$summary |>
  as.data.frame() |>
  tibble::rownames_to_column("parameter") |>
  dplyr::filter(stringr::str_detect(parameter, "prev_country")) |>
  dplyr::mutate(country_id = as.numeric(stringr::str_extract(parameter, "\\d+"))) |>
  dplyr::left_join(hierarchy_lookup, by = "country_id") |>
  dplyr::select(country_id, country, region, prevalence = `50%`, conf.low = `2.5%`, conf.high = `97.5%`) |>
  dplyr::mutate(study_type = "Summary")

study_data <- df |>
  dplyr::transmute(
    country,
    region,
    prevalence = percent,
    n_effective,
    study_type = dplyr::case_when(
      level_type %in% c("District", "City") ~ "Subnational",
      level_type == "Country" ~ "Country survey",
      TRUE ~ "Survey"
    )
  ) |>
  dplyr::mutate(
    se = sqrt(prevalence * (1 - prevalence) / n_effective),
    conf.low = pmax(0, prevalence - 1.96 * se),
    conf.high = pmin(1, prevalence + 1.96 * se)
  )

combined_summary <- dplyr::bind_rows(study_data, country_summary)

forest.f <- function(searchterm) {
  plot_df <- combined_summary |>
    dplyr::filter(region == searchterm)
  
  ggplot2::ggplot(plot_df, ggplot2::aes(x = prevalence, y = country, color = study_type)) +
    ggplot2::geom_point(
      data = dplyr::filter(plot_df, study_type != "Summary"),
      ggplot2::aes(size = n_effective),
      alpha = 0.4
    ) +
    ggplot2::geom_pointrange(
      data = dplyr::filter(plot_df, study_type == "Summary"),
      ggplot2::aes(xmin = conf.low, xmax = conf.high),
      shape = 18, size = 1
    ) +
    ggplot2::scale_color_manual(values = c(
      "Subnational" = "pink",
      "Country survey" = "steelblue",
      "Survey" = "grey60",
      "Summary" = "black"
    )) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = paste("Individual Studies and Bayesian Pooled Estimates -", region_label(searchterm)),
      subtitle = "\n",
      caption = "\nColored dots = observed surveys (size reflects n_eff)\nBlack diamonds = Bayesian posterior median",
      x = "\nEBF Prevalence",
      y = NULL
    ) +
    ggplot2::scale_x_continuous(labels = scales::label_percent()) +
    ggplot2::theme(
      legend.position = "none",
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.title = ggplot2::element_text(size = 10),
      axis.text.y = ggplot2::element_text(size = 9)
    )
}

halfeye <- region_samples |>
  ggplot2::ggplot(ggplot2::aes(x = prevalence, y = reorder(region, prevalence))) +
  ggdist::stat_halfeye(fill = "skyblue", .width = 0.95, alpha = 0.5) +
  ggplot2::geom_vline(xintercept = 0.5, linetype = "dashed", color = "red") +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title = "Estimated EBF Prevalence by Region",
    subtitle = "Posterior distributions with 95% credible intervals\n",
    caption = "\nDashed red line indicates WHO 50% target",
    x = "\nEBF Prevalence",
    y = NULL
  ) +
  ggplot2::scale_x_continuous(labels = scales::label_percent()) +
  ggplot2::theme(
    legend.position = "none",
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    axis.text.y = ggplot2::element_text(size = 9)
  )

#------------------------------------------------------------------------------------------------------------------------------------------#
### END ###