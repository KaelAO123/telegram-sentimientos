# Funciones para el analisis de sentimientos del chat de temporada UMSA.

paquetes_requeridos <- c(
  "rvest", "xml2", "dplyr", "tidyr", "stringr", "stringi", "purrr",
  "lubridate", "ggplot2", "readr", "scales", "rmarkdown", "knitr",
  "tm", "quanteda", "syuzhet", "SnowballC"
)

verificar_paquetes <- function(paquetes = paquetes_requeridos) {
  faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltantes) > 0) {
    stop(
      "Faltan paquetes de R: ", paste(faltantes, collapse = ", "),
      ". Ejecute: Rscript scripts/00_instalar_paquetes.R",
      call. = FALSE
    )
  }
}

codificar_senales_graficas <- function(x) {
  # Se traducen antes de retirar puntuacion. Se usan codigos propios para que
  # el diccionario pueda distinguir estas señales de palabras escritas.
  grupos <- c(
    "[😂🤣😆😄😁😀😃😹🥳🎉]" = " emojialegria ",
    "[😊🙂😇]" = " emojibienestar ",
    "[🙏]" = " emojigratitud ",
    "[❤♥💕💖💗💓💞😍🥰😘]" = " emojiamor ",
    "[🔥👏🏆🌟]" = " emojiadmiracion ",
    "[👍👌]" = " emojiaprobacion ",
    "[💪🍀🤞]" = " emojiesperanza ",
    "[😌]" = " emojitranquilidad ",
    "[😮😲🤯😱]" = " emojisorpresa ",
    "[🤔😕😵]" = " emojiconfusion ",
    "[😟😰😨😬🥺🚨⚠]" = " emojipreocupacion ",
    "[😢😭😔☹🙁💔😞🥲🥹]" = " emojitristeza ",
    "[😡😠🤬😤]" = " emojienojo ",
    "[😒🙄]" = " emojidecepcion ",
    "[😴🥱😫😩🫠]" = " emojicansancio ",
    "[😳🫣]" = " emojiverguenza ",
    "[👀🧐]" = " emojicuriosidad "
  )
  for (patron in names(grupos)) {
    x <- stringr::str_replace_all(x, stringr::regex(patron), unname(grupos[[patron]]))
  }
  x |>
    stringr::str_replace_all("(?i)(?<![[:alnum:]])(?:x+d{2,}|x{2,}d+)(?![[:alnum:]])", " emoticonalegria ") |>
    stringr::str_replace_all("(?<![[:alnum:]])[:;=]-?[)D]+", " emoticonalegria ") |>
    stringr::str_replace_all("(?<![[:alnum:]])[:=]-?[(]+", " emoticontristeza ")
}

normalizar_texto <- function(x) {
  x |>
    dplyr::coalesce("") |>
    codificar_senales_graficas() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower(locale = "es") |>
    stringr::str_replace_all("https?://\\S+|www\\.\\S+", " ") |>
    stringr::str_replace_all("[^a-z0-9[:space:]]", " ") |>
    stringr::str_squish()
}

