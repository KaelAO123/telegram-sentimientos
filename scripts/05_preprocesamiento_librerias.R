source("configuracion.R", encoding = "UTF-8")
source("R/funciones.R", encoding = "UTF-8")
source("R/preprocesamiento_texto.R", encoding = "UTF-8")
verificar_paquetes()

salida <- "resultados/preprocesamiento"
graficos <- "resultados/graficos_preprocesamiento"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
dir.create(graficos, recursive = TRUE, showWarnings = FALSE)

mensajes <- readr::read_csv(file.path(DIR_DATOS, "mensajes_clasificados.csv"), show_col_types = FALSE)
texto_original <- dplyr::coalesce(mensajes$texto, "")

message("Limpieza del corpus con tm...")
texto_tm <- limpiar_textos_tm(texto_original)

message("Tokenizacion y normalizacion con quanteda...")
texto_normalizado <- normalizar_texto(texto_original)
tokens <- tokenizar_quanteda(texto_normalizado)
tokens_stem <- tokenizar_quanteda(texto_normalizado, aplicar_stemming = TRUE)
dfmat <- quanteda::dfm(tokens)
dfmat_stem <- quanteda::dfm(tokens_stem)

message("Puntuacion con syuzhet y lexico propio en espanol...")
puntaje <- puntuar_con_syuzhet(texto_normalizado)
n_tokens_documento <- quanteda::ntoken(tokens)
n_tipos_documento <- quanteda::ntype(tokens)

set.seed(20261025)
indices <- sample(seq_len(nrow(mensajes)), min(100, nrow(mensajes)))
lista_tokens <- as.list(tokens)
lista_stem <- as.list(tokens_stem)
muestra_etapas <- tibble::tibble(
  message_id = mensajes$message_id[indices],
  original = texto_original[indices],
  limpieza_tm = texto_tm[indices],
  normalizacion = texto_normalizado[indices],
  tokens_quanteda = vapply(lista_tokens[indices], function(x) paste(x, collapse = " | "), character(1)),
  raices_stemming = vapply(lista_stem[indices], function(x) paste(x, collapse = " | "), character(1)),
  puntaje_syuzhet = puntaje[indices]
)

resumen_documentos <- tibble::tibble(
  message_id = mensajes$message_id,
  tokens = n_tokens_documento,
  terminos_unicos = n_tipos_documento,
  puntaje_syuzhet = puntaje,
  polaridad_syuzhet = dplyr::case_when(
    .data$puntaje_syuzhet > 0 ~ "positiva",
    .data$puntaje_syuzhet < 0 ~ "negativa",
    TRUE ~ "sin_puntaje"
  )
)
resumen_matriz <- tibble::tibble(
  documentos = quanteda::ndoc(dfmat),
  terminos = quanteda::nfeat(dfmat),
  celdas_no_cero = Matrix::nnzero(dfmat),
  dispersion = 1 - Matrix::nnzero(dfmat) / (quanteda::ndoc(dfmat) * quanteda::nfeat(dfmat))
)

readr::write_csv(muestra_etapas, file.path(salida, "muestra_tokenizacion_limpieza_normalizacion.csv"))
readr::write_csv(frecuencias_dfm(dfmat), file.path(salida, "frecuencia_tokens_quanteda.csv"))
readr::write_csv(frecuencias_dfm(dfmat_stem), file.path(salida, "frecuencia_raices_stemming.csv"))
readr::write_csv(resumen_documentos, file.path(salida, "resumen_documentos_syuzhet.csv"))
readr::write_csv(resumen_matriz, file.path(salida, "resumen_matriz_documento_termino.csv"))
saveRDS(dfmat, file.path(salida, "matriz_documento_termino_quanteda.rds"))

top <- frecuencias_dfm(dfmat, n = 25) |>
  dplyr::mutate(token = stats::reorder(.data$token, .data$frecuencia))
p1 <- ggplot2::ggplot(top, ggplot2::aes(.data$token, .data$frecuencia)) +
  ggplot2::geom_col(fill = "#2C7FB8") + ggplot2::coord_flip() +
  ggplot2::labs(title = "Tokens mas frecuentes con quanteda", x = NULL, y = "Frecuencia") + tema_umsa()
ggplot2::ggsave(file.path(graficos, "01_tokens_frecuentes.png"), p1, width = 9, height = 7, dpi = 160)

p2 <- ggplot2::ggplot(resumen_documentos, ggplot2::aes(.data$puntaje_syuzhet)) +
  ggplot2::geom_histogram(binwidth = 1, fill = "#7A5195", color = "white") +
  ggplot2::labs(title = "Puntaje de polaridad con syuzhet", subtitle = "Lexico personalizado en espanol", x = "Puntaje", y = "Mensajes") + tema_umsa()
ggplot2::ggsave(file.path(graficos, "02_puntaje_syuzhet.png"), p2, width = 9, height = 5, dpi = 160)

message("Preprocesamiento terminado: ", quanteda::ndoc(dfmat), " documentos y ", quanteda::nfeat(dfmat), " terminos.")

