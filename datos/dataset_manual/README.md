# Libro de códigos del dataset de sentimientos UMSA

## Unidad de análisis

Cada fila representa un mensaje de texto del chat de temporada. Los nombres están sustituidos por identificadores como `P001`. La muestra está enriquecida por gestión y por señales emocionales para representar categorías poco frecuentes; por ello no debe usarse directamente para estimar porcentajes del chat completo.

## Antes de etiquetar

1. Trabaje sobre `etiquetado_anotador_a.csv`.
2. No consulte `referencia_reglas_no_usar_al_etiquetar.csv` hasta terminar: sus sugerencias podrían sesgar la decisión.
3. Lea únicamente lo expresado en el mensaje y no infiera estados psicológicos.
4. Un segundo anotador puede trabajar independientemente en `etiquetado_anotador_b.csv`. Es suficiente una submuestra común de al menos 20 % para medir acuerdo.
5. No modifique las columnas comprendidas entre `message_id` y `tipo_muestreo`.

## Etiquetas

### Presencia y polaridad

`tiene_sentimiento`: `si`, `no` o `dudoso`.

`polaridad_manual`: `positiva`, `negativa`, `neutra`, `mixta`, `sin_sentimiento` o `ambigua`.

Sorpresa y curiosidad son neutras según el documento. Use `mixta` cuando coexistan señales positivas y negativas.

### Sentimientos

Valores oficiales para `sentimiento_1` y, opcionalmente, `sentimiento_2`:

`alegria`, `gratitud`, `esperanza`, `amor`, `admiracion`, `tranquilidad`, `sorpresa`, `confusion`, `preocupacion`, `tristeza`, `enojo`, `decepcion`, `cansancio`, `verguenza` y `curiosidad`.

También se permiten `sin_sentimiento`, `ambiguo` y `otro`. Si `tiene_sentimiento = no`, use `sin_sentimiento` como sentimiento principal.

### Intensidad y tema

`intensidad`: `0` sin sentimiento, `1` baja, `2` media o `3` alta.

`tema`: `consulta_academica`, `recomendacion_docente`, `horarios_aulas`, `inscripcion_retiro_adicion`, `pagos_tramites`, `grupos_contactos`, `material_academico`, `conversacion_social`, `anuncio_publicidad` u `otro`.

`ironia`: `si`, `no` o `dudoso`.

`confianza_anotacion`: `alta`, `media` o `baja`.

## Librerías aplicadas

- `tm`: creación y limpieza del corpus.
- `quanteda`: tokenización, eliminación de palabras vacías, stemming y matriz documento-término.
- `syuzhet`: puntuación de polaridad con el léxico propio en español.

El archivo `muestra_tokenizacion_limpieza_normalizacion.csv`, generado por el script 05, permite observar las transformaciones paso a paso.

## Validación y análisis

```bash
Rscript scripts/03_validar_dataset_manual.R
Rscript scripts/04_mineria_descriptiva.R
Rscript scripts/05_preprocesamiento_librerias.R
```

La validación detecta valores incorrectos, consolida las filas completas y calcula kappa de Cohen. La minería genera frecuencias, TF-IDF, bigramas y asociaciones; no entrena modelos.

