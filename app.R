library(shiny)
library(speciesnet)  # remotes::install_github("boettiger-lab/speciesnet")
library(dplyr)
library(ggplot2)
library(bslib)

# SETUP (correr solo una vez en la consola antes de lanzar la app):
# install_speciesnet()

# Cargar modelo UNA vez al iniciar (descarga ~214MB la primera vez)
model <- load_speciesnet()

# ── Textos bilingües ──────────────────────────────────────────────────────────
i18n <- list(
  es = list(
    titulo           = "BioObserva",
    subtitulo        = "Identificación de fauna silvestre · ICOMVIS-UNA",
    idioma_btn       = "EN",
    sec_imagen       = "IMAGEN",
    sec_geo          = "FILTRO GEOGRÁFICO",
    sec_pais         = "País",
    sec_coords       = "Especificar coordenadas",
    sec_lat          = "Latitud",
    sec_lon          = "Longitud",
    sec_lote         = "MÚLTIPLES IMÁGENES",
    sec_lote_label   = "Múltiples imágenes",
    btn_clasificar   = "Identificar especie",
    btn_descargar    = "Descargar resultados (.csv)",
    sel_imagen       = "Seleccionar...",
    sin_imagen       = "Sin imagen",
    preview          = "Vista previa",
    top_clf          = "Top clasificaciones",
    col_especie      = "Especie",
    col_comun        = "Nombre común",
    col_familia      = "Familia",
    col_confianza    = "Confianza",
    col_archivo      = "Archivo",
    dist_conf        = "Distribución de confianza",
    res_lote         = "Resultados — lote",
    pred_final       = "Predicción final:",
    fuente           = "Fuente:",
    conf_det         = "Confianza detector:",
    eje_y            = "Confianza (%)",
    clasificando     = "Clasificando imagen...",
    clasificando_n   = "imágenes..."
  ),
  en = list(
    titulo           = "BioObserva",
    subtitulo        = "Wildlife identification · ICOMVIS-UNA",
    idioma_btn       = "ES",
    sec_imagen       = "IMAGE",
    sec_geo          = "GEOGRAPHIC FILTER",
    sec_pais         = "Country",
    sec_coords       = "Specify coordinates",
    sec_lat          = "Latitude",
    sec_lon          = "Longitude",
    sec_lote         = "MULTIPLE IMAGES",
    sec_lote_label   = "Multiple images",
    btn_clasificar   = "Identify species",
    btn_descargar    = "Download results (.csv)",
    sel_imagen       = "Select...",
    sin_imagen       = "No image",
    preview          = "Preview",
    top_clf          = "Top classifications",
    col_especie      = "Species",
    col_comun        = "Common name",
    col_familia      = "Family",
    col_confianza    = "Confidence",
    col_archivo      = "File",
    dist_conf        = "Confidence distribution",
    res_lote         = "Results — batch",
    pred_final       = "Final prediction:",
    fuente           = "Source:",
    conf_det         = "Detector confidence:",
    eje_y            = "Confidence (%)",
    clasificando     = "Classifying image...",
    clasificando_n   = "images..."
  )
)

paises <- list(
  es = c(
    "Sin filtro geográfico" = "",
    "Costa Rica (CRI)"      = "CRI",
    "Panamá (PAN)"          = "PAN",
    "México (MEX)"          = "MEX",
    "Colombia (COL)"        = "COL",
    "Uruguay (URY)"         = "URY",
    "Brasil (BRA)"          = "BRA",
    "Argentina (ARG)"       = "ARG",
    "Estados Unidos (USA)"  = "USA"
  ),
  en = c(
    "No geographic filter"  = "",
    "Costa Rica (CRI)"      = "CRI",
    "Panama (PAN)"          = "PAN",
    "Mexico (MEX)"          = "MEX",
    "Colombia (COL)"        = "COL",
    "Uruguay (URY)"         = "URY",
    "Brazil (BRA)"          = "BRA",
    "Argentina (ARG)"       = "ARG",
    "United States (USA)"   = "USA"
  )
)

