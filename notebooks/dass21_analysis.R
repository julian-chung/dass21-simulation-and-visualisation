# Clear environment and load libraries
rm(list=ls())
graphics.off()

this_file <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(file.path(this_file, ".."))

library(tidyverse)

# Load data
data <- read.csv("data/simulated_dass21_full.csv")

# Multiply scores by 2
data <- data %>%
  mutate(across(c(DASS_Anxiety, DASS_Depression, DASS_Stress), ~ .x * 2))

# Pivot longer for plotting
dass_long <- data %>%
  pivot_longer(cols = c(DASS_Anxiety, DASS_Depression, DASS_Stress),
              names_to = "subscale",
              values_to = "score")

# Convert timepoint to factor with correct month order
dass_long$timepoint <- factor(dass_long$timepoint,
                              levels = c("baseline", "3_months", "6_months", "9_months", "12_months"))

# Create severity band classifier as per guidelines
classify_severity <- function(score, subscale) {
  if (subscale == "DASS_Depression") {
    cut(score, breaks = c(-Inf, 9, 13, 20, 27, Inf),
        labels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"),
        right = TRUE)
  } else if (subscale == "DASS_Anxiety") {
    cut(score, breaks = c(-Inf, 7, 9, 14, 19, Inf),
        labels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"),
        right = TRUE)
  } else if (subscale == "DASS_Stress") {
    cut(score, breaks = c(-Inf, 14, 18, 25, 33, Inf),
        labels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe"),
        right = TRUE)
  } else {
    return(NA)
  }
}

# Filter to just intervention group
intervention_data <- dass_long %>%
  filter(group == "intervention")

# Classify severity bands
intervention_data <- intervention_data %>%
  mutate(severity_band = mapply(classify_severity, score, subscale),
        severity_band = factor(severity_band,
                                levels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe")))

# Create time point labels
timepoint_labels <- c(
  "baseline" = "Baseline",
  "3_months" = "3 Months",
  "6_months" = "6 Months",
  "9_months" = "9 Months",
  "12_months" = "12 Months"
)

# Plotting - Intervention Group

# Plot: flip axes for correct visual flow
ggplot(intervention_data, aes(x = severity_band, y = timepoint, colour = subscale)) +
  geom_path(aes(group = interaction(id, subscale)),
            position = position_dodge(width = 0.4), alpha = 0.7) +
  geom_point(
  aes(group = interaction(id, subscale)),
  position = position_dodge(width = 0.4),
  size = 1.5,
  shape = 21,
  fill = "white",
  stroke = 0.3,
  alpha = 0.9
)+
  scale_colour_manual("Subscale",
                      values = c("DASS_Anxiety" = "#E23418",
                                "DASS_Depression" = "#184CE2",
                                "DASS_Stress" = "#03AC50"),
                      labels = c("Anxiety", "Depression", "Stress")) +
  scale_y_discrete(labels = timepoint_labels) +
  coord_flip() +
  facet_wrap(~id) +
  theme_bw() +
  labs(
    title = "DASS21 Severity Trajectories by Subscale (Intervention Only)",
    x = "Severity Band",
    y = "Timepoint"
  ) +
  theme(
    axis.text.y = element_text(angle = 0, hjust = 1),
    axis.text.x = element_text(angle = 45, size = 8, hjust = 1, margin = margin(t = 5)),
    plot.title = element_text(hjust = 0.5),
    strip.text = element_text(size = 8),
    legend.background = element_rect(fill = "white", colour = "black", linewidth = 0.5),
legend.key = element_rect(fill = "white", colour = NA)
  )

# Plotting - Control Group

# Filter and prep control group
control_data <- dass_long %>%
  filter(group == "control") %>%
  mutate(severity_band = mapply(classify_severity, score, subscale),
        severity_band = factor(severity_band,
                                levels = c("Normal", "Mild", "Moderate", "Severe", "Extremely Severe")))

# Plot: control group
ggplot(control_data, aes(x = severity_band, y = timepoint, colour = subscale)) +
  geom_path(aes(group = interaction(id, subscale)),
            position = position_dodge(width = 0.4), alpha = 0.7) +
  geom_point(
    aes(group = interaction(id, subscale)),
    position = position_dodge(width = 0.4),
    size = 1.5,
    shape = 21,
    fill = "white",
    stroke = 0.3,
    alpha = 0.9
  ) +
  scale_colour_manual("Subscale",
                      values = c("DASS_Anxiety" = "#E23418",
                                "DASS_Depression" = "#184CE2",
                                "DASS_Stress" = "#03AC50"),
                      labels = c("Anxiety", "Depression", "Stress")) +
  scale_y_discrete(labels = timepoint_labels) +
  coord_flip() +
  facet_wrap(~id) +
  theme_bw() +
  labs(
    title = "DASS21 Severity Trajectories by Subscale (Control Group)",
    x = "Severity Band",
    y = "Timepoint"
  ) +
  theme(
    axis.text.y = element_text(angle = 0, hjust = 1),
    axis.text.x = element_text(angle = 45, size = 8, hjust = 1, margin = margin(t = 5)),
    plot.title = element_text(hjust = 0.5),
    strip.text = element_text(size = 8),
    legend.background = element_rect(fill = "white", colour = "black", linewidth = 0.5),
    legend.key = element_rect(fill = "white", colour = NA)
  )
