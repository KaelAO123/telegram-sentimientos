source("configuracion.R", encoding = "UTF-8")
source("R/dataset_manual.R", encoding = "UTF-8")

consenso_path <- file.path(DIR_DATASET, "dataset_consenso_umsa.csv")
adjudicacion_path <- file.path(DIR_DATASET, "desacuerdos_modelado.csv")
output_path <- file.path(DIR_DATASET, "dataset_modelado_umsa.csv")
for (path in c(consenso_path, adjudicacion_path)) {
  if (!file.exists(path)) stop("No se encontro: ", path, call. = FALSE)
}

datos <- readr::read_csv(consenso_path, show_col_types = FALSE)
adjudicacion <- readr::read_csv(
  adjudicacion_path,
  col_types = readr::cols(.default = readr::col_character())
)
if (anyDuplicated(adjudicacion$message_id)) {
  stop("Hay message_id duplicados en desacuerdos_modelado.csv.", call. = FALSE)
}
ids_requeridos <- datos |>
  dplyr::filter(
    .data$doble_anotacion &
      (!.data$acuerdo_polaridad | !.data$acuerdo_sentimientos)
  ) |>
  dplyr::pull(.data$message_id)
ids_ausentes <- setdiff(ids_requeridos, adjudicacion$message_id)
if (length(ids_ausentes) > 0L) {
  stop(
    "desacuerdos_modelado.csv esta desactualizado: faltan ",
    length(ids_ausentes),
    " message_id del consenso. Ejecute primero scripts/03_validar_dataset_manual.R.",
    call. = FALSE
  )
}

adjudicacion <- adjudicacion |>
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(c(
        "polaridad_adjudicada", "sentimiento_1_adjudicado",
        "sentimiento_2_adjudicado"
      )),
      normalizar_etiqueta
    )
  )

polaridades <- c("positiva", "negativa", "neutra", "mixta", "sin_sentimiento", "ambigua")
sentimientos <- c(
  "alegria", "gratitud", "esperanza", "amor", "admiracion", "tranquilidad",
  "sorpresa", "confusion", "preocupacion", "tristeza", "enojo", "decepcion",
  "cansancio", "verguenza", "curiosidad", "sin_sentimiento", "ambiguo", "otro"
)
requiere_polaridad <- adjudicacion$polaridad_a != adjudicacion$polaridad_b
requiere_sentimientos <- adjudicacion$sentimientos_a != adjudicacion$sentimientos_b

invalida_polaridad <- requiere_polaridad &
  !adjudicacion$polaridad_adjudicada %in% polaridades
invalido_sentimiento_1 <- requiere_sentimientos &
  !adjudicacion$sentimiento_1_adjudicado %in% sentimientos
invalido_sentimiento_2 <- adjudicacion$sentimiento_2_adjudicado != "" &
  !adjudicacion$sentimiento_2_adjudicado %in% sentimientos
if (any(invalida_polaridad | invalido_sentimiento_1 | invalido_sentimiento_2)) {
  stop(
    "Faltan o son invalidas ",
    sum(invalida_polaridad | invalido_sentimiento_1 | invalido_sentimiento_2),
    " adjudicaciones de modelado: ",
    sum(invalida_polaridad), " de polaridad, ",
    sum(invalido_sentimiento_1), " de sentimiento principal y ",
    sum(invalido_sentimiento_2), " sentimientos secundarios invalidos.",
    call. = FALSE
  )
}

adjudicadas <- adjudicacion |>
  dplyr::transmute(
    message_id,
    polaridad_adjudicada,
    sentimientos_adjudicados = mapply(function(x, y) {
      valores <- sort(unique(c(x, y)))
      valores <- valores[!is.na(valores) & valores != ""]
      paste(valores, collapse = ";")
    }, sentimiento_1_adjudicado, sentimiento_2_adjudicado, USE.NAMES = FALSE)
  )

final <- datos |>
  dplyr::left_join(adjudicadas, by = "message_id") |>
  dplyr::mutate(
    polaridad_objetivo = dplyr::case_when(
      .data$acuerdo_polaridad ~ .data$polaridad_consenso,
      .data$doble_anotacion ~ .data$polaridad_adjudicada,
      TRUE ~ .data$polaridad_manual
    ),
    sentimientos_objetivo = dplyr::case_when(
      .data$acuerdo_sentimientos ~ .data$sentimientos_consenso,
      .data$doble_anotacion ~ .data$sentimientos_adjudicados,
      TRUE ~ .data$sentimientos_a
    ),
    fuente_polaridad = dplyr::case_when(
      .data$acuerdo_polaridad ~ "acuerdo_ab",
      .data$doble_anotacion ~ "adjudicado",
      TRUE ~ "solo_a"
    ),
    fuente_sentimientos = dplyr::case_when(
      .data$acuerdo_sentimientos ~ "acuerdo_ab",
      .data$doble_anotacion ~ "adjudicado",
      TRUE ~ "solo_a"
    ),
    apto_test_alta_confianza = .data$doble_anotacion
  )
if (any(is.na(final$polaridad_objetivo) | final$polaridad_objetivo == "")) {
  stop("Quedaron polaridades objetivo vacias.", call. = FALSE)
}
if (any(is.na(final$sentimientos_objetivo) | final$sentimientos_objetivo == "")) {
  stop("Quedaron sentimientos objetivo vacios.", call. = FALSE)
}

readr::write_csv(final, output_path, na = "")
message("Dataset adjudicado para modelado: ", nrow(final), " filas en ", output_path, ".")
