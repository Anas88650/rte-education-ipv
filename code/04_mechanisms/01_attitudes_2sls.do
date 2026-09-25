/*==============================================================================
  File:    code/04_mechanisms/01_attitudes_2sls.do
  Purpose: 2SLS for each attitude-towards-wife-beating item separately.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/mechanisms/attitudes_separate_2sls.csv
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
log using "$log_dir/01_attitudes_2sls.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/mechanisms"

use "$data", clear

global controls "rural i.v130 i.v131"
global attitude_outcomes ///
    beat_out_withoutpermission ///
    beat_neglectchild ///
    beat_argue_husband ///
    beat_refuse_sex ///
    beat_burn_food

gen age1830 = inrange(v012, 18, 30)
gen main_mech_v005 = mech_sample & age1830

tempname att
postfile `att' str40 outcome double coef se p firststage_F N ///
    using "$results/attitudes_separate_2sls.dta", replace

foreach y of global attitude_outcomes {
    capture quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    if !_rc {
        local fsf = e(widstat)
        post `att' ("`y'") (_b[schooling]) (_se[schooling]) ///
            (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
    }
}

postclose `att'

use "$results/attitudes_separate_2sls.dta", clear
export delimited using "$results/attitudes_separate_2sls.csv", replace

log close
