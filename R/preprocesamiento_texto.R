# Funciones didacticas con las librerias vistas en Data Mining.

limpiar_textos_tm <- function(textos) {
  textos <- dplyr::coalesce(as.character(textos), "")
  corpus <- tm::VCorpus(tm::VectorSource(textos))
  quitar_url <- tm::content_transformer(function(x) stringr::str_replace_all(x, "https?://\\S+|www\\.\\S+", " "))
  a_minusculas <- tm::content_transformer(function(x) stringr::str_to_lower(x, locale = "es"))
  stop_es <- setdiff(tm::stopwords("spanish"), c("no", "nunca", "sin", "ni"))

  corpus <- tm::tm_map(corpus, quitar_url)
  corpus <- tm::tm_map(corpus, a_minusculas)
  corpus <- tm::tm_map(corpus, tm::removeNumbers)
  corpus <- tm::tm_map(corpus, tm::removePunctuation, preserve_intra_word_dashes = TRUE)
  corpus <- tm::tm_map(corpus, tm::removeWords, stop_es)
  corpus <- tm::tm_map(corpus, tm::stripWhitespace)
  vapply(corpus, tm::content, character(1), USE.NAMES = FALSE)
}

tokenizar_quanteda <- function(textos, aplicar_stemming = FALSE) {
  tokens <- quanteda::tokens(
    dplyr::coalesce(as.character(textos), ""),
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_numbers = TRUE,
    remove_url = TRUE
  ) |>
    quanteda::tokens_tolower() |>
    quanteda::tokens_remove(quanteda::stopwords("es")) |>
    quanteda::tokens_select(pattern = "*", min_nchar = 2)
  if (aplicar_stemming) tokens <- quanteda::tokens_wordstem(tokens, language = "spanish")
  tokens
}

crear_lexico_syuzhet <- function(diccionario = crear_diccionario()) {
  purrr::map2_dfr(diccionario$terminos, diccionario$polaridad, function(terminos, polaridad) {
    tibble::tibble(word = terminos, value = as.numeric(polaridad))
  }) |>
    dplyr::filter(!stringr::str_detect(.data$word, "\\s"), .data$value != 0) |>
    dplyr::group_by(.data$word) |>
    dplyr::summarise(value = mean(.data$value), .groups = "drop")
}

puntuar_con_syuzhet <- function(textos, lexico = crear_lexico_syuzhet()) {
  syuzhet::get_sentiment(
    dplyr::coalesce(as.character(textos), ""),
    method = "custom",
    lexicon = lexico,
    regex = "[^A-Za-z0-9_]+",
    lowercase = TRUE
  )
}

frecuencias_dfm <- function(dfmat, n = 200L) {
  frecuencias <- sort(Matrix::colSums(dfmat), decreasing = TRUE)
  limite <- min(n, length(frecuencias))
  tibble::tibble(
    token = names(frecuencias)[seq_len(limite)],
    frecuencia = as.integer(frecuencias[seq_len(limite)])
  )
}

extraer_top_por_grupo <- function(dfmat, n = 15L, nombre_valor = "frecuencia") {
  matriz <- as.matrix(dfmat)
  if (nrow(matriz) == 0 || ncol(matriz) == 0) return(tibble::tibble())
  purrr::map_dfr(seq_len(nrow(matriz)), function(i) {
    orden <- order(matriz[i, ], decreasing = TRUE)
    orden <- orden[matriz[i, orden] > 0]
    orden <- utils::head(orden, n)
    resultado <- tibble::tibble(
      grupo = rownames(matriz)[i],
      token = colnames(matriz)[orden],
      valor = as.numeric(matriz[i, orden])
    )
    names(resultado)[3] <- nombre_valor
    resultado
  })
}

