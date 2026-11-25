# Sys.setenv(RETICULATE_PYTHON = "~/r-reticulate/bin/python")  # Not needed unless you call Python via reticulate

library(shiny)
library(shinydashboard)
library(shinyjs)
library(dplyr)
library(ggplot2)
library(DT)
library(lubridate)

# ==== CONFIG: set your CSV location (use forward slashes on Windows) ====
data_path <- file.path("data", "dummy_hospital_data_2023_2025.csv")

# ---- Helper: robust CSV reader with clear errors in UI ----
safe_read_csv <- function(p) {
  if (!file.exists(p)) {
    stop(sprintf(
      "CSV not found at:\n  %s\n\nTips:\n• Check spelling (DataPhantoms vs 'Data Phantoms')\n• Ensure the file is 'Always keep on this device' in OneDrive\n• Use forward slashes in Windows paths", p
    ))
  }
  tryCatch(
    read.csv(p, check.names = FALSE),
    error = function(e) {
      stop(sprintf("Failed to open CSV at:\n  %s\n\nError: %s", p, conditionMessage(e)))
    }
  )
}

# ---- Display mappings ----
var_display_names <- list(
  "No..of.Admissions" = "Number of Admissions",
  "Bed.Occupancy.Rate...." = "Bed Occupancy Rate (%)",
  "Average.Length.of.Stay..days." = "Average Length of Stay (days)"
)

get_display_name <- function(var_name) {
  display_name <- var_display_names[[var_name]]
  if (is.null(display_name)) return(var_name)
  return(display_name)
}

# ---- Theme & palette ----
hospital_theme <- theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, color = "#d81b60"),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#6d4c41"),
    axis.title = element_text(size = 12, face = "bold", color = "#4a148c"),
    axis.text = element_text(size = 10, color = "#37474f"),
    legend.title = element_text(size = 11, face = "bold", color = "#4a148c"),
    legend.text = element_text(size = 10, color = "#37474f"),
    panel.grid.major = element_line(color = "#e0f7fa", size = 0.5),
    panel.grid.minor = element_line(color = "#e0f7fa", size = 0.25),
    panel.background = element_rect(fill = "#ffffff", color = NA),
    plot.background = element_rect(fill = "#ffffff", color = NA),
    strip.background = element_rect(fill = "#f3e5f5", color = "#ce93d8"),
    strip.text = element_text(size = 11, face = "bold", color = "#4a148c"),
    legend.background = element_rect(fill = "#ffffff", color = "#ce93d8")
  )

hospital_colors <- c("#d81b60", "#f06292", "#4a148c", "#ab47bc", "#ff6f00", "#ffca28", "#00c4b4", "#4dd0e1")

