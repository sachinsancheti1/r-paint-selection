FROM rocker/r-ver:4.4.1

# Baseline nginx/proxy deps only — no geospatial system libraries needed
# (this app is pure color-matching, no sf/terra/whitebox).
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev zlib1g-dev \
    nginx apache2-utils gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default

# Posit Package Manager's Linux binary mirror (jammy = Ubuntu 22.04, which
# rocker/r-ver:4.4.1 is based on) installs pre-built binaries instead of
# compiling from source — much faster, and avoids source-compile build-time
# risk. install.packages() doesn't make R exit non-zero just because some
# packages in the list failed, so verify explicitly and fail the build
# loudly (by name) if anything didn't actually land.
RUN Rscript -e "install.packages(c('shiny','data.table','farver','DT'), repos='https://packagemanager.posit.co/cran/__linux__/jammy/latest')"
RUN Rscript -e "pkgs <- c('shiny','data.table','farver','DT'); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly=TRUE)]; if (length(missing) > 0) { cat('FAILED to install R package(s):', paste(missing, collapse=', '), '\n'); quit(status=1) }"

WORKDIR /app
COPY ui.R /app/ui.R
COPY server.R /app/server.R
# Wildcarded rather than one COPY per file - a new catalog_*.csv (a future
# brand) landed in server.R's fread() calls without a matching COPY line
# here once already, which only surfaced as a live 500/crash-on-first-
# search after deploy, not at build time.
COPY catalog_*.csv /app/

RUN mkdir -p /etc/nginx/templates
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV PORT=3838
EXPOSE 3838
CMD ["/start.sh"]
