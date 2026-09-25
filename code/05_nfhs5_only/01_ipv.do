/*==============================================================================
  File:    code/05_nfhs5_only/01_ipv.do
  Purpose: NFHS-5 only: first stage, reduced form and 2SLS for IPV.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/nfhs5_only/nfhs5_ipv_*.csv
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
log using "$log_dir/01_ipv.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/nfhs5_only"

use "$data", clear

global controls "rural i.v130 i.v131"
global ipv_outcomes any_ipv less_severe_violence severe_violence sexual_violence emotional_violence

gen nfhs5_ipv_v005 = (nfhs == 2019) & inrange(v012, 18, 30) & ipv_sample_v005

tempname fs rf iv

postfile `fs' str32 sample double coef se p F N ///
    using "$results/nfhs5_ipv_first_stage.dta", replace

postfile `rf' str40 outcome double coef se p N ///
    using "$results/nfhs5_ipv_reduced_form.dta", replace

postfile `iv' str40 outcome double coef se p firststage_F N ///
    using "$results/nfhs5_ipv_2sls.dta", replace

quietly reghdfe schooling reform_isc $controls [pw=wt_v005] if nfhs5_ipv_v005, ///
    absorb(cohort state_id) vce(cluster state_id)
test reform_isc
post `fs' ("nfhs5_ipv_v005_age18_30") (_b[reform_isc]) (_se[reform_isc]) ///
    (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (r(F)) (e(N))

foreach y of global ipv_outcomes {
    quietly reghdfe `y' reform_isc $controls [pw=wt_v005] ///
        if nfhs5_ipv_v005 & !missing(`y'), absorb(cohort state_id) ///
        vce(cluster state_id)
    post `rf' ("`y'") (_b[reform_isc]) (_se[reform_isc]) ///
        (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))

    quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] ///
        if nfhs5_ipv_v005 & !missing(`y'), absorb(cohort state_id) ///
        vce(cluster state_id) first
    local fsf = e(widstat)
    post `iv' ("`y'") (_b[schooling]) (_se[schooling]) ///
        (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
}

postclose `fs'
postclose `rf'
postclose `iv'

foreach f in ipv_first_stage ipv_reduced_form ipv_2sls {
    use "$results/nfhs5_`f'.dta", clear
    export delimited using "$results/nfhs5_`f'.csv", replace
}

log close
