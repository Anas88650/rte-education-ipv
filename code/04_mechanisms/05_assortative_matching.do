/*==============================================================================
  File:    code/04_mechanisms/05_assortative_matching.do
  Purpose: Marriage-market channel: husband's schooling and spousal education and age gaps.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/mechanisms/assortative_matching_*.csv
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
log using "$log_dir/05_assortative_matching.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/mechanisms"

use "$data", clear

global controls "rural i.v130 i.v131"
global assort_outcomes ///
    husband_schooling ///
    educ_gap_husband_minus_wife ///
    age_gap_husband_minus_wife ///
    husband_more_educated ///
    wife_more_educated

gen age1830 = inrange(v012, 18, 30)
gen main_mech_v005 = mech_sample & age1830

tempname rf iv

postfile `rf' str40 outcome double coef se p N ///
    using "$results/assortative_matching_reduced_form.dta", replace

postfile `iv' str40 outcome double coef se p firststage_F N ///
    using "$results/assortative_matching_2sls.dta", replace

foreach y of global assort_outcomes {
    capture quietly reghdfe `y' reform_isc $controls [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id)
    if !_rc {
        post `rf' ("`y'") (_b[reform_isc]) (_se[reform_isc]) ///
            (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))
    }

    capture quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    if !_rc {
        local fsf = e(widstat)
        post `iv' ("`y'") (_b[schooling]) (_se[schooling]) ///
            (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
    }
}

postclose `rf'
postclose `iv'

use "$results/assortative_matching_reduced_form.dta", clear
export delimited using "$results/assortative_matching_reduced_form.csv", replace

use "$results/assortative_matching_2sls.dta", clear
export delimited using "$results/assortative_matching_2sls.csv", replace

log close
