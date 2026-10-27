source("configuracion.R", encoding = "UTF-8")
source("R/funciones.R", encoding = "UTF-8")
source("R/dataset_manual.R", encoding = "UTF-8")
verificar_paquetes()

dir_dataset <- DIR_DATASET
a <- readr::read_csv(
  file.path(dir_dataset, "etiquetado_anotador_a.csv"),
  col_types = readr::cols(.default = readr::col_character())
) |>
  validar_etiquetas()
b <- readr::read_csv(
  file.path(dir_dataset, "etiquetado_anotador_b.csv"),
  col_types = readr::cols(.default = readr::col_character())
) |>
  validar_etiquetas()

errores <- dplyr::bind_rows(
  a |> dplyr::filter(.data$error != "") |> dplyr::transmute(anotador = "A", message_id, error),
  b |> dplyr::filter(.data$error != "") |> dplyr::transmute(anotador = "B", message_id, error),
  a |>
    dplyr::add_count(.data$message_id) |>
    dplyr::filter(.data$n > 1) |>
    dplyr::transmute(anotador = "A", message_id, error = "message_id duplicado"),
  b |>
    dplyr::add_count(.data$message_id) |>
    dplyr::filter(.data$n > 1) |>
    dplyr::transmute(anotador = "B", message_id, error = "message_id duplicado")
)
readr::write_csv(errores, file.path(dir_dataset, "errores_etiquetado.csv"))

completas_a <- a |> dplyr::filter(.data$fila_completa, .data$error == "")
completas_b <- b |> dplyr::filter(.data$fila_completa, .data$error == "")
variables_acuerdo <- c(
  "tiene_sentimiento", "polaridad_manual", "sentimiento_1", "intensidad",
  "tema", "ironia", "confianza_anotacion"
)

comunes <- completas_a |>
  dplyr::select(message_id, texto, dplyr::all_of(variables_acuerdo), sentimiento_2) |>
  dplyr::inner_join(
    completas_b |>
      dplyr::select(message_id, dplyr::all_of(variables_acuerdo), sentimiento_2),
    by = "message_id",
    suffix = c("_a", "_b")
  )

acuerdo_variables <- dplyr::bind_rows(lapply(variables_acuerdo, function(variable) {
  valor_a <- comunes[[paste0(variable, "_a")]]
  valor_b <- comunes[[paste0(variable, "_b")]]
  tibble::tibble(
    variable = variable,
    n = length(valor_a),
    acuerdo = if (length(valor_a)) mean(valor_a == valor_b) else NA_real_,
    kappa = if (length(valor_a)) calcular_kappa(valor_a, valor_b) else NA_real_
  )
}))
readr::write_csv(acuerdo_variables, file.path(dir_dataset, "acuerdo_por_variable.csv"))

normalizar_conjunto <- function(principal, secundario) {
  mapply(function(x, y) {
    valores <- sort(unique(c(x, y)))
    valores <- valores[!is.na(valores) & valores != ""]
    paste(valores, collapse = ";")
  }, principal, secundario, USE.NAMES = FALSE)
}

conjunto_a <- normalizar_conjunto(comunes$sentimiento_1_a, comunes$sentimiento_2_a)
conjunto_b <- normalizar_conjunto(comunes$sentimiento_1_b, comunes$sentimiento_2_b)
jaccard <- mapply(function(x, y) {
  a_set <- strsplit(x, ";", fixed = TRUE)[[1]]
  b_set <- strsplit(y, ";", fixed = TRUE)[[1]]
  length(intersect(a_set, b_set)) / length(union(a_set, b_set))
}, conjunto_a, conjunto_b)

calidad <- tibble::tibble(
  filas_totales = nrow(a),
  completas_anotador_a = nrow(completas_a),
  errores_a = sum(a$error != ""),
  duplicados_a = sum(duplicated(a$message_id)),
  completas_anotador_b = nrow(completas_b),
  errores_b = sum(b$error != ""),
  duplicados_b = sum(duplicated(b$message_id)),
  filas_comunes = nrow(comunes),
  kappa_polaridad = calcular_kappa(comunes$polaridad_manual_a, comunes$polaridad_manual_b),
  kappa_sentimiento = calcular_kappa(comunes$sentimiento_1_a, comunes$sentimiento_1_b),
  jaccard_sentimientos = mean(jaccard),
  acuerdo_exacto_sentimientos = mean(conjunto_a == conjunto_b)
)

actualizar_plantilla_adjudicacion <- function(nueva, archivo) {
  campos_adjudicacion <- c(
    "polaridad_adjudicada", "sentimiento_1_adjudicado",
    "sentimiento_2_adjudicado", "intensidad_adjudicada",
    "tema_adjudicado", "ironia_adjudicada",
    "observaciones_adjudicacion"
  )
  if (!file.exists(archivo)) {
    readr::write_csv(nueva, archivo, na = "")
    return(invisible(TRUE))
  }

  anterior <- readr::read_csv(
    archivo,
    col_types = readr::cols(.default = readr::col_character())
  )
  if (anyDuplicated(anterior$message_id)) {
    stop("Hay message_id duplicados en ", archivo, ".", call. = FALSE)
  }
  for (campo in setdiff(campos_adjudicacion, names(anterior))) {
    anterior[[campo]] <- ""
  }

  preservados <- anterior |>
    dplyr::select(message_id, dplyr::all_of(campos_adjudicacion))
  actualizada <- nueva |>
    dplyr::select(-dplyr::all_of(campos_adjudicacion)) |>
    dplyr::left_join(preservados, by = "message_id") |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(campos_adjudicacion),
        ~ dplyr::coalesce(as.character(.x), "")
      )
    ) |>
    dplyr::select(dplyr::all_of(names(nueva)))

  obsoletas <- anterior |>
    dplyr::anti_join(nueva |> dplyr::select(message_id), by = "message_id")
  if (nrow(obsoletas) > 0L) {
    archivo_obsoletas <- stringr::str_replace(
      archivo,
      "\\.csv$",
      "_obsoletas.csv"
    )
    readr::write_csv(obsoletas, archivo_obsoletas, na = "")
  }

  temporal <- tempfile(
    pattern = "adjudicacion_",
    tmpdir = dirname(archivo),
    fileext = ".csv"
  )
  readr::write_csv(actualizada, temporal, na = "")
  if (!file.rename(temporal, archivo)) {
    stop("No se pudo actualizar ", archivo, ".", call. = FALSE)
  }
  message(
    basename(archivo), ": ", nrow(actualizada), " filas actuales; ",
    sum(actualizada$polaridad_adjudicada != "" |
      actualizada$sentimiento_1_adjudicado != ""),
    " con adjudicacion preservada; ", nrow(obsoletas), " obsoletas respaldadas."
  )
  invisible(TRUE)
}

