/* Separate 2SLS runs for each wife-beating attitude item */

clear all
set more off
set maxvar 20000

capture log close
log using "C:\Users\anas\Desktop\THESIS\Chapter 1\CODE\23_attitudes_separate_2sls.log", replace text

global data    "C:\Users\anas\Desktop\THESIS\Chapter 1\DATA\pooled_iv_ipv_mechanism_clean.dta"
global results "C:\Users\anas\Desktop\THESIS\Chapter 1\RESULTS"

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
    using "$results\attitudes_separate_2sls.dta", replace

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

use "$results\attitudes_separate_2sls.dta", clear
export delimited using "$results\attitudes_separate_2sls.csv", replace

log close
