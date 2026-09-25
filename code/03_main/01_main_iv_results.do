/*==============================================================================
  File:    code/03_main/01_main_iv_results.do
  Purpose: Main results: first stage, reduced form, 2SLS for IPV, 2SLS for mechanisms,
           weight sensitivity, and years-of-exposure specification.
  Input:   $data_dir/pooled_iv_ipv_mechanism_clean.dta
  Output:  results/main/main_*.csv
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
log using "$log_dir/01_main_iv_results.log", replace text

global data    "$data_dir/pooled_iv_ipv_mechanism_clean.dta"
global results "$results_dir/main"

use "$data", clear

global controls "rural i.v130 i.v131"

global ipv_outcomes ///
    any_ipv ///
    less_severe_violence ///
    severe_violence ///
    sexual_violence ///
    emotional_violence

global mechanism_outcomes ///
    z_attitudes ///
    decision_health_care ///
    decision_household_purchases ///
    decision_family_visits ///
    decision_husband_money ///
    decision_own_earning ///
    mother_violence ///
    read_newspaper ///
    bank_account ///
    use_mobile ///
    read_text

gen age1830 = inrange(v012, 18, 30)
gen main_ipv_v005 = ipv_sample_v005 & age1830
gen main_ipv_sd005 = ipv_sample_sd005 & age1830
gen main_mech_v005 = mech_sample & age1830

gen rte_impl_cmc = cutoff + 168 if cutoff < .
gen age_at_rte = (rte_impl_cmc - v011)/12 if rte_impl_cmc < . & v011 < .
gen years_exposure = 0 if age_at_rte < .
replace years_exposure = 8 if age_at_rte < 6
replace years_exposure = 14 - age_at_rte if inrange(age_at_rte, 6, 14)
replace years_exposure = 0 if age_at_rte > 14 & age_at_rte < .
replace years_exposure = 0 if years_exposure < 0
replace years_exposure = 8 if years_exposure > 8 & years_exposure < .

tempname fs rf iv mech sens exposure

postfile `fs' str32 sample double coef se p F N ///
    using "$results/main_first_stage.dta", replace

postfile `rf' str32 outcome double coef se p N ///
    using "$results/main_reduced_form.dta", replace

postfile `iv' str32 outcome double coef se p firststage_F N ///
    using "$results/main_ipv_2sls.dta", replace

postfile `mech' str32 outcome double coef se p firststage_F N ///
    using "$results/main_mechanisms_2sls.dta", replace

postfile `sens' str32 outcome str24 spec double coef se p firststage_F N ///
    using "$results/main_weight_sensitivity.dta", replace

postfile `exposure' str32 outcome str24 model double coef se p F_or_firststage_F N ///
    using "$results/main_exposure_years.dta", replace

capture program drop calc_p
program define calc_p, rclass
    args b se df
    return scalar p = 2*ttail(`df', abs(`b'/`se'))
end

* First stage: main IPV sample
quietly reghdfe schooling reform_isc $controls [pw=wt_v005] if main_ipv_v005, ///
    absorb(cohort state_id nfhs) vce(cluster state_id)
test reform_isc
post `fs' ("v005_ipv_age18_30") (_b[reform_isc]) (_se[reform_isc]) ///
    (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (r(F)) (e(N))

* First stage: mechanism sample
quietly reghdfe schooling reform_isc $controls [pw=wt_v005] if main_mech_v005, ///
    absorb(cohort state_id nfhs) vce(cluster state_id)
test reform_isc
post `fs' ("v005_mechanism_age18_30") (_b[reform_isc]) (_se[reform_isc]) ///
    (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (r(F)) (e(N))

foreach y of global ipv_outcomes {
    quietly reghdfe `y' reform_isc $controls [pw=wt_v005] ///
        if main_ipv_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id)
    post `rf' ("`y'") (_b[reform_isc]) (_se[reform_isc]) ///
        (2*ttail(e(df_r), abs(_b[reform_isc]/_se[reform_isc]))) (e(N))

    quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] ///
        if main_ipv_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    local fsf = e(widstat)
    post `iv' ("`y'") (_b[schooling]) (_se[schooling]) ///
        (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))

    quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_sd005] ///
        if main_ipv_sd005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    local fsf = e(widstat)
    post `sens' ("`y'") ("sd005_age18_30") (_b[schooling]) (_se[schooling]) ///
        (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
}

foreach y of global mechanism_outcomes {
    capture quietly ivreghdfe `y' $controls (schooling = reform_isc) [pw=wt_v005] ///
        if main_mech_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    if !_rc {
        local fsf = e(widstat)
        post `mech' ("`y'") (_b[schooling]) (_se[schooling]) ///
            (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
    }
}

quietly reghdfe schooling years_exposure $controls [pw=wt_v005] if main_ipv_v005, ///
    absorb(cohort state_id nfhs) vce(cluster state_id)
test years_exposure
post `exposure' ("schooling") ("first_stage") (_b[years_exposure]) (_se[years_exposure]) ///
    (2*ttail(e(df_r), abs(_b[years_exposure]/_se[years_exposure]))) (r(F)) (e(N))

foreach y of global ipv_outcomes {
    quietly reghdfe `y' years_exposure $controls [pw=wt_v005] ///
        if main_ipv_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id)
    test years_exposure
    post `exposure' ("`y'") ("reduced_form") (_b[years_exposure]) (_se[years_exposure]) ///
        (2*ttail(e(df_r), abs(_b[years_exposure]/_se[years_exposure]))) (r(F)) (e(N))

    quietly ivreghdfe `y' $controls (schooling = years_exposure) [pw=wt_v005] ///
        if main_ipv_v005 & !missing(`y'), absorb(cohort state_id nfhs) ///
        vce(cluster state_id) first
    local fsf = e(widstat)
    post `exposure' ("`y'") ("iv") (_b[schooling]) (_se[schooling]) ///
        (2*ttail(e(df_r), abs(_b[schooling]/_se[schooling]))) (`fsf') (e(N))
}

postclose `fs'
postclose `rf'
postclose `iv'
postclose `mech'
postclose `sens'
postclose `exposure'

foreach f in first_stage reduced_form ipv_2sls mechanisms_2sls weight_sensitivity exposure_years {
    use "$results/main_`f'.dta", clear
    export delimited using "$results/main_`f'.csv", replace
}

log close
