library(shiny)
library(tidyverse)
library(plotly)
library(bslib)

# load data
# df_clean <- read_csv("tpbm_clean.csv")

studies <- df_clean |>
  distinct(study_id, condition, .keep_all = TRUE)

all_conditions  <- sort(unique(studies$condition))
all_designs     <- sort(unique(studies$study_design))
all_directions  <- sort(unique(studies$outcome_direction))
all_populations <- sort(unique(studies$population_type))
all_ages        <- sort(unique(studies$population_age))
year_range      <- range(studies$year, na.rm = TRUE)

pal_direction <- c(
  "positive"     = "#2a7f62",
  "mixed"        = "#e09b3d",
  "inconclusive" = "#7f8c8d",
  "negative"     = "#c0392b"
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
                choices = c("All", all_conditions), selected = "All", multiple = TRUE
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
    
    selectInput("age_filter", "Population age",
                choices = c("All", all_ages), selected = "All", multiple = TRUE
    ),
    
    hr(),
    
    actionButton("reset", "Reset filters",
                 class = "btn-outline-secondary btn-sm w-100"
    )
  ),
  
  # row 1: three plots
  layout_columns(
    col_widths = c(5, 3, 4),
    
    card(
      full_screen = TRUE,
      card_header("Which conditions are most studied, and how consistent are the results?"),
      plotlyOutput("stacked_bar", height = "460px")
    ),
    
    card(
      full_screen = TRUE,
      card_header("Research volume by population type and condition"),
      plotlyOutput("sunburst", height = "460px")
    ),
    
    card(
      full_screen = TRUE,
      card_header("Sample size distribution by control type"),
      plotlyOutput("box_ctrl", height = "460px")
    )
  ),
  
  # row 2: sankey full width
  card(
    full_screen = TRUE,
    card_header("How does population age flow into conditions and study designs?"),
    plotlyOutput("sankey2", height = "550px")
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
    updateSelectInput(session, "age_filter",        selected = "All")
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
    if (!"All" %in% input$age_filter        && length(input$age_filter)        > 0)
      d <- d |> filter(population_age    %in% input$age_filter)
    if (!"All" %in% input$direction_filter  && length(input$direction_filter)  > 0)
      d <- d |> filter(outcome_direction %in% input$direction_filter)
    d
  })
  
  # value boxes (server kept in case UI is uncommented)
  output$n_studies    <- renderText(nrow(filtered()))
  output$n_conditions <- renderText(n_distinct(filtered()$condition))
  output$pct_rct <- renderText({
    paste0(
      round(mean(
        str_detect(filtered()$study_design, regex("rct", ignore_case = TRUE)),
        na.rm = TRUE
      ) * 100),
      "%"
    )
  })
  output$med_sample <- renderText({
    m <- median(filtered()$sample, na.rm = TRUE)
    if (is.na(m)) "N/A" else round(m)
  })
  
  # ── plot 1: stacked bar ───────────────────────────────────────────────────
  output$stacked_bar <- renderPlotly({
    d <- filtered() |>
      count(condition, outcome_direction) |>
      mutate(condition = fct_reorder(condition, n, sum))
    
    validate(need(nrow(d) > 0, "No data available for current filters."))
    
    dirs <- c("positive", "mixed", "inconclusive", "negative")
    p    <- plot_ly(type = "bar", orientation = "h")
    
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
      font   = list(color = "#1a1f2e", family = "Source Sans Pro", size = 10),
      xaxis  = list(
        title     = list(text = "Number of studies", font = list(size = 10)),
        gridcolor = "#edf0f5",
        zeroline  = FALSE,
        tickfont  = list(size = 9)
      ),
      yaxis  = list(
        title      = "",
        tickfont   = list(size = 9),
        automargin = TRUE
      ),
      legend = list(
        orientation   = "h",
        x             = 0,
        y             = -0.14,
        bgcolor       = "#ffffff",
        bordercolor   = "#dde2ed",
        borderwidth   = 1,
        font          = list(size = 9),
        tracegroupgap = 0
      ),
      margin = list(l = 0, r = 10, t = 10, b = 50)
    )
  })
  
  # ── plot 2: sunburst ──────────────────────────────────────────────────────
  output$sunburst <- renderPlotly({
    df_nested <- bind_rows(
      filtered() |>
        group_by(population_type) |>
        summarise(total = n(), .groups = "drop") |>
        mutate(id = population_type, label = population_type, parent = ""),
      
      filtered() |>
        group_by(population_type, condition) |>
        summarise(total = n(), .groups = "drop") |>
        mutate(
          id     = paste(population_type, condition, sep = " - "),
          label  = condition,
          parent = population_type
        )
    )
    
    validate(need(nrow(df_nested) > 0, "No data available for current filters."))
    
    plot_ly(
      data         = df_nested,
      type         = "sunburst",
      ids          = ~id,
      labels       = ~label,
      parents      = ~parent,
      values       = ~total,
      branchvalues = "total",
      textinfo     = "label+percent parent"
    ) |>
      layout(
        paper_bgcolor = "#ffffff",
        font          = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
        margin        = list(l = 10, r = 10, t = 10, b = 10)
      )
  })
  
  # ── plot 3: box plot ──────────────────────────────────────────────────────
  output$box_ctrl <- renderPlotly({
    d_box_ctrl <- filtered() |>
      filter(!is.na(sample), !is.na(control_type)) |>
      filter(sample <= 150) |>
      mutate(
        control_type = str_to_title(str_trim(control_type)),
        tip = paste0(
          "<b>", author, " (", year, ")</b><br>",
          condition, "<br>",
          "Sample size: ", sample, "<br>",
          control_type
        )
      )
    
    validate(need(nrow(d_box_ctrl) > 0, "No data available for current filters."))
    
    ctrl_pal <- c(
      "Placebo-Controlled" = "#2a5298",
      "Sham-Controlled"    = "#2a7f62",
      "No Control Group"   = "#e09b3d",
      "Open-Label"         = "#8e44ad",
      "Case-Control"       = "#c0392b"
    )
    
    ctrl_levels <- intersect(names(ctrl_pal), unique(d_box_ctrl$control_type))
    
    p <- plot_ly(type = "box")
    
    for (ctrl in ctrl_levels) {
      sub <- d_box_ctrl |> filter(control_type == ctrl)
      if (nrow(sub) == 0) next
      p <- p |> add_trace(
        y         = sub$sample,
        name      = ctrl,
        type      = "box",
        boxpoints = "all",
        jitter    = 0.4,
        pointpos  = 0,
        marker    = list(color = ctrl_pal[[ctrl]], size = 5, opacity = 0.6),
        line      = list(color = ctrl_pal[[ctrl]]),
        fillcolor = paste0(
          "rgba(",
          paste(c(
            strtoi(substr(ctrl_pal[[ctrl]], 2, 3), 16),
            strtoi(substr(ctrl_pal[[ctrl]], 4, 5), 16),
            strtoi(substr(ctrl_pal[[ctrl]], 6, 7), 16)
          ), collapse = ","),
          ",0.2)"
        ),
        text      = sub$tip,
        hoverinfo = "text"
      )
    }
    
    p |> layout(
      paper_bgcolor = "#ffffff",
      plot_bgcolor  = "#ffffff",
      font       = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
      xaxis      = list(title = "Control type", tickangle = -20, automargin = TRUE),
      yaxis      = list(title = "Sample size (n)", zeroline = FALSE),
      showlegend = FALSE,
      margin     = list(l = 50, r = 20, t = 10, b = 80)
    )
  })
  
  # ── plot 4: sankey ────────────────────────────────────────────────────────
  output$sankey2 <- renderPlotly({
    d_sankey2 <- filtered() |>
      filter(!is.na(population_age), !is.na(condition), !is.na(study_design)) |>
      mutate(study_design = as.character(fct_lump_n(study_design, n = 6))) |>
      count(population_age, condition, study_design) |>
      filter(n >= 1)
    
    validate(need(nrow(d_sankey2) > 0, "No data available for current filters."))
    
    ages    <- sort(unique(d_sankey2$population_age))
    conds   <- sort(unique(d_sankey2$condition))
    designs <- sort(unique(d_sankey2$study_design))
    
    node_labels <- c(ages, conds, designs)
    
    age_colors <- c("adult" = "#2a5298", "geriatric" = "#8e44ad", "pediatric" = "#e09b3d")
    
    node_colors <- c(
      sapply(ages,   function(x) age_colors[[x]]),
      rep("#6a93d4", length(conds)),
      rep("#95a5a6", length(designs))
    )
    
    source1 <- match(d_sankey2$population_age, node_labels) - 1
    target1 <- match(d_sankey2$condition,      node_labels) - 1
    source2 <- match(d_sankey2$condition,      node_labels) - 1
    target2 <- match(d_sankey2$study_design,   node_labels) - 1
    
    plot_ly(
      type = "sankey",
      node = list(
        label     = node_labels,
        color     = node_colors,
        pad       = 15,
        thickness = 20,
        line      = list(color = "#ffffff", width = 0.5)
      ),
      link = list(
        source = c(source1, source2),
        target = c(target1, target2),
        value  = c(d_sankey2$n, d_sankey2$n),
        label  = c(
          paste0(d_sankey2$population_age, " -> ", d_sankey2$condition,  ": ", d_sankey2$n),
          paste0(d_sankey2$condition,      " -> ", d_sankey2$study_design, ": ", d_sankey2$n)
        )
      )
    ) |>
      layout(
        paper_bgcolor = "#ffffff",
        font          = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
        margin        = list(l = 20, r = 20, t = 30, b = 20)
      )
  })
}

shinyApp(ui, server)