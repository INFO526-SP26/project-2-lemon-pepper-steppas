# Red Light Therapy & Mental Health: Mapping the Research Landscape

**INFO 526: Data Visualization | Spring 2026**  
**University of Arizona — College of Information Science**  
**Authors: Vivian Huynh & Levi Hood**

---

## Abstract

Red light therapy, also known as photobiomodulation (tPBM), has gained widespread attention for a range of claimed health benefits, yet the underlying scientific evidence is rarely presented with meaningful context. This project organizes and visualizes published research on red light therapy and mental health outcomes, providing a clearer picture of what the current science actually supports. Using 102 studies collected from PubMed, ScienceDirect, and Sage Journals via the PICO framework, we built an interactive Shiny dashboard that allows users to explore which mental health conditions are most studied, how results vary across study designs and populations, and where findings are consistent versus mixed or inconclusive.

---

## Repository Contents

| File | Description |
| --- | --- |
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
2. Install dependencies in R:

```r
install.packages(c("shiny", "tidyverse", "plotly", "bslib", "bsicons"))
```

3. Load the cleaned dataset:

```r
df_clean <- read_csv("tpbm_clean.csv")
```

4. Run the app:

```r
shiny::runApp("app.R")
```

---

## Dependencies

| Package | Purpose |
| --- | --- |
| `shiny` | Dashboard framework |
| `tidyverse` | Data cleaning and wrangling |
| `plotly` | Interactive visualizations |
| `bslib` | Dashboard theming |
| `bsicons` | Icons |

---

## Course Context

This project was completed as Project 2 for INFO 526: Data Visualization at the University of Arizona College of Information Science, Spring 2026.
