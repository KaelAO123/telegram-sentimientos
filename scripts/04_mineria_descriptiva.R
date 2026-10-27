source("R/funciones.R", encoding = "UTF-8")
source("R/preprocesamiento_texto.R", encoding = "UTF-8")
verificar_paquetes()

archivo_adjudicado <- "datos/dataset_manual/dataset_modelado_umsa.csv"
archivo <- if (file.exists(archivo_adjudicado)) {
  archivo_adjudicado
} else {
  "datos/dataset_manual/dataset_sentimientos_umsa.csv"
}
salida <- "resultados/mineria_dataset"
graficos <- "resultados/graficos_dataset"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
dir.create(graficos, recursive = TRUE, showWarnings = FALSE)

datos <- readr::read_csv(archivo, show_col_types = FALSE)
if (all(c("polaridad_objetivo", "sentimientos_objetivo") %in% names(datos))) {
  sentimientos_separados <- stringr::str_split_fixed(
    datos$sentimientos_objetivo,
    stringr::fixed(";"),
    2
  )
  datos <- datos |>
    dplyr::mutate(
      polaridad_manual = .data$polaridad_objetivo,
      sentimiento_1 = sentimientos_separados[, 1],
      sentimiento_2 = sentimientos_separados[, 2]
    )
}
if (nrow(datos) < 50) stop("Etiquete y valide al menos 50 mensajes antes de ejecutar la mineria descriptiva.", call. = FALSE)

# Tokenizacion y matriz documento-termino con quanteda.
texto_normalizado <- normalizar_texto(datos$texto)
tokens <- tokenizar_quanteda(texto_normalizado)
dfmat <- quanteda::dfm(tokens)
dfmat_grupo <- quanteda::dfm_group(dfmat, groups = datos$sentimiento_1)
dfmat_tfidf <- quanteda::dfm_tfidf(dfmat_grupo, scheme_tf = "prop")

# Bigramas con la misma tokenizacion.
tokens_bigramas <- quanteda::tokens_ngrams(tokens, n = 2)
dfmat_bigramas <- quanteda::dfm(tokens_bigramas) |>
  quanteda::dfm_group(groups = datos$sentimiento_1)

distribucion_sentimientos <- datos |> dplyr::count(.data$sentimiento_1, sort = TRUE)
distribucion_polaridad <- datos |> dplyr::count(.data$polaridad_manual, sort = TRUE)
distribucion_temas <- datos |> dplyr::count(.data$tema, sort = TRUE)
terminos_frecuentes <- extraer_top_por_grupo(dfmat_grupo, n = 15, nombre_valor = "frecuencia") |>
  dplyr::rename(sentimiento_1 = grupo, palabra = token)
terminos_tfidf <- extraer_top_por_grupo(dfmat_tfidf, n = 15, nombre_valor = "tf_idf") |>
  dplyr::rename(sentimiento_1 = grupo, palabra = token)
bigramas <- extraer_top_por_grupo(dfmat_bigramas, n = 10, nombre_valor = "frecuencia") |>
  dplyr::rename(sentimiento_1 = grupo, bigrama = token)

# Asociaciones descriptivas sentimiento-tema.
asociaciones <- datos |>
  dplyr::count(.data$sentimiento_1, .data$tema, name = "juntos") |>
  dplyr::mutate(soporte = .data$juntos / nrow(datos)) |>
  dplyr::left_join(datos |> dplyr::count(.data$sentimiento_1, name = "n_sentimiento"), by = "sentimiento_1") |>
  dplyr::left_join(datos |> dplyr::count(.data$tema, name = "n_tema"), by = "tema") |>
  dplyr::mutate(
    confianza = .data$juntos / .data$n_sentimiento,
    lift = .data$soporte / ((.data$n_sentimiento / nrow(datos)) * (.data$n_tema / nrow(datos)))
  ) |>
  dplyr::arrange(dplyr::desc(.data$lift), dplyr::desc(.data$juntos))

# syuzhet se usa con el lexico propio en espanol y se compara con la etiqueta manual.
comparacion_syuzhet <- datos |>
  dplyr::transmute(
    message_id = .data$message_id,
    polaridad_manual = .data$polaridad_manual,
    puntaje_syuzhet = puntuar_con_syuzhet(texto_normalizado),
    polaridad_syuzhet = dplyr::case_when(
      .data$puntaje_syuzhet > 0 ~ "positiva",
      .data$puntaje_syuzhet < 0 ~ "negativa",
      TRUE ~ "sin_puntaje"
    )
  )
tabla_comparacion <- comparacion_syuzhet |>
  dplyr::count(.data$polaridad_manual, .data$polaridad_syuzhet, name = "mensajes")

readr::write_csv(distribucion_sentimientos, file.path(salida, "distribucion_sentimientos.csv"))
readr::write_csv(distribucion_polaridad, file.path(salida, "distribucion_polaridad.csv"))
readr::write_csv(distribucion_temas, file.path(salida, "distribucion_temas.csv"))
readr::write_csv(terminos_frecuentes, file.path(salida, "terminos_por_sentimiento.csv"))
readr::write_csv(terminos_tfidf, file.path(salida, "tfidf_por_sentimiento.csv"))
readr::write_csv(bigramas, file.path(salida, "bigramas_por_sentimiento.csv"))
readr::write_csv(asociaciones, file.path(salida, "asociaciones_sentimiento_tema.csv"))
readr::write_csv(comparacion_syuzhet, file.path(salida, "comparacion_manual_syuzhet.csv"))
readr::write_csv(tabla_comparacion, file.path(salida, "tabla_manual_syuzhet.csv"))
saveRDS(dfmat, file.path(salida, "matriz_documento_termino_manual.rds"))

p <- ggplot2::ggplot(distribucion_sentimientos, ggplot2::aes(stats::reorder(.data$sentimiento_1, .data$n), .data$n)) +
  ggplot2::geom_col(fill = "#2C7FB8") + ggplot2::coord_flip() +
  ggplot2::labs(title = "Distribucion del dataset manual", x = NULL, y = "Mensajes") + tema_umsa()
ggplot2::ggsave(file.path(graficos, "01_distribucion_dataset.png"), p, width = 9, height = 6, dpi = 160)
message(
  "Mineria descriptiva terminada con ", nrow(datos),
  " mensajes etiquetados desde ", archivo, "."
)

