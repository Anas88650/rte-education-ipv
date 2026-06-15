/* NFHS-5 only: attitudes and access-to-information mechanisms */

clear all
set more off
set maxvar 20000
capture log close
log using "C:\Users\anas\Desktop\THESIS\Chapter 1\CODE\34_nfhs5_attitude_access_only.log", replace text

global data "C:\Users\anas\Desktop\THESIS\Chapter 1\DATA\pooled_iv_ipv_mechanism_clean.dta"
global results "C:\Users\anas\Desktop\THESIS\Chapter 1\RESULTS"
use "$data", clear

global controls "rural i.v130 i.v131"
global outcomes z_attitudes beat_out_withoutpermission beat_neglectchild beat_argue_husband beat_refuse_sex beat_burn_food read_newspaper bank_account use_mobile read_text
gen sample = (nfhs == 2019) & inrange(v012, 18, 30) & mech_sample

tempname rf iv
postfile `rf' str40 outcome double coef se p N using "$results\nfhs5_attitude_access_reduced_form.dta", replace
postfile `iv' str40 outcome double coef se p firststage_F N using "$results\nfhs5_attitude_access_2sls.dta", replace

foreach y of global outcomes {
    capture quietly reghdfe `y' reform_isc $controls [pw=wt_v005] if sample & !missing(`y'), absorb(cohort state_id) vce(cluster state_id)
    if !_rc {
        post `rf' ("`y'") (_b[reform_isc]) (_se[reform_isc]) (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))
    }

    capture quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] if sample & !missing(`y'), absorb(cohort state_id) vce(cluster state_id) first
    if !_rc {
        local fsf = e(widstat)
        post `iv' ("`y'") (_b[schooling]) (_se[schooling]) (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
    }
}

postclose `rf'
postclose `iv'

use "$results\nfhs5_attitude_access_reduced_form.dta", clear
export delimited using "$results\nfhs5_attitude_access_reduced_form.csv", replace
use "$results\nfhs5_attitude_access_2sls.dta", clear
export delimited using "$results\nfhs5_attitude_access_2sls.csv", replace

log close
