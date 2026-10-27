# Análisis de sentimientos del chat de Informática UMSA

Proyecto académico para la materia **Data Mining**. Analiza mensajes del chat de temporada de la carrera de Informática de la UMSA mediante técnicas de minería de texto en R: extracción, limpieza, normalización, tokenización, construcción de frecuencias, aplicación de léxicos y elaboración de un dataset etiquetado manualmente.

El proyecto combina minería descriptiva y modelado supervisado. Compara el
diccionario, TF-IDF, embeddings multilingües y un modelo híbrido; las etiquetas
humanas adjudicadas siguen siendo la referencia y el modelo no sustituye su revisión.

## Objetivo

Identificar y describir sentimientos, emociones, temas y patrones lingüísticos presentes en el chat, siguiendo como referencia metodológica el documento `sentimientos_documento.pdf`.

Los objetivos específicos son:

- Preparar un corpus anonimizado a partir de la exportación de Telegram.
- Aplicar limpieza, normalización y tokenización de texto.
- Analizar frecuencias de palabras, términos distintivos y emociones.
- Reducir los casos `sin_evidencia` ampliando el vocabulario contextual de forma documentada.
- Construir un dataset propio de sentimientos mediante etiquetado manual.
- Comparar los resultados automáticos basados en reglas con las etiquetas humanas.
- Evaluar modelos mediante validación cruzada sin mezclar textos duplicados.
- Clasificar el corpus completo con el mejor modelo y analizar resultados agregados.

## Enfoque metodológico

El flujo de trabajo sigue estas etapas:

1. Extracción de los mensajes desde los archivos HTML exportados.
2. Exclusión de mensajes de servicio y contenido no analizable.
3. Anonimización de usuarios mediante identificadores irreversibles.
4. Limpieza y normalización del texto.
5. Tokenización y construcción de matrices documento-término.
6. Clasificación exploratoria con reglas y léxicos en español.
7. Diseño de una muestra estratificada.
8. Etiquetado manual independiente.
9. Validación del dataset y medición del acuerdo entre anotadores.
10. Adjudicación de desacuerdos y creación del objetivo final.
11. Validación cruzada de modelos supervisados.
12. Clasificación del corpus completo con el modelo seleccionado.
13. Minería descriptiva y generación del informe.

La clasificación automática funciona como apoyo exploratorio. Las predicciones de referencia no deben copiarse durante el etiquetado manual.

## Herramientas principales


| Paquete                              | Uso en el proyecto                                                           |
| -------------------------------------- | ------------------------------------------------------------------------------ |
| `tm`                                 | Creación del corpus, limpieza, eliminación de palabras vacías y espacios  |
| `quanteda`                           | Tokenización, stemming en español, documentos y matriz documento-término  |
| `syuzhet`                            | Cálculo auxiliar de polaridad mediante un léxico personalizado en español |
| `SnowballC`                          | Reducción de palabras a raíces                                             |
| `rvest` y `xml2`                     | Lectura de los archivos HTML de Telegram                                     |
| `dplyr`, `tidyr`, `stringr`, `purrr` | Transformación, limpieza y organización de datos                           |
| `ggplot2`                            | Visualización de resultados                                                 |
| `rmarkdown` y `knitr`                | Generación del informe reproducible                                         |
| `sentence-transformers`              | Embeddings semánticos multilingües para el benchmark experimental            |
| `scikit-learn`                       | Regresión logística y métricas para TF-IDF y embeddings                      |

## Estructura del proyecto

```text
.
├── R/
│   ├── funciones.R
│   ├── dataset_manual.R
│   └── preprocesamiento_texto.R
├── scripts/
│   ├── 00_instalar_paquetes.R
│   ├── 01_ejecutar_analisis.R
│   ├── 02_generar_dataset_manual.R
│   ├── 03_validar_dataset_manual.R
│   ├── 04_mineria_descriptiva.R
│   ├── 05_preprocesamiento_librerias.R
│   ├── 06_corregir_etiquetado_b.R
│   ├── 07_consolidar_adjudicaciones.R
│   ├── 08_modelo_embeddings.py
│   ├── 09_validacion_cruzada.py
│   └── 10_clasificar_corpus.py
├── datos/
│   └── dataset_manual/
├── informe/
│   └── Informe_analisis_sentimientos.Rmd
├── docs/
│   └── PLAN_PROYECTO.md
├── resultados/
├── configuracion.R
├── BITACORA.md
├── sentimientos_documento.pdf
└── umsa-sentimientos.Rproj
```

La exportación original de Telegram debe estar en una carpeta cuyo nombre comience con `ChatExport_`. Esa carpeta contiene datos privados y no se versiona.

## Requisitos

- R 4.x o una versión reciente compatible.
- RStudio, recomendado pero no obligatorio.
- Una exportación HTML del chat de Telegram.
- Pandoc, si se desea compilar el informe.

## Configuración inicial

1. Abrir `umsa-sentimientos.Rproj` en RStudio o situarse en la raíz del proyecto.
2. Colocar la exportación de Telegram dentro del proyecto.
3. Revisar las rutas y parámetros de [configuracion.R](configuracion.R).
4. Instalar las dependencias:

