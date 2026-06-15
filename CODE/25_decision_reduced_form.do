/* Reduced-form regressions for decision-making mechanisms */

clear all
set more off
set maxvar 20000

capture log close
log using "C:\Users\anas\Desktop\THESIS\Chapter 1\CODE\25_decision_reduced_form.log", replace text

global data    "C:\Users\anas\Desktop\THESIS\Chapter 1\DATA\pooled_iv_ipv_mechanism_clean.dta"
global results "C:\Users\anas\Desktop\THESIS\Chapter 1\RESULTS"

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
    using "$results\decision_reduced_form.dta", replace

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

use "$results\decision_reduced_form.dta", clear
export delimited using "$results\decision_reduced_form.csv", replace

log close
