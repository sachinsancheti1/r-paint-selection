# ui.R
library(shiny)
library(DT)

shinyUI(fluidPage(
  titlePanel("Paint Colour Selection: Nearest-Shade Matching & Palette Builder"),

  sidebarLayout(
    sidebarPanel(
      h4("Target colour"),
      textInput("target_hex", "Hex colour", value = "#C8C0B1"),
      uiOutput("target_swatch"),
      br(),
      textInput("target_label", "Label (optional, e.g. \"Living room wall\")", value = ""),
      numericInput("top_n", "Matches per brand", value = 8, min = 1, max = 30, step = 1),
      actionButton("search_btn", "Find closest shades", class = "btn-primary"),
      tags$p(tags$small(
        "Matching uses CIEDE2000 (perceptual colour distance in Lab space), not plain RGB ",
        "distance — lower ΔE means a closer visual match."
      )),

      tags$hr(),
      h4("Palette"),
      textOutput("palette_count"),
      br(),
      downloadButton("download_palette", "Download palette CSV"),
      br(), br(),
      actionButton("clear_palette", "Clear palette")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel(
          "Matches",
          tags$p(tags$small("Select rows below, then add them to your palette.")),
          actionButton("add_selected", "Add selected to palette", class = "btn-success"),
          tags$hr(),
          DT::dataTableOutput("matches_table")
        ),
        tabPanel(
          "Palette",
          tags$p(tags$small("Select rows below to remove them from the palette.")),
          actionButton("remove_selected", "Remove selected"),
          tags$hr(),
          DT::dataTableOutput("palette_table")
        )
      )
    )
  )
))