crear_diccionario_base <- function() {
  # Polaridad del documento: 1 positivo, 0 neutro, -1 negativo.
  # "f" se trata como palabra exacta y no como raiz para evitar falsos positivos.
  tibble::tribble(
    ~emocion, ~polaridad, ~definicion, ~terminos, ~raices,
    "alegria", 1L, "Sentimiento grato y vivo que suele manifestarse con signos exteriores.",
    c("alegre", "alegria", "feliz", "felices", "felicidad", "contento", "contenta", "jaja", "jeje", "xd", "genial", "buenisimo", "buenisima", "bacan", "chevere", "divertido", "divertida", "festejar", "celebrar"), c("aleg"),
    "gratitud", 1L, "Sentimiento que obliga a estimar el beneficio recibido.",
    c("gracias", "grax", "agradezco", "agradecido", "agradecida", "mil gracias", "muchas gracias", "bendiciones", "dios le pague"), c("agradec"),
    "esperanza", 1L, "Estado de animo en el que se presenta como posible lo que se desea.",
    c("ojala", "espero", "esperemos", "esperanza", "confio", "confiamos", "suerte", "exito", "exitos", "animo", "animos", "lograremos", "podemos lograrlo", "vamos a poder"), c("esperanz"),
    "amor", 1L, "Sentimiento intenso que busca el encuentro y union con otro ser.",
    c("amor", "amo", "te amo", "te quiero", "carino", "corazon", "hermoso", "hermosa", "bonito", "bonita", "lindo", "linda", "abrazo", "abrazos"), character(),
    "admiracion", 1L, "Aprecio hacia alguien por sus cualidades o meritos.",
    c("admiro", "admiracion", "excelente", "crack", "capo", "genio", "increible", "bravo", "felicitaciones", "felicidades", "respeto", "recomendado", "recomendada", "recomiendo", "recomendable"), c("admir", "felicit"),
    "tranquilidad", 1L, "Cualidad de quien esta sosegado y en paz.",
    c("tranquilo", "tranquila", "tranquilidad", "calma", "calmado", "relajado", "paz", "descuida", "tranqui", "sin problema", "no hay problema", "aliviado", "alivio", "menos mal", "relax"), c("tranqui", "relaj"),
    "sorpresa", 0L, "Sentimiento producido por algo imprevisto, raro o incomprensible.",
    c("wow", "guau", "sorpresa", "sorprendido", "sorprendida", "imposible", "uf", "ufff", "dios mio", "no puede ser", "no lo puedo creer", "de repente", "inesperado", "insolito", "raro", "rara"), c("sorpren", "inesper"),
    "confusion", -1L, "Falta de claridad, desorden o perplejidad.",
    c("confundido", "confundida", "confusion", "confuso", "confusa", "no entiendo", "no entendi", "nose", "ni idea", "duda", "dudas", "dudo", "perdido", "perdida", "me perdi", "como asi"), c("confu"),
    "preocupacion", -1L, "Intranquilidad o inquietud por algo.",
    c("preocupado", "preocupada", "preocupacion", "inquieto", "nervioso", "nerviosa", "nervios", "ansiedad", "ansioso", "ansiosa", "miedo", "temo", "urgente", "apurate", "apurense", "riesgo", "peligro", "angustia"), c("preocup", "nervi", "angust"),
    "tristeza", -1L, "Afliccion o pesadumbre.",
    c("triste", "tristeza", "lamento", "lamentable", "que pena", "penita", "lastima", "llorar", "lloro", "duele", "sufrir", "sufro", "deprimido", "deprimida", "desanimado", "descontento"), c("trist", "llor", "lament", "deprim"),
    "enojo", -1L, "Movimiento del animo que suscita ira contra alguien.",
    c("enojado", "enojada", "enojo", "molesto", "molesta", "bronca", "rabia", "furioso", "furiosa", "harto", "harta", "ira", "fastidio", "odio", "pesimo", "pesima", "horrible", "asco", "maldito", "maldita", "mierda", "carajo", "chucha", "puta", "pucha", "joder", "estupido", "idiota", "inutil", "basura", "mal", "malo", "mala", "peor", "reclamo", "queja", "injusto", "abuso", "envidia"), c("enoj", "moles", "pesim", "reclam", "injust"),
    "decepcion", -1L, "Pesar causado por un desengano.",
    c("decepcion", "decepcionado", "decepcionada", "decepciono", "desilusion", "desilusionado", "fraude", "engano", "mentira", "mintieron", "falso", "falsa", "no sirve", "para nada", "fracaso", "fracase", "reprobe", "reprobado", "reprobaron", "aplazado", "jale", "jalaron", "f"), c("decep", "desilus"),
    "cansancio", -1L, "Falta de fuerzas que resulta de haberse fatigado.",
    c("cansado", "cansada", "cansancio", "agotado", "agotada", "agotador", "fatiga", "estres", "estresado", "estresada", "estresante", "pesado", "pesada", "tedioso", "aburrido", "aburrida", "aburre", "aburrimiento", "flojera"), c("cansa", "agota", "estres", "aburr"),
    "verguenza", -1L, "Turbacion ocasionada por una falta o una accion humillante.",
    c("verguenza", "pena ajena", "avergonzado", "avergonzada", "oso", "ridiculo", "ridicula", "papelon", "humillante", "humillacion", "bochorno", "penoso", "que oso", "mi culpa", "cague"), c("averg", "bochorn", "humill"),
    "curiosidad", 0L, "Deseo de saber o averiguar alguna cosa.",
    c("curioso", "curiosa", "curiosidad", "interesante", "me interesa", "quisiera saber", "quiero saber", "me gustaria saber", "cuentame mas"), c("curios")
  )
}