```bash
Rscript scripts/00_instalar_paquetes.R
```

No es necesario establecer manualmente el directorio de trabajo si los comandos se ejecutan desde la raíz del proyecto.

## Ejecución completa

### 1. Análisis automático y resultados generales

```bash
Rscript scripts/01_ejecutar_analisis.R
```

Este paso extrae, anonimiza y analiza el corpus. También genera tablas y gráficos con las reglas de sentimiento y emociones.

### 2. Creación del dataset para etiquetado manual

```bash
Rscript scripts/02_generar_dataset_manual.R
```

Los archivos se crean en `datos/dataset_manual/`. El procedimiento detallado está en [la guía del dataset](datos/dataset_manual/README.md).

### 3. Preprocesamiento con las librerías de la materia

```bash
Rscript scripts/05_preprocesamiento_librerias.R
```

Este script deja evidencia separada de:

- limpieza con `tm`;
- tokenización y normalización con `quanteda`;
- stemming en español;
- matriz documento-término;
- puntuación auxiliar con `syuzhet`.

### 4. Etiquetado humano

Completar la columna `sentimiento_manual` de:

- `datos/dataset_manual/etiquetado_anotador_a.csv`;
- `datos/dataset_manual/etiquetado_anotador_b.csv`, si participa un segundo anotador.

Las etiquetas admitidas y sus criterios están documentados en el libro de códigos. Debe etiquetarse leyendo únicamente el mensaje y su contexto, sin consultar las columnas de predicción automática.

### 5. Validación y consolidación

```bash
Rscript scripts/03_validar_dataset_manual.R
```

Antes de validar se pueden aplicar las correcciones mecánicas documentadas de B:

```bash
Rscript scripts/06_corregir_etiquetado_b.R
```

1. Este paso comprueba etiquetas inválidas, duplicados, campos incompletos y, cuando existen dos anotadores, calcula el acuerdo y señala desacuerdos. El dataset consolidado se guarda como:

```text
datos/dataset_manual/dataset_sentimientos_umsa.csv
```

La validación también crea `dataset_consenso_umsa.csv`, `acuerdo_por_variable.csv`
y una plantilla privada de desacuerdos. El archivo descriptivo tradicional conserva
las etiquetas de A; el consenso distingue acuerdos, desacuerdos y filas solo A.

### 6. Adjudicación

Completar `desacuerdos_modelado.csv` sin modificar las decisiones originales y luego ejecutar:

```bash
Rscript scripts/07_consolidar_adjudicaciones.R
```

El script se detiene mientras falte alguna decisión necesaria y, al finalizar,
crea `dataset_modelado_umsa.csv`.

### 7. Minería descriptiva del dataset manual

```bash
Rscript scripts/04_mineria_descriptiva.R
```

Se requieren al menos 50 mensajes con etiquetas manuales válidas. El script genera distribuciones, términos frecuentes, comparaciones por sentimiento y gráficos descriptivos.

### 8. Benchmark exploratorio de embeddings

```bash
python3 -m venv .venv-embeddings
.venv-embeddings/bin/pip install -r requirements-embeddings.txt
.venv-embeddings/bin/python scripts/08_modelo_embeddings.py
```

Compara la clase mayoritaria, el diccionario de reglas, TF-IDF y embeddings
`paraphrase-multilingual-MiniLM-L12-v2`. Los textos duplicados no cruzan de
entrenamiento a prueba. Los resultados se guardan en `resultados/modelos_embeddings/`.

### 9. Validación cruzada y selección del modelo

```bash
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
  .venv-embeddings/bin/python scripts/09_validacion_cruzada.py
```

Ejecuta cinco particiones estratificadas y agrupadas por hash de texto. Compara
el diccionario, TF-IDF, MiniLM y el híbrido TF-IDF+MiniLM. Genera métricas fuera
de muestra, resultados por fold, matriz de confusión y F1 por emoción en
`resultados/validacion_cruzada/`.

### 10. Clasificación del corpus completo

```bash
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
  .venv-embeddings/bin/python scripts/10_clasificar_corpus.py --batch-size 256
```

Entrena el modelo híbrido seleccionado con las 1 085 etiquetas finales y
clasifica los 21 546 mensajes. La salida no contiene texto ni participantes y se
guarda en `resultados/modelo_final/`.

### 11. Generación del informe

Desde R:

```r
rmarkdown::render("informe/Informe_analisis_sentimientos.Rmd")
```

## Dataset manual

Los principales archivos son:


