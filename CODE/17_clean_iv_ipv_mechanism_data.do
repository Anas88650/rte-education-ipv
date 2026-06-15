/*==============================================================================
    Project:  Chapter 1 - Education, IPV, and Mechanisms
    Author:   Codex
    Date:     18 May 2026
    Purpose:  Build a cleaned pooled NFHS analysis file for:
              1. first-stage schooling regressions
              2. IPV IV analysis
              3. mechanism IV analysis
              4. heterogeneity by region, caste, and wealth

    Input:    DATA\appended_data.dta
    Output:   DATA\pooled_iv_ipv_mechanism_clean.dta
==============================================================================*/

clear all
set more off
set maxvar 20000

capture log close
log using "C:\Users\anas\Desktop\THESIS\Chapter 1\CODE\17_clean_iv_ipv_mechanism_data.log", replace text

*------------------------------------------------------------------------------
* 1. LOAD ONLY REQUIRED VARIABLES
*------------------------------------------------------------------------------

local keepvars ///
    nfhs state sdistri ///
    v005 sd005 sdweight ///
    v009 v010 v011 v012 v024 v025 v044 ///
    v130 v131 v133 v149 v190 v501 ///
    v701 v715 v729 v730 ///
    v157 s929 v169a s930 s930c ///
    v739 v743a v743b v743d v743f ///
    v744a v744b v744c v744d v744e ///
    d104 d106 d107 d108 d121