crear_diccionario <- function(ampliado = TRUE) {
  diccionario <- crear_diccionario_base()
  if (!ampliado) return(diccionario)

  extras <- list(
    alegria = list(
      terminos = c("emojialegria", "emoticonalegria", "emojibienestar", "jsjs", "jiji", "uwu"),
      raices = c("jaj", "jej", "jij")
    ),
    gratitud = list(
      terminos = c("emojigratitud", "thx", "grx", "grasias", "se agradece"),
      raices = character()
    ),
    esperanza = list(
      terminos = c("emojiesperanza", "si se puede", "todo saldra bien"),
      raices = character()
    ),
    amor = list(
      terminos = c("emojiamor", "tqm", "los quiero", "las quiero"),
      raices = character()
    ),
    admiracion = list(
      terminos = c("emojiadmiracion", "emojiaprobacion", "ensena bien", "buen docente", "buena docente", "buen lic", "buena lic", "muy recomendado", "muy recomendada"),
      raices = c("recomend")
    ),
    tranquilidad = list(
      terminos = c("emojitranquilidad", "todo bien", "esta bien", "no pasa nada"),
      raices = character()
    ),
    sorpresa = list(
      terminos = c("emojisorpresa", "ala", "asu", "what"),
      raices = character()
    ),
    confusion = list(
      terminos = c("emojiconfusion", "no se", "no comprendo", "no me queda claro", "que significa", "como funciona"),
      raices = character()
    ),
    preocupacion = list(
      terminos = c("emojipreocupacion", "auxilio", "necesito ayuda", "no puedo", "me preocupa", "tengo miedo"),
      raices = character()
    ),
    tristeza = list(
      terminos = c("emojitristeza", "emoticontristeza", "que triste", "estoy mal"),
      raices = character()
    ),
    enojo = list(
      terminos = c("emojienojo", "que rabia", "que bronca", "estafa"),
      raices = character()
    ),
    decepcion = list(
      terminos = c("emojidecepcion", "sin cupo", "no hay cupo", "no habilitaron", "cancelaron", "me rechazaron"),
      raices = character()
    ),
    cansancio = list(
      terminos = c("emojicansancio", "mucho trabajo", "no dormi", "ya no puedo mas"),
      raices = character()
    ),
    verguenza = list(
      terminos = c("emojiverguenza"),
      raices = character()
    ),
    curiosidad = list(
      terminos = c("emojicuriosidad", "alguien sabe", "alguno sabe", "alguna sabe", "saben si", "sabe algo", "una consulta", "tengo una consulta", "quisiera consultar", "alguna informacion"),
      raices = character()
    )
  )

  for (nombre in names(extras)) {
    i <- match(nombre, diccionario$emocion)
    diccionario$terminos[[i]] <- unique(c(diccionario$terminos[[i]], extras[[nombre]]$terminos))
    diccionario$raices[[i]] <- unique(c(diccionario$raices[[i]], extras[[nombre]]$raices))
  }
  diccionario
}

ordenar_archivos_chat <- function(chat_dir) {
  archivos <- list.files(chat_dir, pattern = "^messages([0-9]+)?\\.html$", full.names = TRUE)
  if (length(archivos) == 0) stop("No se encontraron archivos messages*.html en ", chat_dir)
  numero <- stringr::str_match(basename(archivos), "^messages([0-9]*)\\.html$")[, 2]
  numero[numero == ""] <- "1"
  archivos[order(as.integer(numero))]
}

