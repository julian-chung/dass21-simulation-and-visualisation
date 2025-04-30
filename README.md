# Longitudinal Visualisation of DASS21 Subscale Scores

The DASS21 (Depression, Anxiety, and Stress Scales – short form) is a common self-report instrument used in psychology and mental health research.

This project demonstrates how DASS21 subscale scores (Depression, Anxiety, Stress) can be visualised longitudinally across multiple timepoints for a simulated clinical cohort. The visualisation approach supports clear, per-participant subscale tracking over time and could be used in early-phase trials, psychological research, or exploratory analyses.

## 🔍 Project Overview

- **Objective:** Simulate REDCap-style data and create a reusable visualisation framework for individual-level symptom tracking.
- **Toolchain:** Python (for data simulation), R + ggplot2 + Quarto (for analysis and reporting)
- **Focus:** Subscale-level trajectories for Depression, Anxiety, and Stress across five timepoints (baseline through 12 months)

## 🔍 Highlights

- Fully reproducible simulation pipeline (Python)
- REDCap-style output with Q1–Q21 + subscale scores
- DASS severity band classification applied in R
- Participant-level plots by subscale and timepoint
- Clean faceted visualisation with ggplot2
- Quarto-powered report with exportable figures

## 📈 Visualisation Features

- Faceted plots showing each participant’s symptom progression
- Severity bands aligned with DASS42 thresholds
- Control vs. intervention group comparison
- Extensible to total scores or other PRO instruments (e.g. PHQ-9, EQ-5D)

## 📂 Files

- `dass21_longitudinal_visualisation.qmd` – Quarto notebook (R + markdown)
- `dass21_facet_plot.r` – R script for faceted plots
- `simulated_dass21_full.csv` – Synthetic dataset (no real participant data)
- `scripts/data_simulation.py` – Python script to generate the dataset

## 🌐 View the Report

👉 [**Click here to view the report**]()

> Note: This is simulated data only. The project structure and visualisation logic are derived from real clinical workflows.

## 🚀 Quickstart

```bash
quarto render
open docs/index.html
```

## 🧠 Author

Julian Chung  
Public Health | Data Analysis | Clinical Trials  
