# ui.R
library(shiny)
library(DT)

# Shows a clear, unmissable "please refresh" banner when the Shiny session
# disconnects (server restart, crash, idle timeout, etc.). Shiny's own
# default disconnect behavior is just a subtle page-dimming effect - easy to
# miss unless you already know what a Shiny disconnect looks like. No
# auto-reconnect attempt: a Railway-hosted session is not reliably
# resumable, so the honest answer is always "refresh," not "wait."
# Kept identical across every app's ui.R - copy verbatim, don't diverge.
disconnect_overlay <- function() {
  tagList(
    tags$head(tags$style(HTML("
      #shiny-disconnect-overlay {
        display: none;
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(20, 20, 20, 0.75);
        z-index: 2147483647;
        align-items: center;
        justify-content: center;
      }
      #shiny-disconnect-overlay .box {
        background: #fff;
        border-radius: 8px;
        padding: 28px 32px;
        max-width: 380px;
        text-align: center;
        box-shadow: 0 4px 24px rgba(0,0,0,0.3);
        font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif;
      }
      #shiny-disconnect-overlay .title {
        font-size: 18px;
        font-weight: 600;
        color: #b02a2a;
        margin-bottom: 8px;
      }
      #shiny-disconnect-overlay .msg {
        font-size: 14px;
        color: #333;
        margin-bottom: 18px;
        line-height: 1.4;
      }
      #shiny-disconnect-overlay button {
        background: #2c7be5;
        color: #fff;
        border: none;
        border-radius: 5px;
        padding: 10px 22px;
        font-size: 14px;
        cursor: pointer;
      }
      #shiny-disconnect-overlay button:hover { background: #1a63c4; }
    ")),
    tags$script(HTML("
      $(document).on('shiny:disconnected', function() {
        document.getElementById('shiny-disconnect-overlay').style.display = 'flex';
      });
    "))),
    tags$div(id = "shiny-disconnect-overlay",
      tags$div(class = "box",
        tags$div(class = "title", "Connection lost"),
        tags$div(class = "msg",
          "This session has disconnected from the server. Your work in this ",
          "session can't be recovered — please refresh the page to start a new one."),
        tags$button("Refresh page", onclick = "location.reload()")
      )
    )
  )
}

shinyUI(fluidPage(
  disconnect_overlay(),
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
          fluidRow(
            column(9, DT::dataTableOutput("matches_table")),
            column(3, h5("Preview"), uiOutput("match_preview"))
          )
        ),
        tabPanel(
          "Palette",
          tags$p(tags$small("Select rows below to remove them from the palette.")),
          actionButton("remove_selected", "Remove selected"),
          tags$hr(),
          fluidRow(
            column(9, DT::dataTableOutput("palette_table")),
            column(3, h5("Preview"), uiOutput("palette_preview"))
          )
        )
      )
    )
  )
))