texto_nodo <- function(nodos, xpath) {
  purrr::map_chr(nodos, function(nodo) {
    encontrado <- rvest::html_element(nodo, xpath = xpath)
    if (inherits(encontrado, "xml_missing")) NA_character_ else rvest::html_text2(encontrado)
  })
}

atributo_nodo <- function(nodos, xpath, atributo) {
  purrr::map_chr(nodos, function(nodo) {
    encontrado <- rvest::html_element(nodo, xpath = xpath)
    if (inherits(encontrado, "xml_missing")) NA_character_ else rvest::html_attr(encontrado, atributo)
  })
}

extraer_mensajes <- function(chat_dir, zona_horaria = "America/La_Paz") {
  archivos <- ordenar_archivos_chat(chat_dir)
  xpath_body <- "./div[contains(concat(' ',normalize-space(@class),' '),' body ')]"

  datos <- purrr::map2_dfr(archivos, seq_along(archivos), function(archivo, orden_archivo) {
    doc <- rvest::read_html(archivo, encoding = "UTF-8")
    nodos <- rvest::html_elements(doc, ".message.default")
    tibble::tibble(
      orden_archivo = orden_archivo,
      orden_mensaje = seq_along(nodos),
      message_id = rvest::html_attr(nodos, "id"),
      fecha_original = atributo_nodo(nodos, paste0(xpath_body, "/div[contains(concat(' ',normalize-space(@class),' '),' date ')]"), "title"),
      autor = texto_nodo(nodos, paste0(xpath_body, "/div[contains(concat(' ',normalize-space(@class),' '),' from_name ')]")),
      texto = texto_nodo(nodos, paste0(xpath_body, "/div[contains(concat(' ',normalize-space(@class),' '),' text ')]"))
    )
  }) |>
    dplyr::arrange(.data$orden_archivo, .data$orden_mensaje) |>
    tidyr::fill(autor) |>
    dplyr::mutate(
      autor = dplyr::coalesce(.data$autor, "Autor desconocido"),
      fecha_texto = stringr::str_remove(.data$fecha_original, " UTC[+-].*$"),
      fecha_hora = as.POSIXct(.data$fecha_texto, format = "%d.%m.%Y %H:%M:%S", tz = zona_horaria),
      texto = stringr::str_squish(.data$texto)
    ) |>
    dplyr::filter(!is.na(.data$texto), .data$texto != "", !is.na(.data$fecha_hora))

  autores <- unique(datos$autor)
  datos |>
    dplyr::mutate(
      participante = sprintf("P%03d", match(.data$autor, autores)),
      texto_normalizado = normalizar_texto(.data$texto),
      fecha = as.Date(.data$fecha_hora, tz = zona_horaria),
      gestion = lubridate::year(.data$fecha_hora),
      mes = as.Date(lubridate::floor_date(.data$fecha_hora, unit = "month")),
      hora = lubridate::hour(.data$fecha_hora)
    ) |>
    dplyr::select(-dplyr::all_of(c("autor", "fecha_texto")))
}

patron_terminos <- function(terminos) {
  if (length(terminos) == 0) {
    return(NULL)
  }
  paste0("(?<![a-z0-9])(?:", paste(terminos, collapse = "|"), ")(?![a-z0-9])")
}

patron_raices <- function(raices) {
  if (length(raices) == 0) {
    return(NULL)
  }
  paste0("(?<![a-z0-9])(?:", paste(raices, collapse = "|"), "[a-z]*)(?![a-z0-9])")
}

