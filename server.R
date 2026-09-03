# server.R
library(shiny)
library(data.table)
library(farver)
library(DT)

# colClasses forced explicitly: Asian Paints has no genuine descriptive
# shade name (see README), so its "name" column is entirely blank -
# fread infers an all-blank column as logical rather than character,
# which would silently break rbindlist() below when combined with
# Berger's character-type names.
catalog_colclasses <- c(code = "character", name = "character")
catalogs <- list(
  Berger = fread("catalog_berger.csv", colClasses = catalog_colclasses),
  "Asian Paints" = fread("catalog_asian.csv", colClasses = catalog_colclasses)
)

hex_to_rgb <- function(hex) {
  hex <- gsub("^#", "", trimws(hex))
  if (!grepl("^[0-9A-Fa-f]{6}$", hex)) return(NULL)
  as.integer(c(strtoi(substr(hex, 1, 2), 16L), strtoi(substr(hex, 3, 4), 16L), strtoi(substr(hex, 5, 6), 16L)))
}

rgb_to_hex <- function(r, g, b) sprintf("#%02X%02X%02X", r, g, b)

swatch_html <- function(hex) {
  sprintf('<div style="width:28px;height:20px;background:%s;border:1px solid #999;border-radius:3px;"></div>', hex)
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
