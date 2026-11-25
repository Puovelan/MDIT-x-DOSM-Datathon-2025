# Data sources and attribution

The two CSV files in this folder are historical Ministry of Health Malaysia datasets.

## 1. COVID-19 cases by state

- Local file: `covid_cases.csv`
- Upstream catalogue: https://data.moh.gov.my/data-catalogue/covid_cases
- Source: Ministry of Health Malaysia (via KKMNOW)
- Coverage in this supplied file: 25 January 2020 to 31 May 2025
- Licence stated by the catalogue: Creative Commons Attribution 4.0 International (CC BY 4.0)
- The dataset includes state-level records and a national `Malaysia` row.

## 2. Hospital records

- Local file: `hospital.csv`
- Upstream repository: https://github.com/MoH-Malaysia/covid19-public/tree/main/epidemic
- Upstream file: `epidemic/hospital.csv`
- Source: Ministry of Health Malaysia / CPRC Hospital System
- Coverage in this supplied file: 24 March 2020 to 31 May 2025
- The upstream repository's `LICENSE.md` refers users to Appendix B of the Government Open Data Circular (Pekeliling Pelaksanaan Data Terbuka Bil. 1/2015): https://www.data.gov.my/p/pekeliling-data-terbuka

Please retain source attribution and check the upstream terms when redistributing or adapting these datasets.

## Data quality note

The supplied `covid_cases.csv` contains 1,283 negative values in `cases_active`, with a minimum of -630. The project report says negative active-case anomalies were corrected, but this supplied CSV still contains those values. Do not describe this particular CSV as fully cleaned unless the relevant cleaning transformation is also supplied and documented.
