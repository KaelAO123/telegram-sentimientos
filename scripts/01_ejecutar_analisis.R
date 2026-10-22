source("configuracion.R", encoding = "UTF-8")
source("R/funciones.R", encoding = "UTF-8")
verificar_paquetes()

dir.create(DIR_DATOS, recursive = TRUE, showWarnings = FALSE)
dir.create(DIR_GRAFICOS, recursive = TRUE, showWarnings = FALSE)
dir.create(DIR_INFORME, recursive = TRUE, showWarnings = FALSE)
dir.create(DIR_DATASET, recursive = TRUE, showWarnings = FALSE)

message("1/5 Extrayendo mensajes de Telegram...")
archivos_entrada <- ordenar_archivos_chat(CHAT_DIR)
mensajes <- extraer_mensajes(CHAT_DIR, ZONA_HORARIA)
if (!is.null(ANIOS_ANALISIS)) mensajes <- dplyr::filter(mensajes, .data$gestion %in% ANIOS_ANALISIS)
if (nrow(mensajes) == 0) stop("No hay mensajes para las gestiones seleccionadas.")

message("2/5 Clasificando con el diccionario original y el ampliado...")
diccionario_base <- crear_diccionario(ampliado = FALSE)
coincidencias_base <- clasificar_emociones(mensajes, diccionario_base)
mensajes_base <- asignar_polaridad_mensaje(mensajes, coincidencias_base)

diccionario <- crear_diccionario()
coincidencias <- clasificar_emociones(mensajes, diccionario)
mensajes <- asignar_polaridad_mensaje(mensajes, coincidencias) |>
  agregar_diagnostico_cobertura()

message("3/5 Exportando datos y resumenes...")
readr::write_csv(
  mensajes |> dplyr::select(-dplyr::all_of(c("fecha_original", "orden_archivo", "orden_mensaje"))),
  file.path(DIR_DATOS, "mensajes_clasificados.csv")
)
readr::write_csv(coincidencias, file.path(DIR_DATOS, "coincidencias_emociones.csv"))
readr::write_csv(
  diccionario |>
    dplyr::transmute(
      emocion = .data$emocion,
      polaridad = .data$polaridad,
      definicion = .data$definicion,
      tipo_polaridad = dplyr::case_when(.data$polaridad > 0 ~ "positiva", .data$polaridad < 0 ~ "negativa", TRUE ~ "neutra"),
      n_terminos = lengths(.data$terminos),
      n_raices = lengths(.data$raices),
      version = "ampliado_v2"
    ),
  file.path(DIR_DATOS, "diccionario_sentimientos.csv")
)

resumen_emociones <- coincidencias |>
  dplyr::count(.data$emocion, .data$polaridad_valor, sort = TRUE) |>
  dplyr::mutate(porcentaje_mensajes = .data$n / nrow(mensajes))
resumen_polaridad <- mensajes |>
  dplyr::count(.data$polaridad, sort = TRUE) |>
  dplyr::mutate(porcentaje = .data$n / sum(.data$n))
resumen_gestion <- mensajes |>
  dplyr::count(.data$gestion, .data$polaridad) |>
  dplyr::group_by(.data$gestion) |>
  dplyr::mutate(porcentaje = .data$n / sum(.data$n)) |>
  dplyr::ungroup()
resumen_mensual <- mensajes |>
  dplyr::count(.data$mes, .data$polaridad)
comparacion_cobertura <- dplyr::bind_rows(
  mensajes_base |> dplyr::summarise(version = "original_pdf", mensajes = dplyr::n(), clasificados = sum(.data$polaridad != "sin coincidencia")),
  mensajes |> dplyr::summarise(version = "ampliado_v2", mensajes = dplyr::n(), clasificados = sum(.data$polaridad != "sin coincidencia"))
) |>
  dplyr::mutate(sin_coincidencia = .data$mensajes - .data$clasificados, cobertura = .data$clasificados / .data$mensajes)
cobertura_gestion <- mensajes |>
  dplyr::group_by(.data$gestion) |>
  dplyr::summarise(
    mensajes = dplyr::n(),
    clasificados = sum(.data$polaridad != "sin coincidencia"),
    cobertura = .data$clasificados / .data$mensajes,
    .groups = "drop"
  )
resumen_tipo_coincidencia <- coincidencias |>
  dplyr::count(.data$tipo_coincidencia, .data$confianza, sort = TRUE)
resumen_no_clasificados <- mensajes |>
  dplyr::filter(.data$polaridad == "sin coincidencia") |>
  dplyr::count(.data$motivo_no_clasificado, sort = TRUE) |>
  dplyr::mutate(porcentaje = .data$n / sum(.data$n))
terminos_pendientes <- palabras_sin_clasificar(mensajes, n = 100)
pares_emociones <- coincidencias |>
  dplyr::select(message_id, emocion_1 = emocion) |>
  dplyr::inner_join(
    coincidencias |> dplyr::select(message_id, emocion_2 = emocion),
    by = "message_id",
    relationship = "many-to-many"
  ) |>
  dplyr::filter(.data$emocion_1 < .data$emocion_2) |>
  dplyr::count(.data$emocion_1, .data$emocion_2, sort = TRUE)

readr::write_csv(resumen_emociones, file.path(DIR_DATOS, "resumen_emociones.csv"))
readr::write_csv(resumen_polaridad, file.path(DIR_DATOS, "resumen_polaridad.csv"))
readr::write_csv(resumen_gestion, file.path(DIR_DATOS, "resumen_por_gestion.csv"))
readr::write_csv(resumen_mensual, file.path(DIR_DATOS, "resumen_mensual.csv"))
readr::write_csv(comparacion_cobertura, file.path(DIR_DATOS, "comparacion_cobertura.csv"))
readr::write_csv(cobertura_gestion, file.path(DIR_DATOS, "cobertura_por_gestion.csv"))
readr::write_csv(resumen_tipo_coincidencia, file.path(DIR_DATOS, "resumen_tipo_coincidencia.csv"))
readr::write_csv(resumen_no_clasificados, file.path(DIR_DATOS, "resumen_no_clasificados.csv"))
readr::write_csv(terminos_pendientes, file.path(DIR_DATOS, "terminos_sin_clasificar.csv"))
readr::write_csv(pares_emociones, file.path(DIR_DATOS, "coocurrencia_emociones.csv"))

message("4/5 Generando graficos...")
guardar_graficos(mensajes, coincidencias, DIR_GRAFICOS)
registrar_bitacora(file.path(DIR_DATOS, "bitacora_ejecuciones.csv"), mensajes, coincidencias, archivos_entrada, ZONA_HORARIA)

message("5/5 Generando informe HTML...")
rmarkdown::render(
  "informe/Informe_analisis_sentimientos.Rmd",
  output_file = "Informe_analisis_sentimientos.html",
  output_dir = normalizePath(DIR_INFORME),
  params = list(anios = ANIOS_ANALISIS),
  envir = new.env(parent = globalenv()),
  knit_root_dir = normalizePath("."),
  quiet = TRUE
)

message("Analisis terminado: ", nrow(mensajes), " mensajes y ", nrow(coincidencias), " coincidencias.")