# Plantilla privada para resolver solamente decisiones realmente discrepantes.
desacuerdos <- comunes |>
  dplyr::mutate(
    conjunto_a = conjunto_a,
    conjunto_b = conjunto_b,
    difiere_polaridad = .data$polaridad_manual_a != .data$polaridad_manual_b,
    difiere_sentimientos = .data$conjunto_a != .data$conjunto_b,
    difiere_intensidad = .data$intensidad_a != .data$intensidad_b,
    difiere_tema = .data$tema_a != .data$tema_b,
    difiere_ironia = .data$ironia_a != .data$ironia_b
  ) |>
  dplyr::filter(
    .data$difiere_polaridad | .data$difiere_sentimientos |
      .data$difiere_intensidad | .data$difiere_tema | .data$difiere_ironia
  ) |>
  dplyr::transmute(
    message_id,
    texto,
    polaridad_a = polaridad_manual_a,
    polaridad_b = polaridad_manual_b,
    sentimientos_a = conjunto_a,
    sentimientos_b = conjunto_b,
    intensidad_a,
    intensidad_b,
    tema_a,
    tema_b,
    ironia_a,
    ironia_b,
    polaridad_adjudicada = "",
    sentimiento_1_adjudicado = "",
    sentimiento_2_adjudicado = "",
    intensidad_adjudicada = "",
    tema_adjudicado = "",
    ironia_adjudicada = "",
    observaciones_adjudicacion = ""
  )
actualizar_plantilla_adjudicacion(
  desacuerdos,
  file.path(dir_dataset, "desacuerdos_anotacion.csv")
)
desacuerdos_modelado <- desacuerdos |>
  dplyr::filter(
    .data$polaridad_a != .data$polaridad_b |
      .data$sentimientos_a != .data$sentimientos_b
  )
actualizar_plantilla_adjudicacion(
  desacuerdos_modelado,
  file.path(dir_dataset, "desacuerdos_modelado.csv")
)

# El dataset descriptivo existente conserva A para no cambiar silenciosamente sus
# resultados. El dataset de consenso separa acuerdos, desacuerdos y filas solo A.
referencia <- readr::read_csv(
  file.path(dir_dataset, "referencia_reglas_no_usar_al_etiquetar.csv"),
  show_col_types = FALSE
)
dataset_final <- completas_a |>
  dplyr::select(-fila_completa, -error) |>
  dplyr::left_join(referencia, by = "message_id")

etiquetas_b <- completas_b |>
  dplyr::select(
    message_id,
    polaridad_b = polaridad_manual,
    sentimiento_1_b = sentimiento_1,
    sentimiento_2_b = sentimiento_2
  ) |>
  dplyr::mutate(sentimientos_b = normalizar_conjunto(.data$sentimiento_1_b, .data$sentimiento_2_b))

dataset_consenso <- completas_a |>
  dplyr::select(-fila_completa, -error) |>
  dplyr::mutate(sentimientos_a = normalizar_conjunto(.data$sentimiento_1, .data$sentimiento_2)) |>
  dplyr::left_join(etiquetas_b, by = "message_id") |>
  dplyr::mutate(
    doble_anotacion = !is.na(.data$polaridad_b),
    acuerdo_polaridad = .data$doble_anotacion & .data$polaridad_manual == .data$polaridad_b,
    acuerdo_sentimientos = .data$doble_anotacion & .data$sentimientos_a == .data$sentimientos_b,
    estado_consenso = dplyr::case_when(
      .data$acuerdo_polaridad & .data$acuerdo_sentimientos ~ "acuerdo_ab",
      .data$doble_anotacion ~ "desacuerdo_ab",
      TRUE ~ "solo_a"
    ),
    polaridad_consenso = dplyr::if_else(.data$acuerdo_polaridad, .data$polaridad_manual, NA_character_),
    sentimientos_consenso = dplyr::if_else(.data$acuerdo_sentimientos, .data$sentimientos_a, NA_character_)
  ) |>
  dplyr::left_join(referencia, by = "message_id")

readr::write_csv(calidad, file.path(dir_dataset, "control_calidad.csv"))
readr::write_csv(dataset_final, file.path(dir_dataset, "dataset_sentimientos_umsa.csv"))
readr::write_csv(dataset_consenso, file.path(dir_dataset, "dataset_consenso_umsa.csv"))
message("Etiquetas validas A: ", nrow(completas_a), "; B: ", nrow(completas_b), ".")
message("Filas comunes: ", nrow(comunes), "; desacuerdos para revisar: ", nrow(desacuerdos), ".")
