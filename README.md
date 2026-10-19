# National, regional and global compliance with exclusive breastfeeding recommendations
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23469123.svg)](https://doi.org/10.5281/zenodo.23469123)

Code and derived data for:

> Khoury SM, Fink G, Joseph A-C, Wallenborn JT. *National, regional and global compliance with exclusive breastfeeding recommendations: A re-assessment using Bayesian hierarchical meta-analysis.* (manuscript under review)

The analysis estimates exclusive breastfeeding (EBF) prevalence at exactly six months of age for 135 countries, 9 UNICEF regions, and globally (2000–2023). It combines 191 Demographic and Health Surveys (DHS), 224 Multiple Indicator Cluster Surveys (MICS), and 63 published studies (546 observations) in a Bayesian hierarchical meta-analysis with a cubic B-spline for time.

## Repository structure

```
Global_EBF_Bayesian/
├── 01_data_preparation/        Stata: compile, harmonize and restrict DHS and MICS data
│   ├── 01_KR_BF_workfile_construction_22_June_2026.do   step 01 (DHS): extract and append KR files → wf_breastfeeding_dhs_22Jun2026.dta
│   ├── 01a_KR_variable_selection_22_June_2026.do         called by step 01
│   ├── 01b_KR_country_codes_29_Sept_2021.do              called by step 01
│   ├── 02_DHS-data-research.do                       step 02 (DHS): harmonize → DHS_harmonized.dta
│   ├── 03_MICS_survey_compilation_v4.do                 step 03 (MICS): compile ch.sav files → wf_mics_19sept2025.dta
│   ├── 04_MICS_survey_compilation_hh_and_wm.do          step 04 (MICS): compile hh.sav and wm.sav files
│   ├── 05_MICS-data-research.do                      step 05 (MICS): harmonize, merge CU5 and WM → MICS_harmonized_merged_final.dta
│   └── 06_Bayesian_Analysis_Final.do                    step 06: sample restrictions for this paper (DHS and MICS)
├── 02_multiple_imputation/     R: multiple imputation (m = 20) and survey-level EBF at 6 months
│   ├── 07_DHS_MI.R
│   └── 08_MICS_MI.R
├── 03_meta_analysis/           R: Bayesian hierarchical meta-analysis (JAGS)
│   ├── 09_MetaAnalysis_Manager_080726_spline.rmd   <- runs everything below, in order
│   ├── 10_MetaAnalysis_Bayes_Description.r      descriptive tables, Fig 2 (data map)
│   ├── 11_MetaAnalysis_Bayes_spline.r              data preparation, logit SEs, hierarchy, year spline
│   ├── 12_MetaAnalysis_JAGS_spline.r               JAGS model and MCMC sampling
│   ├── 13_MetaAnalysis_Diagnostics.r               R-hat, ESS, trace/density/autocorrelation plots
│   ├── 14_MetaAnalysis_PosteriorChecks_spline.r    posterior predictive checks
│   ├── 15_MetaAnalysis_ICC.r                       variance decomposition (Fig 6)
│   ├── 16_MetaAnalysis_Summary.r                   caterpillar, forest and half-eye plots
│   ├── 17_MetaAnalysis_Probabilities.r             probabilities of reaching the 50% benchmark
│   └── 18_MetaAnalysis_Results_Section.r           manuscript tables and figures, exports
└── data/
    ├── derived/                Shareable aggregate data: Bayesian_Meta-Analysis_dataset (.dta and .csv)
    └── restricted/             DHS/MICS microdata — NOT included (see data/README.md)
```

## How to reproduce

1. **Obtain DHS and MICS microdata** (free, on registration) from the [DHS Program](https://dhsprogram.com) (Children's Recode files, Stata format) and [UNICEF MICS](https://mics.unicef.org) (ch, hh and wm files, SPSS format), using the survey lists in the compilation do-files.
2. **Stata (step 1):** at the top of each do-file set `global root` to the repository folder (an absolute path), and `global dhs_raw` / `global mics_raw` to the folders holding the downloaded survey files. Run, in order: `01_KR_BF_workfile_construction_22_June_2026.do` → `02_DHS-data-research.do`; `03_MICS_survey_compilation_v4.do` and `04_MICS_survey_compilation_hh_and_wm.do` → `05_MICS-data-research.do`; then `06_Bayesian_Analysis_Final.do`. All intermediate datasets are written to `data/restricted/`.
3. **R (step 2):** with the working directory set to `02_multiple_imputation/`, run `07_DHS_MI.R` and `08_MICS_MI.R`. These produce survey-level estimates of EBF at six months, which were combined with the estimates extracted from published studies to form `data/derived/Bayesian_Meta-Analysis_dataset.dta`.
4. **R (step 3):** open `03_meta_analysis/09_MetaAnalysis_Manager_080726_spline.rmd` and knit it. It reads `data/derived/Bayesian_Meta-Analysis_dataset.dta` and writes tables, figures and diagnostics to `03_meta_analysis/EBF_Results/<timestamp>/`.

Steps 1–2 require the restricted microdata. **Step 3 can be run directly from the shared derived dataset**, which reproduces all estimates reported in the paper.

Note: the main JAGS run (4 chains × 300,000 iterations) takes several hours. The fitted model is saved to `03_meta_analysis/model_outputs/ebf_fit_final.rds`.

## Software

- Stata (64-bit) for data cleaning and variable harmonization
- R 4.5.1 with `mice`, `survey`, `R2jags` (0.8.9), `rjags`, `coda`, `splines`, `tidyverse`, `haven`, `bayesplot`, `ggdist`, `sf`, `rnaturalearth`, `countrycode`
- JAGS 4.3.2 (install separately from <https://mcmc-jags.sourceforge.io>)

Random seeds: multiple imputation `1452`; JAGS `1552`.

## Data availability

DHS and MICS microdata are third-party data and cannot be redistributed; they are freely available on registration from the sources above. The derived dataset in `data/derived/` contains only aggregate survey- and study-level prevalence estimates with their uncertainty and is shared under CC BY 4.0.

## License

Code: MIT License (see `LICENSE`). Derived data: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## Contact

Stephanie M. Khoury — stephanie.khoury@swisstph.ch
Swiss Tropical and Public Health Institute, Allschwil, Switzerland
