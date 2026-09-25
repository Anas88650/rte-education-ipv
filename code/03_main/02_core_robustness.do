/*==============================================================================
  File:    code/03_main/02_core_robustness.do
  Purpose: Core IPV robustness: district fixed effects and state-specific cohort trends.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/robustness/core_robustness.csv
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
log using "$log_dir/02_core_robustness.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/robustness"

use "$data", clear

global controls "rural i.v130 i.v131"
global ipv_outcomes any_ipv less_severe_violence severe_violence sexual_violence emotional_violence

gen age1830 = inrange(v012, 18, 30)
gen main_ipv_v005 = ipv_sample_v005 & age1830
gen cohort_num = cohort

tempname robust
postfile `robust' str32 outcome str40 spec double coef se p firststage_F N ///
    using "$results/core_robustness.dta", replace

foreach y of global ipv_outcomes {
    capture quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] ///
        if main_ipv_v005 & !missing(`y'), absorb(cohort state_id district_id nfhs) ///
        vce(cluster state_id) first
    if !_rc {
        local fsf = e(widstat)
        post `robust' ("`y'") ("district_fe") (_b[schooling]) (_se[schooling]) ///
            (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
    }

    capture quietly ivreghdfe `y' $controls c.cohort_num#i.state_id ///
        (schooling = reform_isc) [pw=wt_v005] ///
        if main_ipv_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    if !_rc {
        local fsf = e(widstat)
        post `robust' ("`y'") ("state_specific_cohort_trends") (_b[schooling]) (_se[schooling]) ///
            (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
    }
}

postclose `robust'

use "$results/core_robustness.dta", clear
export delimited using "$results/core_robustness.csv", replace

log close
