# Upgrading to a Shiny Dashboard

This guide walks through turning the existing static Quarto report into an interactive Shiny app. It's written to build directly on the code already in `R/dass21_facet_plot.R` and the data produced by `scripts/dass21_data_simulation.py`.

---

## 1. Project Structure

Create a new directory for the Shiny app alongside the existing project files:

```
shiny/
  app.R            # Single-file Shiny app (UI + server)
  R/
    data_prep.R    # Data loading, scoring, reshaping (extracted from dass21_facet_plot.R)
    severity.R     # classify_severity() function (extracted from dass21_facet_plot.R)
```

The app will read from the existing `data/simulated_dass21_full.csv` — no need to duplicate the data.

A single-file `app.R` is fine for an app this size. If it grows beyond ~300 lines, split into `ui.R` and `server.R`.

---

## 2. Extract Reusable Logic

### `shiny/R/data_prep.R`

Pull the data loading and reshaping logic out of `dass21_facet_plot.R` into a standalone function. The key steps are:

1. Read the CSV
2. Multiply subscale scores by 2 (DASS42 alignment)
3. Pivot to long format (one row per participant per timepoint per subscale)
4. Factor the timepoints in chronological order

This function should return the long-format dataframe so the app can use it reactively. Something like:

```r
prepare_dass_data <- function(path) {
  # read CSV -> score -> pivot -> factor timepoints -> return
}
```

You already have all this logic in lines 11-22 of `R/dass21_facet_plot.R` — just wrap it in a function.

### `shiny/R/severity.R`

Copy `classify_severity()` (lines 25-38 of `dass21_facet_plot.R`) as-is. It already works as a standalone function. You'll call it after filtering in the server, so severity bands update when data changes.

---

## 3. App Layout

Use `bslib::page_sidebar()` for a clean, modern layout that doesn't require writing CSS. The structure:

```
+------------------+---------------------------------------------+
|                  |                                             |
|  SIDEBAR         |   MAIN PANEL                                |
|                  |                                             |
|  Group selector  |   Tab 1: Individual Trajectories            |
|  Subscale toggle |     (your existing faceted plot, filtered)  |
|  Participant     |                                             |
|    multi-select  |   Tab 2: Group Summary                      |
|  Timepoint range |     (spaghetti plot + mean trend line)      |
|                  |                                             |
|  Download buttons|   Tab 3: Data Table                         |
|                  |     (filtered data, searchable)             |
+------------------+---------------------------------------------+
```

### Sidebar Inputs

These are the Shiny input widgets you'll need:

| Widget | Purpose | Maps to your data |
|--------|---------|-------------------|
| `radioButtons()` | Group: Intervention / Control / Both | `group` column |
| `checkboxGroupInput()` | Subscales: Anxiety, Depression, Stress | `subscale` column (values: `DASS_Anxiety`, `DASS_Depression`, `DASS_Stress`) |
| `selectizeInput(multiple = TRUE)` | Participant IDs | `id` column (I01-I20, C01-C20) |
| `sliderInput()` | Timepoint range (1-5) | `timepoint` factor levels |
| `downloadButton()` | Export filtered CSV | — |
| `downloadButton()` | Export current plot as PNG | — |

The participant selector should update dynamically based on the group selection — when "Intervention" is selected, only show I01-I20. Use `updateSelectizeInput()` in an `observe()` block for this.

**Important UX note:** Pre-select all participants by default rather than starting with an empty selection. An empty plot on first load is a poor first impression for a portfolio piece — the dashboard should show something meaningful immediately.

### Main Panel Tabs

Use `bslib::navset_card_tab()` to create the tabbed content area.

---

## 4. Tab 1: Individual Trajectories (Your Existing Plot)

This is a direct adaptation of `plot_dass_facet()`. The main changes:

