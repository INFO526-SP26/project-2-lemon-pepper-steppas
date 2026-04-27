library(shiny)
library(tidyverse)
library(plotly)
library(bslib)

# ── load data ─────────────────────────────────────────────────────────────────
# df_clean <- read_csv("tpbm_clean.csv")

studies <- df_clean |>
  distinct(study_id, condition, .keep_all = TRUE)

all_conditions  <- sort(unique(studies$condition))
all_designs     <- sort(unique(studies$study_design))
all_directions  <- sort(unique(studies$outcome_direction))
all_populations <- sort(unique(studies$population_type))
year_range      <- range(studies$year, na.rm = TRUE)

pal_direction <- c(
  "positive"     = "#2a7f62",
  "mixed"        = "#e09b3d",
  "inconclusive" = "#c0392b",
  "negative"     = "#7f8c8d"
)

# ── ui ────────────────────────────────────────────────────────────────────────
ui <- page_sidebar(
  title = "Red Light Therapy & Mental Health — Research Evidence Dashboard",
  theme = bs_theme(
    bg           = "#f7f8fa",
    fg           = "#1a1f2e",
    primary      = "#2a5298",
    secondary    = "#e4e8f0",
    base_font    = font_google("Source Sans Pro"),
    heading_font = font_google("Source Serif Pro"),
    font_scale   = 0.95
  ),
  
  tags$style(HTML("
    .navbar { background: #ffffff !important; border-bottom: 2px solid #2a5298 !important; }
    .navbar-brand { font-family: 'Source Serif Pro', serif !important; font-weight: 700; color: #1a1f2e !important; }
    .sidebar { background: #ffffff !important; border-right: 1px solid #dde2ed !important; }
    .card { background: #ffffff !important; border: 1px solid #dde2ed !important; border-radius: 6px !important; box-shadow: 0 1px 4px rgba(0,0,0,0.06) !important; }
    .card-header { background: #ffffff !important; border-bottom: 2px solid #2a5298 !important; font-family: 'Source Sans Pro', sans-serif !important; font-size: 0.72rem !important; font-weight: 700 !important; letter-spacing: 0.08em !important; text-transform: uppercase !important; color: #2a5298 !important; padding: 10px 16px !important; }
    .value-box { border: 1px solid #dde2ed !important; border-radius: 6px !important; box-shadow: 0 1px 4px rgba(0,0,0,0.06) !important; }
    .value-box .value-box-value { color: #1a1f2e !important; font-weight: 700 !important; font-size: 1.8rem !important; }
    .value-box .value-box-title { color: #444444 !important; font-weight: 600 !important; font-size: 0.8rem !important; }
    .value-box svg { color: #2a5298 !important; }
    hr { border-color: #dde2ed !important; }
    .btn-outline-secondary { border-color: #dde2ed !important; color: #555 !important; font-size: 0.8rem !important; }
    .selectize-input { border-color: #dde2ed !important; border-radius: 4px !important; font-size: 0.85rem !important; }
    label { font-size: 0.8rem !important; font-weight: 600 !important; color: #444 !important; }
    .sidebar-title { font-family: 'Source Sans Pro', sans-serif; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; color: #2a5298; margin-bottom: 16px; }
  ")),
  
  sidebar = sidebar(
    width = 250,
    bg = "#ffffff",
    
    tags$p("Filters", class = "sidebar-title"),
    
    sliderInput("year_range", "Year range",
                min = year_range[1], max = year_range[2],
                value = year_range, step = 1, sep = ""
    ),
    
    selectInput("condition_filter", "Condition",
                choices = c("All", all_conditions), selected = "All"
    ),
    
    selectInput("design_filter", "Study design",
                choices = c("All", all_designs), selected = "All", multiple = TRUE
    ),
    
    selectInput("population_filter", "Population",
                choices = c("All", all_populations), selected = "All", multiple = TRUE
    ),
    
    selectInput("direction_filter", "Outcome direction",
                choices = c("All", all_directions), selected = "All", multiple = TRUE
    ),
    
    hr(),
    actionButton("reset", "Reset filters",
                 class = "btn-outline-secondary btn-sm w-100"
    )
  ),
  
  # value boxes
  layout_columns(
    fill = FALSE,
    value_box(
      title    = "Total studies",
      value    = textOutput("n_studies"),
      showcase = bsicons::bs_icon("journal-text"),
      theme    = value_box_theme(bg = "#eef2fb", fg = "#1a1f2e")
    ),
    value_box(
      title    = "Conditions studied",
      value    = textOutput("n_conditions"),
      showcase = bsicons::bs_icon("diagram-3"),
      theme    = value_box_theme(bg = "#eef2fb", fg = "#1a1f2e")
    ),
    value_box(
      title    = "% Positive outcomes",
      value    = textOutput("pct_positive"),
      showcase = bsicons::bs_icon("graph-up-arrow"),
      theme    = value_box_theme(bg = "#eef2fb", fg = "#1a1f2e")
    ),
    value_box(
      title    = "Median sample size",
      value    = textOutput("med_sample"),
      showcase = bsicons::bs_icon("people"),
      theme    = value_box_theme(bg = "#eef2fb", fg = "#1a1f2e")
    )
  ),
  
  # 2x2 grid
  layout_columns(
    col_widths = c(6, 6),
    
    card(
      full_screen = TRUE,
      card_header("Which conditions are most studied, and how consistent are the results?"),
      plotlyOutput("stacked_bar", height = "500px")
    ),
    
    card(
      full_screen = TRUE,
      card_header("How rigorous is the evidence by condition?"),
      plotlyOutput("evidence_matrix", height = "500px")
    ),
    
    card(
      full_screen = TRUE,
      card_header("Where is research volume concentrated, and how positive is it?"),
      plotlyOutput("treemap", height = "500px")
    ),
    
    card(
      full_screen = TRUE,
      card_header("Are positive results coming from rigorous study designs?"),
      plotlyOutput("sankey", height = "500px")
    )
  )
)

# ── server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  observeEvent(input$reset, {
    updateSliderInput(session, "year_range",        value = year_range)
    updateSelectInput(session, "condition_filter",  selected = "All")
    updateSelectInput(session, "design_filter",     selected = "All")
    updateSelectInput(session, "population_filter", selected = "All")
    updateSelectInput(session, "direction_filter",  selected = "All")
  })
  
  filtered <- reactive({
    d <- studies |>
      filter(year >= input$year_range[1], year <= input$year_range[2])
    if (!"All" %in% input$condition_filter  && length(input$condition_filter)  > 0)
      d <- d |> filter(condition         %in% input$condition_filter)
    if (!"All" %in% input$design_filter     && length(input$design_filter)     > 0)
      d <- d |> filter(study_design      %in% input$design_filter)
    if (!"All" %in% input$population_filter && length(input$population_filter) > 0)
      d <- d |> filter(population_type   %in% input$population_filter)
    if (!"All" %in% input$direction_filter  && length(input$direction_filter)  > 0)
      d <- d |> filter(outcome_direction %in% input$direction_filter)
    d
  })
  
  # value boxes
  output$n_studies    <- renderText(nrow(filtered()))
  output$n_conditions <- renderText(n_distinct(filtered()$condition))
  output$pct_positive <- renderText({
    paste0(round(mean(filtered()$outcome_direction == "positive", na.rm = TRUE) * 100), "%")
  })
  output$med_sample <- renderText({
    m <- median(filtered()$sample, na.rm = TRUE)
    if (is.na(m)) "—" else round(m)
  })
  
  # ── 1. stacked bar ───────────────────────────────────────────────────────────
  output$stacked_bar <- renderPlotly({
    d <- filtered() |>
      count(condition, outcome_direction) |>
      mutate(condition = fct_reorder(condition, n, sum))
    
    validate(need(nrow(d) > 0, "No data available for current filters."))
    
    dirs <- c("positive", "mixed", "inconclusive", "negative")
    p <- plot_ly(type = "bar", orientation = "h")
    
    for (dir in dirs) {
      sub <- d |> filter(outcome_direction == dir)
      if (nrow(sub) == 0) next
      p <- p |> add_trace(
        x         = sub$n,
        y         = as.character(sub$condition),
        name      = str_to_title(dir),
        marker    = list(
          color = pal_direction[[dir]],
          line  = list(color = "#ffffff", width = 0.8)
        ),
        text      = paste0(str_to_title(dir), ": ", sub$n, " studies"),
        hoverinfo = "text+y"
      )
    }
    
    p |> layout(
      barmode       = "stack",
      paper_bgcolor = "#ffffff",
      plot_bgcolor  = "#ffffff",
      font    = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
      xaxis   = list(
        title     = "Number of studies",
        gridcolor = "#edf0f5",
        zeroline  = FALSE
      ),
      yaxis   = list(title = "", tickfont = list(size = 10)),
      legend  = list(
        orientation = "h", x = 0, y = -0.1,
        bgcolor     = "#ffffff",
        bordercolor = "#dde2ed",
        borderwidth = 1,
        font        = list(size = 10)
      ),
      margin = list(l = 10, r = 20, t = 10, b = 60)
    )
  })
  
  # ── 2. evidence matrix ───────────────────────────────────────────────────────
  output$evidence_matrix <- renderPlotly({
    validate(need(
      nrow(filtered()) > 1 && n_distinct(filtered()$condition) > 1,
      "Select more data to display the evidence matrix."
    ))
    
    d <- filtered() |>
      group_by(condition) |>
      summarise(
        `Study count`   = n(),
        `% Positive`    = round(mean(outcome_direction == "positive", na.rm = TRUE) * 100),
        `% RCT`         = round(mean(str_detect(study_design, regex("rct", ignore_case = TRUE)), na.rm = TRUE) * 100),
        `Median sample` = round(median(sample, na.rm = TRUE)),
        .groups = "drop"
      ) |>
      mutate(
        condition = if (n_distinct(condition) > 1)
          fct_reorder(condition, `Study count`) else condition
      )
    
    metrics <- c("Study count", "% Positive", "% RCT", "Median sample")
    
    mat <- d |>
      mutate(across(all_of(metrics), ~ as.numeric(scale(.x)))) |>
      pivot_longer(all_of(metrics), names_to = "metric", values_to = "z")
    
    raw <- d |>
      pivot_longer(all_of(metrics), names_to = "metric", values_to = "raw_val")
    
    combined <- left_join(mat, raw, by = c("condition", "metric")) |>
      mutate(metric = factor(metric, levels = metrics))
    
    plot_ly(
      combined,
      x         = ~metric,
      y         = ~condition,
      z         = ~z,
      text      = ~paste0(condition, "\n", metric, ": ", raw_val),
      hoverinfo = "text",
      type      = "heatmap",
      colorscale = list(
        list(0,   "#c0392b"),
        list(0.5, "#f7f8fa"),
        list(1,   "#2a7f62")
      ),
      showscale = TRUE,
      colorbar  = list(title = "z-score", tickfont = list(size = 9))
    ) |>
      layout(
        paper_bgcolor = "#ffffff",
        plot_bgcolor  = "#ffffff",
        font  = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
        xaxis = list(
          title     = "",
          side      = "top",
          tickfont  = list(size = 10),
          tickangle = -20
        ),
        yaxis  = list(title = "", tickfont = list(size = 10)),
        margin = list(l = 10, r = 10, t = 80, b = 10)
      )
  })
  
  # ── 3. treemap ───────────────────────────────────────────────────────────────
  output$treemap <- renderPlotly({
    d <- filtered() |>
      group_by(condition) |>
      summarise(
        n_studies    = n(),
        pct_positive = mean(outcome_direction == "positive", na.rm = TRUE),
        .groups = "drop"
      ) |>
      mutate(
        tip = paste0(
          "<b>", condition, "</b><br>",
          n_studies, " studies<br>",
          round(pct_positive * 100), "% positive"
        )
      )
    
    validate(need(nrow(d) > 0, "No data available for current filters."))
    
    # treemap color scale: red (0% positive) to green (100% positive)
    colorscale <- list(
      list(0,   "#c0392b"),
      list(0.5, "#e09b3d"),
      list(1,   "#2a7f62")
    )
    
    plot_ly(
      d,
      type       = "treemap",
      labels     = ~condition,
      parents    = "",
      values     = ~n_studies,
      text       = ~tip,
      hoverinfo  = "text",
      marker     = list(
        colors     = ~pct_positive,
        colorscale = colorscale,
        showscale  = TRUE,
        colorbar   = list(
          title      = "% Positive",
          tickformat = ".0%",
          tickfont   = list(size = 9)
        )
      ),
      textinfo   = "label+value",
      textfont   = list(size = 12, color = "#ffffff")
    ) |>
      layout(
        paper_bgcolor = "#ffffff",
        font   = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
        margin = list(l = 10, r = 10, t = 10, b = 10)
      )
  })
  
  # ── 4. sankey ────────────────────────────────────────────────────────────────
  output$sankey <- renderPlotly({
    
    # lump to top 5 study designs to keep it readable
    d <- filtered() |>
      filter(!is.na(outcome_direction)) |>
      mutate(
        study_design = fct_lump_n(study_design, n = 5),
        study_design = as.character(study_design)
      ) |>
      count(study_design, outcome_direction)
    
    validate(need(nrow(d) > 0, "No data available for current filters."))
    
    designs    <- sort(unique(d$study_design))
    directions <- sort(unique(d$outcome_direction))
    
    # nodes: designs first, then directions
    node_labels <- c(designs, directions)
    n_designs   <- length(designs)
    
    # map to indices (0-based for plotly)
    source_idx <- match(d$study_design,     node_labels) - 1
    target_idx <- match(d$outcome_direction, node_labels) - 1
    
    # node colors
    dir_colors <- c(
      "positive"     = "#2a7f62",
      "mixed"        = "#e09b3d",
      "inconclusive" = "#c0392b",
      "negative"     = "#7f8c8d"
    )
    
    node_colors <- c(
      rep("#6a93d4", n_designs),
      sapply(directions, function(x) dir_colors[[x]])
    )
    
    # link colors: match outcome direction
    link_colors <- sapply(d$outcome_direction, function(x) {
      col <- dir_colors[[x]]
      # convert hex to rgba for transparency
      r <- strtoi(substr(col, 2, 3), 16)
      g <- strtoi(substr(col, 4, 5), 16)
      b <- strtoi(substr(col, 6, 7), 16)
      paste0("rgba(", r, ",", g, ",", b, ",0.4)")
    })
    
    plot_ly(
      type = "sankey",
      orientation = "h",
      node = list(
        label = node_labels,
        color = node_colors,
        pad   = 20,
        thickness = 24,
        line  = list(color = "#ffffff", width = 0.5)
      ),
      link = list(
        source = source_idx,
        target = target_idx,
        value  = d$n,
        color  = link_colors,
        label  = paste0(d$study_design, " → ", str_to_title(d$outcome_direction), ": ", d$n, " studies")
      )
    ) |>
      layout(
        paper_bgcolor = "#ffffff",
        font   = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
        margin = list(l = 20, r = 20, t = 20, b = 20)
      )
  })
}

shinyApp(ui, server)