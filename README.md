# r-paint-selection

Shiny app: pick a target colour (hex) → rank every shade in the Berger and Asian Paints catalogs by perceptual closeness (CIEDE2000 in Lab space) → build a shortlist palette with cost-free color matches → export as CSV for ordering site-trial pots.

## Run

`shiny::runApp()` from this directory. Enter a hex colour (e.g. `#C8C0B1`), optionally label it (e.g. "Living room wall"), click "Find closest shades". Select rows in the results table and "Add selected to palette"; the Palette tab lets you remove entries and download the final shortlist as CSV.

## Data

`catalog_berger.csv` (780 shades) and `catalog_asian.csv` (2192 shades) were extracted from `2024-08-21 Paint Colour Selection.xlsx`'s "Berger Closest"/"Asian Closest" sheets — those sheets were originally generated as one-off distance rankings against a single historical target color each; this app extracts just the underlying Code/Name/RGB catalog data (ignoring the stale distance column) and computes fresh CIEDE2000 distances against whatever target you enter.

## Dependencies

`shiny, data.table, farver, DT`. No geospatial/system libraries needed — much lighter Docker build than r-contour-analysis. `farver::compare_colour(method = "CIE2000")` provides the perceptual color-distance calculation (verified locally against known reference cases before shipping).

## Known issues / design notes

- Matching uses CIEDE2000 (perceptual, Lab space), not plain RGB Euclidean distance — deliberately different from the original spreadsheet's convention, since CIEDE2000 more reliably ranks colors the way they actually look to the eye.
- The target-color input is a plain hex text field for v1 (no color-picker widget or image eyedropper) — `colourpicker` would be a natural v2 addition for a nicer UI, and an image-upload eyedropper for sampling a rendering/photo directly.
- Cost/quantity estimation (sqft, coverage, coats, cost) from the original spreadsheet's "Wall Options" sheet is intentionally out of scope for v1 — matching + palette building only.
- Verified end-to-end locally with Playwright (headless Chromium): search → swatch rendering → row selection → add to palette → remove/clear → CSV download, all confirmed working with zero console errors before deployment.

## Deployment

Docker + Railway + Basic Auth, same pattern as r-contour-analysis — see that project's `NEXT-STEPS.md` for the general playbook and gotchas (the `--service` flag requirement on non-interactive `railway` CLI calls, `railway logs` defaulting to the last successful deployment, verifying package installs explicitly, preferring the Posit Package Manager binary mirror over source CRAN).