- **Make it reactive:** The plot re-renders when inputs change. Wrap your ggplot code in `renderPlot({})`.
- **Filter before plotting:** Instead of hardcoding `filter(group == "intervention")`, filter based on the sidebar inputs:
  ```r
  filtered_data <- reactive({
    dass_long %>%
      filter(
        group %in% input$group,
        subscale %in% input$subscales,
        id %in% input$participants,
        as.numeric(timepoint) >= input$timepoint_range[1],
        as.numeric(timepoint) <= input$timepoint_range[2]
      )
  })
  ```
- **Dynamic facet columns:** When fewer participants are selected, reduce `ncol` in `facet_wrap()`. A simple heuristic: `ncol = min(5, length(input$participants))`.
- **Dynamic plot height:** With fewer panels the plot can be shorter. Use the `height` argument in `plotOutput()` reactively, or set it in `renderPlot()`.

Your existing colour palette, theme, `coord_flip()`, severity band ordering, and dodge positioning all carry over unchanged.

### Tooltip Option

If you want hover tooltips on this tab (participant ID, exact score, severity band on hover), use `ggiraph` rather than `plotly`. Your plot combines `coord_flip()`, `position_dodge()`, `geom_path()`, and `facet_wrap()` — a combination that plotly routinely mangles during the ggplot-to-plotly conversion. `ggiraph` renders as SVG and preserves ggplot geometry faithfully, so your existing plot code carries over with minimal changes (swap `geom_point()` for `geom_point_interactive()`, etc.).

If you go this route, replace `renderPlot()` with `ggiraph::renderGirafe()` and `plotOutput()` with `ggiraph::girafeOutput()`. Add `ggiraph` to your package dependencies instead of `plotly`.

---

## 5. Tab 2: Group Summary

This is a new visualisation that complements your existing individual-level view. The idea is a spaghetti plot: all individual trajectories drawn as thin, semi-transparent lines, with a bold group mean overlaid.

### Data Shape

For this plot, work with the **raw DASS42 scores** (the `score` column in your long data) rather than the severity bands. The x-axis is timepoint, y-axis is score.

### Building it

1. Plot all individual lines: `geom_line(aes(x = timepoint, y = score, group = interaction(id, subscale)), alpha = 0.2)`
2. Compute the group mean per timepoint per subscale: use `stat_summary(fun = mean, geom = "line", linewidth = 1.5)` or precompute with `group_by(timepoint, subscale) %>% summarise(mean_score = mean(score))`
3. Add a confidence ribbon: `stat_summary(fun.data = mean_se, geom = "ribbon", alpha = 0.2)` (or use `mean_cl_boot` for bootstrap CIs)
4. Facet by subscale (3 panels: Anxiety, Depression, Stress)
5. If "Both" groups are selected, use `colour = group` and `fill = group` to distinguish intervention vs control

### Severity Band Reference Lines

Add horizontal reference lines at the DASS42 severity thresholds using `geom_hline()`. For example, for the Depression panel: dashed lines at y = 9, 13, 20, 27. Label them with `annotate()` or a secondary axis. This gives clinical context to the raw scores.

---

## 6. Tab 3: Data Table

Use `DT::renderDataTable()` to show the filtered data in a searchable, sortable table. Columns to display:

- `id`, `group`, `timepoint`, `subscale`, `score`, `severity_band`

Add `DT::datatable(..., extensions = 'Buttons', options = list(dom = 'Bfrtip', buttons = c('csv', 'excel')))` for built-in export buttons (this replaces the need for a separate download handler for data).

---

## 7. Download Handlers

### CSV Export

```r
output$download_csv <- downloadHandler(
  filename = function() paste0("dass21_filtered_", Sys.Date(), ".csv"),
  content = function(file) write.csv(filtered_data(), file, row.names = FALSE)
)
```

### Plot Export

```r
output$download_plot <- downloadHandler(
  filename = function() paste0("dass21_plot_", Sys.Date(), ".png"),
  content = function(file) {
    ggsave(file, plot = current_plot(), width = 14, height = 10, dpi = 300)
  }
)
```