# ── CSS ───────────────────────────────────────────────────────────────────────
css <- HTML("
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Source+Sans+3:wght@300;400;600&display=swap');

  :root {
    --rojo-vivo:   #C0392B;
    --rojo-oscuro: #922B21;
    --rojo-suave:  #F9EBEA;
    --verde-logo:  #2D6A2D;
    --gris-texto:  #2C2C2C;
    --gris-muted:  #6C757D;
    --fondo:       #FAFAFA;
    --borde:       #E0E0E0;
  }

  body {
    background: var(--fondo);
    font-family: 'Source Sans 3', sans-serif;
    color: var(--gris-texto);
  }

  /* ── Header ── */
  .bio-header {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 18px 0 14px 0;
    border-bottom: 2px solid var(--rojo-vivo);
    margin-bottom: 20px;
  }
  .bio-header img {
    width: 70px;
    height: 70px;
    object-fit: contain;
  }
  .bio-titulo {
    font-family: 'Playfair Display', serif;
    font-size: 26px;
    font-weight: 700;
    color: var(--verde-logo);
    margin: 0;
    line-height: 1.1;
  }
  .bio-subtitulo {
    font-size: 11px;
    color: var(--gris-muted);
    margin: 3px 0 0 0;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }
  .btn-idioma {
    margin-left: auto;
    background: var(--verde-logo) !important;
    border: none !important;
    color: white !important;
    font-family: 'Source Sans 3', sans-serif !important;
    font-weight: 600 !important;
    font-size: 13px !important;
    padding: 6px 18px !important;
    border-radius: 20px !important;
    transition: background 0.2s;
    flex-shrink: 0;
  }
  .btn-idioma:hover { background: var(--rojo-vivo) !important; }

  /* ── Sidebar ── */
  .well {
    background: white !important;
    border: 1px solid var(--borde) !important;
    border-radius: 10px !important;
    box-shadow: 0 1px 4px rgba(0,0,0,0.05) !important;
    padding: 18px !important;
  }
  .sec-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.1em;
    color: var(--gris-muted);
    margin-bottom: 6px;
    display: block;
  }

  /* ── Botón identificar ── */
  .btn-clasificar {
    background: var(--rojo-vivo) !important;
    border: none !important;
    color: white !important;
    font-family: 'Source Sans 3', sans-serif !important;
    font-weight: 600 !important;
    letter-spacing: 0.02em !important;
    border-radius: 6px !important;
    padding: 10px !important;
    transition: background 0.2s, transform 0.1s;
  }
  .btn-clasificar:hover {
    background: var(--rojo-oscuro) !important;
    transform: translateY(-1px);
  }
  .btn-clasificar:active { transform: translateY(0); }

  /* ── Botón descarga ── */
  #descargar_csv {
    border-color: var(--rojo-vivo) !important;
    color: var(--rojo-vivo) !important;
    font-family: 'Source Sans 3', sans-serif !important;
    font-weight: 600 !important;
    border-radius: 6px !important;
    background: white !important;
    transition: background 0.2s;
  }
  #descargar_csv:hover { background: var(--rojo-suave) !important; }

  /* ── Títulos de sección ── */
  .h6-seccion {
    font-family: 'Source Sans 3', sans-serif;
    font-weight: 600;
    font-size: 13px;
    color: var(--gris-texto);
    border-left: 3px solid var(--rojo-vivo);
    padding-left: 8px;
    margin-bottom: 10px;
  }

  /* ── Tablas ── */
  .tabla-scroll { overflow-x: auto; -webkit-overflow-scrolling: touch; }
  table { font-family: 'Source Sans 3', sans-serif !important; font-size: 13px; }
  thead tr { background: var(--rojo-suave) !important; }
  thead th { color: var(--rojo-oscuro) !important; font-weight: 600 !important; }
  tbody tr:hover { background: #fdf3f2 !important; }

  /* ── Metadatos ── */
  .meta-box {
    background: var(--rojo-suave);
    border-left: 3px solid var(--rojo-vivo);
    border-radius: 0 6px 6px 0;
    padding: 10px 14px;
    font-size: 12px;
    line-height: 1.8;
  }

  /* ── Preview imagen ── */
  .img-preview {
    width: 100%;
    border-radius: 8px;
    border: 1px solid var(--borde);
    display: block;
    box-shadow: 0 2px 8px rgba(0,0,0,0.07);
  }

  /* ── Responsivo ── */
  @media (max-width: 991.98px) {
    .col-sm-3, .well { width: 100% !important; max-width: 100% !important; }
    .col-sm-9        { width: 100% !important; max-width: 100% !important; }
    .col-preview, .col-tabla,
    .col-grafico, .col-lote { width: 100% !important; margin-bottom: 1rem; }
    .bio-titulo { font-size: 20px; }
    .bio-header img { width: 54px; height: 54px; }
  }
  @media (min-width: 992px) {
    .col-preview { width: 41.66% !important; }
    .col-tabla   { width: 58.33% !important; }
    .col-grafico { width: 50% !important; }
    .col-lote    { width: 50% !important; }
  }
  .grafico-wrap .shiny-plot-output { height: 220px !important; }
  @media (max-width: 767.98px) {
    .grafico-wrap .shiny-plot-output { height: 180px !important; }
  }
")

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- fluidPage(
  theme = bs_theme(version = 5),
  tags$head(tags$style(css)),

  # Header institucional con logo
  div(class = "bio-header",
    tags$img(src = "logo_maritza.png", alt = "Noctua — BioObserva"),
    div(
      p(class = "bio-titulo",    textOutput("ui_titulo",    inline = TRUE)),
      p(class = "bio-subtitulo", textOutput("ui_subtitulo", inline = TRUE))
    ),
    actionButton("toggle_idioma", textOutput("ui_btn_idioma", inline = TRUE),
                 class = "btn-idioma")
  ),

  sidebarLayout(

    # ── Sidebar ──────────────────────────────────────────────────────────
    sidebarPanel(
      width = 3,

      span(class = "sec-label", textOutput("ui_sec_imagen", inline = TRUE)),
      fileInput("imagen", NULL,
                accept      = c("image/jpeg", "image/png", "image/jpg"),
                buttonLabel = "Seleccionar...",
                placeholder = "No hay imagen seleccionada"),
      
      hr(),
      span(class = "sec-label", textOutput("ui_sec_geo", inline = TRUE)),
      uiOutput("ui_pais_select"),
      checkboxInput("usar_coords",
                    label = textOutput("ui_sec_coords", inline = TRUE),
                    value = FALSE),
      conditionalPanel(
        condition = "input.usar_coords == true",
        fluidRow(
          column(6, numericInput("lat", textOutput("ui_lat", inline = TRUE),
                                 value =  9.75,  min =  -90, max =  90, step = 0.01)),
          column(6, numericInput("lon", textOutput("ui_lon", inline = TRUE),
                                 value = -83.75, min = -180, max = 180, step = 0.01))
        )
      ),

      hr(),
      span(class = "sec-label", textOutput("ui_sec_lote", inline = TRUE)),
      fileInput("imagenes_lote",
                label       = "Images / Imágenes",
                multiple    = TRUE,
                accept      = c("image/jpeg", "image/png", "image/jpg"),
                buttonLabel = "Seleccionar...",
                placeholder = "No hay imágenes seleccionadas"),
      hr(),
      actionButton("clasificar",
                   label = textOutput("ui_btn_clasificar", inline = TRUE),
                   class = "btn-primary w-100 btn-clasificar",
                   icon  = icon("play")),
      br(), br(),
      downloadButton("descargar_csv",
                     label = textOutput("ui_btn_descargar", inline = TRUE),
                     class = "btn-outline-secondary w-100")
    ),

    # ── Main panel ───────────────────────────────────────────────────────
    mainPanel(
      width = 9,

      fluidRow(
        div(class = "col-preview",
          p(class = "h6-seccion", textOutput("ui_preview",  inline = TRUE)),
          uiOutput("preview_imagen")
        ),
        div(class = "col-tabla",
          p(class = "h6-seccion", textOutput("ui_top_clf",  inline = TRUE)),
          div(class = "tabla-scroll", tableOutput("tabla_top")),
          br(),
          uiOutput("meta_deteccion")
        )
      ),

      hr(),

      fluidRow(
        div(class = "col-grafico grafico-wrap",
          p(class = "h6-seccion", textOutput("ui_dist_conf", inline = TRUE)),
          plotOutput("grafico_barras")
        ),
        div(class = "col-lote",
          p(class = "h6-seccion", textOutput("ui_res_lote",  inline = TRUE)),
          div(class = "tabla-scroll", tableOutput("tabla_lote"))
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # ── Idioma reactivo ────────────────────────────────────────────────────────
  idioma <- reactiveVal("es")
  observeEvent(input$toggle_idioma, {
    idioma(if (idioma() == "es") "en" else "es")
  })
  t <- reactive({ i18n[[idioma()]] })

  # Textos de la UI
  output$ui_titulo         <- renderText({ t()$titulo })
  output$ui_subtitulo      <- renderText({ t()$subtitulo })
  output$ui_btn_idioma     <- renderText({ t()$idioma_btn })
  output$ui_sec_imagen     <- renderText({ t()$sec_imagen })
  output$ui_sec_geo        <- renderText({ t()$sec_geo })
  output$ui_sec_coords     <- renderText({ t()$sec_coords })
  output$ui_lat            <- renderText({ t()$sec_lat })
  output$ui_lon            <- renderText({ t()$sec_lon })
  output$ui_sec_lote       <- renderText({ t()$sec_lote })
  output$ui_sel_imagen     <- renderText({ t()$sel_imagen })
  output$ui_sin_imagen     <- renderText({ t()$sin_imagen })
  output$ui_sel_lote       <- renderText({ t()$sel_imagen })
  output$ui_btn_clasificar <- renderText({ t()$btn_clasificar })
  output$ui_btn_descargar  <- renderText({ t()$btn_descargar })
  output$ui_preview        <- renderText({ t()$preview })
  output$ui_top_clf        <- renderText({ t()$top_clf })
  output$ui_dist_conf      <- renderText({ t()$dist_conf })
  output$ui_res_lote       <- renderText({ t()$res_lote })

  # Select de país reactivo al idioma
  output$ui_pais_select <- renderUI({
    selectInput("pais", t()$sec_pais,
                choices  = paises[[idioma()]],
                selected = "CRI")
  })

  # ── Vista previa ───────────────────────────────────────────────────────────
  output$preview_imagen <- renderUI({
    req(input$imagen)
    ext  <- tools::file_ext(input$imagen$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    tags$img(
      src   = base64enc::dataURI(file = input$imagen$datapath, mime = mime),
      class = "img-preview"
    )
  })

  # ── Predicción imagen única ────────────────────────────────────────────────
  pred <- eventReactive(input$clasificar, {
    req(input$imagen)
    lat  <- if (isTRUE(input$usar_coords)) input$lat else NULL
    lon  <- if (isTRUE(input$usar_coords)) input$lon else NULL
    pais <- if (!is.null(input$pais) && nchar(input$pais) > 0) input$pais else NULL

    withProgress(message = t()$clasificando, value = 0.3, {
      resultado <- predict_species(
        model,
        image_paths = input$imagen$datapath,
        country     = pais,
        latitude    = lat,
        longitude   = lon
      )
      incProgress(0.7)
      resultado
    })
  })

  df_pred <- reactive({
    req(pred())
    predictions_to_df(pred())
  })

  # ── Tabla top-5 ────────────────────────────────────────────────────────────
  output$tabla_top <- renderTable({
    df <- df_pred()
    tx <- t()
    df |>
      arrange(desc(prediction_score)) |>
      slice_head(n = 5) |>
      transmute(
        !!tx$col_especie   := species,
        !!tx$col_comun     := common_name,
        !!tx$col_familia   := family,
        !!tx$col_confianza := paste0(round(prediction_score * 100, 1), "%")
      )
  }, striped = TRUE, hover = TRUE, bordered = FALSE)

  # ── Metadatos ──────────────────────────────────────────────────────────────
  output$meta_deteccion <- renderUI({
    req(pred())
    p  <- pred()$predictions[[1]]
    tx <- t()
    fuente <- p$prediction_source %||% "—"
    final  <- p$prediction        %||% "—"
    conf   <- tryCatch(round(p$detections[[1]]$conf, 3), error = function(e) "—")

    div(class = "meta-box",
      tags$b(tx$pred_final), " ", final,  tags$br(),
      tags$b(tx$fuente),     " ", fuente, tags$br(),
      tags$b(tx$conf_det),   " ", as.character(conf)
    )
  })

  # ── Gráfico de barras ──────────────────────────────────────────────────────
  output$grafico_barras <- renderPlot({
    df <- df_pred()
    df |>
      arrange(desc(prediction_score)) |>
      slice_head(n = 8) |>
      mutate(sp = forcats::fct_reorder(species, prediction_score)) |>
      ggplot(aes(x = sp, y = prediction_score * 100, fill = prediction_score)) +
      geom_col(width = 0.65, show.legend = FALSE) +
      coord_flip() +
      scale_fill_gradient(low = "#B5D4F4", high = "#185FA5") +
      scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, 105)) +
      labs(x = NULL, y = t()$eje_y) +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        axis.text.y        = element_text(face = "italic")
      )
  })

  # ── Lote ───────────────────────────────────────────────────────────────────
  pred_lote <- eventReactive(input$clasificar, {
    req(input$imagenes_lote)
    rutas <- input$imagenes_lote$datapath
    pais  <- if (!is.null(input$pais) && nchar(input$pais) > 0) input$pais else NULL
    n     <- nrow(input$imagenes_lote)

    withProgress(
      message = paste(if (idioma() == "es") "Clasificando" else "Classifying",
                      n, t()$clasificando_n), {
        resultado <- predict_species(model, image_paths = rutas, country = pais)
        incProgress(1)
        resultado
      }
    )
  })

  output$tabla_lote <- renderTable({
    req(pred_lote())
    tx <- t()
    df <- predictions_to_df(pred_lote())
    df |>
      group_by(filepath) |>
      slice_max(prediction_score, n = 1, with_ties = FALSE) |>
      ungroup() |>
      transmute(
        !!tx$col_archivo   := basename(filepath),
        !!tx$col_especie   := species,
        !!tx$col_comun     := common_name,
        !!tx$col_confianza := paste0(round(prediction_score * 100, 1), "%")
      )
  }, striped = TRUE)

  # ── Descarga CSV ───────────────────────────────────────────────────────────
  output$descargar_csv <- downloadHandler(
    filename = function() paste0("bioobserva_", Sys.Date(), ".csv"),
    content  = function(file) {
      dfs <- list()
      if (!is.null(isolate(pred())))
        dfs[["unica"]] <- predictions_to_df(isolate(pred()))
      if (!is.null(isolate(pred_lote())))
        dfs[["lote"]]  <- predictions_to_df(isolate(pred_lote()))
      write.csv(bind_rows(dfs), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
