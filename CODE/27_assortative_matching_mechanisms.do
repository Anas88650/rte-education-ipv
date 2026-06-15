/* Assortative matching / marriage characteristics mechanisms */

clear all
set more off
set maxvar 20000

capture log close
log using "C:\Users\anas\Desktop\THESIS\Chapter 1\CODE\27_assortative_matching_mechanisms.log", replace text

global data    "C:\Users\anas\Desktop\THESIS\Chapter 1\DATA\pooled_iv_ipv_mechanism_clean.dta"
global results "C:\Users\anas\Desktop\THESIS\Chapter 1\RESULTS"

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
    using "$results\assortative_matching_reduced_form.dta", replace

postfile `iv' str40 outcome double coef se p firststage_F N ///
    using "$results\assortative_matching_2sls.dta", replace

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

use "$results\assortative_matching_reduced_form.dta", clear
export delimited using "$results\assortative_matching_reduced_form.csv", replace

use "$results\assortative_matching_2sls.dta", clear
export delimited using "$results\assortative_matching_2sls.csv", replace

log close