| Archivo                                      | Propósito                                                    |
| ---------------------------------------------- | --------------------------------------------------------------- |
| `corpus_anonimizado.csv`                     | Corpus completo sin nombres reales                            |
| `diseno_muestra.csv`                         | Selección y estratos de la muestra                           |
| `etiquetado_anotador_a.csv`                  | Plantilla del primer anotador                                 |
| `etiquetado_anotador_b.csv`                  | Plantilla opcional del segundo anotador                       |
| `referencia_reglas_no_usar_al_etiquetar.csv` | Resultado automático reservado para la evaluación posterior |
| `diccionario_variables.csv`                  | Definición de las variables                                  |
| `control_calidad.csv`                        | Resumen de validaciones y acuerdo                             |
| `errores_etiquetado.csv`                     | Registros que necesitan corrección                           |
| `dataset_sentimientos_umsa.csv`              | Dataset manual consolidado                                    |
| `dataset_consenso_umsa.csv`                  | Acuerdos A/B, desacuerdos y filas anotadas solo por A          |
| `desacuerdos_modelado.csv`                   | Plantilla privada para adjudicar polaridad y sentimientos       |
| `dataset_modelado_umsa.csv`                  | Dataset objetivo después de completar la adjudicación           |

El contenido de los mensajes y las plantillas etiquetadas se mantienen fuera de Git para proteger la privacidad del chat.

## Resultados generados

Los productos reproducibles se guardan en `resultados/`:

- `datos/`: tablas agregadas y resultados del análisis;
- `graficos/`: visualizaciones de sentimientos, emociones y actividad;
- `preprocesamiento/`: tokens, frecuencias y matrices;
- `graficos_preprocesamiento/`: gráficos específicos del procesamiento textual;
- `validacion_cruzada/`: métricas OOF, resultados por fold y gráficos de evaluación;
- `modelo_final/`: predicciones privadas, agregados, gráficos y artefactos del modelo.

El HTML compilado se guarda junto al R Markdown en `informe/`.

La carpeta se ignora en Git porque puede regenerarse ejecutando los scripts.

## Estado actual

Con la exportación disponible, el corpus contiene:

- 21 546 mensajes;
- mensajes comprendidos entre el 16 de diciembre de 2022 y el 12 de octubre de 2026;
- una muestra manual de 1 085 mensajes;
- 1 085 etiquetas completas y válidas tanto de A como de B;
- 1 085 etiquetas finales después de adjudicar todos los desacuerdos;
- kappa de Cohen de 0,418 en polaridad y 0,432 en emoción principal antes de adjudicar;
- 2 034 mensajes con evidencia usando el léxico base del documento (9,4 %);
- 5 299 mensajes con evidencia usando el léxico contextual ampliado (24,6 %).

La ampliación reduce `sin_evidencia`, pero no elimina todos los casos: un mensaje puede ser informativo, ambiguo, muy corto o no contener términos afectivos explícitos. Por esa razón, el dataset manual es la referencia principal para evaluar las reglas.

La validación cruzada agrupada de cinco folds obtuvo macro-F1 de polaridad
`0,393` para el híbrido TF-IDF+MiniLM, `0,369` para MiniLM, `0,354` para el
diccionario y `0,305` para TF-IDF. En diez emociones, el macro-F1 fue `0,375`
para el híbrido, `0,336` para MiniLM, `0,333` para el diccionario y `0,312` para
TF-IDF. El híbrido fue seleccionado para clasificar el corpus completo.

## Privacidad y reproducibilidad

- No se publican nombres, identificadores de Telegram, archivos multimedia ni el texto completo del chat.
- Los usuarios se sustituyen por identificadores anonimizados.
- Los resultados versionables deberían ser agregados y no permitir reconstruir conversaciones individuales.
- La exportación original, los CSV con mensajes y los resultados generados están incluidos en `.gitignore`.
- Las decisiones metodológicas se registran en [BITACORA.md](BITACORA.md).
- El plan detallado se encuentra en [docs/PLAN_PROYECTO.md](docs/PLAN_PROYECTO.md).

## Limitaciones

- Los léxicos pueden no reconocer modismos, ironía, errores ortográficos o vocabulario propio de la UMSA.
- La ausencia de una palabra emocional no significa necesariamente ausencia de sentimiento.
- El stemming agrupa variantes, pero también puede reducir términos distintos a una raíz similar.
- Los resultados describen el chat analizado y no deben generalizarse automáticamente a toda la comunidad universitaria.
- La calidad final depende de que el etiquetado manual siga criterios consistentes.
- Las clases siguen desbalanceadas y algunas emociones tienen pocos ejemplos; por
  ello se priorizan macro-F1, micro-F1 y métricas por clase sobre la exactitud sola.
- La muestra manual fue enriquecida mediante señales del diccionario, por lo que
  las prevalencias finales del modelo deben interpretarse como estimaciones exploratorias.

## Uso académico

Este repositorio fue preparado con fines educativos para la materia Data Mining. Cualquier uso de los datos debe respetar la privacidad de los participantes y las normas institucionales aplicables.

## Documentación para la defensa

La guía de estudio completa para el equipo se encuentra en
[docs/GUIA_DEFENSA_Y_CSV.md](docs/GUIA_DEFENSA_Y_CSV.md). Explica el flujo de
datos, código R y Python, archivos CSV, anotación, diccionario, TF-IDF, embeddings,
validación cruzada, métricas, dashboard, resultados, preguntas de defensa y el
reparto sugerido para los cuatro integrantes.