use `keepvars' using "C:\Users\anas\Desktop\THESIS\Chapter 1\DATA\appended_data.dta", clear

describe
count

*------------------------------------------------------------------------------
* 2. IDENTIFIERS, WEIGHTS, AND BASIC CHECKS
*------------------------------------------------------------------------------

rename state state_id
rename sdistri district_id

gen wt_v005 = v005/1000000
gen wt_sd005 = sd005/1000000
gen wt_sdweight = sdweight/1000000

label variable state_id    "Mapped pooled state code"
label variable district_id "Mapped pooled district code"
label variable wt_v005     "Women's individual weight"
label variable wt_sd005    "Domestic violence state weight"
label variable wt_sdweight "Domestic violence weight (legacy field)"

assert !missing(state_id)
assert !missing(nfhs)

*------------------------------------------------------------------------------
* 3. CORE DEMOGRAPHICS
*------------------------------------------------------------------------------

gen schooling = v133
replace schooling = . if schooling > 30
label variable schooling "Years of schooling"

gen rural = (v025 == 2) if v025 < .
label variable rural "Rural residence"

gen birth_month = v009
gen birth_year  = v010
gen cohort      = ym(v010, v009)
format cohort %tm

label variable birth_month "Month of birth"
label variable birth_year  "Year of birth"
label variable cohort      "Birth month-year cohort"

* Simple education bins retained for descriptive work if needed
gen primaryschool = 0 if !missing(v149)
replace primaryschool = 1 if inlist(v149, 3, 4, 5)

gen secondaryschool = 0 if !missing(v149)
replace secondaryschool = 1 if inlist(v149, 4, 5)

gen college = 0 if !missing(v149)
replace college = 1 if v149 == 5 & schooling >= 15

label variable primaryschool   "Completed at least primary schooling"
label variable secondaryschool "Completed at least secondary schooling"
label variable college         "College or above"

*------------------------------------------------------------------------------
* 4. TREATMENT / INSTRUMENT CONSTRUCTION
*------------------------------------------------------------------------------

gen cutoff = .
replace cutoff = 1156 if inlist(state_id, 1, 2, 5, 6, 8, 9, 18, 36, 33, 34)
replace cutoff = 1158 if state_id == 3
replace cutoff = 1175 if inlist(state_id, 4, 25, 27, 31)
replace cutoff = 1163 if state_id == 7
replace cutoff = 1184 if state_id == 10
replace cutoff = 1178 if state_id == 11
replace cutoff = 1170 if state_id == 12
replace cutoff = 1167 if inlist(state_id, 13, 19, 23, 24, 29)
replace cutoff = 1169 if inlist(state_id, 15, 17)
replace cutoff = 1180 if state_id == 16
replace cutoff = 1162 if inlist(state_id, 21, 26)
replace cutoff = 1172 if state_id == 22
replace cutoff = 1160 if state_id == 30
replace cutoff = 1171 if state_id == 32
replace cutoff = 1179 if state_id == 35
replace cutoff = 1174 if inlist(state_id, 20, 28)

gen reform_isc = (v011 >= cutoff) if cutoff < .
gen norm_cutoff = v011 - cutoff if cutoff < .

label variable cutoff      "State-specific RTE birth cutoff in CMC"
label variable reform_isc  "RTE exposure by mapped state and birth cohort"
label variable norm_cutoff "Birth date distance from state-specific cutoff"

assert inlist(reform_isc, 0, 1) if !missing(reform_isc)

*------------------------------------------------------------------------------
* 5. MECHANISM VARIABLES
*------------------------------------------------------------------------------

gen decision_health_care = .
replace decision_health_care = 0 if inlist(v743a, 4, 5, 6)
replace decision_health_care = 1 if inlist(v743a, 1, 2)
label variable decision_health_care "Woman decides on own health care"

gen decision_household_purchases = .
replace decision_household_purchases = 0 if inlist(v743b, 4, 5, 6)
replace decision_household_purchases = 1 if inlist(v743b, 1, 2)
label variable decision_household_purchases "Woman decides on large household purchases"

gen decision_family_visits = .
replace decision_family_visits = 0 if inlist(v743d, 4, 5, 6)
replace decision_family_visits = 1 if inlist(v743d, 1, 2)
label variable decision_family_visits "Woman decides on family visits"

gen decision_husband_money = .
replace decision_husband_money = 0 if inlist(v743f, 4, 5, 6)
replace decision_husband_money = 1 if inlist(v743f, 1, 2)
label variable decision_husband_money "Woman decides on husband's earnings"

gen decision_own_earning = .
replace decision_own_earning = 0 if inlist(v739, 4, 5)
replace decision_own_earning = 1 if inlist(v739, 1, 2)
label variable decision_own_earning "Woman decides on own earnings"

gen beat_out_withoutpermission = .
replace beat_out_withoutpermission = 0 if v744a == 0
replace beat_out_withoutpermission = 1 if v744a == 1

gen beat_neglectchild = .
replace beat_neglectchild = 0 if v744b == 0
replace beat_neglectchild = 1 if v744b == 1

gen beat_argue_husband = .
replace beat_argue_husband = 0 if v744c == 0
replace beat_argue_husband = 1 if v744c == 1

gen beat_refuse_sex = .
replace beat_refuse_sex = 0 if v744d == 0
replace beat_refuse_sex = 1 if v744d == 1

gen beat_burn_food = .
replace beat_burn_food = 0 if v744e == 0
replace beat_burn_food = 1 if v744e == 1

egen z_attitudes = rowmean(beat_burn_food beat_refuse_sex beat_argue_husband ///
    beat_neglectchild beat_out_withoutpermission)
label variable z_attitudes "Attitudes index from IPV-justification items"

gen mother_violence = d121
replace mother_violence = . if d121 == 8
label variable mother_violence "Respondent's father beat mother"

* Access to information
gen read_newspaper = .
replace read_newspaper = 0 if v157 == 0
replace read_newspaper = 1 if inlist(v157, 1, 2)
label variable read_newspaper "Reads newspaper at least sometimes"

gen bank_account = .
replace bank_account = s929 if inlist(s929, 0, 1)
label variable bank_account "Has a bank account"

gen use_mobile = .
replace use_mobile = v169a if inlist(v169a, 0, 1)
replace use_mobile = s930 if missing(use_mobile) & inlist(s930, 0, 1)
label variable use_mobile "Uses a mobile phone"

gen read_text = .
replace read_text = 0 if s930c == 0
replace read_text = 1 if inlist(s930c, 1, 2)
label variable read_text "Can read a text message"

*------------------------------------------------------------------------------
* 6. IPV OUTCOMES
*------------------------------------------------------------------------------

gen emotional_violence = d104 if inlist(d104, 0, 1)
gen less_severe_violence = d106 if inlist(d106, 0, 1)
gen severe_violence = d107 if inlist(d107, 0, 1)
gen sexual_violence = d108 if inlist(d108, 0, 1)

egen any_ipv = rowmax(emotional_violence less_severe_violence ///
    severe_violence sexual_violence)

label variable emotional_violence   "Emotional violence"
label variable less_severe_violence "Less severe physical violence"
label variable severe_violence      "Severe physical violence"
label variable sexual_violence      "Sexual violence"
label variable any_ipv              "Any IPV"

gen dv_module = (v044 == 1) if v044 < .
label variable dv_module "Selected for domestic violence module"

*------------------------------------------------------------------------------
* 7. ASSORTATIVE MATCHING / MARRIAGE CHARACTERISTICS
*------------------------------------------------------------------------------

gen husband_schooling = v715
replace husband_schooling = . if husband_schooling > 30
label variable husband_schooling "Husband/partner years of schooling"

gen husband_age = v730
replace husband_age = . if husband_age > 95
label variable husband_age "Husband/partner age"

gen husband_educ_attain = v729
replace husband_educ_attain = . if husband_educ_attain >= 8
label variable husband_educ_attain "Husband/partner educational attainment"

gen educ_gap_husband_minus_wife = husband_schooling - schooling if !missing(husband_schooling, schooling)
label variable educ_gap_husband_minus_wife "Education gap: husband schooling minus wife's schooling"

gen age_gap_husband_minus_wife = husband_age - v012 if !missing(husband_age, v012)
label variable age_gap_husband_minus_wife "Age gap: husband age minus wife's age"

gen husband_more_educated = (husband_schooling > schooling) if !missing(husband_schooling, schooling)
label variable husband_more_educated "Husband has more schooling than wife"

gen wife_more_educated = (schooling > husband_schooling) if !missing(husband_schooling, schooling)
label variable wife_more_educated "Wife has more schooling than husband"

*------------------------------------------------------------------------------
* 8. HETEROGENEITY VARIABLES
*------------------------------------------------------------------------------

gen caste_group = .
replace caste_group = 1 if v131 == 991
replace caste_group = 2 if v131 == 992
replace caste_group = 3 if v131 == 993
label define caste_group 1 "Caste" 2 "Tribe" 3 "No caste/tribe", replace
label values caste_group caste_group
label variable caste_group "Collapsed caste/tribe group"

gen wealth3 = .
replace wealth3 = 1 if inlist(v190, 1, 2)
replace wealth3 = 2 if v190 == 3
replace wealth3 = 3 if inlist(v190, 4, 5)
label define wealth3 1 "Poor" 2 "Middle" 3 "Rich", replace
label values wealth3 wealth3
label variable wealth3 "Collapsed wealth tercile"

gen region6 = .
replace region6 = 1 if inlist(state_id, 6, 12, 13, 14, 25, 28, 34)
replace region6 = 2 if inlist(state_id, 5, 15, 26, 33, 35)
replace region6 = 3 if inlist(state_id, 3, 4, 21, 22, 23, 24, 30, 32)
replace region6 = 4 if inlist(state_id, 10, 11, 20, 29, 8, 9)
replace region6 = 5 if inlist(state_id, 2, 7, 16, 17, 27, 31, 36, 18, 1)
replace region6 = 6 if state_id == 19
label define region6 1 "North" 2 "East" 3 "Northeast" 4 "West" 5 "South" 6 "Central", replace
label values region6 region6
label variable region6 "Broad region"

*------------------------------------------------------------------------------
* 9. SAMPLE FLAGS
*------------------------------------------------------------------------------

gen base_controls_ok = !missing(schooling, reform_isc, cohort, state_id, nfhs, ///
    rural, v130, v131)

gen mech_sample = base_controls_ok & !missing(wt_v005)
gen ipv_sample_sd005 = base_controls_ok & dv_module == 1 & !missing(wt_sd005)
gen ipv_sample_v005  = base_controls_ok & dv_module == 1 & !missing(wt_v005)
gen ipv_sample_unw   = base_controls_ok & dv_module == 1

label variable mech_sample     "Main mechanism analysis sample"
label variable ipv_sample_sd005 "Main IPV sample with sd005"
label variable ipv_sample_v005  "IPV sample with v005"
label variable ipv_sample_unw   "IPV sample unweighted"

*------------------------------------------------------------------------------
* 10. VALIDATION
*------------------------------------------------------------------------------

count if mech_sample
count if ipv_sample_sd005
count if ipv_sample_v005
count if ipv_sample_unw

tab dv_module, missing
tab region6 if mech_sample, missing
tab caste_group if mech_sample, missing
tab wealth3 if mech_sample, missing

assert inlist(decision_health_care, 0, 1) if !missing(decision_health_care)
assert inlist(decision_household_purchases, 0, 1) if !missing(decision_household_purchases)
assert inlist(decision_family_visits, 0, 1) if !missing(decision_family_visits)
assert inlist(decision_husband_money, 0, 1) if !missing(decision_husband_money)
assert inlist(decision_own_earning, 0, 1) if !missing(decision_own_earning)
assert inlist(any_ipv, 0, 1) if !missing(any_ipv)
assert inlist(husband_more_educated, 0, 1) if !missing(husband_more_educated)
assert inlist(wife_more_educated, 0, 1) if !missing(wife_more_educated)

*------------------------------------------------------------------------------
* 11. ORDER, COMPRESS, SAVE
*------------------------------------------------------------------------------

order nfhs state_id district_id cohort birth_year birth_month v011 ///
    cutoff norm_cutoff reform_isc ///
    schooling primaryschool secondaryschool college ///
    rural v130 v131 caste_group v190 wealth3 region6 ///
    wt_v005 wt_sd005 wt_sdweight ///
    decision_health_care decision_household_purchases ///
    decision_family_visits decision_husband_money decision_own_earning ///
    husband_schooling husband_age husband_educ_attain ///
    educ_gap_husband_minus_wife age_gap_husband_minus_wife ///
    husband_more_educated wife_more_educated ///
    z_attitudes mother_violence read_newspaper bank_account use_mobile read_text ///
    emotional_violence less_severe_violence severe_violence sexual_violence any_ipv ///
    dv_module mech_sample ipv_sample_sd005 ipv_sample_v005 ipv_sample_unw

compress
save "C:\Users\anas\Desktop\THESIS\Chapter 1\DATA\pooled_iv_ipv_mechanism_clean.dta", replace

codebook, compact

log close
