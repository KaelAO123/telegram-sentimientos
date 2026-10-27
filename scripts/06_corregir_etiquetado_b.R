source("configuracion.R", encoding = "UTF-8")

archivo <- file.path(DIR_DATASET, "etiquetado_anotador_b.csv")
salida_log <- file.path(DIR_DATASET, "correcciones_anotador_b.csv")
if (!file.exists(archivo)) stop("No se encontro: ", archivo, call. = FALSE)

datos <- readr::read_csv(
  archivo,
  col_types = readr::cols(.default = readr::col_character())
)

# Solo correcciones mecanicas e inequivocas. Nunca se completa una decision
# subjetiva del anotador copiando las etiquetas de otra persona.
correcciones <- tibble::tribble(
  ~message_id, ~campo, ~valor_original, ~valor_corregido, ~motivo,
  "message5483", "polaridad_manual", "mixto", "mixta", "categoria escrita en masculino",
  "message23955", "ironia", "n", "no", "abreviatura no admitida",
  "message25102", "tema", "horario_aulas", "horarios_aulas", "categoria escrita en singular",
  "message7492", "sentimiento_2", "felicidad", "alegria", "sinonimo de la categoria oficial alegria"
)

for (i in seq_len(nrow(correcciones))) {
  id <- correcciones$message_id[[i]]
  campo <- correcciones$campo[[i]]
  original <- correcciones$valor_original[[i]]
  corregido <- correcciones$valor_corregido[[i]]
  fila <- which(datos$message_id == id)
  if (length(fila) != 1L) stop("No se encontro un ID unico para: ", id, call. = FALSE)
  actual <- datos[[campo]][[fila]]
  if (!identical(actual, original) && !identical(actual, corregido)) {
    stop("Valor inesperado en ", id, "/", campo, ": ", actual, call. = FALSE)
  }
  datos[[campo]][[fila]] <- corregido
}

temporal <- tempfile(pattern = "etiquetado_b_", tmpdir = dirname(archivo), fileext = ".csv")
readr::write_csv(datos, temporal, na = "")
if (!file.rename(temporal, archivo)) stop("No se pudo reemplazar el CSV corregido.", call. = FALSE)
readr::write_csv(correcciones, salida_log)

message("Se aplicaron o verificaron ", nrow(correcciones), " correcciones mecanicas en ", archivo, ".")
