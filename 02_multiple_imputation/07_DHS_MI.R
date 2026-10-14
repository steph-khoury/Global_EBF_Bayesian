# BAYESIAN ANALYSIS - DHS Multiple Imputation
# Run with the working directory set to this folder (02_multiple_imputation/).
####################################################################

# At 6 months - MI - DHS-MI (DHS EBF definition)

#----------------------------------#
#      Load required packages      #
#----------------------------------#

packages <- c("tidyverse", "haven", "survey", "mice", "openxlsx")
lapply(packages, library, character.only = TRUE)

# ---------------------------------------------------------------
# 1. Load data and derive helper variables
# ---------------------------------------------------------------
DHS.df <- haven::read_dta("../data/restricted/Bayesian_DHS_analysis.dta") |>
  mutate(
    v005           = v005 / 1000000,          # DHS weights are scaled by 1e6
    agemonths_sq   = agemonths^2,
    agemonths_cub  = agemonths^3,
    agemonths_quar = agemonths^4,
  )

# Unweighted N of children under 12 months per survey (for DEFF later)
actualN_u12 <- DHS.df |>
  filter(agemonths < 12, v005 != 0) |>
  count(survey, name = "Actual_N_u12")

# ---------------------------------------------------------------
# 2. Imputation setup: impute ONLY food and liquid
# ---------------------------------------------------------------
# Only food and liquid contain missing values. All other columns are complete and act purely as predictors
imputation_vars <- DHS.df |>
  select(agemonths, BF, v012, b4, v025, edu, food, liquid) |>
  mutate(
    across(c(BF, b4, v025, food, liquid), factor)  
  )
meth <- make.method(imputation_vars)

meth[setdiff(names(meth), c("food", "liquid"))] <- ""

cat("\nImputation methods (should be logreg for food & liquid, blank elsewhere):\n")
print(meth)
cat("\nMissing values per variable:\n")
print(colSums(is.na(imputation_vars)))

imputed_data <- mice(
  imputation_vars,
  m         = 20,
  method    = meth,
  seed      = 1452,
  printFlag = FALSE
)

# ---------------------------------------------------------------
# 3. Rebuild EBF within each completed dataset
# ---------------------------------------------------------------
add_var <- DHS.df |>
  select(v005, survey, agemonths_sq, agemonths_cub, agemonths_quar)

imputed_dfs <- lapply(1:imputed_data$m, function(i) {
  complete(imputed_data, i) |>
    bind_cols(add_var) |>
    mutate(
      EBF = case_when(
        BF     == 0 ~ 0,
        food   == 1 ~ 0,
        liquid == 1 ~ 0,
        TRUE        ~ 1
      )
    )
})

