# BedWise: Utilization Forecast

BedWise is an R Shiny prototype included as a separate technical deliverable from the Power BI dashboard. It uses a small sample hospital dataset to demonstrate data inspection, visual analysis and a linear-regression-based bed-occupancy forecast.

## App sections

- **Data Overview:** interactive table and dataset summary.
- **Visual Insights:** admissions, bed-occupancy rate and average length-of-stay charts.
- **Predictive Analytics:** test-set predictions, 95% prediction intervals, future forecasts and model metrics.
- **Summary:** fitted linear-regression equation and next-month prediction.

## Data

`data/dummy_hospital_data_2023_2025.csv` contains 32 monthly sample records from January 2023 to August 2025. It is a dummy/sample dataset for the prototype, not the official daily COVID-19 or hospital-capacity dataset used by the Power BI report.

## Requirements

R and the following packages:

```r
install.packages(c(
  "shiny", "shinydashboard", "shinyjs", "dplyr",
  "ggplot2", "DT", "lubridate"
))
```

## Run locally

1. Open this folder as the working directory in RStudio.
2. Run the following command in the R console:

```r
shiny::runApp()
```

The app reads the CSV using a relative path: `data/dummy_hospital_data_2023_2025.csv`. This replaces the original machine-specific absolute path.

## Model overview

The supplied code fits a linear regression model with:

- Number of admissions
- Average length of stay
- One-month lagged admissions
- One-month lagged average length of stay
- Month as a factor

The target variable is bed-occupancy rate. The training proportion can be adjusted in the sidebar, and the app can generate forecasts for 1 to 12 months.

## Limitations to understand before interpreting the forecast

- The data is a small dummy/sample dataset, so the forecast is a demonstration rather than a real hospital forecast.
- Future admissions and average length of stay are held at their last observed values when generating the future occupancy predictions.
- The current R-squared calculation floors negative values at zero; use the conventional formula if the app is extended for model evaluation.
- The app is not connected to a live database or hospital information system.
