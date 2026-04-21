FROM rocker/shiny:4.4.0

# ── Sistema base ──────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Python 3.12 como default ──────────────────────────────────────────────────
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    python3 -m ensurepip --upgrade && \
    python3 -m pip install --upgrade pip

# ── Instalar SpeciesNet y dependencias Python ─────────────────────────────────
RUN python3 -m pip install --no-cache-dir \
    speciesnet==5.0.3 \
    numpy \
    torch \
    pillow \
    pandas \
    huggingface_hub \
    kagglehub

# ── Paquetes R ────────────────────────────────────────────────────────────────
RUN R -e "install.packages(c( \
    'shiny', \
    'dplyr', \
    'ggplot2', \
    'bslib', \
    'forcats', \
    'base64enc', \
    'reticulate' \
), repos='https://cran.rstudio.com/')"

# ── speciesnet desde GitHub ───────────────────────────────────────────────────
RUN R -e "remotes::install_github('boettiger-lab/speciesnet')"

# ── Configurar reticulate para usar Python 3.12 ───────────────────────────────
ENV RETICULATE_PYTHON=/usr/bin/python3.12

# ── Copiar la app ─────────────────────────────────────────────────────────────
COPY app.R /srv/shiny-server/app.R
COPY www/  /srv/shiny-server/www/

# ── Permisos ──────────────────────────────────────────────────────────────────
RUN chown -R shiny:shiny /srv/shiny-server

# ── Puerto Hugging Face Spaces ────────────────────────────────────────────────
EXPOSE 7860

# ── Shiny en puerto 7860 ──────────────────────────────────────────────────────
RUN echo 'run_app <- function() { \n\
  shiny::runApp("/srv/shiny-server", host="0.0.0.0", port=7860) \n\
}' > /srv/shiny-server/start.R

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', host='0.0.0.0', port=7860)"]
