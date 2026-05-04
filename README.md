```markdown
# Red Light Therapy & Mental Health — Research Evidence Dashboard

**INFO 526: Data Visualization | Spring 2026**  
**University of Arizona — College of Information Science**  
**Authors: Vivian Huynh & Levi Hood**

---

## Overview

This project maps the current research landscape of photobiomodulation (red light therapy) and mental health outcomes. Rather than arguing whether the therapy works, the goal is to visualize what the science actually shows — which conditions are most studied, how results vary across study designs and populations, and where findings are consistent versus mixed or inconclusive.

---

## Repository Contents

| File | Description |
|---|---|
| `data_cleaning.Rmd` | Full data cleaning and preprocessing pipeline |
| `tPBM_data.csv` | Raw dataset (102 studies, 18 features) |
| `tpbm_clean.csv` | Cleaned and expanded dataset (227 rows) |
| `app.R` | Interactive Shiny dashboard |
| `v_viz.Rmd` | Exploratory visualizations (Vivian) |
| `levi_viz.Rmd` | Exploratory visualizations (Levi) |

---

## Dashboard

The dashboard was built in R using Shiny and Plotly and includes four interactive visualizations:

- **Stacked bar chart** — study count by condition, colored by outcome direction
- **Sunburst chart** — research volume by population type and condition
- **Box plot** — sample size distribution by control type
- **Sankey diagram** — flow from population age to condition to study design

All charts respond to a shared sidebar with filters for year range, condition, study design, population type, population age, and outcome direction.

---

## Data

- **102** published studies collected from PubMed, ScienceDirect, Sage Journals, and other academic sources
- Studies selected using the PICO framework (Population, Intervention, Comparison, Outcome)
- Raw data expanded to **227 rows** representing unique study × condition × outcome combinations
- **26** condition categories and **26** outcome categories after cleaning

---

## How to Run

1. Clone the repository
2. Open R and install dependencies:
```r
install.packages(c("shiny", "tidyverse", "plotly", "bslib", "bsicons"))
```
3. Load your cleaned dataset into the environment:
```r
df_clean <- read_csv("tpbm_clean.csv")
```
4. Run the app:
```r
shiny::runApp("app.R")
```

---

## Dependencies

- R 4.3+
- `shiny`
- `tidyverse`
- `plotly`
- `bslib`
- `bsicons`

---

## Course Context

This project was completed as Project 2 for INFO 526: Data Visualization at the University of Arizona College of Information Science, Spring 2026.
```