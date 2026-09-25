/*==============================================================================
  File:    code/04_mechanisms/04_decision_reduced_form.do
  Purpose: Reduced form of RTE exposure on household decision-making outcomes.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/mechanisms/decision_reduced_form.csv
  Run from code/00_master.do, which sets $data_dir, $results_dir, $log_dir.
==============================================================================*/

if "$root" == "" {
    display as error "Set the project paths first: run code/00_master.do"
    exit 198
}

clear all
set more off
set maxvar 20000

capture log close
log using "$log_dir/04_decision_reduced_form.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/mechanisms"

use "$data", clear

global controls "rural i.v130 i.v131"
global decision_outcomes ///
    decision_health_care ///
    decision_household_purchases ///
    decision_family_visits ///
    decision_husband_money ///
    decision_own_earning

gen age1830 = inrange(v012, 18, 30)
gen main_mech_v005 = mech_sample & age1830

tempname rf
postfile `rf' str40 outcome double coef se p N ///
    using "$results/decision_reduced_form.dta", replace

foreach y of global decision_outcomes {
    capture quietly reghdfe `y' reform_isc $controls [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id)
    if !_rc {
        post `rf' ("`y'") (_b[reform_isc]) (_se[reform_isc]) ///
            (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))
    }
}

postclose `rf'

use "$results/decision_reduced_form.dta", clear
export delimited using "$results/decision_reduced_form.csv", replace

log close