For the plot export, store the ggplot object in a `reactiveVal` so both `renderPlot()` and the download handler can access the same object.

### A Note on Redundancy

If you implement the DT table in Tab 3 with built-in export buttons (`extensions = 'Buttons'`), the sidebar CSV download becomes redundant — users would have two ways to export the same data. Consider dropping the sidebar CSV download and keeping only the DT buttons for data export. The sidebar plot download button is the one that genuinely needs sidebar placement, since there's no built-in equivalent in the plot panel.

---

## 8. Value Boxes (Optional but Effective)

At the top of the main panel, add a row of `bslib::value_box()` cards showing summary stats for the current filter selection:

- **N participants** selected
- **Mean change from baseline** (latest timepoint score minus baseline score, averaged across selected participants)
- **% in Normal band** at latest timepoint

A caveat on "% in Normal band": since DASS subscales have different severity thresholds, this metric can be misleading when aggregated across subscales. Either show it per-subscale, or use a simpler alternative like **median score at latest timepoint vs baseline**, which sidesteps the severity-band-mixing issue.

These update reactively as filters change and give an at-a-glance summary before the user scrolls to the plots.

---

## 9. Theming

Use `bslib::bs_theme()` to match your existing report's look:

```r
theme <- bs_theme(
  version = 5,
  bootswatch = "cosmo",      # matches your Quarto theme
  primary = "#184CE2",        # your Depression blue
  "navbar-bg" = "#f7f7f7"    # matches your strip.background
)
```

Your existing colour palette (`#E23418`, `#184CE2`, `#03AC50`) carries over in the ggplot `scale_colour_manual()` calls.

---

## 10. Package Dependencies

These are the packages you'll need beyond what you already use:

| Package | Purpose |
|---------|---------|
| `shiny` | Core framework |
| `bslib` | Modern UI layout and theming |
| `DT` | Interactive data tables |
| `ggiraph` | Interactive plots (optional — only if you want hover tooltips) |

Install with:

```r
install.packages(c("shiny", "bslib", "DT"))
# Optional:
install.packages("ggiraph")
```

`tidyverse`, `here`, and `ggplot2` are already in your `renv.lock`.

After adding the new packages, run `renv::snapshot()` to update the lockfile.

---

## 11. Running Locally

From the project root:

```r
shiny::runApp("shiny")
```

Or from the terminal:

```bash
Rscript -e "shiny::runApp('shiny', port = 3838)"
```

---

## 12. Deployment Options

### shinyapps.io (Easiest)

Free tier gives you 5 apps and 25 active hours/month — plenty for a portfolio piece.

```r
# One-time setup
install.packages("rsconnect")
rsconnect::setAccountInfo(name = "your-account", token = "...", secret = "...")

# Deploy
rsconnect::deployApp("shiny")
```

The data CSV needs to be accessible to the app. Either:
- Copy it into the `shiny/` directory before deploying, or
- Read it from a relative path like `../data/simulated_dass21_full.csv` locally but adjust for deployment

The simplest approach: include a copy of the CSV inside `shiny/data/` for deployment, so the app is self-contained.

### shinylive (No Server Required)

If you want to keep everything on GitHub Pages with no server at all, `shinylive` compiles the Shiny app to WebAssembly and runs it entirely in the browser. For a dataset this small (200 rows) it works well.

```r
install.packages("shinylive")
shinylive::export("shiny", "docs/dashboard")
```

This produces static files you can deploy to GitHub Pages alongside your existing Quarto report. You'd link to it from your main `index.qmd`.

### Posit Connect / Docker

Overkill for a portfolio piece, but worth knowing about if you ever deploy this against real clinical data behind authentication.

---

## 13. Linking from Your Existing Report

Once deployed, add a link to the dashboard from your Quarto report. In `index.qmd`, you could add a section:

