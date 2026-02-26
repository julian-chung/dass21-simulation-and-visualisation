# Longitudinal Visualisation of DASS21 Subscale Scores

The DASS21 (Depression, Anxiety, and Stress Scales – short form) is a widely used self-report instrument in psychology and mental health research.

This project demonstrates how DASS21 subscale scores (Depression, Anxiety, Stress) can be visualised longitudinally across five timepoints using simulated clinical trial data. The approach supports clear, per-participant tracking and could be used in early-phase trials, exploratory studies, or internal dashboards.

---

## Project Summary

- **Goal:** Simulate REDCap-style output and visualise individual symptom trajectories across DASS subscales.
- **Toolchain:** Python (simulation), R + ggplot2 (visualisation), Quarto (reporting)
- **Scope:** Intervention vs. control comparison across baseline, 3, 6, 9, and 12 months

---

## Key Files

- `index.qmd` – Quarto notebook with inline discussion and visuals
- `scripts/dass21_data_simulation.py` – Python script for generating synthetic DASS21 data
- `scripts/simulation_checking.py` – Helper script to confirm intervention/control divergence
- `data/simulated_dass21_full.csv` – Simulated REDCap-style dataset (Q1–Q21 + subscales)
- `R/dass21_facet_plot.R` – Modularised R script for reusable visualisation
- `figures/` – Sample output figures for control and intervention groups

---

## View the Live Report

[**Click here to view the report**](https://julian-chung.github.io/dass21-simulation-and-visualisation/)

> This project uses only simulated data. The visualisation structure and logic are adapted from real clinical trial workflows.

---

## Quickstart

```bash
quarto render
open docs/index.html
```

---

## Author

Julian Chung
Public Health | Data Analysis | Clinical Trials
