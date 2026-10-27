# Libro de códigos del dataset de sentimientos UMSA

## Unidad de análisis

Cada fila representa un mensaje de texto del chat de temporada. Los nombres están sustituidos por identificadores como `P001`. La muestra está enriquecida por gestión y por señales emocionales para representar categorías poco frecuentes; por ello no debe usarse directamente para estimar porcentajes del chat completo.

## Antes de etiquetar

1. Trabaje sobre `etiquetado_anotador_a.csv`.
2. No consulte `referencia_reglas_no_usar_al_etiquetar.csv` hasta terminar: sus sugerencias podrían sesgar la decisión.
3. Lea únicamente lo expresado en el mensaje y no infiera estados psicológicos.
4. El segundo anotador trabaja independientemente en `etiquetado_anotador_b.csv`; en la versión final se completaron las 1.085 filas para medir acuerdo en toda la muestra.
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

## Consenso y adjudicación

La validación genera además:

- `acuerdo_por_variable.csv`: acuerdo y kappa para cada variable;
- `dataset_consenso_umsa.csv`: distingue `acuerdo_ab`, `desacuerdo_ab` y `solo_a`;
- `desacuerdos_anotacion.csv`: todos los desacuerdos descriptivos;
- `desacuerdos_modelado.csv`: solo los desacuerdos de polaridad o sentimientos que
  afectan al modelo.

Las columnas adjudicadas deben completarse mediante revisión humana. No se deben
copiar automáticamente las etiquetas de A o B. Después se ejecuta:

```bash
Rscript scripts/07_consolidar_adjudicaciones.R
```

El resultado `dataset_modelado_umsa.csv` conserva la fuente de cada etiqueta:
`acuerdo_ab`, `adjudicado` o `solo_a`.

## Estado final y modelado

El dataset final contiene 1.085 objetivos completos. Antes de adjudicar, kappa es
0,418 en polaridad y 0,432 en emoción principal. La validación cruzada y la
clasificación del corpus se ejecutan con:

```bash
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
  .venv-embeddings/bin/python scripts/09_validacion_cruzada.py
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
  .venv-embeddings/bin/python scripts/10_clasificar_corpus.py --batch-size 256
```

Se modelan diez emociones con soporte mínimo de veinte casos. La muestra está
enriquecida y no debe usarse directamente para estimar prevalencias poblacionales;
las predicciones del corpus completo son resultados exploratorios del modelo.