# ========================= UI =========================
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(
    title = span(
      h4("BedWise", style = "margin-right: 10px; color: #ffffff;"),
      "BedWise: Utilization Forecast"
    ),
    titleWidth = 300
  ),
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      menuItem("Data Overview", tabName = "data", icon = icon("database")),
      menuItem("Visual Insights", tabName = "visual_insights", icon = icon("chart-bar")),
      menuItem("Predictive Analytics", tabName = "predictive_analytics", icon = icon("chart-line")),
      menuItem("Summary", tabName = "summary", icon = icon("info-circle"))
    ),
    br(),
    div(style = "padding: 10px;",
        sliderInput("train_prop", "Training Data Proportion:",
                    min = 0.6, max = 0.9, value = 0.8, step = 0.05),
        numericInput("future_months", "Months to Forecast:",
                     value = 6, min = 1, max = 12)
    ),
    br(),
    div(style = "
      padding: 15px;
      margin: 10px;
      background: linear-gradient(135deg, #fff3e0 0%, #fce4ec 100%);
      border: 2px solid #ffccbc;
      border-radius: 8px;
    ",
        h5("📋 Dashboard Guide",
           style = "color: #d81b60; font-weight: bold; font-size: 14px; text-align: center;"),
        div(style = "color: #37474f; font-size: 12px; background: white; padding: 10px; border-radius: 5px;",
            "BedWise predicts hospital bed occupancy using a linear regression model based on admissions, length of stay, and time features. Explore data, visualize trends, and forecast future bed utilization."
        )
    )
  ),
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side { background-color: #e3f2fd; }
        .box {
          border-radius: 6px; border-top: 3px solid #f06292;
          box-shadow: 0 2px 6px rgba(0,0,0,0.1);
          margin-bottom: 15px; background-color: #ffffff;
        }
        .box-header { background: linear-gradient(135deg, #fce4ec 0%, #f3e5f5 100%); color: #4a148c; font-weight: 600; }
        .box-title { font-size: 14px; color: #4a148c; }
        .info-box { box-shadow: 0 2px 6px rgba(0,0,0,0.1); border-radius: 6px; }
        .small-box { border-radius: 6px; background: linear-gradient(135deg, #ffca28 0%, #ff8a65 100%); }
        .small-box .icon { color: rgba(255,255,255,0.9); }
        .highlight-box {
          background: linear-gradient(135deg, #fff3e0 0%, #fce4ec 100%);
          border: 2px solid #ffccbc; border-radius: 8px; padding: 15px; margin-top: 10px;
        }
      "))
    ),
    tabItems(
      tabItem(tabName = "data",
              fluidRow(
                box(
                  title = span(icon("database"), "Hospital Dataset"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  collapsible = TRUE,
                  div(
                    p("View the hospital dataset focused on admissions, length of stay, and bed occupancy.",
                      style = "color: #37474f; font-size: 12px;"),
                    DT::dataTableOutput("data_table")
                  )
                ),
                box(
                  title = span(icon("info-circle"), "Dataset Summary"),
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  verbatimTextOutput("dataset_info")
                )
              )
      ),
      tabItem(tabName = "visual_insights",
              fluidRow(
                box(
                  title = span(icon("chart-line"), "Admissions Over Time"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotOutput("admissions_plot", height = "250px")
                ),
                box(
                  title = span(icon("bed"), "Bed Occupancy Rate"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  plotOutput("bor_plot", height = "250px")
                )
              ),
              fluidRow(
                box(
                  title = span(icon("clock"), "Average Length of Stay"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput("alos_plot", height = "250px")
                )
              )
      ),
      tabItem(tabName = "predictive_analytics",
              fluidRow(
                box(
                  title = span(icon("chart-line"), "Bed Occupancy Forecast"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  plotOutput("pred_plot", height = "400px"),
                  p("Solid line shows predictions; shaded area shows 95% prediction intervals.",
                    style = "color: #37474f; font-size: 12px; margin-top: 10px;")
                )
              ),
              fluidRow(
                box(
                  title = span(icon("table"), "Forecast Results"),
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("forecast_table")
                ),
                box(
                  title = span(icon("chart-bar"), "Model Performance Metrics"),
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  DT::dataTableOutput("metrics_table"),
                  p("Performance metrics for the Linear Regression model on the test set.",
                    style = "color: #37474f; font-size: 12px; margin-top: 10px;")
                )
              )
      ),
      tabItem(tabName = "summary",
              fluidRow(
                box(
                  title = span(icon("info-circle"), "Linear Regression Model Summary"),
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  verbatimTextOutput("model_equation"),
                  p("The equation above represents the linear regression model used to predict Bed Occupancy Rate (%). Coefficients are rounded to two decimal places.",
                    style = "color: #37474f; font-size: 12px; margin-top: 10px;")
                )
              ),
              fluidRow(
                box(
                  title = span(icon("chart-line"), "Next Month Prediction"),
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  div(class = "highlight-box",
                      uiOutput("next_month_prediction")
                  )
                )
              )
      )
    )
  )
)

# ========================= SERVER =========================
server <- function(input, output, session) {
  
  # ---- Load the sample data from the repository data folder ----
  original_data <- reactive({
    df <- safe_read_csv(data_path)
    # Rename columns to match internal naming convention
    colnames(df) <- c("Year", "Month", "No..of.Admissions",
                      "Average.Length.of.Stay..days.",
                      "Bed.Occupancy.Rate....")
    df
  })
  
  # ---- Processed data for modeling ----
  data <- reactive({
    df <- original_data()
    
    if (any(is.na(df))) {
      showNotification("Data contains NA values. Rows with NA will be dropped for modeling.", type = "warning")
    }
    
    numeric_cols <- dplyr::select(df, where(is.numeric))
    if (any(!is.finite(as.matrix(numeric_cols)))) {
      showNotification("Data contains non-finite numeric values", type = "error")
      return(NULL)
    }
    
    df <- df %>%
      mutate(Date = ymd(paste(Year, Month, 1, sep = "-"))) %>%
      arrange(Date) %>%
      mutate(
        Lag1_Admissions = lag(No..of.Admissions, 1),
        Lag1_ALOS = lag(Average.Length.of.Stay..days., 1),
        Month_Factor = as.factor(Month)
      ) %>%
      na.omit()
    
    validate(need(nrow(df) >= 24, "Not enough rows after processing to train/test."))
    df
  })
  
  # ---- Prepare data & model ----
  lm_data <- reactive({
    df <- data()
    if (is.null(df)) return(NULL)
    
    tryCatch({
      features <- c("No..of.Admissions", "Average.Length.of.Stay..days.", "Lag1_Admissions", "Lag1_ALOS")
      target <- "Bed.Occupancy.Rate...."
      
      train_size <- floor(input$train_prop * nrow(df))
      validate(need(train_size < nrow(df), "Training proportion too high for dataset size."))
      
      train_df <- df[1:train_size, ]
      test_df  <- df[(train_size + 1):nrow(df), ]
      
      lm_mod <- NULL
      lm_preds <- rep(NA, nrow(test_df))
      lm_lower <- lm_upper <- lm_preds
      
      lm_metrics <- list(MSE = NA, RMSE = NA, MAE = NA, MAPE = NA, R2 = NA)
      
      # Train Linear Model
      tryCatch({
        lm_formula <- as.formula(paste(target, "~", paste(c(features, "Month_Factor"), collapse = " + ")))
        lm_mod <- stats::lm(lm_formula, data = train_df)
        
        lm_pred_int <- stats::predict(lm_mod, newdata = test_df, interval = "prediction", level = 0.95)
        lm_preds <- lm_pred_int[, "fit"]
        lm_lower <- lm_pred_int[, "lwr"]
        lm_upper <- lm_pred_int[, "upr"]
        
        y_test <- test_df[[target]]
        lm_mse  <- mean((y_test - lm_preds)^2)
        lm_rmse <- sqrt(lm_mse)
        lm_mae  <- mean(abs(y_test - lm_preds))
        lm_mape <- mean(abs((y_test - lm_preds) / pmax(y_test, 1))) * 100
        lm_ss_res <- sum((y_test - lm_preds)^2)
        lm_ss_tot <- sum((y_test - mean(y_test))^2)
        lm_r2 <- max(0, 1 - lm_ss_res / lm_ss_tot)
        
        lm_metrics <- list(MSE = lm_mse, RMSE = lm_rmse, MAE = lm_mae, MAPE = lm_mape, R2 = lm_r2)
      }, error = function(e) {
        showNotification(paste("Linear Regression error:", conditionMessage(e)), type = "error")
      })
      
      # Future forecasts
      future_dates <- NULL
      lm_future_preds <- lm_future_lower <- lm_future_upper <- NULL
      
      tryCatch({
        future_months <- input$future_months
        last_row <- tail(df, 1)
        future_dates <- seq(max(df$Date) %m+% months(1), by = "month", length.out = future_months)
        
        lm_future_preds <- numeric(future_months)
        lm_future_lower <- numeric(future_months)
        lm_future_upper <- numeric(future_months)
        
        prev_adm  <- last_row[["No..of.Admissions"]]
        prev_alos <- last_row[["Average.Length.of.Stay..days."]]
        
        for (i in 1:future_months) {
          future_month_num <- (month(last_row$Date) + i - 1) %% 12 + 1
          
          future_row <- last_row[, c("No..of.Admissions", "Average.Length.of.Stay..days.", "Month_Factor")]
          future_row$Lag1_Admissions <- prev_adm
          future_row$Lag1_ALOS <- prev_alos
          future_row$Month_Factor <- factor(future_month_num, levels = levels(df$Month_Factor))
          
          pred_int <- stats::predict(lm_mod, newdata = future_row, interval = "prediction", level = 0.95)
          lm_future_preds[i] <- max(0, pred_int[, "fit"])
          lm_future_lower[i] <- max(0, pred_int[, "lwr"])
          lm_future_upper[i] <- pred_int[, "upr"]
          
          # keep lags static based on last observed month (simple approach)
          prev_adm  <- last_row[["No..of.Admissions"]]
          prev_alos <- last_row[["Average.Length.of.Stay..days."]]
        }
      }, error = function(e) {
        showNotification(paste("Future forecast error:", conditionMessage(e)), type = "error")
      })
      
      list(
        test = test_df,
        future_dates = future_dates,
        lm_preds = lm_preds,
        lm_lower = lm_lower,
        lm_upper = lm_upper,
        lm_future_preds = lm_future_preds,
        lm_future_lower = lm_future_lower,
        lm_future_upper = lm_future_upper,
        lm_metrics = lm_metrics,
        lm_mod = lm_mod
      )
    }, error = function(e) {
      showNotification(paste("Model processing error:", conditionMessage(e)), type = "error")
      NULL
    })
  })
  
  # -------- Data Overview --------
  output$data_table <- DT::renderDataTable({
    df <- original_data()
    display_df <- df
    names(display_df) <- sapply(names(df), get_display_name)
    
    datatable(
      display_df,
      extensions = "Buttons",
      options = list(
        scrollX = TRUE,
        pageLength = 10,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv')
      ),
      class = 'cell-border stripe hover',
      caption = "Hospital Admissions Dataset"
    ) %>%
      formatStyle(names(display_df), backgroundColor = '#e3f2fd', color = '#37474f')
  })
  
  output$dataset_info <- renderPrint({
    df <- data()
    if (is.null(df)) return("No data available")
    cat("Dataset Summary:\n")
    cat("==============\n")
    cat("Records:", nrow(df), "\n")
    cat("Variables:", ncol(df) - 3, "\n")
    cat("Date Range:", as.character(min(df$Date)), "to", as.character(max(df$Date)), "\n")
  })
  
  # -------- Visuals --------
  output$admissions_plot <- renderPlot({
    df <- data(); if (is.null(df)) return(NULL)
    ggplot(df, aes(x = Date, y = No..of.Admissions)) +
      geom_line(color = hospital_colors[1], size = 1) +
      geom_point(color = hospital_colors[2], size = 2) +
      labs(title = get_display_name("No..of.Admissions"), x = "Date", y = "Count") +
      hospital_theme +
      scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$bor_plot <- renderPlot({
    df <- data(); if (is.null(df)) return(NULL)
    ggplot(df, aes(x = Date, y = Bed.Occupancy.Rate....)) +
      geom_line(color = hospital_colors[3], size = 1) +
      geom_point(color = hospital_colors[4], size = 2) +
      labs(title = get_display_name("Bed.Occupancy.Rate...."), x = "Date", y = "Percentage") +
      hospital_theme +
      scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$alos_plot <- renderPlot({
    df <- data(); if (is.null(df)) return(NULL)
    ggplot(df, aes(x = Date, y = Average.Length.of.Stay..days.)) +
      geom_line(color = hospital_colors[5], size = 1) +
      geom_point(color = hospital_colors[6], size = 2) +
      labs(title = get_display_name("Average.Length.of.Stay..days."), x = "Date", y = "Days") +
      hospital_theme +
      scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  # -------- Predictive --------
  output$pred_plot <- renderPlot({
    md <- lm_data(); if (is.null(md)) return(NULL)
    
    historical_data <- data.frame(
      Date = data()$Date,
      Bed_Occupancy = data()$Bed.Occupancy.Rate....,
      Type = "Historical"
    )
    test_data <- data.frame(
      Date = md$test$Date,
      Bed_Occupancy = md$test$Bed.Occupancy.Rate....,
      Type = "Actual (Test)"
    )
    lm_test_preds <- data.frame(
      Date = md$test$Date,
      Value = md$lm_preds,
      Lower = md$lm_lower,
      Upper = md$lm_upper,
      Type = "Test Prediction"
    )
    lm_future_preds <- data.frame(
      Date = md$future_dates,
      Value = md$lm_future_preds,
      Lower = md$lm_future_lower,
      Upper = md$lm_future_upper,
      Type = "Future Forecast"
    )
    all_preds <- bind_rows(lm_test_preds, lm_future_preds) %>%
      filter(!is.na(Value))
    
    ggplot() +
      geom_line(data = historical_data, aes(x = Date, y = Bed_Occupancy, color = Type), size = 1) +
      geom_point(data = test_data, aes(x = Date, y = Bed_Occupancy, color = Type), size = 2) +
      geom_line(data = all_preds, aes(x = Date, y = Value, color = Type, linetype = Type), size = 1) +
      geom_ribbon(data = all_preds, aes(x = Date, ymin = Lower, ymax = Upper, fill = Type), alpha = 0.3) +
      geom_vline(xintercept = max(md$test$Date), linetype = "dashed", color = hospital_colors[5], size = 1) +
      labs(
        title = "Bed Occupancy Rate Forecast (Linear Regression)",
        x = "Date",
        y = get_display_name("Bed.Occupancy.Rate...."),
        color = "Data Type",
        fill = "Data Type",
        linetype = "Data Type"
      ) +
      scale_color_manual(values = c("Historical" = hospital_colors[1], "Actual (Test)" = hospital_colors[3],
                                    "Test Prediction" = hospital_colors[2], "Future Forecast" = hospital_colors[2])) +
      scale_fill_manual(values = c("Test Prediction" = hospital_colors[2], "Future Forecast" = hospital_colors[2])) +
      scale_linetype_manual(values = c("Historical" = "solid", "Actual (Test)" = "solid",
                                       "Test Prediction" = "solid", "Future Forecast" = "dashed")) +
      hospital_theme +
      scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
      theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$forecast_table <- DT::renderDataTable({
    md <- lm_data()
    if (is.null(md) || is.null(md$future_dates)) return(NULL)
    
    forecast_df <- data.frame(
      Date = md$future_dates,
      Prediction = round(md$lm_future_preds, 1),
      Lower = round(md$lm_future_lower, 1),
      Upper = round(md$lm_future_upper, 1)
    ) %>% filter(!is.na(Prediction))
    
    datatable(
      forecast_df,
      extensions = "Buttons",
      options = list(scrollX = TRUE, pageLength = 10, dom = 'Bfrtip', buttons = c('csv')),
      class = 'cell-border stripe hover',
      caption = paste("Future Bed Occupancy Rate Forecasts for", input$future_months, "Months")
    ) %>%
      formatStyle(names(forecast_df), backgroundColor = '#e3f2fd', color = '#37474f')
  })
  
  output$metrics_table <- DT::renderDataTable({
    md <- lm_data(); if (is.null(md) || is.null(md$lm_metrics)) return(NULL)
    metrics_df <- data.frame(
      Metric = c("MSE", "RMSE", "MAE", "MAPE (%)", "R²"),
      Value = c(
        round(md$lm_metrics$MSE, 2),
        round(md$lm_metrics$RMSE, 2),
        round(md$lm_metrics$MAE, 2),
        round(md$lm_metrics$MAPE, 2),
        round(md$lm_metrics$R2, 4)
      )
    )
    
    datatable(
      metrics_df,
      options = list(scrollX = TRUE, pageLength = 5, dom = 't', ordering = FALSE),
      class = 'cell-border stripe hover',
      caption = "Linear Regression Model Performance on Test Set"
    ) %>%
      formatStyle(names(metrics_df), backgroundColor = '#e3f2fd', color = '#37474f')
  })
  
  # -------- Summary --------
  output$model_equation <- renderPrint({
    md <- lm_data(); if (is.null(md) || is.null(md$lm_mod)) return("No model available")
    coefs <- coef(md$lm_mod)
    coef_names <- names(coefs)
    coef_values <- round(coefs, 2)
    
    terms <- c()
    for (i in seq_along(coef_names)) {
      coef_name <- coef_names[i]
      if (coef_name == "(Intercept)") {
        terms <- c(terms, sprintf("%.2f", coef_values[i]))
      } else {
        sign <- if (coef_values[i] >= 0) "+" else ""
        term <- sprintf("%s %.2f * %s", sign, coef_values[i],
                        if (grepl("Month_Factor", coef_name))
                          paste("Month_", sub("Month_Factor", "", coef_name), sep = "")
                        else
                          get_display_name(coef_name))
        terms <- c(terms, term)
      }
    }
    equation <- paste("Bed Occupancy Rate (%) =", paste(terms, collapse = " "))
    cat("Linear Regression Equation:\n")
    cat(equation, "\n")
  })
  
  output$next_month_prediction <- renderUI({
    md <- lm_data()
    if (is.null(md) || is.null(md$future_dates) || length(md$future_dates) == 0) {
      return(HTML("<p>No prediction available</p>"))
    }
    next_month <- format(md$future_dates[1], "%B %Y")
    pred_value <- round(md$lm_future_preds[1], 1)
    lower_value <- round(md$lm_future_lower[1], 1)
    upper_value <- round(md$lm_future_upper[1], 1)
    HTML(sprintf("
      <h4 style='color: #d81b60; font-weight: bold;'>Prediction for %s</h4>
      <p style='color: #37474f; font-size: 14px;'>
        <strong>Point Estimate:</strong> %.1f%%<br>
        <strong>95%% Prediction Interval:</strong> [%.1f%%, %.1f%%]
      </p>", next_month, pred_value, lower_value, upper_value))
  })
}

addResourcePath("www", ".")
shinyApp(ui, server)