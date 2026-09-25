/*==============================================================================
  File:    code/04_mechanisms/02_attitudes_diagnostics.do
  Purpose: OLS and reduced-form diagnostics for the attitude outcomes.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/mechanisms/attitudes_diagnostics.csv
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
log using "$log_dir/02_attitudes_diagnostics.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/mechanisms"

use "$data", clear

global controls "rural i.v130 i.v131"
global attitude_outcomes ///
    beat_out_withoutpermission ///
    beat_neglectchild ///
    beat_argue_husband ///
    beat_refuse_sex ///
    beat_burn_food ///
    z_attitudes

gen age1830 = inrange(v012, 18, 30)
gen main_mech_v005 = mech_sample & age1830

tempname diag
postfile `diag' str40 outcome str16 model double coef se p N ///
    using "$results/attitudes_diagnostics.dta", replace

foreach y of global attitude_outcomes {
    quietly reghdfe `y' schooling $controls [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id)
    post `diag' ("`y'") ("OLS") (_b[schooling]) (_se[schooling]) ///
        (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (e(N))

    quietly reghdfe `y' reform_isc $controls [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id)
    post `diag' ("`y'") ("Reduced form") (_b[reform_isc]) (_se[reform_isc]) ///
        (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))
}

postclose `diag'

use "$results/attitudes_diagnostics.dta", clear
export delimited using "$results/attitudes_diagnostics.csv", replace

log close
