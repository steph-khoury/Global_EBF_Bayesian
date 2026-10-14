# BAYESIAN ANALYSIS - MICS Multiple Imputation
# Run with the working directory set to this folder (02_multiple_imputation/).
####################################################################

# At 6 months - MI - MICS-MI (MICS EBF definition)
#----------------------------------#
#      Load required packages      #
#----------------------------------#
packages= c('tidyverse', 'haven', 'survey', 'mice', 'table1', 'margins','openxlsx')
lapply(packages, library, character.only = TRUE)

#----------------------------------#
#        Load and inspect data     #
#----------------------------------#

MICS.df <- haven::read_dta("../data/restricted/Bayesian_MICS_analysis.dta")


# Unweighted N

actualN_u12 <- MICS.df %>%
  filter(agemonths < 12) %>%
  count(survey, name = "Actual_N_u12")
print(actualN_u12)


#----------------------------------#
#         Imputation setup         #
#----------------------------------#

# Ensure marital is binary factor with clear labels
MICS.df$marital <- factor(
  MICS.df$marital,
  levels = c(1, 2),
  labels = c("Married", "Not married")
)

# Select variables for imputation
imputation_vars <- MICS.df |>
  select(agemonths, BF, marital, weight, food, liquid) |>
  mutate(
    agemonths = as.numeric(agemonths),  # keep numeric
    across(c(BF, marital, food, liquid), ~factor(.x))
  )

# Check types
print(sapply(imputation_vars, class))

# Create the method vector
meth <- make.method(imputation_vars)

# Tell mice how to handle each variable
meth["agemonths"] <- ""          # DO NOT impute (use it as predictor only)
meth["BF"]        <- "logreg"    # binary
meth["marital"]   <- "logreg"    # binary
meth["food"]      <- "logreg"    # binary
meth["liquid"]    <- "logreg"    # binary

# Create predictor matrix
pred <- make.predictorMatrix(imputation_vars)

# Prevent agemonths from being imputed, but allow it to predict others
pred["agemonths", ] <- 0        # don't impute agemonths
pred[, "agemonths"]  <- 1        # agemonths predicts other variables

# Optional: prevent variables from predicting themselves
diag(pred) <- 0

# Run multiple imputation
imputed_data <- mice(
  imputation_vars,
  m = 20,
  method = meth,
  predictorMatrix = pred,
  seed = 1452,
  printFlag = FALSE
)

# Add necessary variables back to each imputed dataset
# Append variables from original data: survey id and age;
# then create EBF_WHO within each imputed dataset.
add_var = MICS.df |> select(c(survey, agemonths_sq, agemonths_quar, agemonths_cub))
imputed_dfs <- lapply(1:imputed_data$m, function(i) {
  temp.df <- complete(imputed_data, i)
  temp.df <- temp.df |>
    mutate(EBF_WHO = case_when(BF==0 ~ 0,
                               food==1 ~ 0,
                               liquid==1 ~ 0,
                               TRUE ~ 1),
           EBF_WHO = factor(EBF_WHO),
           add_var)
  return(temp.df)
})

