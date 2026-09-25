/*==============================================================================
  File:    code/00_master.do
  Purpose: Run the full pipeline, from the pooled NFHS file to every results
           table, in order.
  Usage:   1. Edit the one line under "1. Paths" to point to this repository.
           2. Place the input data in data/ (see data/README.md).
           3. In Stata: do code/00_master.do
  Notes:   Uses set maxvar 20000, which needs Stata SE or MP.
==============================================================================*/

clear all
set more off

*------------------------------------------------------------------------------
* 1. Paths: edit this line only
*------------------------------------------------------------------------------
global root "C:/path/to/rte-education-ipv"

global code_dir    "$root/code"
global data_dir    "$root/data"
global results_dir "$root/results"
global log_dir     "$root/logs"

capture mkdir "$log_dir"
foreach d in main robustness mechanisms nfhs5_only {
    capture mkdir "$results_dir/`d'"
}

*------------------------------------------------------------------------------
* 2. User-written packages (installed from SSC if missing)
*------------------------------------------------------------------------------
foreach pkg in ftools reghdfe ivreg2 ranktest ivreghdfe {
    capture which `pkg'
    if _rc ssc install `pkg', replace
}

*------------------------------------------------------------------------------
* 3. Data: build the analysis sample
*------------------------------------------------------------------------------
do "$code_dir/01_data/01_build_analysis_sample.do"      // pooled NFHS-4/5 -> analysis file

*------------------------------------------------------------------------------
* 4. Instrument validation
*------------------------------------------------------------------------------
do "$code_dir/02_validation/01_iv_validation_tests.do"  // birth-month trends, old-cohort falsification

*------------------------------------------------------------------------------
* 5. Main results
*------------------------------------------------------------------------------
do "$code_dir/03_main/01_main_iv_results.do"            // first stage, reduced form, 2SLS
do "$code_dir/03_main/02_core_robustness.do"            // district fixed effects

*------------------------------------------------------------------------------
* 6. Mechanisms (pooled sample)
*------------------------------------------------------------------------------
do "$code_dir/04_mechanisms/01_attitudes_2sls.do"         // each attitude item, 2SLS
do "$code_dir/04_mechanisms/02_attitudes_diagnostics.do"  // OLS and reduced form, attitudes
do "$code_dir/04_mechanisms/03_attitudes_reduced_form.do" // reduced form, attitudes
do "$code_dir/04_mechanisms/04_decision_reduced_form.do"  // reduced form, decision-making
do "$code_dir/04_mechanisms/05_assortative_matching.do"   // husband's schooling, spousal gaps

*------------------------------------------------------------------------------
* 7. NFHS-5 only (replication on the latest wave)
*------------------------------------------------------------------------------
do "$code_dir/05_nfhs5_only/01_ipv.do"
do "$code_dir/05_nfhs5_only/02_assortative_matching.do"
do "$code_dir/05_nfhs5_only/03_decision_making.do"
do "$code_dir/05_nfhs5_only/04_attitudes_and_information.do"

display as result "Pipeline finished. Results are in $results_dir"
