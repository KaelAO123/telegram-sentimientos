source("configuracion.R", encoding = "UTF-8")
source("R/funciones.R", encoding = "UTF-8")
source("R/dataset_manual.R", encoding = "UTF-8")
verificar_paquetes()

dir_dataset <- DIR_DATASET
dir.create(dir_dataset, recursive = TRUE, showWarnings = FALSE)

mensajes <- readr::read_csv(file.path(DIR_DATOS, "mensajes_clasificados.csv"), show_col_types = FALSE)
mensajes$fecha_hora <- as.POSIXct(mensajes$fecha_hora, tz = ZONA_HORARIA)
coincidencias <- readr::read_csv(file.path(DIR_DATOS, "coincidencias_emociones.csv"), show_col_types = FALSE)

muestra <- crear_muestra_estratificada(mensajes, coincidencias)
plantilla <- plantilla_etiquetado(muestra)
referencia <- crear_referencia_reglas(mensajes, coincidencias) |>
  dplyr::semi_join(muestra, by = "message_id")

corpus <- crear_variables_textuales(mensajes) |>
  dplyr::select(
    message_id, gestion, fecha, hora, participante, texto, texto_normalizado,
    caracteres, palabras, signos_pregunta, signos_exclamacion, emojis,
    contiene_url, dia_semana
  )

readr::write_csv(corpus, file.path(dir_dataset, "corpus_anonimizado.csv"))
readr::write_csv(referencia, file.path(dir_dataset, "referencia_reglas_no_usar_al_etiquetar.csv"))
guardar_si_no_existe(plantilla, file.path(dir_dataset, "etiquetado_anotador_a.csv"))
guardar_si_no_existe(plantilla, file.path(dir_dataset, "etiquetado_anotador_b.csv"))

distribucion <- muestra |>
  dplyr::count(.data$gestion, .data$estrato, .data$tipo_muestreo, sort = TRUE)
readr::write_csv(distribucion, file.path(dir_dataset, "diseno_muestra.csv"))
message("Dataset preparado: ", nrow(plantilla), " mensajes para etiquetar y ", nrow(corpus), " en el corpus completo.")