clasificar_emociones <- function(mensajes, diccionario = crear_diccionario()) {
  purrr::pmap_dfr(diccionario, function(emocion, polaridad, definicion, terminos, raices) {
    p_terminos <- patron_terminos(terminos)
    p_raices <- patron_raices(raices)
    evidencia_termino <- if (is.null(p_terminos)) {
      rep(NA_character_, nrow(mensajes))
    } else {
      stringr::str_extract(mensajes$texto_normalizado, stringr::regex(p_terminos))
    }
    evidencia_raiz <- if (is.null(p_raices)) {
      rep(NA_character_, nrow(mensajes))
    } else {
      stringr::str_extract(mensajes$texto_normalizado, stringr::regex(p_raices))
    }
    evidencia <- dplyr::coalesce(evidencia_termino, evidencia_raiz)
    encontrados <- which(!is.na(evidencia))
    tipo <- dplyr::case_when(
      stringr::str_starts(evidencia, "emoji") ~ "emoji",
      stringr::str_starts(evidencia, "emoticon") ~ "emoticon",
      !is.na(evidencia_termino) ~ "termino_exacto",
      !is.na(evidencia_raiz) ~ "raiz",
      TRUE ~ NA_character_
    )
    tibble::tibble(
      message_id = mensajes$message_id[encontrados],
      emocion = emocion,
      polaridad_valor = polaridad,
      evidencia = evidencia[encontrados],
      tipo_coincidencia = tipo[encontrados],
      confianza = dplyr::if_else(tipo[encontrados] == "termino_exacto", "alta", "media")
    )
  }) |>
    dplyr::distinct(.data$message_id, .data$emocion, .keep_all = TRUE)
}

palabras_sin_clasificar <- function(mensajes, n = 100L) {
  textos <- mensajes |>
    dplyr::filter(.data$polaridad == "sin coincidencia") |>
    dplyr::pull(.data$texto_normalizado) |>
    dplyr::coalesce("")
  tokens <- quanteda::tokens(
    textos,
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_numbers = TRUE,
    remove_url = TRUE
  ) |>
    quanteda::tokens_remove(quanteda::stopwords("es")) |>
    quanteda::tokens_select(pattern = "emoji*", selection = "remove", valuetype = "glob") |>
    quanteda::tokens_select(pattern = "*", min_nchar = 3)
  frecuencias <- sort(Matrix::colSums(quanteda::dfm(tokens)), decreasing = TRUE)
  tibble::tibble(
    palabra = names(frecuencias)[seq_len(min(n, length(frecuencias)))],
    n = as.integer(frecuencias[seq_len(min(n, length(frecuencias)))])
  )
}


asignar_polaridad_mensaje <- function(mensajes, coincidencias) {
  por_mensaje <- coincidencias |>
    dplyr::group_by(.data$message_id) |>
    dplyr::summarise(
      n_emociones = dplyr::n_distinct(.data$emocion),
      tiene_positiva = any(.data$polaridad_valor > 0),
      tiene_negativa = any(.data$polaridad_valor < 0),
      tiene_neutra = any(.data$polaridad_valor == 0),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      polaridad = dplyr::case_when(
        .data$tiene_positiva & .data$tiene_negativa ~ "mixta",
        .data$tiene_positiva ~ "positiva",
        .data$tiene_negativa ~ "negativa",
        .data$tiene_neutra ~ "neutra",
        TRUE ~ "sin coincidencia"
      )
    )

  mensajes |>
    dplyr::left_join(por_mensaje, by = "message_id") |>
    dplyr::mutate(
      n_emociones = dplyr::coalesce(.data$n_emociones, 0L),
      polaridad = dplyr::coalesce(.data$polaridad, "sin coincidencia")
    ) |>
    dplyr::select(-dplyr::any_of(c("tiene_positiva", "tiene_negativa", "tiene_neutra")))
}

agregar_diagnostico_cobertura <- function(mensajes) {
  palabras <- stringr::str_count(dplyr::coalesce(mensajes$texto_normalizado, ""), "\\S+")
  administrativo <- stringr::str_detect(
    dplyr::coalesce(mensajes$texto_normalizado, ""),
    "(?<![a-z])(?:materia|materias|grupo|paralelo|horario|clases|inscripcion|retiro|adicion|pago|kardex|docente|semestre|carrera|aula|link)(?![a-z])"
  )
  mensajes |>
    dplyr::mutate(
      palabras = palabras,
      motivo_no_clasificado = dplyr::case_when(
        .data$polaridad != "sin coincidencia" ~ "clasificado",
        stringr::str_detect(.data$texto, "https?://|www\\.") & .data$palabras == 0 ~ "solo enlace",
        .data$palabras == 0 ~ "sin texto analizable",
        .data$palabras <= 2 ~ "contexto insuficiente",
        stringr::str_detect(.data$texto, "[?¿]") ~ "pregunta no cubierta",
        administrativo ~ "contenido academico informativo",
        TRUE ~ "sin señal conocida"
      )
    )
}