```markdown
## Interactive Dashboard

An interactive version of this visualisation is available as a
[Shiny dashboard](https://your-account.shinyapps.io/dass21-dashboard/),
which allows filtering by group, subscale, and participant.
```

This keeps the static report as the narrative/methodology piece and the Shiny app as the interactive exploration tool. They complement each other rather than one replacing the other.

---

## 14. Input Validation

The guide above doesn't cover what happens when the user deselects everything. With no participants, no subscales, or a single-point timepoint range, ggplot will throw errors that bubble up as red stack traces in the UI — not a great look for a portfolio piece.

Add defensive checks at the top of each reactive or `renderPlot()` block:

```r
filtered_data <- reactive({
  req(input$participants, input$subscales)  # silently halt if empty

  dass_long %>%
    filter(
      group %in% input$group,
      subscale %in% input$subscales,
      id %in% input$participants,
      as.numeric(timepoint) >= input$timepoint_range[1],
      as.numeric(timepoint) <= input$timepoint_range[2]
    ) %>%
    validate_data()
})

validate_data <- function(df) {
  validate(
    need(nrow(df) > 0, "No data matches the current filter selection. Try broadening your filters.")
  )
  df
}
```

`req()` silently stops the reactive chain (the output just goes blank). `validate()` with `need()` shows a friendly message in the plot/table area instead of an error. Use `req()` for the inputs themselves, and `validate()` for the resulting data.

---

## 15. Simulation Pipeline Improvement

The current simulation in `scripts/dass21_data_simulation.py` draws each participant's item scores independently at every timepoint — there's no within-subject correlation. Participant I05 at baseline has no statistical relationship to I05 at 3 months. The treatment effect is applied per-draw rather than as a shift from the participant's own trajectory.

For the static Quarto report this is fine — the plots still tell a coherent visual story. But in an interactive dashboard where users drill into individual trajectories and compare timepoints, reviewers with stats backgrounds will notice that "individual trajectories" are really independent random draws wearing a trench coat.

### A Better Approach: Latent Baseline + Correlated Timepoints

The idea is to give each participant a stable underlying severity profile, then model timepoints as correlated deviations from that profile. The treatment effect acts on the trajectory rather than on isolated draws.

```python
import pandas as pd
import numpy as np
import os

np.random.seed(42)

n_per_group = 20
timepoints = ["baseline", "3_months", "6_months", "9_months", "12_months"]
groups = ["intervention", "control"]
questions = [f"Q{i}" for i in range(1, 22)]

dass_anxiety = ["Q2", "Q4", "Q7", "Q9", "Q15", "Q19", "Q20"]
dass_depression = ["Q3", "Q5", "Q10", "Q13", "Q16", "Q17", "Q21"]
dass_stress = ["Q1", "Q6", "Q8", "Q11", "Q12", "Q14", "Q18"]

# Treatment effect increases over time (no effect at baseline)
treatment_effects = {
    "baseline":  0.0,
    "3_months":  0.10,
    "6_months":  0.18,
    "9_months":  0.22,
    "12_months": 0.25
}

def participant_item_probs(base_severity):
    """
    Convert a participant's latent severity (0-1 scale) into
    item-level response probabilities [P(0), P(1), P(2), P(3)].
    Higher severity shifts weight toward 2 and 3.
    """
    s = base_severity
    return [
        max(0.05, 0.35 - 0.30 * s),  # P(0): decreases with severity
        max(0.05, 0.30 - 0.10 * s),  # P(1): slight decrease
        0.20 + 0.15 * s,              # P(2): increases
        0.15 + 0.25 * s               # P(3): increases most
    ]

data = []

for group in groups:
    for subject_id in range(1, n_per_group + 1):
        full_id = f"{group[:1].upper()}{subject_id:02d}"

        # Each participant gets a stable latent severity drawn from Beta(2, 2)
        # This gives a bell-shaped distribution centred around 0.5
        base_severity = np.random.beta(2, 2)

        # Each item gets a small per-participant offset so that individual
        # items aren't perfectly correlated (some questions hit harder)
        item_offsets = {q: np.random.normal(0, 0.05) for q in questions}

        for t_idx, time in enumerate(timepoints):
            row = {"id": full_id, "group": group, "timepoint": time}

            # Timepoint-level fluctuation (small random walk)
            time_noise = np.random.normal(0, 0.03) * t_idx

            for q in questions:
                # Effective severity for this item at this timepoint
                effective = np.clip(
                    base_severity + item_offsets[q] + time_noise,
                    0.01, 0.99
                )

                # Apply treatment effect for intervention group
                if group == "intervention":
                    effective = np.clip(
                        effective - treatment_effects[time],
                        0.01, 0.99
                    )

                probs = participant_item_probs(effective)
                probs = np.array(probs)
                probs /= probs.sum()  # renormalise
                row[q] = np.random.choice([0, 1, 2, 3], p=probs)

            row["DASS_Anxiety"] = sum(row[q] for q in dass_anxiety)
            row["DASS_Depression"] = sum(row[q] for q in dass_depression)
            row["DASS_Stress"] = sum(row[q] for q in dass_stress)
            data.append(row)

df = pd.DataFrame(data)

output_dir = "data"
os.makedirs(output_dir, exist_ok=True)
df.to_csv(os.path.join(output_dir, "simulated_dass21_full.csv"), index=False)
```

