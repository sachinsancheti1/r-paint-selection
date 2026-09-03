# server.R
library(shiny)
library(data.table)
library(farver)
library(DT)

# Default Shiny upload cap is 5MB. Matches nginx's client_max_body_size
# (200M) in nginx.conf.template - nginx's own default (1MB) sits in front
# of this and would 413 anything larger before Shiny ever saw it, so both
# had to move together. This app has no real file upload today, but kept
# consistent with the other apps rather than a silent exception.
options(shiny.maxRequestSize = 200 * 1024^2)

# colClasses forced explicitly: Asian Paints has no genuine descriptive
# shade name (see README), so its "name" column is entirely blank -
# fread infers an all-blank column as logical rather than character,
# which would silently break rbindlist() below when combined with
# Berger's character-type names.
catalog_colclasses <- c(code = "character", name = "character")
catalogs <- list(
  Berger = fread("catalog_berger.csv", colClasses = catalog_colclasses),
  "Asian Paints" = fread("catalog_asian.csv", colClasses = catalog_colclasses),
  "Birla Opus" = fread("catalog_birla_opus.csv", colClasses = catalog_colclasses)
)

hex_to_rgb <- function(hex) {
  hex <- gsub("^#", "", trimws(hex))
  if (!grepl("^[0-9A-Fa-f]{6}$", hex)) return(NULL)
  as.integer(c(strtoi(substr(hex, 1, 2), 16L), strtoi(substr(hex, 3, 4), 16L), strtoi(substr(hex, 5, 6), 16L)))
}

rgb_to_hex <- function(r, g, b) sprintf("#%02X%02X%02X", r, g, b)

swatch_html <- function(hex) {
  sprintf('<div style="width:56px;height:36px;background:%s;border:1px solid #999;border-radius:3px;"></div>', hex)
}

# Large preview shown for the most recently selected table row - a 56x36
# table swatch is too small to actually judge a color by (the whole point
# of this app); this gives a real, sizable block plus the details needed
# to go order it.
large_preview_ui <- function(row) {
  if (is.null(row) || nrow(row) == 0) {
    return(tags$p(tags$small("Select a row to preview it here.")))
  }
  tagList(
    tags$div(style = sprintf(
      "width:100%%; height:120px; background:%s; border:1px solid #999; border-radius:6px; margin-bottom:8px;",
      row$Hex
    )),
    tags$table(
      style = "font-size: 14px;",
      tags$tr(tags$td(tags$b("Brand: ")), tags$td(row$Brand)),
      tags$tr(tags$td(tags$b("Code: ")), tags$td(row$Code)),
      tags$tr(tags$td(tags$b("Name: ")), tags$td(row$Name)),
      tags$tr(tags$td(tags$b("Hex: ")), tags$td(row$Hex))
    )
  )
}

match_catalog <- function(target_rgb, catalog, top_n) {
  cat_mat <- as.matrix(catalog[, .(r, g, b)])
  de <- as.numeric(farver::compare_colour(
    matrix(target_rgb, nrow = 1), cat_mat,
    from_space = "rgb", to_space = "rgb", method = "CIE2000"
  ))
  out <- copy(catalog)
  out$deltaE <- de
  out <- out[order(deltaE)]
  out[seq_len(min(top_n, .N))]
}

shinyServer(function(input, output, session) {

  output$target_swatch <- renderUI({
    rgb <- hex_to_rgb(input$target_hex)
    hex <- if (is.null(rgb)) "#ffffff" else input$target_hex
    tags$div(style = sprintf(
      "background-color:%s; width:100%%; height:44px; border:1px solid #999; border-radius:4px;", hex
    ))
  })

  matches <- eventReactive(input$search_btn, {
    rgb <- hex_to_rgb(input$target_hex)
    validate(need(!is.null(rgb), "Enter a valid 6-digit hex colour, e.g. #C8C0B1"))

    res_list <- lapply(names(catalogs), function(brand) {
      m <- match_catalog(rgb, catalogs[[brand]], input$top_n)
      m$brand <- brand
      m
    })
    res <- rbindlist(res_list)
    res <- res[order(deltaE)]
    res$hex <- rgb_to_hex(res$r, res$g, res$b)
    res$target_hex <- toupper(input$target_hex)
    res$target_label <- input$target_label
    res
  })

  output$matches_table <- DT::renderDataTable({
    m <- matches()
    df <- data.table(
      Swatch = swatch_html(m$hex),
      Brand = m$brand,
      Code = m$code,
      Name = m$name,
      Hex = m$hex,
      `ΔE (CIEDE2000)` = round(m$deltaE, 2)
    )
    DT::datatable(df, selection = "multiple", rownames = FALSE, escape = FALSE,
                  options = list(pageLength = 20))
  })

  # Preview follows the most recently clicked row, not just the first
  # selected - clicking a new row to compare should update the preview
  # immediately even with earlier rows still checked.
  output$match_preview <- renderUI({
    sel <- input$matches_table_rows_selected
    if (length(sel) == 0) return(large_preview_ui(NULL))
    m <- matches()[tail(sel, 1)]
    large_preview_ui(data.table(Brand = m$brand, Code = m$code, Name = m$name, Hex = m$hex))
  })

  palette <- reactiveVal(data.table(
    Label = character(), Target = character(), Brand = character(), Code = character(),
    Name = character(), Hex = character(), DeltaE = numeric()
  ))

  observeEvent(input$add_selected, {
    sel <- input$matches_table_rows_selected
    req(length(sel) > 0)
    m <- matches()[sel]
    new_rows <- data.table(
      Label = m$target_label, Target = m$target_hex, Brand = m$brand, Code = m$code,
      Name = m$name, Hex = m$hex, DeltaE = round(m$deltaE, 2)
    )
    palette(unique(rbindlist(list(palette(), new_rows))))
  })

  output$palette_table <- DT::renderDataTable({
    p <- palette()
    df <- copy(p)
    if (nrow(df) > 0) df$Swatch <- swatch_html(df$Hex)
    setcolorder(df, intersect(c("Swatch", names(p)), names(df)))
    DT::datatable(df, selection = "multiple", rownames = FALSE, escape = FALSE,
                  options = list(pageLength = 20))
  })

  output$palette_preview <- renderUI({
    sel <- input$palette_table_rows_selected
    if (length(sel) == 0) return(large_preview_ui(NULL))
    p <- palette()[tail(sel, 1)]
    large_preview_ui(data.table(Brand = p$Brand, Code = p$Code, Name = p$Name, Hex = p$Hex))
  })

  observeEvent(input$remove_selected, {
    sel <- input$palette_table_rows_selected
    req(length(sel) > 0)
    palette(palette()[-sel])
  })

  observeEvent(input$clear_palette, {
    palette(palette()[0])
  })

  output$palette_count <- renderText({
    sprintf("%d colour(s) in palette", nrow(palette()))
  })

  output$download_palette <- downloadHandler(
    filename = function() paste0("paint_palette_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"),
    content = function(file) fwrite(palette(), file)
  )
})
