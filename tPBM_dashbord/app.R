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
      title    = "% RCTs",
      value    = textOutput("pct_rct"),        # <-- changed from pct_positive
      showcase = bsicons::bs_icon("clipboard2-check"),
      theme    = value_box_theme(bg = "#eef2fb", fg = "#1a1f2e")
    ),
    value_box(
      title    = "Median sample size",
      value    = textOutput("med_sample"),
      showcase = bsicons::bs_icon("people"),
      theme    = value_box_theme(bg = "#eef2fb", fg = "#1a1f2e")
    )
  ),
  
  # ── layout ──────────────────────────────────────────────────────────────────
  # HOW TO ADD A PLOT TO THE UI:
  # 1. Add a new card() inside layout_columns() below
  # 2. Give it a card_header() with a descriptive title
  # 3. Add plotlyOutput("your_plot_id") — the id must match what you use in the server
  # 4. Adjust col_widths if needed: c(6,6) = 2 columns, c(12) = full width,
  #    c(4,4,4) = 3 columns, c(8,4) = wide + narrow side by side
  # Example:
  #   card(
  #     full_screen = TRUE,
  #     card_header("Your chart title here"),
  #     plotlyOutput("your_plot_id", height = "500px")
  #   )
  
  layout_columns(
    col_widths = c(6, 6),
    
    # ── plot 1 ──────────────────────────────────────────────────────────────
    card(
      full_screen = TRUE,
      card_header("Which conditions are most studied, and how consistent are the results?"),
      plotlyOutput("stacked_bar", height = "500px")
    ),
    
    # ── plot 2 ──────────────────────────────────────────────────────────────
    # REPLACE THIS CARD to swap in your own plot:
    # - change the card_header() text to describe your chart
    # - change plotlyOutput("plot_2") to match your output id in the server
    card(
      full_screen = TRUE,
      card_header("Chart 2 title — replace me"),
      plotlyOutput("sunburst", height = "500px")
    ),
    
    # ── plot 3 ──────────────────────────────────────────────────────────────
    card(
      full_screen = TRUE,
      card_header("Chart 3 title — replace me"),
      plotlyOutput("plot_3", height = "500px")
    ),
    
    # ── plot 4 ──────────────────────────────────────────────────────────────
    card(
      full_screen = TRUE,
      card_header("Chart 4 title — replace me"),
      plotlyOutput("plot_4", height = "500px")
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
    if (is.na(m)) "—" else round(m)
  })
  
  # ── plot 1: stacked bar ───────────────────────────────────────────────────
  output$stacked_bar <- renderPlotly({
    d <- filtered() |>
      count(condition, outcome_direction) |>
      mutate(condition = fct_reorder(condition, n, sum))
    
    validate(need(nrow(df_nested) > 0, "No data available for current filters."))
    
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
      xaxis   = list(title = "Number of studies", gridcolor = "#edf0f5", zeroline = FALSE),
      yaxis   = list(title = "", tickfont = list(size = 10)),
      legend  = list(orientation = "h", x = 0, y = -0.1, bgcolor = "#ffffff",
                     bordercolor = "#dde2ed", borderwidth = 1, font = list(size = 10)),
      margin  = list(l = 10, r = 20, t = 10, b = 60)
    )
  })
  
  # ── plot 2: ADD YOUR PLOT HERE ────────────────────────────────────────────
  # HOW TO ADD YOUR PLOT:
  # 1. Rename output$plot_2 to something descriptive e.g. output$heatmap
  # 2. Make sure the name matches plotlyOutput("heatmap") in the UI above
  # 3. Always use filtered() instead of studies so filters apply
  # 4. Always wrap your data prep in validate(need(...)) so empty filters
  #    show a clean message instead of crashing
  # 5. Always add paper_bgcolor = "#ffffff" and plot_bgcolor = "#ffffff"
  #    to layout() to match the dashboard style
  # 6. Always add font = list(color = "#1a1f2e", family = "Source Sans Pro")
  #    to layout() to match the dashboard font
  #
  # TEMPLATE:
  # output$your_plot_id <- renderPlotly({
  #   d <- filtered() %>%
  #     # your data wrangling here
  #
  #   validate(need(nrow(d) > 0, "No data available for current filters."))
  #
  #   plot_ly(d, ...) %>%
  #     layout(
  #       paper_bgcolor = "#ffffff",
  #       plot_bgcolor  = "#ffffff",
  #       font = list(color = "#1a1f2e", family = "Source Sans Pro", size = 11),
  #       # your layout options here
  #     )
  # })
  
  
  output$sunburst <- renderPlotly({
    
    df_nested <- bind_rows(
      # inner ring
      filtered() |>
        group_by(population_type) |>
        summarise(total = n(), .groups = 'drop') |>
        mutate(id = population_type, label = population_type, parent = ''),
      
      # outer ring
      filtered() |>
        group_by(population_type, condition) |>
        summarise(total = n(), .groups = 'drop') |>
        mutate(
          id     = paste(population_type, condition, sep = ' - '),
          label  = condition,
          parent = population_type
        )
    )
    
    validate(need(nrow(df_nested) > 0, "No data available for current filters."))
    
    p_pie <- plot_ly(
      data         = df_nested,
      type         = 'sunburst',
      ids          = ~id,
      labels       = ~label,
      parents      = ~parent,
      values       = ~total,
      branchvalues = 'total',
      textinfo     = 'label+percent parent'
    )
  })
  
  # ── plot 3: ADD YOUR PLOT HERE ────────────────────────────────────────────
  # Same instructions as plot 2 above.
  
  output$plot_3 <- renderPlotly({
    validate(need(FALSE, "Replace this block with your plot code."))
    plot_ly()
  })
  
  # ── plot 4: ADD YOUR PLOT HERE ────────────────────────────────────────────────────────
  output$plot_4 <- renderPlotly({
    validate(need(FALSE, "Replace this block with your plot code."))
    plot_ly()
  })
}

shinyApp(ui, server)