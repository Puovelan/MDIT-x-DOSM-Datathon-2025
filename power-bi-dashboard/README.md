# Power BI Dashboard

This folder contains the Power BI Desktop report, its PDF export and the two source datasets used in the MDIT x DOSM Datathon 2025 project.

## Report pages

- **Page 1 - National Overview:** date and state slicers, COVID-19 indicators, new and active cases, admissions/discharges, hospitalised COVID-19 patients and COVID-designated beds.
- **Page 2 - State-level Analysis and Bed Capacity vs Cases:** state map, state-level comparisons and bed-utilisation table.

## Open the report

1. Install Microsoft Power BI Desktop.
2. Open `Dashboard.pbix`.
3. Use the report tabs to switch between the two pages.
4. Use the date, state and year slicers to filter the visuals.
5. Hover over charts and other visuals to inspect tooltips.

No additional Power BI plugins or add-ons are listed in the original project README.

## Included data

- `data/covid_cases.csv`
- `data/hospital.csv`

See `data/README.md` for source attribution, dataset coverage and data-quality notes.

## Limitations

- The supplied source data ends on 31 May 2025.
- The COVID-19 file includes a national `Malaysia` row as well as state-level records.
- Hospital data begins on 24 March 2020.
- The dashboard is intended for analysis and visualisation, not live hospital operations.
