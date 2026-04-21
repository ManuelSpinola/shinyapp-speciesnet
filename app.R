library(shiny)
library(speciesnet)  # remotes::install_github("boettiger-lab/speciesnet")
library(dplyr)
library(ggplot2)

# SETUP (correr solo una vez en la consola antes de lanzar la app):
# install_speciesnet()

# Cargar modelo UNA vez al iniciar (descarga ~214MB la primera vez)
model <- load_speciesnet()

paises <- c(
  "Sin filtro geográfico" = "",
  "Costa Rica (CRI)"     = "CRI",
  "Panamá (PAN)"         = "PAN",
  "México (MEX)"         = "MEX",
  "Colombia (COL)"       = "COL",
  "Uruguay (URY)"        = "URY",
  "Brasil (BRA)"         = "BRA",
  "Argentina (ARG)"      = "ARG",
  "Estados Unidos (USA)" = "USA"
)

# ── CSS responsivo ────────────────────────────────────────────────────────────
css_responsivo <- HTML("

  /* ── Tipografía y espaciado base ── */
  .titulo-app { margin: 0; font-weight: 600; }
  .subtitulo-app { font-size: 13px; margin: 0; }

  /* ── Sidebar: colapsa abajo en pantallas < 992px (lg) ── */
  @media (max-width: 991.98px) {
    .col-sm-3,
    .well { 
      width: 100% !important; 
      max-width: 100% !important;
    }
    .col-sm-9 { 
      width: 100% !important; 
      max-width: 100% !important;
    }
  }

  /* ── Columnas internas del main panel ── */

  /* Pantallas medianas (tablet ~768-991px):
     preview y tabla se apilan */
  @media (max-width: 991.98px) {
    .col-preview  { width: 100% !important; margin-bottom: 1rem; }
    .col-tabla    { width: 100% !important; }
    .col-grafico  { width: 100% !important; margin-bottom: 1rem; }
    .col-lote     { width: 100% !important; }
  }

  /* Pantallas grandes (>= 992px): layout original de dos columnas */
  @media (min-width: 992px) {
    .col-preview  { width: 41.66% !important; }   /* ~5/12  */
    .col-tabla    { width: 58.33% !important; }   /* ~7/12  */
    .col-grafico  { width: 50% !important; }
    .col-lote     { width: 50% !important; }
  }

  /* ── Gráfico: altura adaptable ── */
  .grafico-wrap .shiny-plot-output {
    height: 220px !important;
  }
  @media (max-width: 767.98px) {
    .grafico-wrap .shiny-plot-output {
      height: 180px !important;
    }
  }

  /* ── Tablas: scroll horizontal en móvil ── */
  .tabla-scroll { overflow-x: auto; -webkit-overflow-scrolling: touch; }

  /* ── Botones: siempre ancho completo en móvil ── */
  @media (max-width: 575.98px) {
    .btn-clasificar,
    .btn-descargar { font-size: 14px; }
  }

  /* ── Preview de imagen ── */
  .img-preview {
    width: 100%;
    border-radius: 8px;
    border: 1px solid #ddd;
    display: block;
  }

  /* ── Pequeño margen entre secciones del sidebar ── */
  .sidebar-section { margin-bottom: 0.25rem; }
")

# ─────────────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  theme = bslib::bs_theme(version = 5, base_font = bslib::font_google("Inter")),

  # Inyectar CSS responsivo
  tags$head(tags$style(css_responsivo)),

  titlePanel(
    div(
      h4("SpeciesNet", class = "titulo-app"),
      p("Identificación de fauna silvestre",
        class = "text-muted subtitulo-app")
    )
  ),

  sidebarLayout(

    # ── Sidebar ──────────────────────────────────────────────────────────────
    sidebarPanel(
      width = 3,

      div(class = "sidebar-section",
        h6("IMAGEN", class = "text-muted fw-semibold"),
        fileInput("imagen", NULL,
                  accept      = c("image/jpeg", "image/png", "image/jpg"),
                  buttonLabel = "Seleccionar...",
                  placeholder = "Sin imagen")
      ),

      hr(),
      div(class = "sidebar-section",
        h6("FILTRO GEOGRÁFICO", class = "text-muted fw-semibold"),
        selectInput("pais", "País", choices = paises, selected = "CRI"),
        checkboxInput("usar_coords", "Especificar coordenadas", value = FALSE),
        conditionalPanel(
          condition = "input.usar_coords == true",
          # En móvil los dos campos van uno debajo del otro;
          # en pantallas >= sm van lado a lado
          fluidRow(
            column(6, numericInput("lat", "Latitud",
                                   value =  9.75, min =  -90, max =  90, step = 0.01)),
            column(6, numericInput("lon", "Longitud",
                                   value = -83.75, min = -180, max = 180, step = 0.01))
          )
        )
      ),

      hr(),
      div(class = "sidebar-section",
        h6("LOTE", class = "text-muted fw-semibold"),
        fileInput("imagenes_lote", "Múltiples imágenes",
                  multiple    = TRUE,
                  accept      = c("image/jpeg", "image/png"),
                  buttonLabel = "Seleccionar...")
      ),

      hr(),
      actionButton("clasificar", "Identificar especie",
                   class = "btn-primary w-100 btn-clasificar",
                   icon  = icon("play")),
      br(), br(),
      downloadButton("descargar_csv", "Descargar resultados (.csv)",
                     class = "btn-outline-secondary w-100 btn-descargar")
    ),

    # ── Main panel ───────────────────────────────────────────────────────────
    mainPanel(
      width = 9,

      # Fila 1: preview + tabla top-5
      # Usamos div con clases propias en lugar de column() fijo
      fluidRow(
        div(class = "col-preview",
          h6("Vista previa"),
          uiOutput("preview_imagen")
        ),
        div(class = "col-tabla",
          h6("Top clasificaciones"),
          div(class = "tabla-scroll", tableOutput("tabla_top")),
          br(),
          uiOutput("meta_deteccion")
        )
      ),

      hr(),

      # Fila 2: gráfico + tabla lote
      fluidRow(
        div(class = "col-grafico grafico-wrap",
          h6("Distribución de confianza"),
          plotOutput("grafico_barras")   # altura manejada por CSS
        ),
        div(class = "col-lote",
          h6("Resultados — lote"),
          div(class = "tabla-scroll", tableOutput("tabla_lote"))
        )
      )
    )
  )
)

