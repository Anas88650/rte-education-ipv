/*==============================================================================
  File:    code/02_validation/01_iv_validation_tests.do
  Purpose: Two validation tests for the instrument: (A) within-year birth-month trends
           in schooling; (B) falsification on cohorts too old to be exposed.
  Input:   $data_dir/appended_data.dta
  Output:  $log_dir/01_iv_validation_tests.log
  Run from code/00_master.do, which sets $data_dir, $results_dir, $log_dir.
==============================================================================*/

if "$root" == "" {
    display as error "Set the project paths first: run code/00_master.do"
    exit 198
}

clear all
set more off
cap log close
log using "$log_dir/01_iv_validation_tests.log", replace

global data    "$data_dir/appended_data.dta"
global results "$results_dir"

********************************************************************************
* 1. LOAD & PREP
********************************************************************************

use v005 v009 v010 v011 v024 v025 v130 v131 v133 v044 nfhs state ///
    d104 d106 d107 d108 using "$data", clear

gen wt         = v005 / 1000000
gen rural      = (v025 == 2) if v025 < .
gen schooling  = v133
replace schooling = . if schooling > 30
gen cohort     = ym(v010, v009)
format cohort %tm
gen birth_year = v010
gen birth_month = v009     /* 1–12 */

rename state state_id

keep if v044 == 1
drop if missing(wt)

* IPV outcomes
gen emotional_violence   = d104 if inlist(d104, 0, 1)
gen less_severe_violence = d106 if inlist(d106, 0, 1)
gen severe_violence      = d107 if inlist(d107, 0, 1)
gen sexual_violence      = d108 if inlist(d108, 0, 1)
egen any_ipv = rowmax(emotional_violence less_severe_violence ///
                      severe_violence sexual_violence)

* Cutoffs — J&K excluded (state_id==1 not assigned)
gen cutoff = .
replace cutoff = 1156 if inlist(state_id, 2, 5, 6, 8, 9, 18, 36, 33, 34)
replace cutoff = 1158 if state_id == 3
replace cutoff = 1175 if inlist(state_id, 4, 25, 27, 31)
replace cutoff = 1163 if state_id == 7
replace cutoff = 1184 if state_id == 10
replace cutoff = 1178 if state_id == 11
replace cutoff = 1170 if state_id == 12
replace cutoff = 1167 if inlist(state_id, 13, 19, 23, 24, 29)
replace cutoff = 1169 if inlist(state_id, 15, 17)
replace cutoff = 1180 if state_id == 16
replace cutoff = 1162 if inlist(state_id, 26, 21)
replace cutoff = 1172 if state_id == 22
replace cutoff = 1160 if state_id == 30
replace cutoff = 1171 if state_id == 32
replace cutoff = 1179 if state_id == 35
replace cutoff = 1174 if inlist(state_id, 20, 28)

drop if missing(cutoff)

gen reform_isc = (v011 >= cutoff)
gen running    = v011 - cutoff

* Pre-reform flag: born <= 1990 → aged >= 19 at RTE enactment (2009)
* These women completed schooling before RTE could affect them
gen prereform = (birth_year <= 1990)

di "=== SAMPLE SIZES ==="
count
count if prereform == 1
count if prereform == 0

tab birth_year prereform if birth_year >= 1985 & birth_year <= 1996, m


********************************************************************************
* TEST A: BIRTH-MONTH-WITHIN-YEAR TREND IN SCHOOLING (PRE-REFORM COHORTS)
********************************************************************************

di ""
di "================================================================"
di "TEST A: BIRTH-MONTH-WITHIN-YEAR TREND IN SCHOOLING"
di "Sample: pre-reform cohorts (born <= 1990)"
di "If birth_month significantly predicts schooling AFTER birth_year + state FE,"
di "then birth-year FE is insufficient and the IV assumption is violated."
di "================================================================"
di ""

preserve
keep if prereform == 1

* A1: Linear birth-month trend within year
* Coefficient on birth_month should be ≈ 0 if no within-year trend
reghdfe schooling birth_month rural i.v130 i.v131 [pw=wt], ///
    absorb(birth_year state_id nfhs) vce(cluster state_id)

di ""
di "A1 — Linear birth-month coefficient:"
di "  β(birth_month) = " %8.5f _b[birth_month]
di "  SE             = " %8.5f _se[birth_month]
di "  t              = " %8.3f (_b[birth_month] / _se[birth_month])
di "  Interpretation: If |t| < 2, no systematic within-year schooling gradient"

* A2: Joint F-test on month dummies (more flexible)
reghdfe schooling i.birth_month rural i.v130 i.v131 [pw=wt], ///
    absorb(birth_year state_id nfhs) vce(cluster state_id)

test 2.birth_month 3.birth_month 4.birth_month 5.birth_month ///
     6.birth_month 7.birth_month 8.birth_month 9.birth_month ///
     10.birth_month 11.birth_month 12.birth_month

di ""
di "A2 — Joint F-test on 11 birth-month dummies (birth_year + state + wave FE absorbed):"
di "  F(" r(df) ", " r(df_r) ") = " %8.3f r(F)
di "  p-value        = " %8.4f r(p)
di "  DECISION: p > 0.10 => no within-year birth-month gradient => birth-year FE defensible"
di "            p < 0.10 => within-year gradient exists => birth-month FE required"

