# Data

No data are stored in this repository. NFHS microdata are distributed by the DHS Program under registration and may not be redistributed.

## Source

1. Register for a free account at the [DHS Program](https://dhsprogram.com/data/new-user-registration.cfm) and request access to the India surveys.
2. Download the individual women's recode (IR) files in Stata format:
   - NFHS-4 (India DHS 2015–16)
   - NFHS-5 (India DHS 2019–21)

## Expected input

The pipeline starts from one pooled file:

| File | Description |
|---|---|
| `data/appended_data.dta` | NFHS-4 and NFHS-5 women's records appended, with a round indicator (`nfhs`) and state (`state`) and district (`sdistri`) codes mapped to common boundaries across the two rounds |

`code/01_data/01_build_analysis_sample.do` reads this file and writes `data/pooled_iv_ipv_mechanism_clean.dta`, which all later scripts use.

The pooled file and the state and district mapping are available from the author on request.