### What This Changes

| Aspect | Current Simulation | Improved Simulation |
|--------|-------------------|---------------------|
| Within-subject correlation | None — each timepoint is independent | Stable latent severity per participant |
| Treatment effect | Flat 20% reduction at every post-baseline timepoint | Progressive effect that builds over time (10% → 25%) |
| Item-level variation | All items identically distributed | Per-participant item offsets (some questions "hit harder") |
| Temporal noise | None | Small random walk across timepoints |
| Individual trajectories | Random scatter that happens to be coloured by ID | Coherent trajectories where you can see a participant's story |

### Impact on the Dashboard

With correlated data, the dashboard's individual trajectory view (Tab 1) becomes genuinely informative — you can see participants who start high and trend down under treatment, or participants who are stable throughout. The spaghetti plot (Tab 2) will show cleaner separation between groups because the treatment effect accumulates rather than being a flat modifier on random noise.

The severity thresholds, subscale mappings, and all downstream R code remain unchanged — this is purely a simulation-side improvement that produces a more realistic CSV in the same format.

### Note

The `treatment_effects` dictionary and `participant_item_probs()` function are the two main tuning knobs. Adjust `treatment_effects` values to control how aggressively the intervention works, and adjust the probability mappings to shift the overall severity distribution of the cohort. The `Beta(2, 2)` prior for `base_severity` produces a roughly symmetric distribution — use `Beta(2, 5)` for a healthier cohort or `Beta(5, 2)` for a sicker one.

---

## Suggested Build Order

0. **Improve the simulation** (optional but recommended) — update `dass21_data_simulation.py` with correlated within-subject data, re-generate the CSV, and confirm the Quarto report still renders correctly
1. **`shiny/R/data_prep.R` and `shiny/R/severity.R`** — extract and test the functions independently
2. **Minimal `app.R`** — sidebar + one tab with the filtered facet plot, no extras. Pre-select all participants so the first load shows real data
3. **Get filtering working** — group selector, subscale toggle, participant multi-select. Add `req()` and `validate()` calls so empty selections don't produce errors
4. **Add Tab 2** — group summary spaghetti plot with mean trend
5. **Add Tab 3** — DT data table with built-in export buttons (drop the sidebar CSV download since DT covers it)
6. **Add download handler for plot export and value boxes**
7. **Theme and polish**
8. **Deploy to shinyapps.io**
9. **Link from Quarto report**

Each step should produce a working app, so you can commit and test incrementally.