* A3: Mean schooling by birth month (pre-reform cohorts)
tempfile a3_data
save `a3_data'
collapse (mean) mean_school = schooling (count) n = schooling, by(birth_month)
list birth_month mean_school n, sep(0) noobs
use `a3_data', clear

restore


********************************************************************************
* TEST B: PRE-REFORM COHORT FALSIFICATION
********************************************************************************

di ""
di "================================================================"
di "TEST B: PRE-REFORM COHORT FALSIFICATION"
di "Sample: born <= 1990 (aged >= 19 at RTE enactment — unaffected)"
di "If reform_isc predicts schooling or IPV for these women,"
di "the instrument is picking up something beyond RTE eligibility."
di "Expected: β ≈ 0, F ≈ 0, p > 0.10 for all outcomes"
di "================================================================"
di ""

preserve
keep if prereform == 1

di "--- B1: FIRST STAGE (old cohorts) ---"
reghdfe schooling reform_isc rural i.v130 i.v131 [pw=wt], ///
    absorb(birth_year state_id nfhs) vce(cluster state_id)
local b_fs  = _b[reform_isc]
local se_fs = _se[reform_isc]
local t_fs  = `b_fs' / `se_fs'
test reform_isc
local F_fs  = r(F)
local p_fs  = r(p)
local N_fs  = e(N)

di ""
di "B1 RESULT (old cohorts — expect ZERO):"
di "  β(reform_isc) = " %8.4f `b_fs'
di "  SE            = " %8.4f `se_fs'
di "  t             = " %8.3f `t_fs'
di "  F             = " %8.3f `F_fs'
di "  p             = " %8.4f `p_fs'
di "  N             = " `N_fs'
di "  VERDICT: " cond(`p_fs' > 0.10, "PASS (p > 0.10 — instrument clean for old cohorts)", ///
                      "FAIL (p < 0.10 — instrument predicts schooling for old cohorts)")

di ""
di "--- B2: REDUCED FORM — IPV outcomes (old cohorts) ---"
di ""

local ipv_outcomes "any_ipv sexual_violence severe_violence less_severe_violence emotional_violence"
foreach y of local ipv_outcomes {
    cap reghdfe `y' reform_isc rural i.v130 i.v131 [pw=wt], ///
        absorb(birth_year state_id nfhs) vce(cluster state_id)
    if _rc != 0 {
        di "  `y': FAILED (likely all missing)"
        continue
    }
    local b_rf  = _b[reform_isc]
    local se_rf = _se[reform_isc]
    local t_rf  = `b_rf' / `se_rf'
    cap test reform_isc
    local p_rf  = r(p)
    di "  `y': β = " %8.4f `b_rf' "  SE = " %7.4f `se_rf' "  p = " %6.4f `p_rf' ///
       "  " cond(`p_rf' > 0.10, "[PASS]", "[FAIL]")
}

di ""
di "--- B3: 2SLS ON OLD COHORTS (expect null everywhere) ---"
di ""

foreach y of local ipv_outcomes {
    cap ivreghdfe `y' rural i.v130 i.v131 (schooling = reform_isc) [pw=wt], ///
        absorb(birth_year state_id nfhs) vce(cluster state_id)
    if _rc != 0 {
        di "  `y': FAILED"
        continue
    }
    local b_iv  = _b[schooling]
    local se_iv = _se[schooling]
    local p_iv  = 2 * ttail(e(df_r), abs(`b_iv' / `se_iv'))
    di "  `y': β(schooling) = " %8.4f `b_iv' "  SE = " %7.4f `se_iv' "  p = " %6.4f `p_iv' ///
       "  " cond(`p_iv' > 0.10, "[PASS]", "[FAIL]")
}

restore


********************************************************************************
* TEST B SUPPLEMENTAL: BANDWIDTH RESTRICTION (old cohorts, ±36 months)
********************************************************************************

di ""
di "--- B4: FALSIFICATION — BANDWIDTH ±36 MONTHS, OLD COHORTS ---"
di "(Mirrors preferred new spec; should still show zero)"
di ""

preserve
keep if prereform == 1
keep if abs(running) <= 36

di "N in window (old cohorts, ±36): " _N

cap reghdfe schooling reform_isc rural i.v130 i.v131 [pw=wt], ///
    absorb(birth_year state_id nfhs) vce(cluster state_id)
if _rc == 0 {
    local b_bw  = _b[reform_isc]
    local se_bw = _se[reform_isc]
    test reform_isc
    local F_bw  = r(F)
    local p_bw  = r(p)
    di "First stage (bw=36, old cohorts): β = " %8.4f `b_bw' "  F = " %6.3f `F_bw' "  p = " %6.4f `p_bw'
    di "VERDICT: " cond(`p_bw' > 0.10, "PASS", "FAIL")
}
else {
    di "Regression failed (too few obs or collinearity)"
}

restore


********************************************************************************
* SUMMARY
********************************************************************************

di ""
di "================================================================"
di "VALIDATION SUMMARY"
di "================================================================"
di ""
di "TEST A (Birth-month within-year trend):"
di "  Check the F-test p-value above."
di "  p > 0.10 => birth-year FE defensible => parametric IV viable"
di "  p < 0.10 => birth-month FE required  => add birth-month fixed effects"
di ""
di "TEST B (Pre-reform falsification):"
di "  All [PASS] => instrument clean, exclusion restriction supported"
di "  Any [FAIL] => instrument picks up non-RTE variation => re-examine cutoff mapping"
di ""
di "Note: J&K (state_id==1) excluded throughout — RTE exempt until 2019."

log close
