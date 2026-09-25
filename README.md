# Empowering Through Education: Analyzing the Impact of the Right to Education Act on Intimate Partner Violence in India 

**Author:** Anas Khan, PhD candidate in Economics, Indira Gandhi Institute of Development Research (IGIDR), Mumbai

**Paper:** [*Empowering Through Education: Analyzing the Impact of the Right to Education Act on Intimate Partner Violence in India*](paper/education_ipv_anas_khan.pdf) (working draft)

## Research question

Does more schooling reduce the IPV that women experience, and through which channels?

## Data

- **National Family Health Survey (NFHS)**, rounds 4 (2015–16) and 5 (2019–21), women's file with the domestic violence module.
- The two rounds are pooled, and state and district codes are mapped to a common set of boundaries.
- Sample: women aged 18–30 selected for the domestic violence module.

No microdata are included in this repository. See [`data/README.md`](data/README.md) for how to obtain the data and where to place it. The processed files are available from the author on request.

## Empirical strategy

The instrument, `reform_isc`, equals one if a woman was born on or after the RTE birth cutoff for her state. Years of schooling is the endogenous regressor.

```stata
ivreghdfe outcome rural i.v130 i.v131 (schooling = reform_isc) [pw = weight], ///
    absorb(cohort state_id nfhs) vce(cluster state_id)
```

- **Fixed effects:** birth month-year cohort, state, and survey round.
- **Controls:** rural residence, religion (`v130`), and caste or tribe (`v131`).
- **Standard errors:** clustered by state.
- **Weights:** women's sample weight (`v005`), with the domestic violence weight (`sd005`) as a sensitivity check.

The 2SLS coefficient is the change in the outcome from one additional year of schooling induced by RTE exposure. Two tests check the instrument validation (`code/02_validation`).

## Repository structure

```
rte-education-ipv/
├── code/
│   ├── 00_master.do                        # Runs the whole pipeline in order; set the root path here
│   ├── 01_data/
│   │   └── 01_build_analysis_sample.do     # Builds exposure, schooling, IPV and mechanism variables, weights, sample flags
│   ├── 02_validation/
│   │   └── 01_iv_validation_tests.do       # Birth-month trend test and old-cohort falsification test
│   ├── 03_main/
│   │   ├── 01_main_iv_results.do           # First stage, reduced form, 2SLS for IPV and mechanisms, exposure years
│   │   └── 02_core_robustness.do           # IPV 2SLS with district fixed effects
│   ├── 04_mechanisms/
│   │   ├── 01_attitudes_2sls.do            # 2SLS for each attitude-towards-wife-beating item
│   │   ├── 02_attitudes_diagnostics.do     # OLS and reduced-form checks for the attitude items
│   │   ├── 03_attitudes_reduced_form.do    # Reduced form: attitudes
│   │   ├── 04_decision_reduced_form.do     # Reduced form: household decision-making
│   │   └── 05_assortative_matching.do      # Husband's schooling, spousal education and age gaps
│   └── 05_nfhs5_only/                      # Main results and mechanisms re-estimated on NFHS-5 alone
│       ├── 01_ipv.do
│       ├── 02_assortative_matching.do
│       ├── 03_decision_making.do
│       └── 04_attitudes_and_information.do
├── data/
│   └── README.md                           # How to obtain the NFHS files; no data are stored here
├── paper/
│   └── education_ipv_anas_khan.pdf         # Thesis chapter (working draft)
├── results/                                # CSV output written by the code (one row per outcome)
│   ├── main/                               # main_*.csv
│   ├── robustness/                         # core_robustness.csv
│   ├── mechanisms/                         # attitudes_*, decision_*, assortative_matching_*
│   └── nfhs5_only/                         # nfhs5_*.csv
├── logs/                                   # Stata logs, created when the code runs (not tracked)
├── LICENSE
└── README.md
```

## How to run

1. Install Stata 16 or later. The code uses `set maxvar 20000`, which needs Stata SE or MP.
2. Put the input data in `data/` (see [`data/README.md`](data/README.md)).
3. Open `code/00_master.do` and set `global root` to the folder where you cloned this repository.
4. Run `do code/00_master.do`.

The master file installs the required packages from SSC if they are missing: `ftools`, `reghdfe`, `ivreg2`, `ranktest`, and `ivreghdfe`. Each script stops with a message if it is run on its own before the master file has set the paths.

## Outputs

Every results file has one row per outcome, with the coefficient, standard error, p-value, observations and, for 2SLS, the Kleibergen–Paap first-stage F statistic.

| File | Contents |
|---|---|
| `results/main/main_first_stage.csv` | Effect of RTE exposure on years of schooling |
| `results/main/main_reduced_form.csv` | Effect of RTE exposure on each IPV outcome |
| `results/main/main_ipv_2sls.csv` | 2SLS effect of schooling on each IPV outcome |
| `results/main/main_mechanisms_2sls.csv` | 2SLS effect of schooling on attitudes, decision-making and access to information |
| `results/main/main_weight_sensitivity.csv` | IPV 2SLS using the domestic violence weight |
| `results/main/main_exposure_years.csv` | Years of exposure to RTE as a continuous instrument |
| `results/robustness/core_robustness.csv` | IPV 2SLS with district fixed effects |
| `results/mechanisms/*.csv` | Mechanism estimates for the pooled sample |
| `results/nfhs5_only/*.csv` | Main and mechanism estimates on NFHS-5 alone |

IPV outcomes are any IPV, less severe physical violence, severe physical violence, sexual violence and emotional violence.

## License

The code is released under the MIT License (see [`LICENSE`](LICENSE)). NFHS data remain subject to the DHS Program's terms of use.
