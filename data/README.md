# Data

## `derived/` (shared)
Aggregate estimates only — no individual-level records.

| File | Description |
|---|---|
| `Bayesian_Meta-Analysis_dataset.dta` | Input to the meta-analysis (read by `03_meta_analysis/`). 610 rows: one per survey or study estimate from DHS (191), MICS (224) and published studies. 64 rows from four European studies without any uncertainty measure are excluded by the code, giving the 546 observations analysed. |
| `Bayesian_Meta-Analysis_dataset.csv` | Identical copy in CSV format |

The DHS and MICS rows are the survey-level estimates produced by `02_multiple_imputation/07_DHS_MI.R` and `08_MICS_MI.R`; published-study rows were extracted from the articles by two reviewers.

### Variables

| Variable | Description |
|---|---|
| `Study` | "DHS", "MICS", or the title of the published study |
| `Year_of_Prevalence` | Year the EBF prevalence refers to |
| `District_City_Country` | Geographic level of the estimate (Country, District, City) |
| `Specify_city_district_country` | Name of the country, district or city |
| `Country` | Country |
| `UNICEF_region` | UNICEF region |
| `Sample_size` | Sample size (effective sample size for DHS/MICS) |
| `Estimate` | EBF prevalence at six months (%) |
| `Lower_bound`, `Upper_bound` | 95% confidence interval (%) |
| `Standard_Errors__SE_` | Standard error (percentage points) |

## `restricted/` (not shared)
DHS and MICS microdata cannot be redistributed under their terms of use. To reproduce steps 1–2, register with the DHS Program and UNICEF MICS, download the Children's Recode (DHS) and Children Under Five and Women modules (MICS), and the Stata scripts in `01_data_preparation/` write every intermediate dataset here, including:

- `wf_breastfeeding_dhs_22Jun2026.dta` → `DHS_harmonized.dta`
- `wf_mics_19sept2025.dta`, `wf_mics_wm_24sept2025.dta` → `MICS_harmonized_merged_final.dta`
- `Bayesian_DHS_analysis.dta`, `Bayesian_MICS_analysis.dta` (inputs to `02_multiple_imputation/`)
