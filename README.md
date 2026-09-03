# r-paint-selection

Shiny app: pick a target colour (hex) → rank every shade in the Berger and Asian Paints catalogs by perceptual closeness (CIEDE2000 in Lab space) → build a shortlist palette with cost-free color matches → export as CSV for ordering site-trial pots.

## Run

`shiny::runApp()` from this directory. Enter a hex colour (e.g. `#C8C0B1`), optionally label it (e.g. "Living room wall"), click "Find closest shades". Select rows in the results table and "Add selected to palette"; the Palette tab lets you remove entries and download the final shortlist as CSV.

## Data

`catalog_berger.csv` (780 shades) and `catalog_asian.csv` (2195 shades) were extracted from `2024-08-21 Paint Colour Selection.xlsx`'s "Berger Closest"/"Asian Closest" sheets — those sheets were originally generated as one-off distance rankings against a single historical target color each; this app extracts just the underlying Code/Name/RGB catalog data (ignoring the stale distance column) and computes fresh CIEDE2000 distances against whatever target you enter.

**Fixed: Asian Paints "Code" was showing a meaningless made-up value, not a real reference code.** The source spreadsheet's "Asian Closest" sheet labels its columns "Color Code" / "Color Name" — matching the Berger sheet's structure — but for Asian Paints, the "Color Code" column actually holds a hex string mechanically re-derived from the RGB value (`sprintf("%02X%02X%02X", r, g, b)` reproduces it for all 2195 rows, confirmed), not anything Asian Paints itself publishes, while "Color Name" holds a 4-character alphanumeric value (`0302`, `8657`, `K260`, ...) matching the real numeric shade-code format Asian Paints actually uses on its shade cards. The two were effectively swapped, and Asian Paints has **no genuine descriptive shade name in this dataset at all** — only the code and RGB were ever captured, unlike Berger which has real descriptive names (`SECRET TREASURE`, `GLORY OF SPRING`, ...). Fixed by re-extracting `catalog_asian.csv` directly from the source spreadsheet with `code` = the real shade code and `name` left blank (honest, rather than showing a fabricated name) — the app's "Code" column for an Asian Paints match now shows something you can actually quote at a paint shop, instead of a hex string that means nothing to them. If real descriptive Asian Paints shade names are wanted later, they'd need to come from Asian Paints' own published catalogue matched by code — not recoverable from this source file.
- A related, easy-to-miss consequence: `data.table::fread()` infers an **entirely blank** character column (Asian's now-empty `name`) as `logical`, not `character` — silently breaking `rbindlist()` when combined with Berger's character-type `name` column. Fixed by forcing `colClasses = c(code = "character", name = "character")` on both `fread()` calls.

## Dependencies

`shiny, data.table, farver, DT`. No geospatial/system libraries needed — much lighter Docker build than r-contour-analysis. `farver::compare_colour(method = "CIE2000")` provides the perceptual color-distance calculation (verified locally against known reference cases before shipping).

## Known issues / design notes

- Matching uses CIEDE2000 (perceptual, Lab space), not plain RGB Euclidean distance — deliberately different from the original spreadsheet's convention, since CIEDE2000 more reliably ranks colors the way they actually look to the eye.
- The target-color input is a plain hex text field for v1 (no color-picker widget or image eyedropper) — `colourpicker` would be a natural v2 addition for a nicer UI, and an image-upload eyedropper for sampling a rendering/photo directly.
- Cost/quantity estimation (sqft, coverage, coats, cost) from the original spreadsheet's "Wall Options" sheet is intentionally out of scope for v1 — matching + palette building only.
- Verified end-to-end locally with Playwright (headless Chromium): search → swatch rendering → row selection → add to palette → remove/clear → CSV download, all confirmed working with zero console errors before deployment.

## Deployment

Docker + Railway + Basic Auth, same pattern as r-contour-analysis — see that project's `NEXT-STEPS.md` for the general playbook and gotchas (the `--service` flag requirement on non-interactive `railway` CLI calls, `railway logs` defaulting to the last successful deployment, verifying package installs explicitly, preferring the Posit Package Manager binary mirror over source CRAN).
