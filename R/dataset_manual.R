# Construccion y control del dataset manual de sentimientos UMSA.

normalizar_etiqueta <- function(x) {
  x |>
    dplyr::coalesce("") |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_squish() |>
    stringr::str_replace_all("[ /-]+", "_")
}

crear_muestra_estratificada <- function(mensajes, coincidencias, n_por_estrato = 10L, n_refuerzo = 400L) {
  orden_emociones <- crear_diccionario()$emocion
  emocion_principal <- coincidencias |>
    dplyr::mutate(prioridad = match(.data$emocion, orden_emociones)) |>
    dplyr::arrange(.data$message_id, .data$prioridad) |>
    dplyr::group_by(.data$message_id) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup() |>
    dplyr::select(message_id, emocion_regla = emocion)

  universo <- mensajes |>
    dplyr::left_join(emocion_principal, by = "message_id") |>
    dplyr::mutate(
      estrato = dplyr::coalesce(.data$emocion_regla, "sin_evidencia"),
      tipo_muestreo = "estratificado_gestion_emocion"
    )

  set.seed(20261024)
  estratificada <- universo |>
    dplyr::group_by(.data$gestion, .data$estrato) |>
    dplyr::group_modify(~ dplyr::slice_sample(.x, n = min(n_por_estrato, nrow(.x)))) |>
    dplyr::ungroup()

  disponibles <- universo |>
    dplyr::filter(.data$estrato == "sin_evidencia") |>
    dplyr::anti_join(estratificada, by = "message_id")
  por_gestion <- ceiling(n_refuerzo / dplyr::n_distinct(disponibles$gestion))
  refuerzo <- disponibles |>
    dplyr::group_by(.data$gestion) |>
    dplyr::group_modify(~ dplyr::slice_sample(.x, n = min(por_gestion, nrow(.x)))) |>
    dplyr::ungroup() |>
    dplyr::slice_sample(n = min(n_refuerzo, nrow(disponibles))) |>
    dplyr::mutate(tipo_muestreo = "refuerzo_sin_evidencia")

  dplyr::bind_rows(estratificada, refuerzo) |>
    dplyr::distinct(.data$message_id, .keep_all = TRUE) |>
    dplyr::arrange(.data$gestion, .data$message_id)
}

crear_variables_textuales <- function(datos) {
  emoji <- stringi::stri_count_regex(dplyr::coalesce(datos$texto, ""), "[\\p{Emoji_Presentation}\\p{Extended_Pictographic}]")
  datos |>
    dplyr::mutate(
      caracteres = stringr::str_length(dplyr::coalesce(.data$texto, "")),
      palabras = stringr::str_count(dplyr::coalesce(.data$texto_normalizado, ""), "\\S+"),
      signos_pregunta = stringr::str_count(dplyr::coalesce(.data$texto, ""), "[?¿]"),
      signos_exclamacion = stringr::str_count(dplyr::coalesce(.data$texto, ""), "[!¡]"),
      emojis = emoji,
      contiene_url = stringr::str_detect(dplyr::coalesce(.data$texto, ""), "https?://|www\\."),
      dia_semana = c("lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo")[lubridate::wday(.data$fecha_hora, week_start = 1)]
    )
}

crear_referencia_reglas <- function(mensajes, coincidencias) {
  evidencia <- coincidencias |>
    dplyr::group_by(.data$message_id) |>
    dplyr::summarise(
      emociones_regla = paste(sort(unique(.data$emocion)), collapse = ";"),
      evidencias_regla = paste(sort(unique(.data$evidencia)), collapse = ";"),
      tipos_regla = paste(sort(unique(.data$tipo_coincidencia)), collapse = ";"),
      .groups = "drop"
    )
  mensajes |>
    dplyr::select(message_id, polaridad_regla = polaridad, motivo_no_clasificado) |>
    dplyr::left_join(evidencia, by = "message_id")
}

plantilla_etiquetado <- function(muestra) {
  crear_variables_textuales(muestra) |>
    dplyr::transmute(
      message_id = .data$message_id,
      gestion = .data$gestion,
      fecha = as.character(.data$fecha),
      hora = .data$hora,
      participante = .data$participante,
      texto = .data$texto,
      caracteres = .data$caracteres,
      palabras = .data$palabras,
      signos_pregunta = .data$signos_pregunta,
      signos_exclamacion = .data$signos_exclamacion,
      emojis = .data$emojis,
      contiene_url = .data$contiene_url,
      dia_semana = .data$dia_semana,
      tipo_muestreo = .data$tipo_muestreo,
      tiene_sentimiento = "",
      polaridad_manual = "",
      sentimiento_1 = "",
      sentimiento_2 = "",
      intensidad = "",
      tema = "",
      ironia = "",
      confianza_anotacion = "",
      observaciones = ""
    )
}

guardar_si_no_existe <- function(datos, archivo) {
  if (file.exists(archivo)) {
    return(invisible(FALSE))
  }
  readr::write_csv(datos, archivo)
  invisible(TRUE)
}

validar_etiquetas <- function(datos) {
  sentimientos <- c(
    "alegria", "gratitud", "esperanza", "amor", "admiracion", "tranquilidad",
    "sorpresa", "confusion", "preocupacion", "tristeza", "enojo", "decepcion",
    "cansancio", "verguenza", "curiosidad", "sin_sentimiento", "ambiguo", "otro", ""
  )
  polaridades <- c("positiva", "negativa", "neutra", "mixta", "sin_sentimiento", "ambigua", "")
  temas <- c(
    "consulta_academica", "recomendacion_docente", "horarios_aulas", "inscripcion_retiro_adicion",
    "pagos_tramites", "grupos_contactos", "material_academico", "conversacion_social",
    "anuncio_publicidad", "otro", ""
  )

  limpio <- datos |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(c("tiene_sentimiento", "polaridad_manual", "sentimiento_1", "sentimiento_2", "tema", "ironia", "confianza_anotacion")),
        normalizar_etiqueta
      ),
      intensidad = stringr::str_squish(dplyr::coalesce(as.character(.data$intensidad), "")),
      fila_completa = .data$tiene_sentimiento %in% c("si", "no", "dudoso") &
        .data$polaridad_manual != "" & .data$sentimiento_1 != "" & .data$tema != "",
      error = dplyr::case_when(
        !.data$tiene_sentimiento %in% c("si", "no", "dudoso", "") ~ "tiene_sentimiento invalido",
        !.data$polaridad_manual %in% polaridades ~ "polaridad invalida",
        !.data$sentimiento_1 %in% sentimientos ~ "sentimiento_1 invalido",
        !.data$sentimiento_2 %in% sentimientos ~ "sentimiento_2 invalido",
        !.data$tema %in% temas ~ "tema invalido",
        !.data$ironia %in% c("si", "no", "dudoso", "") ~ "ironia invalida",
        !.data$confianza_anotacion %in% c("alta", "media", "baja", "") ~ "confianza invalida",
        !.data$intensidad %in% c("0", "1", "2", "3", "") ~ "intensidad invalida",
        TRUE ~ ""
      )
    )
  limpio
}

calcular_kappa <- function(real_a, real_b) {
  niveles <- union(unique(real_a), unique(real_b))
  tabla <- table(factor(real_a, niveles), factor(real_b, niveles))
  total <- sum(tabla)
  if (total == 0) {
    return(NA_real_)
  }
  acuerdo <- sum(diag(tabla)) / total
  esperado <- sum(rowSums(tabla) * colSums(tabla)) / total^2
  if (esperado == 1) NA_real_ else (acuerdo - esperado) / (1 - esperado)
}