# ─────────────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # ── Vista previa ──────────────────────────────────────────────────────────
  output$preview_imagen <- renderUI({
    req(input$imagen)
    ext  <- tools::file_ext(input$imagen$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    tags$img(
      src   = base64enc::dataURI(file = input$imagen$datapath, mime = mime),
      class = "img-preview"
    )
  })

  # ── Predicción imagen única ───────────────────────────────────────────────
  pred <- eventReactive(input$clasificar, {
    req(input$imagen)

    lat  <- if (input$usar_coords) input$lat else NULL
    lon  <- if (input$usar_coords) input$lon else NULL
    pais <- if (nchar(input$pais) > 0) input$pais else NULL

    withProgress(message = "Clasificando imagen...", value = 0.3, {
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

  # ── data frame reactivo ───────────────────────────────────────────────────
  df_pred <- reactive({
    req(pred())
    predictions_to_df(pred())
  })

  # ── Tabla top-5 ───────────────────────────────────────────────────────────
  output$tabla_top <- renderTable({
    df <- df_pred()
    df |>
      arrange(desc(prediction_score)) |>
      slice_head(n = 5) |>
      transmute(
        Especie        = species,
        `Nombre común` = common_name,
        Familia        = family,
        Confianza      = paste0(round(prediction_score * 100, 1), "%")
      )
  }, striped = TRUE, hover = TRUE, bordered = FALSE)

  # ── Metadatos ─────────────────────────────────────────────────────────────
  output$meta_deteccion <- renderUI({
    req(pred())
    p <- pred()$predictions[[1]]

    fuente <- p$prediction_source %||% "—"
    final  <- p$prediction        %||% "—"
    conf   <- tryCatch(round(p$detections[[1]]$conf, 3), error = function(e) "—")

    tagList(
      tags$small(class = "text-muted",
                 tags$b("Predicción final: "),   final,  tags$br(),
                 tags$b("Fuente: "),             fuente, tags$br(),
                 tags$b("Confianza detector: "), conf
      )
    )
  })

  # ── Gráfico de barras ─────────────────────────────────────────────────────
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
      labs(x = NULL, y = "Confianza (%)") +
      theme_minimal(base_size = 12) +
      theme(
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        axis.text.y        = element_text(face = "italic")
      )
  })

  # ── Lote ──────────────────────────────────────────────────────────────────
  pred_lote <- eventReactive(input$clasificar, {
    req(input$imagenes_lote)
    rutas <- input$imagenes_lote$datapath
    pais  <- if (nchar(input$pais) > 0) input$pais else NULL

    withProgress(
      message = paste("Clasificando", nrow(input$imagenes_lote), "imágenes..."), {
        resultado <- predict_species(
          model,
          image_paths = rutas,
          country     = pais
        )
        incProgress(1)
        resultado
      }
    )
  })

  output$tabla_lote <- renderTable({
    req(pred_lote())
    df <- predictions_to_df(pred_lote())
    df |>
      group_by(filepath) |>
      slice_max(prediction_score, n = 1, with_ties = FALSE) |>
      ungroup() |>
      transmute(
        Archivo        = basename(filepath),
        Especie        = species,
        `Nombre común` = common_name,
        Confianza      = paste0(round(prediction_score * 100, 1), "%")
      )
  }, striped = TRUE)

  # ── Descarga CSV ──────────────────────────────────────────────────────────
  output$descargar_csv <- downloadHandler(
    filename = function() paste0("speciesnet_", Sys.Date(), ".csv"),
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