tema_umsa <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}

guardar_graficos <- function(mensajes, coincidencias, dir_graficos) {
  dir.create(dir_graficos, recursive = TRUE, showWarnings = FALSE)
  paleta <- c(positiva = "#238B45", negativa = "#CB181D", neutra = "#636363", mixta = "#756BB1", `sin coincidencia` = "#BDBDBD")

  emociones <- coincidencias |>
    dplyr::count(.data$emocion, .data$polaridad_valor, sort = TRUE) |>
    dplyr::mutate(emocion = stats::reorder(.data$emocion, .data$n))
  p1 <- ggplot2::ggplot(emociones, ggplot2::aes(.data$emocion, .data$n, fill = factor(.data$polaridad_valor))) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(values = c(`-1` = "#CB181D", `0` = "#636363", `1` = "#238B45")) +
    ggplot2::labs(title = "Emociones detectadas", x = NULL, y = "Mensajes con coincidencia") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "01_emociones.png"), p1, width = 9, height = 6, dpi = 160)

  polaridades <- mensajes |>
    dplyr::count(.data$polaridad) |>
    dplyr::mutate(porcentaje = .data$n / sum(.data$n))
  p2 <- ggplot2::ggplot(polaridades, ggplot2::aes(stats::reorder(.data$polaridad, -.data$n), .data$n, fill = .data$polaridad)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(label = scales::percent(.data$porcentaje, accuracy = 0.1)), vjust = -0.3) +
    ggplot2::scale_fill_manual(values = paleta) +
    ggplot2::labs(title = "Polaridad de los mensajes", x = NULL, y = "Cantidad de mensajes") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "02_polaridad.png"), p2, width = 8, height = 5, dpi = 160)

  mensual <- mensajes |>
    dplyr::filter(.data$polaridad != "sin coincidencia") |>
    dplyr::count(.data$mes, .data$polaridad) |>
    dplyr::mutate(gestion = lubridate::year(.data$mes))
  mensual_lineas <- mensual |>
    dplyr::group_by(.data$gestion, .data$polaridad) |>
    dplyr::filter(dplyr::n() > 1) |>
    dplyr::ungroup()
  p3 <- ggplot2::ggplot(mensual, ggplot2::aes(.data$mes, .data$n, color = .data$polaridad)) +
    ggplot2::geom_line(data = mensual_lineas, linewidth = 0.7) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::facet_wrap(~gestion, scales = "free_x") +
    ggplot2::scale_color_manual(values = paleta) +
    ggplot2::labs(title = "Evolucion mensual de mensajes clasificados", x = "Mes", y = "Mensajes", color = "Polaridad") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "03_evolucion_mensual.png"), p3, width = 10, height = 6, dpi = 160)

  cobertura <- mensajes |>
    dplyr::group_by(.data$gestion) |>
    dplyr::summarise(
      mensajes = dplyr::n(),
      clasificados = sum(.data$polaridad != "sin coincidencia"),
      cobertura = .data$clasificados / .data$mensajes,
      .groups = "drop"
    )
  p4 <- ggplot2::ggplot(cobertura, ggplot2::aes(factor(.data$gestion), .data$cobertura)) +
    ggplot2::geom_col(fill = "#2C7FB8") +
    ggplot2::geom_text(ggplot2::aes(label = scales::percent(.data$cobertura, accuracy = 0.1)), vjust = -0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent, limits = c(0, max(cobertura$cobertura) * 1.18)) +
    ggplot2::labs(title = "Cobertura del diccionario por gestion", x = "Gestion", y = "Mensajes clasificados") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "04_cobertura_gestion.png"), p4, width = 8, height = 5, dpi = 160)

  indice_mensual <- mensajes |>
    dplyr::filter(.data$polaridad %in% c("positiva", "negativa")) |>
    dplyr::count(.data$mes, .data$polaridad) |>
    tidyr::pivot_wider(names_from = "polaridad", values_from = "n", values_fill = 0) |>
    dplyr::mutate(
      indice = (.data$positiva - .data$negativa) / (.data$positiva + .data$negativa),
      gestion = lubridate::year(.data$mes)
    )
  indice_lineas <- indice_mensual |>
    dplyr::group_by(.data$gestion) |>
    dplyr::filter(dplyr::n() > 1) |>
    dplyr::ungroup()
  p5 <- ggplot2::ggplot(indice_mensual, ggplot2::aes(.data$mes, .data$indice)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey60") +
    ggplot2::geom_line(data = indice_lineas, color = "#2C7FB8", linewidth = 0.7) +
    ggplot2::geom_point(ggplot2::aes(color = .data$indice >= 0), size = 1.8, show.legend = FALSE) +
    ggplot2::facet_wrap(~gestion, scales = "free_x") +
    ggplot2::scale_color_manual(values = c(`TRUE` = "#238B45", `FALSE` = "#CB181D")) +
    ggplot2::scale_y_continuous(limits = c(-1, 1)) +
    ggplot2::labs(title = "Indice mensual de sentimiento", subtitle = "-1 = negativo; +1 = positivo", x = "Mes", y = "Indice") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "05_indice_sentimiento.png"), p5, width = 10, height = 6, dpi = 160)

  dias <- c("Lun", "Mar", "Mie", "Jue", "Vie", "Sab", "Dom")
  actividad <- mensajes |>
    dplyr::mutate(
      dia_numero = lubridate::wday(.data$fecha_hora, week_start = 1),
      dia = factor(dias[.data$dia_numero], levels = dias)
    ) |>
    dplyr::group_by(.data$dia, .data$hora) |>
    dplyr::summarise(cobertura = mean(.data$polaridad != "sin coincidencia"), .groups = "drop")
  p6 <- ggplot2::ggplot(actividad, ggplot2::aes(.data$hora, .data$dia, fill = .data$cobertura)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.2) +
    ggplot2::scale_x_continuous(breaks = seq(0, 23, 3)) +
    ggplot2::scale_fill_viridis_c(labels = scales::percent) +
    ggplot2::labs(title = "Cobertura por dia y hora", x = "Hora", y = NULL, fill = "Clasificados") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "06_cobertura_dia_hora.png"), p6, width = 10, height = 5, dpi = 160)

  motivos <- mensajes |>
    dplyr::filter(.data$polaridad == "sin coincidencia") |>
    dplyr::count(.data$motivo_no_clasificado, sort = TRUE) |>
    dplyr::mutate(motivo_no_clasificado = stats::reorder(.data$motivo_no_clasificado, .data$n))
  p7 <- ggplot2::ggplot(motivos, ggplot2::aes(.data$motivo_no_clasificado, .data$n)) +
    ggplot2::geom_col(fill = "#7A5195") +
    ggplot2::coord_flip() +
    ggplot2::labs(title = "Por que quedan mensajes sin clasificar", x = NULL, y = "Mensajes") +
    tema_umsa()
  ggplot2::ggsave(file.path(dir_graficos, "07_motivos_sin_clasificar.png"), p7, width = 9, height = 5, dpi = 160)
}

registrar_bitacora <- function(archivo, mensajes, coincidencias, archivos_entrada, zona_horaria) {
  nueva_fila <- tibble::tibble(
    fecha_ejecucion = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z", tz = zona_horaria),
    archivos_html = as.character(length(archivos_entrada)),
    mensajes_analizados = as.character(nrow(mensajes)),
    coincidencias_emocion = as.character(nrow(coincidencias)),
    primera_fecha = as.character(min(mensajes$fecha)),
    ultima_fecha = as.character(max(mensajes$fecha)),
    huella_entradas = paste(unname(tools::md5sum(archivos_entrada)), collapse = ";")
  )
  anterior <- if (file.exists(archivo)) {
    readr::read_csv(archivo, col_types = readr::cols(.default = readr::col_character()))
  } else {
    NULL
  }
  readr::write_csv(dplyr::bind_rows(anterior, nueva_fila), archivo)
}