#----------------------------------#
#      Prevalence calculation      #
#----------------------------------#
prev_calculator <- function(imp.list) {
  library(dplyr)
  library(survey)
  
  all_results <- list()
  
  for (i in seq_along(imp.list)) {
    cat("Running imputation", i, "\n")
    
    df_imp <- imp.list[[i]] %>%
      filter(
        !is.na(agemonths),
        !is.na(weight),
        weight > 0,
        !is.na(survey)
      ) %>%
      mutate(
        imputation_id = i,
        survey_id     = as.numeric(as.factor(survey))
      )
    
    results_list   <- list()
    unique_surveys <- unique(df_imp$survey_id)
    
    for (sid in unique_surveys) {
      cat("Running model for survey", sid, "in imputation", i, "\n")
      
      df_survey <- df_imp %>%
        filter(survey_id == sid, agemonths < 12)
      
      if (nrow(df_survey) == 0) {
        cat("No data for survey", sid, "in imputation", i, "- skipping\n")
        next
      }
      
      dstrata <- svydesign(ids = ~1, weights = ~weight, data = df_survey, nest = TRUE)
      
      fit <- tryCatch({
        svyglm(
          EBF_WHO ~ agemonths + agemonths_sq + agemonths_cub + agemonths_quar,
          design = dstrata,
          family = quasibinomial()
        )
      }, error = function(e) {
        cat("Model failed for survey", sid, "in imputation", i, ":", e$message, "\n")
        return(NULL)
      })
      
      if (is.null(fit)) next
      
      if (any(!is.finite(coef(fit))) || any(is.na(coef(fit)))) {
        cat("Non-converged model for survey", sid, "in imputation", i, "- skipping\n")
        next
      }
      
      n        <- nrow(df_survey)
      n_events <- sum(df_survey$EBF_WHO == 1, na.rm = TRUE)
      
      # Haldane-Anscombe correction for zero prevalence only
      if (n_events == 0) {
        cat("Zero prevalence for survey", sid, "in imputation", i, "- applying Haldane correction\n")
        
        prev_corrected <- 0.5 / n
        ci_upper       <- qbeta(0.975, 1, n)
        
        fit_link <- qlogis(prev_corrected)
        se_link  <- (qlogis(ci_upper) - qlogis(prev_corrected)) / 1.96
      } else {
        newdata <- data.frame(
          agemonths      = 6,
          agemonths_sq   = 6^2,
          agemonths_cub  = 6^3,
          agemonths_quar = 6^4
        )
        
        X_new <- model.matrix(
          ~ agemonths + agemonths_sq + agemonths_cub + agemonths_quar,
          newdata
        )
        
        beta <- coef(fit)
        V    <- vcov(fit)
        
        if (any(!is.finite(V)) || any(is.na(V))) {
          cat("Invalid variance-covariance matrix for survey", sid, "in imputation", i, "- skipping\n")
          next
        }
        
        fit_link <- as.numeric(X_new %*% beta)
        se_link  <- sqrt(as.numeric(X_new %*% V %*% t(X_new)))
      }
      
      survey_name <- as.character(df_survey$survey[1])
      
      results_list[[length(results_list) + 1]] <- data.frame(
        imputation_id    = i,
        survey           = survey_name,
        survey_id        = sid,
        n_under12        = n,
        n_events_under12 = n_events,
        se_link          = se_link,
        fit_link         = fit_link
      )
    }
    
    all_results[[i]] <- bind_rows(results_list)
  }
  
  # Combine and apply Rubin's Rules
  pooled <- bind_rows(all_results) %>%
    group_by(survey, survey_id) %>%
    summarise(
      m               = n(),
      q_bar           = mean(fit_link, na.rm = TRUE),
      u_bar           = mean(se_link^2, na.rm = TRUE),
      b               = var(fit_link, na.rm = TRUE),
      b               = ifelse(is.na(b), 0, b),
      t_var           = u_bar + (1 + 1/m) * b,
      se_total        = sqrt(t_var),
      logit_L         = q_bar - 1.96 * se_total,
      logit_U         = q_bar + 1.96 * se_total,
      pooled_prob     = plogis(q_bar),
      pooled_ci_lower = plogis(logit_L),
      pooled_ci_upper = plogis(logit_U),
      
      # SE on probability scale
      se_prob     = (pooled_ci_upper - pooled_ci_lower) / (2 * 1.96),
      
      # Effective N
      effective_N = ifelse(
        is.finite(pooled_prob * (1 - pooled_prob) / (se_prob^2)) &
          pooled_prob * (1 - pooled_prob) / (se_prob^2) < 1e6,
        pooled_prob * (1 - pooled_prob) / (se_prob^2),
        NA_real_),
      
      .groups = "drop"
    ) %>%
    arrange(survey) %>%
    select(survey, pooled_prob, pooled_ci_lower, pooled_ci_upper, effective_N)
  
  return(pooled)
}

#----------------------------------#
#      Run analysis + export       #
#----------------------------------#

prevalence_at6months <- prev_calculator(imputed_dfs) %>%
  left_join(actualN_u12, by = "survey") %>%
  mutate(
    Estimate = round(pooled_prob * 100, 1),
    Lower    = round(pooled_ci_lower * 100, 1),
    Upper    = round(pooled_ci_upper * 100, 1),
    Effective_N = round(effective_N, 1),
    DEFF = round(Actual_N_u12 / effective_N, 2)
  ) %>%
  select(survey, Actual_N_u12, Effective_N, DEFF, Estimate, Lower, Upper)

write.xlsx(prevalence_at6months, file = "../data/derived/Bayesian_MICS.xlsx")