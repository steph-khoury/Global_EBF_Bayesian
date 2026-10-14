#===============================#
# Convergence Diagnostics
#===============================#

fit_obj <- if (exists("ebf_fit.upd")) ebf_fit.upd else ebf_fit

cat("Using fit object:", if (exists("ebf_fit.upd")) "ebf_fit.upd" else "ebf_fit", "\n\n")

print(fit_obj, intervals = c(0.025, 0.975))

fit_summary <- fit_obj$BUGSoutput$summary

cat("\n===============================\n")
cat("R-hat check\n")
cat("===============================\n")

if ("Rhat" %in% colnames(fit_summary)) {
  failed_conv <- fit_summary[!is.na(fit_summary[, "Rhat"]) & fit_summary[, "Rhat"] > 1.1, , drop = FALSE]
  if (nrow(failed_conv) == 0) {
    cat("All monitored parameters have R-hat <= 1.1.\n")
  } else {
    print(failed_conv)
  }
} else {
  cat("R-hat column not found.\n")
}

ebf_mcmc <- as.mcmc(fit_obj)

cat("\n===============================\n")
cat("Effective Sample Size (ESS)\n")
cat("===============================\n")

ess_vals <- coda::effectiveSize(ebf_mcmc)
print(summary(ess_vals))

low_ess <- ess_vals[ess_vals < 400]
cat("\nParameters with ESS < 400:\n")
if (length(low_ess) == 0) {
  cat("None.\n")
} else {
  print(low_ess)
}

cat("\nGenerating trace plots...\n")
plot(ebf_mcmc)

cat("\nGenerating density plots...\n")
lattice::densityplot(ebf_mcmc)

cat("\nGenerating autocorrelation plots...\n")
autocorr.plot(ebf_mcmc)

cat("\nAutocorrelation summary (lags 1, 5, 10):\n")
print(coda::autocorr.diag(ebf_mcmc, lags = c(1, 5, 10)))

#------------------------------------------------------------------------------------------------------------------------------------------#
### END ###