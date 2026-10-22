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
  a |> dplyr::add_count(.data$message_id) |> dplyr::filter(.data$n > 1) |>
    dplyr::transmute(anotador = "A", message_id, error = "message_id duplicado"),
  b |> dplyr::add_count(.data$message_id) |> dplyr::filter(.data$n > 1) |>
    dplyr::transmute(anotador = "B", message_id, error = "message_id duplicado")
)
readr::write_csv(errores, file.path(dir_dataset, "errores_etiquetado.csv"))

completas_a <- a |> dplyr::filter(.data$fila_completa, .data$error == "")
comunes <- completas_a |>
  dplyr::select(message_id, polaridad_a = polaridad_manual, sentimiento_a = sentimiento_1) |>
  dplyr::inner_join(
    b |> dplyr::filter(.data$fila_completa, .data$error == "") |>
      dplyr::select(message_id, polaridad_b = polaridad_manual, sentimiento_b = sentimiento_1),
    by = "message_id"
  )

calidad <- tibble::tibble(
  filas_totales = nrow(a),
  completas_anotador_a = nrow(completas_a),
  errores_a = sum(a$error != ""),
  duplicados_a = sum(duplicated(a$message_id)),
  completas_anotador_b = sum(b$fila_completa & b$error == ""),
  errores_b = sum(b$error != ""),
  duplicados_b = sum(duplicated(b$message_id)),
  filas_comunes = nrow(comunes),
  kappa_polaridad = if (nrow(comunes)) calcular_kappa(comunes$polaridad_a, comunes$polaridad_b) else NA_real_,
  kappa_sentimiento = if (nrow(comunes)) calcular_kappa(comunes$sentimiento_a, comunes$sentimiento_b) else NA_real_
)

referencia <- readr::read_csv(file.path(dir_dataset, "referencia_reglas_no_usar_al_etiquetar.csv"), show_col_types = FALSE)
dataset_final <- completas_a |>
  dplyr::select(-fila_completa, -error) |>
  dplyr::left_join(referencia, by = "message_id")

readr::write_csv(calidad, file.path(dir_dataset, "control_calidad.csv"))
readr::write_csv(dataset_final, file.path(dir_dataset, "dataset_sentimientos_umsa.csv"))
message("Etiquetas validas del anotador A: ", nrow(dataset_final), ". Errores encontrados: ", nrow(errores), ".")

