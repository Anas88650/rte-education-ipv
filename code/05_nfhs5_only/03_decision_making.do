/*==============================================================================
  File:    code/05_nfhs5_only/03_decision_making.do
  Purpose: NFHS-5 only: household decision-making channel.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/nfhs5_only/nfhs5_decision_*.csv
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
log using "$log_dir/03_decision_making.log", replace text

global data "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/nfhs5_only"
use "$data", clear

global controls "rural i.v130 i.v131"
global outcomes decision_health_care decision_household_purchases decision_family_visits decision_husband_money decision_own_earning
gen sample = (nfhs == 2019) & inrange(v012, 18, 30) & mech_sample

tempname rf iv
postfile `rf' str40 outcome double coef se p N using "$results/nfhs5_decision_reduced_form.dta", replace
postfile `iv' str40 outcome double coef se p firststage_F N using "$results/nfhs5_decision_2sls.dta", replace

foreach y of global outcomes {
    quietly reghdfe `y' reform_isc $controls [pw=wt_v005] if sample & !missing(`y'), absorb(cohort state_id) vce(cluster state_id)
    post `rf' ("`y'") (_b[reform_isc]) (_se[reform_isc]) (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))

    quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] if sample & !missing(`y'), absorb(cohort state_id) vce(cluster state_id) first
    local fsf = e(widstat)
    post `iv' ("`y'") (_b[schooling]) (_se[schooling]) (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
}

postclose `rf'
postclose `iv'

use "$results/nfhs5_decision_reduced_form.dta", clear
export delimited using "$results/nfhs5_decision_reduced_form.csv", replace
use "$results/nfhs5_decision_2sls.dta", clear
export delimited using "$results/nfhs5_decision_2sls.csv", replace

log close
