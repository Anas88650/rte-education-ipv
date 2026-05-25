# Chapter 1: Education and IPV

This repository contains Stata code and selected paper-facing outputs for the Chapter 1 thesis analysis on education, RTE exposure, and intimate partner violence using pooled NFHS data.

Raw NFHS data files are intentionally excluded from version control.

## Main Analysis Files

- `CODE/17_clean_iv_ipv_mechanism_data.do`: builds the cleaned pooled analysis dataset.
- `CODE/20_main_iv_ipv_results.do`: runs the main first stage, reduced form, IPV 2SLS, mechanisms, and exposure-year specifications.
- `CODE/22_ipv_core_robustness.do`: runs core robustness checks.
- `CODE/23_attitudes_separate_2sls.do`: runs separate attitude mechanism regressions.
- `CODE/24_attitudes_diagnostics.do`: checks OLS and reduced-form diagnostics for attitude variables.

## Outputs

Selected result CSV/Markdown files are stored in `RESULTS/`. Stata `.dta` datasets and logs are ignored to keep the repository lightweight and avoid uploading restricted data.
