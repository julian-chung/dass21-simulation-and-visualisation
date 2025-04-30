# Clear environment and load libraries
rm(list = ls())
graphics.off()

# Load libraries
library(tidyverse)
library(here) # Load the here package
utils::globalVariables(c("timepoint", "subscale", "id", "severity_band", "score", "group"))

# Load data using here() to construct the path relative to the project root
data <- read.csv(here("data", "simulated_dass21_full.csv"))

# Multiply subscale scores by 2 to match DASS42
scored_data <- data %>%
  mutate(across(c(DASS_Anxiety, DASS_Depression, DASS_Stress), ~ .x * 2))

# Reshape to long format
dass_long <- scored_data %>%
  pivot_longer(cols = c(DASS_Anxiety, DASS_Depression, DASS_Stress),
              names_to = "subscale",
              values_to = "score") %>%
  mutate(timepoint = factor(timepoint, levels = c("baseline", "3_months", "6_months", "9_months", "12_months")))

# Severity classification function
classify_severity <- function(score, subscale) {
  if (subscale == "DASS_Depression") {
    cut(score, breaks = c(-Inf, 9, 13, 20, 27, Inf),
        labels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"), right = TRUE)
  } else if (subscale == "DASS_Anxiety") {
    cut(score, breaks = c(-Inf, 7, 9, 14, 19, Inf),
        labels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"), right = TRUE)
  } else if (subscale == "DASS_Stress") {
    cut(score, breaks = c(-Inf, 14, 18, 25, 33, Inf),
        labels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"), right = TRUE)
  } else {
    return(NA)
  }
}

# Add severity band Normal to Extremely Severe
dass_long$severity_band <- mapply(classify_severity, dass_long$score, dass_long$subscale)
dass_long$severity_band <- factor(dass_long$severity_band,
                                  levels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"))

# Define timepoint labels
timepoint_labels <- c(
  "baseline" = "Baseline",
  "3_months" = "3 Months",
  "6_months" = "6 Months",
  "9_months" = "9 Months",
  "12_months" = "12 Months"
)

# Experimented with using a general function to generate visualisation
plot_dass_facet <- function(df, title_text) {
  # Switched to using .data$column_name inside aes() and other tidyverse functions
  ggplot(df, aes(x = .data$severity_band, y = .data$timepoint, colour = .data$subscale)) +
    geom_path(aes(group = interaction(.data$id, .data$subscale)), # Modified to use .data here to suppress console warnings (harmless but annoying)
              position = position_dodge(width = 0.4), alpha = 0.7) +
    geom_point(aes(group = interaction(.data$id, .data$subscale)), # And here
              position = position_dodge(width = 0.4),
              size = 1.5, shape = 21, fill = "white", stroke = 0.3, alpha = 0.9) +
    # Explicitly namespace ggplot2 functions
    ggplot2::scale_colour_manual("Subscale",
                        values = c("DASS_Anxiety" = "#E23418",
                                  "DASS_Depression" = "#184CE2",
                                  "DASS_Stress" = "#03AC50"),
                        labels = c("Anxiety", "Depression", "Stress")) +
    ggplot2::scale_y_discrete(labels = timepoint_labels) +
    ggplot2::coord_flip() +
    # Corrected facet_wrap: Use formula notation ~id, referring to the 'id' column in 'df'
    ggplot2::facet_wrap(~id, ncol = 5) + 
    ggplot2::theme_bw() +
    ggplot2::labs(
      title = title_text,
      x = "Severity Band",
      y = "Timepoint"
    ) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(angle = 0, hjust = 1),
      axis.text.x = ggplot2::element_text(angle = 45, size = 8, hjust = 1, margin = ggplot2::margin(t = 10)),
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold", margin = ggplot2::margin(b = 10)),
      strip.text = ggplot2::element_text(size = 8),
      legend.background = ggplot2::element_rect(fill = "white", colour = "black", linewidth = 0.5),
      legend.title = ggplot2::element_text(hjust = 0.5),
      legend.key = ggplot2::element_rect(fill = "white", colour = NA),
      legend.spacing.y = grid::unit(5, "pt"), 
      strip.background = ggplot2::element_rect(fill = "#f7f7f7", colour = "grey80")
    )
}

# Note: Plot dimensions (especially for faceted panels) may not appear as intended when viewed inline in RStudio, VSCode or notebooks.
# For clean visual output, especially with larger cohorts, export plots using ggsave() with custom width/height with the code provided at the bottom of this script.
# Adjust width/height below based on cohort size or desired layout.

# Plot: Intervention Group
intervention_data <- dass_long %>% filter(group == "intervention") # filter also uses NSE
# Could be written as: intervention_data <- dass_long %>% filter(.data$group == "intervention")
plot_dass_facet(intervention_data, "Visualising Longitudinal DASS21 Severity\nby Subscale (Intervention Group)")

# Plot: Control Group
control_data <- dass_long %>% filter(group == "control") # filter also uses NSE
# Could be written as: control_data <- dass_long %>% filter(.data$group == "control")
plot_dass_facet(control_data, "Visualising Longitudinal DASS21 Severity\nby Subscale (Control Group)")

# Optional: Save high-res copies of the plots for sharing or publication
# Uncomment these lines if you'd like to export the figures directly

# dir.create("figures", showWarnings = FALSE)  # Create folder if it doesn't exist
# ggsave("figures/intervention_group_plot.png",
#         plot = plot_dass_facet(intervention_data, "Visualising Longitudinal DASS21 Severity\nby Subscale (Intervention Group)"),
#         width = 14, height = 10, dpi = 300)

# ggsave("figures/control_group_plot.png",
#         plot = plot_dass_facet(control_data, "Visualising Longitudinal DASS21 Severity\nby Subscale (Control Group)"),
#         width = 14, height = 10, dpi = 300)