# ---------------------------------------------------------------
# 4. Per-survey prevalence at 6 months + Rubin's Rules pooling
# ---------------------------------------------------------------
prev_calculator <- function(imp.list) {
  
  all_results <- list()
  
  for (i in seq_along(imp.list)) {
    cat("Running imputation", i, "\n")
    
    df_imp <- imp.list[[i]] |>
      filter(!is.na(agemonths), !is.na(v005), v005 > 0, !is.na(survey)) |>
      mutate(
        imputation_id = i,
        survey_id     = as.numeric(as.factor(survey))
      )
    
    results_list   <- list()
    unique_surveys <- unique(df_imp$survey_id)
    
    for (sid in unique_surveys) {
      cat("  survey", sid, "in imputation", i, "\n")
      
      df_survey <- df_imp |>
        filter(survey_id == sid, agemonths < 12)
      
      if (nrow(df_survey) == 0) {
        cat("    no data - skipping\n"); next
      }
      
      dstrata <- svydesign(ids = ~1, weights = ~v005, data = df_survey, nest = TRUE)
      
      fit <- tryCatch(
        svyglm(EBF ~ agemonths + agemonths_sq + agemonths_cub + agemonths_quar,
               design = dstrata, family = quasibinomial()),
        error = function(e) { cat("    model failed:", e$message, "\n"); NULL }
      )
      if (is.null(fit)) next
      if (any(!is.finite(coef(fit))) || any(is.na(coef(fit)))) {
        cat("    non-converged - skipping\n"); next
      }
      
      n        <- nrow(df_survey)
      n_events <- sum(df_survey$EBF == 1, na.rm = TRUE)
      
      # Haldane-Anscombe correction for zero-prevalence surveys only
      if (n_events == 0) {
        cat("    zero prevalence - Haldane correction\n")
        prev_corrected <- 0.5 / n
        ci_upper       <- qbeta(0.975, 1, n)
        fit_link <- qlogis(prev_corrected)
        se_link  <- (qlogis(ci_upper) - qlogis(prev_corrected)) / 1.96
      } else {
        newdata <- data.frame(agemonths = 6, agemonths_sq = 6^2,
                              agemonths_cub = 6^3, agemonths_quar = 6^4)
        X_new <- model.matrix(~ agemonths + agemonths_sq + agemonths_cub + agemonths_quar,
                              newdata)
        beta <- coef(fit); V <- vcov(fit)
        if (any(!is.finite(V)) || any(is.na(V))) {
          cat("    invalid vcov - skipping\n"); next
        }
        fit_link <- as.numeric(X_new %*% beta)
        se_link  <- sqrt(as.numeric(X_new %*% V %*% t(X_new)))
      }
      
      results_list[[length(results_list) + 1]] <- data.frame(
        imputation_id    = i,
        survey           = as.character(df_survey$survey[1]),
        survey_id        = sid,
        n_under12        = n,
        n_events_under12 = n_events,
        se_link          = se_link,
        fit_link         = fit_link
      )
    }
    
    all_results[[i]] <- bind_rows(results_list)
  }
  
  # Rubin's Rules across imputations, per survey
  pooled <- bind_rows(all_results) |>
    group_by(survey, survey_id) |>
    summarise(
      m               = n(),
      q_bar           = mean(fit_link, na.rm = TRUE),
      u_bar           = mean(se_link^2, na.rm = TRUE),
      b               = var(fit_link, na.rm = TRUE),
      b               = ifelse(is.na(b), 0, b),
      t_var           = u_bar + (1 + 1 / m) * b,
      se_total        = sqrt(t_var),
      logit_L         = q_bar - 1.96 * se_total,
      logit_U         = q_bar + 1.96 * se_total,
      pooled_prob     = plogis(q_bar),
      pooled_ci_lower = plogis(logit_L),
      pooled_ci_upper = plogis(logit_U),
      se_prob         = (pooled_ci_upper - pooled_ci_lower) / (2 * 1.96),
      effective_N     = ifelse(
        is.finite(pooled_prob * (1 - pooled_prob) / (se_prob^2)) &
          pooled_prob * (1 - pooled_prob) / (se_prob^2) < 1e6,
        pooled_prob * (1 - pooled_prob) / (se_prob^2), NA_real_),
      .groups = "drop"
    ) |>
    arrange(survey) |>
    select(survey, pooled_prob, pooled_ci_lower, pooled_ci_upper, effective_N)
  
  pooled
}

# ---------------------------------------------------------------
# 5. Run + export
# ---------------------------------------------------------------
prevalence_at6months <- prev_calculator(imputed_dfs) |>
  left_join(actualN_u12, by = "survey") |>
  mutate(
    Estimate    = round(pooled_prob * 100, 1),
    Lower       = round(pooled_ci_lower * 100, 1),
    Upper       = round(pooled_ci_upper * 100, 1),
    Effective_N = round(effective_N, 1),
    DEFF        = round(Actual_N_u12 / effective_N, 2)
  ) |>
  select(survey, Actual_N_u12, Effective_N, DEFF, Estimate, Lower, Upper)

print(prevalence_at6months)
write.xlsx(prevalence_at6months, file = "../data/derived/Bayesian_DHS.xlsx")