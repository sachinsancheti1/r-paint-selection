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

# Visual styling pulled from the Vitrag (vitrag-6) design system - navy +
# teal palette, sharp/square corners (radius 0 throughout, not rounded),
# uppercase tracking-wide labels/buttons, Source Sans Pro. Layered on top of
# Shiny's default Bootstrap 3 via a plain CSS override block rather than a
# Shiny theming package, since only the visual language (not the
# React/Tailwind component structure) is being reused here. Font sizes were
# audited against vitrag-6's actual globals.css after an initial pass ran
# too small (13px tabs/12px labels vs. vitrag's real 14px minimums) - kept
# identical across every app's ui.R from here on, copy verbatim.
vitrag_theme <- function() {
  tagList(
    tags$head(
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700&display=swap"),
      tags$style(HTML("
        :root {
          --vblue: #384764;
          --vgreen: #00a99e;
          --vgreen-dark: #00786f;
          --vorange: #ff7824;
          --vsection: #f2f5f9;
        }
        body {
          font-family: 'Source Sans 3', 'Source Sans Pro', system-ui, sans-serif;
          color: var(--vblue);
          background: #ffffff;
          font-size: 15px;
        }
        /* Bootstrap's default <small>/.help-block shrink to ~85% of a
           14px base (~12px) reads as genuinely too small once the base
           itself is 15px - fixed to a real, comfortable size instead of
           a relative shrink. */
        small, .help-block {
          font-size: 13px;
        }
        h1, h2, h3, h4, h5, legend {
          font-family: 'Source Sans 3', 'Source Sans Pro', system-ui, sans-serif;
          color: var(--vblue);
          font-weight: 600;
        }
        .container-fluid > h1:first-child {
          padding: 18px 0 8px;
          border-bottom: 3px solid var(--vgreen);
          margin-bottom: 4px;
        }
        a { color: var(--vblue); }
        a:hover { color: var(--vgreen-dark); }

        /* Tabs: bold uppercase labels, teal underline on the active tab -
           matches vitrag's .nav-link underline-indicator pattern. */
        .nav-tabs { border-bottom: 2px solid var(--vsection); }
        .nav-tabs > li > a {
          font-family: 'Source Sans 3', sans-serif;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.03em;
          font-size: 15px;
          padding: 12px 18px;
          color: var(--vblue);
          border-radius: 0;
          border: none;
          background: transparent;
        }
        .nav-tabs > li.active > a,
        .nav-tabs > li.active > a:hover,
        .nav-tabs > li.active > a:focus {
          color: var(--vblue);
          background: transparent;
          border: none;
          border-bottom: 3px solid var(--vgreen);
        }
        .nav-tabs > li > a:hover {
          background: var(--vsection);
          border: none;
          border-bottom: 3px solid var(--vgreen);
        }

        /* Sidebar: light section background, sharp corners, no shadow. */
        .well {
          background: var(--vsection);
          border: none;
          border-radius: 0;
          box-shadow: none;
        }

        /* Form fields: sharp corners, uppercase tracking-wide labels, teal focus ring. */
        label {
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.03em;
          font-size: 14px;
          color: var(--vblue);
        }
        .form-control {
          border-radius: 0;
          border: 1px solid #c7ccd6;
          font-size: 15px;
          height: auto;
          padding: 8px 12px;
        }
        .form-control:focus {
          border-color: var(--vgreen);
          box-shadow: 0 0 0 1px var(--vgreen);
        }

        /* Buttons: sharp corners, bold uppercase, navy fill / teal hover -
           matches vitrag's .btn-vitrag. */
        .btn, .btn-default, .btn-primary {
          border-radius: 0;
          border: 2px solid var(--vblue);
          background: var(--vblue);
          color: #ffffff;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.03em;
          font-size: 15px;
          padding: 10px 24px;
          transition: all 0.15s ease;
        }
        .btn:hover, .btn-default:hover, .btn-primary:hover {
          background: var(--vgreen-dark);
          border-color: var(--vgreen-dark);
          color: #ffffff;
        }
        /* Positive/add actions get the teal instead of navy - still
           sharp-cornered/uppercase/bold like every other button. */
        .btn-success {
          border-radius: 0;
          border: 2px solid var(--vgreen-dark);
          background: var(--vgreen-dark);
          color: #ffffff;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.03em;
          font-size: 15px;
          padding: 10px 24px;
          transition: all 0.15s ease;
        }
        .btn-success:hover {
          background: var(--vblue);
          border-color: var(--vblue);
          color: #ffffff;
        }

        /* Radio/checkbox accent color. */
        input[type='radio'], input[type='checkbox'] { accent-color: var(--vgreen); }
      "))
    )
  )
}

shinyUI(fluidPage(
  disconnect_overlay(),
  vitrag_theme(),
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
