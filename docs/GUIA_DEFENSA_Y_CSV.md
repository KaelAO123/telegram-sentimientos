# Guía para comprender y defender el proyecto

## 1. Propósito de esta guía

Esta documentación permite que cualquier integrante del grupo pueda explicar:

- qué problema resuelve el proyecto;
- cómo circulan los datos desde Telegram hasta los resultados;
- para qué sirve cada archivo de código;
- qué hacen `tm`, `quanteda` y `syuzhet`;
- qué contiene cada CSV;
- cómo interpretar los resultados sin confundir reglas con modelos;
- cuáles son las limitaciones y los trabajos pendientes.

Los datos numéricos de la sección de resultados corresponden a la ejecución disponible el 24 de octubre de 2026.

## 2. Explicación corta para iniciar la defensa

> El proyecto analiza sentimientos en el chat de temporada de Informática de la UMSA utilizando minería de texto en R. Primero extraemos y pseudonimizamos los mensajes de Telegram. Después limpiamos, normalizamos y tokenizamos el texto. Aplicamos un diccionario de 15 sentimientos para localizar evidencia lingüística, pero no consideramos esas reglas como verdad absoluta. Por eso construimos una muestra de 1.085 mensajes y la etiquetamos manualmente. Finalmente estudiamos frecuencias, TF-IDF, bigramas, temas, polaridad, cobertura y acuerdo entre anotadores. No entrenamos un modelo predictivo: el centro del trabajo es el proceso de minería de datos, la construcción del dataset y la evaluación de reglas interpretables.

## 3. Pregunta, objetivo y alcance

### Pregunta central

¿Qué sentimientos, polaridades, temas y patrones textuales aparecen en el chat de temporada, y qué tan bien puede identificarlos un diccionario contextual en español?

### Objetivo general

Construir un proceso reproducible de minería de texto que transforme una exportación de Telegram en un corpus pseudonimizado, resultados descriptivos y un dataset de sentimientos etiquetado por personas.

### Qué sí hace el proyecto

- Procesa 21.546 mensajes de texto.
- Conserva fechas, horas y códigos de participantes para análisis agregados.
- Limpia y normaliza el contenido textual.
- Tokeniza y crea matrices documento-término.
- Detecta evidencia de 15 sentimientos mediante reglas interpretables.
- Compara el diccionario original con una ampliación contextual.
- Genera una muestra estratificada para etiquetado humano.
- Calcula frecuencias, TF-IDF, bigramas y asociaciones descriptivas.
- Usa `syuzhet` con un léxico propio en español como referencia auxiliar.
- Prepara el cálculo de kappa entre dos anotaciones independientes.

### Qué no hace

- No diagnostica el estado psicológico de los participantes.
- No entrena redes neuronales, clasificadores supervisados ni otros modelos predictivos.
- No considera las reglas automáticas como verdad de referencia.
- No analiza el contenido visual o sonoro de imágenes, videos, audios y stickers.
- No debe publicar mensajes individuales ni datos que permitan identificar personas.

## 4. Flujo completo de los datos

```text
Exportación HTML de Telegram
            │
            ▼
Extracción con rvest y xml2
            │
            ▼
Pseudonimización + fecha + gestión + hora
            │
            ▼
Normalización de texto y codificación de emojis
            │
            ├──────────────► Diccionario base del PDF
            │                         │
            └──────────────► Diccionario contextual ampliado
                                      │
                                      ▼
                          Coincidencias y polaridad por reglas
                                      │
                 ┌────────────────────┴────────────────────┐
                 ▼                                         ▼
       Resultados del corpus                     Muestra estratificada
       completo (21.546)                         manual (1.085)
                 │                                         │
                 ▼                                         ▼
     tm + quanteda + syuzhet                   Anotador A y Anotador B
                 │                                         │
                 └────────────────────┬────────────────────┘
                                      ▼
                       Validación, minería descriptiva,
                       comparación e informe final
```

## 5. Conceptos que el grupo debe poder explicar

### Corpus

Es el conjunto de documentos analizados. En este proyecto cada mensaje de Telegram es un documento y los 21.546 mensajes forman el corpus.

### Limpieza

Elimina elementos que dificultan el análisis, por ejemplo enlaces, puntuación, números, palabras vacías y espacios repetidos. Se conserva una versión original para no perder trazabilidad.

### Normalización

Convierte variantes a una representación comparable: minúsculas, letras sin tilde, espacios uniformes y códigos textuales para emojis o emoticonos. Por ejemplo, un emoji de tristeza se transforma en `emojitristeza` antes de retirar símbolos.

### Tokenización

Divide un texto en unidades llamadas tokens, normalmente palabras. El mensaje “alguien sabe horarios” se convierte en los tokens `alguien`, `sabe` y `horarios`.

### Palabras vacías o stopwords

Son palabras muy frecuentes con poco poder descriptivo, como artículos y preposiciones. En la limpieza con `tm` se preservan `no`, `nunca`, `sin` y `ni` porque pueden cambiar el sentido emocional.

### Stemming

Reduce palabras a una raíz común. Por ejemplo, variantes relacionadas con “preocupar” pueden quedar representadas por una raíz semejante. Sirve para agrupar formas gramaticales, aunque puede unir palabras que no son exactamente equivalentes.

### Matriz documento-término o DFM

Es una matriz donde las filas son mensajes, las columnas son tokens y cada celda indica cuántas veces aparece un token en un mensaje. Es una representación numérica del corpus, no un modelo.

### TF-IDF

Da mayor peso a términos frecuentes dentro de un grupo pero poco frecuentes en los demás. Se usa para encontrar palabras distintivas de cada sentimiento, no solo las palabras más comunes del chat.

### Bigramas

Son secuencias de dos tokens consecutivos, por ejemplo `no entiendo` o `muchas gracias`. Conservan más contexto que una palabra aislada.

### Cobertura

```text
cobertura = mensajes con alguna coincidencia / mensajes analizados
```

Indica qué proporción del corpus pudo reconocer el diccionario. No mide por sí sola si las clasificaciones son correctas.

### `sin coincidencia` o `sin_evidencia`

Significa que el diccionario no encontró una señal conocida. No significa automáticamente que el mensaje sea neutral ni que carezca de sentimiento. Puede tratarse de vocabulario no cubierto, ironía, contexto insuficiente o un mensaje realmente informativo.

### Soporte, confianza y lift

En las asociaciones sentimiento-tema:

- **soporte:** proporción de mensajes donde aparecen juntos un sentimiento y un tema;
- **confianza:** dentro de un sentimiento, proporción asociada a un tema;
- **lift:** compara la asociación observada con la esperada si ambas categorías fueran independientes;
- un `lift > 1` sugiere asociación superior a la esperada;
- un lift alto con muy pocos mensajes debe interpretarse con cautela.

La `confianza` de las asociaciones no es lo mismo que `confianza_anotacion` ni que la confianza técnica de una coincidencia.

### Kappa de Cohen

Mide el acuerdo entre dos anotadores descontando el acuerdo que podría ocurrir por azar:

```text
kappa = (acuerdo observado - acuerdo esperado) /
        (1 - acuerdo esperado)
```

Debe presentarse junto con el número de filas comunes y el acuerdo observado. Un kappa bajo puede indicar criterios ambiguos, categorías difíciles o diferencias entre anotadores.

## 6. Librerías utilizadas


| Librería            | Función en el proyecto                                       |
| ---------------------- | --------------------------------------------------------------- |
| `rvest`, `xml2`      | Leer la estructura HTML exportada por Telegram                |
| `dplyr`, `tidyr`     | Filtrar, unir, agrupar y resumir tablas                       |
| `stringr`, `stringi` | Normalizar texto, buscar patrones y tratar caracteres Unicode |
| `purrr`              | Aplicar funciones a varios archivos y categorías             |
| `lubridate`          | Convertir fechas y obtener gestión, mes, día y hora         |
| `readr`              | Leer y escribir CSV de manera consistente                     |
| `ggplot2`, `scales`  | Crear gráficos y porcentajes                                 |
| `tm`                 | Construir y limpiar un corpus textual                         |
| `quanteda`           | Tokenizar, retirar stopwords, aplicar stemming y crear DFM    |
| `SnowballC`          | Proporcionar el algoritmo de stemming en español             |
| `syuzhet`            | Calcular un puntaje aditivo usando el léxico personalizado   |
| `rmarkdown`, `knitr` | Generar el informe HTML reproducible                          |

## 7. Organización general del proyecto


| Ruta                           | Para qué sirve                                                      |
| -------------------------------- | ---------------------------------------------------------------------- |
| `ChatExport_*/`                | Entrada privada de Telegram; no debe subirse a Git                   |
| `sentimientos_documento.pdf`   | Documento metodológico y fuente inicial de las 15 categorías       |
| `configuracion.R`              | Centraliza rutas, años seleccionados y zona horaria                 |
| `R/`                           | Funciones reutilizables; aquí está la lógica del análisis        |
| `scripts/`                     | Programas ejecutables en el orden `00` a `05`                        |
| `datos/dataset_manual/`        | Corpus pseudonimizado, plantillas, validación y dataset manual      |
| `resultados/datos/`            | Resultados del análisis automático del corpus completo             |
| `resultados/preprocesamiento/` | Evidencias de limpieza, tokenización, stemming y DFM                |
| `resultados/mineria_dataset/`  | Minería descriptiva del dataset etiquetado manualmente              |
| `resultados/graficos*/`        | Imágenes creadas por los scripts                                    |
| `informe/`                     | Código fuente R Markdown del informe                                |
| `resultados/informe/`          | Informe HTML compilado                                               |
| `docs/`                        | Plan y documentación para comprender y defender el trabajo          |
| `BITACORA.md`                  | Registro humano de decisiones y cambios importantes                  |
| `.gitignore`                   | Evita versionar datos privados, resultados regenerables y temporales |

## 8. Explicación del código

### `configuracion.R`

Es el punto central de configuración:

- `CHAT_DIR`: carpeta de la exportación de Telegram;
- `ANIOS_ANALISIS`: años que se desean incluir; `NULL` significa todos;
- `DIR_DATOS`, `DIR_GRAFICOS`, `DIR_INFORME`, `DIR_DATASET`: carpetas de salida;
- `ZONA_HORARIA`: zona usada para interpretar las fechas.

Separar la configuración evita modificar rutas dentro de cada script.

### `R/funciones.R`

Contiene la lógica del análisis general.


| Función                          | Explicación                                                                                                |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `verificar_paquetes()`            | Detiene la ejecución con un mensaje claro si falta una dependencia                                         |
| `codificar_senales_graficas()`    | Convierte emojis y emoticonos en códigos textuales antes de retirar símbolos                              |
| `normalizar_texto()`              | Sustituye señales gráficas, elimina tildes, pasa a minúsculas, retira URL y compacta espacios            |
| `crear_diccionario_base()`        | Construye las 15 categorías, definiciones, polaridades, términos y raíces iniciales                      |
| `crear_diccionario()`             | Agrega modismos, emojis y expresiones contextualizadas para el chat                                         |
| `ordenar_archivos_chat()`         | Encuentra `messages.html`, `messages2.html`, etc. y respeta su orden                                        |
| `texto_nodo()`                    | Extrae texto de un nodo HTML y maneja nodos ausentes                                                        |
| `atributo_nodo()`                 | Extrae atributos HTML como la fecha original                                                                |
| `extraer_mensajes()`              | Lee los HTML, recupera autor, texto y fecha, filtra mensajes vacíos y genera códigos `P001`, `P002`, etc. |
| `patron_terminos()`               | Crea una expresión regular para palabras o frases exactas                                                  |
| `patron_raices()`                 | Crea una expresión regular que acepta terminaciones después de una raíz                                  |
| `clasificar_emociones()`          | Busca evidencia por cada categoría y devuelve una fila por mensaje y emoción detectada                    |
| `palabras_sin_clasificar()`       | Cuenta términos frecuentes en mensajes donde el diccionario no encontró evidencia                         |
| `asignar_polaridad_mensaje()`     | Resume coincidencias como positiva, negativa, neutra, mixta o sin coincidencia                              |
| `agregar_diagnostico_cobertura()` | Propone una razón operativa para los mensajes no clasificados                                              |
| `tema_umsa()`                     | Define un estilo visual común para todos los gráficos                                                     |
| `guardar_graficos()`              | Genera siete gráficos del corpus completo                                                                  |
| `registrar_bitacora()`            | Guarda fecha, tamaños y huellas MD5 para comprobar reproducibilidad                                        |

#### Cómo se asigna la polaridad automática

La regla sigue este orden:

1. Si un mensaje tiene evidencia positiva y negativa, se marca `mixta`.
2. Si solo tiene evidencia positiva, se marca `positiva`.
3. Si solo tiene evidencia negativa, se marca `negativa`.
4. Si únicamente tiene evidencia neutra, se marca `neutra`.
5. Si no existe evidencia, queda `sin coincidencia`.

El sistema es multilabel: un mismo mensaje puede tener varias emociones. La polaridad resume esas coincidencias.

#### Qué significa la confianza automática

- `alta`: se encontró un término o una frase exacta;
- `media`: se encontró una raíz, emoji o emoticono.

No es una probabilidad ni garantiza que la clasificación sea correcta.

### `R/dataset_manual.R`

Gestiona la construcción y validación del dataset humano.


| Función                        | Explicación                                                                             |
| --------------------------------- | ------------------------------------------------------------------------------------------ |
| `normalizar_etiqueta()`         | Uniforma etiquetas escritas con mayúsculas, tildes, espacios, guiones o barras          |
| `crear_muestra_estratificada()` | Selecciona mensajes por gestión y señal emocional, además de reforzar `sin_evidencia` |
| `crear_variables_textuales()`   | Calcula longitud, palabras, signos, emojis, URL y día de la semana                      |
| `crear_referencia_reglas()`     | Guarda aparte la predicción automática para no sesgar a los anotadores                 |
| `plantilla_etiquetado()`        | Crea las columnas que deben completar los anotadores                                     |
| `guardar_si_no_existe()`        | Evita sobrescribir un etiquetado existente al repetir el script 02                       |
| `validar_etiquetas()`           | Normaliza y comprueba que los valores pertenezcan al libro de códigos                   |
| `calcular_kappa()`              | Calcula manualmente el kappa de Cohen a partir de dos vectores de etiquetas              |

La semilla `set.seed(20261024)` permite reproducir la misma muestra mientras no cambie el corpus.

### `R/preprocesamiento_texto.R`

Agrupa las funciones didácticas relacionadas con las librerías vistas en la materia.


| Función                  | Explicación                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------ |
| `limpiar_textos_tm()`     | Crea un `VCorpus` y aplica URL, minúsculas, números, puntuación, stopwords y espacios |
| `tokenizar_quanteda()`    | Crea tokens, retira símbolos, números, URL y stopwords; opcionalmente aplica stemming  |
| `crear_lexico_syuzhet()`  | Convierte el diccionario propio al formato `word`–`value` de `syuzhet`                  |
| `puntuar_con_syuzhet()`   | Suma valores positivos y negativos presentes en cada texto                               |
| `frecuencias_dfm()`       | Obtiene los tokens más frecuentes de una DFM                                            |
| `extraer_top_por_grupo()` | Extrae los principales tokens por sentimiento u otro grupo                               |

`syuzhet` no utiliza aquí su léxico inglés predeterminado. Usa un léxico propio en español. Las frases de varias palabras se excluyen de esta puntuación auxiliar porque `get_sentiment()` opera con palabras individuales en esta configuración.

## 9. Explicación de los scripts ejecutables

### `scripts/00_instalar_paquetes.R`

Comprueba qué librerías faltan y las instala desde CRAN. Solo se necesita al preparar el entorno o cuando falta una dependencia.

### `scripts/01_ejecutar_analisis.R`

Es el análisis principal del corpus completo:

1. carga configuración y funciones;
2. extrae los mensajes HTML;
3. aplica el diccionario base y el ampliado;
4. compara sus coberturas;
5. exporta mensajes, coincidencias y resúmenes;
6. genera siete gráficos;
7. registra la ejecución;
8. compila el informe HTML.

### `scripts/02_generar_dataset_manual.R`

Construye los archivos para etiquetado:

1. lee los resultados del script 01;
2. selecciona una muestra estratificada;
3. crea las plantillas A y B;
4. separa la referencia automática;
5. exporta el corpus pseudonimizado y el diseño de la muestra.

Las plantillas no se sobrescriben si ya existen.

### `scripts/03_validar_dataset_manual.R`

Controla el etiquetado:

1. normaliza las etiquetas A y B;
2. encuentra valores inválidos y duplicados;
3. identifica filas completas;
4. une las filas etiquetadas por ambos anotadores;
5. calcula kappa para polaridad y sentimiento principal;
6. añade la referencia automática al dataset de A;
7. genera control de calidad, errores y dataset consolidado.

Limitación actual: el dataset consolidado conserva las etiquetas de A. Después de completar B todavía se necesita una etapa de adjudicación para resolver desacuerdos y crear una etiqueta consensuada.

### `scripts/04_mineria_descriptiva.R`

Analiza el dataset manual sin entrenar modelos:

- construye tokens y una DFM con `quanteda`;
- agrupa la DFM por sentimiento;
- calcula TF-IDF por sentimiento;
- crea bigramas;
- cuenta sentimientos, polaridades y temas;
- calcula soporte, confianza y lift entre sentimiento y tema;
- compara la polaridad manual con `syuzhet`;
- guarda la matriz y un gráfico de distribución.

### `scripts/05_preprocesamiento_librerias.R`

Demuestra de forma separada los temas vistos en Data Mining:

- limpieza con `tm`;
- normalización propia;
- tokenización con `quanteda`;
- stemming en español;
- matriz documento-término;
- puntuación con `syuzhet` y léxico propio;
- exportación de una muestra de 100 transformaciones paso a paso.

## 10. Diccionario de variables compartidas

Estas variables aparecen en varios CSV:


| Variable                             | Significado                                                                      |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| `message_id`                         | Identificador único tomado del HTML de Telegram                                 |
| `gestion`                            | Año del mensaje                                                                 |
| `fecha`, `fecha_hora`, `mes`, `hora` | Variables temporales en horario de La Paz                                        |
| `participante`                       | Código pseudónimo como `P001`; no se exporta el nombre                         |
| `texto`                              | Mensaje original; es información privada                                        |
| `texto_normalizado`                  | Versión en minúsculas, sin tildes, URL ni puntuación y con emojis codificados |
| `caracteres`                         | Longitud del texto original                                                      |
| `palabras`                           | Número de palabras en la versión normalizada                                   |
| `signos_pregunta`                    | Cantidad de `?` y `¿`                                                           |
| `signos_exclamacion`                 | Cantidad de `!` y `¡`                                                           |
| `emojis`                             | Conteo aproximado de símbolos emoji                                             |
| `contiene_url`                       | Indica si el mensaje incluye un enlace                                           |
| `dia_semana`                         | Día local de lunes a domingo                                                    |
| `tipo_muestreo`                      | Forma en que el mensaje entró a la muestra                                      |
| `tiene_sentimiento`                  | `si`, `no` o `dudoso`, decidido manualmente                                      |
| `polaridad_manual`                   | Positiva, negativa, neutra, mixta, sin sentimiento o ambigua                     |
| `sentimiento_1`                      | Sentimiento principal manual                                                     |
| `sentimiento_2`                      | Sentimiento secundario opcional; debe quedar vacío si no existe                 |
| `intensidad`                         | `0` sin sentimiento, `1` baja, `2` media, `3` alta                               |
| `tema`                               | Tema principal del mensaje                                                       |
| `ironia`                             | `si`, `no` o `dudoso`                                                            |
| `confianza_anotacion`                | Seguridad declarada por el anotador: alta, media o baja                          |
| `observaciones`                      | Nota o justificación libre                                                      |
| `responsable`                        | Integrante encargado de la fila en el archivo A                                  |

## 11. Explicación de los CSV de `datos/dataset_manual/`

### `corpus_anonimizado.csv`

Contiene los 21.546 mensajes utilizables del chat. Sirve como corpus completo para seleccionar muestras o realizar análisis posteriores.

Columnas especiales:

- `texto_normalizado`: texto listo para búsqueda y minería;
- variables de longitud, signos, emojis y URL: características descriptivas del mensaje.

Aunque no contiene nombres, conserva el texto y debe tratarse como archivo privado. Técnicamente existe pseudonimización, no anonimización absoluta.

### `etiquetado_anotador_a.csv`

Plantilla principal de 1.085 mensajes. Incluye datos del mensaje y las columnas manuales. Actualmente contiene las 1.085 filas estructuralmente completas. La columna `responsable` indica qué integrante etiquetó cada bloque.

### `etiquetado_anotador_b.csv`

Segunda plantilla con los mismos 1.085 mensajes. Debe completarse de manera independiente y sin mirar A ni la referencia automática. Permite medir acuerdo y detectar categorías ambiguas.

### `referencia_reglas_no_usar_al_etiquetar.csv`

Mantiene separadas las predicciones automáticas para evitar sesgo de confirmación durante el etiquetado.


| Columna                 | Significado                                              |
| ------------------------- | ---------------------------------------------------------- |
| `polaridad_regla`       | Polaridad asignada por el diccionario                    |
| `motivo_no_clasificado` | Diagnóstico si no hubo coincidencia                     |
| `emociones_regla`       | Emociones encontradas, separadas por `;`                 |
| `evidencias_regla`      | Palabras, frases o códigos que activaron las reglas     |
| `tipos_regla`           | Tipo de coincidencia: término, raíz, emoji o emoticono |

Solo debe consultarse después de terminar el etiquetado humano.

### `diseno_muestra.csv`

Describe cuántos mensajes se seleccionaron por año, estrato y tipo de muestreo.


| Columna         | Significado                                                               |
| ----------------- | --------------------------------------------------------------------------- |
| `gestion`       | Año del estrato                                                          |
| `estrato`       | Emoción automática usada para diversificar la muestra o `sin_evidencia` |
| `tipo_muestreo` | Estratificado por gestión-emoción o refuerzo de mensajes sin evidencia  |
| `n`             | Mensajes seleccionados en esa combinación                                |

La muestra está enriquecida; sus porcentajes no deben presentarse como prevalencia directa del corpus completo sin aplicar pesos muestrales.

### `control_calidad.csv`

Es un resumen de una sola fila producido por el script 03.


| Columna                                        | Significado                                           |
| ------------------------------------------------ | ------------------------------------------------------- |
| `filas_totales`                                | Tamaño de la plantilla A                             |
| `completas_anotador_a`, `completas_anotador_b` | Filas completas y válidas                            |
| `errores_a`, `errores_b`                       | Valores fuera del libro de códigos                   |
| `duplicados_a`, `duplicados_b`                 | Identificadores repetidos                             |
| `filas_comunes`                                | Mensajes completos en A y B                           |
| `kappa_polaridad`                              | Acuerdo corregido por azar para polaridad             |
| `kappa_sentimiento`                            | Acuerdo corregido por azar para sentimiento principal |

Un valor `NA` de kappa significa que todavía no hay filas comunes suficientes o que el cálculo no está definido.

### `errores_etiquetado.csv`

Lista únicamente las filas con problemas estructurales.

- `anotador`: A o B;
- `message_id`: fila que debe corregirse;
- `error`: motivo, por ejemplo polaridad inválida o identificador duplicado.

Un archivo con cero filas indica que no hay errores de formato detectados. No garantiza por sí solo coherencia semántica entre campos.

### `dataset_sentimientos_umsa.csv`

Es el dataset consolidado utilizado por el script 04. Une las etiquetas válidas de A con la referencia automática.

Además de las variables manuales incluye:

- `polaridad_regla`;
- `motivo_no_clasificado`;
- `emociones_regla`;
- `evidencias_regla`;
- `tipos_regla`.

Mientras no exista adjudicación A–B, debe describirse como “dataset validado del anotador A”, no como consenso definitivo.

### `diccionario_variables.csv`

Es una versión tabular del diccionario de variables. Sirve para conocer el tipo y significado de cada columna sin abrir el código.

## 12. Explicación de los CSV de `resultados/datos/`

### `mensajes_clasificados.csv`

Tabla principal del análisis automático, con una fila por mensaje. Incluye texto, tiempo, pseudónimo, polaridad automática, número de emociones y motivo de falta de cobertura.

### `coincidencias_emociones.csv`

Tabla detallada de evidencias. Puede tener varias filas por mensaje porque un mensaje puede activar varias emociones.


| Columna             | Significado                                         |
| --------------------- | ----------------------------------------------------- |
| `emocion`           | Categoría encontrada                               |
| `polaridad_valor`   | `1` positiva, `0` neutra, `-1` negativa             |
| `evidencia`         | Fragmento que produjo la coincidencia               |
| `tipo_coincidencia` | Término exacto, raíz, emoji o emoticono           |
| `confianza`         | Nivel técnico alta o media según el tipo de regla |

### `diccionario_sentimientos.csv`

Resume las 15 categorías del diccionario: definición, polaridad, cantidad de términos, cantidad de raíces y versión. No contiene todas las palabras porque las listas completas están en `R/funciones.R`.

### `resumen_emociones.csv`

Cuenta coincidencias por emoción y muestra qué proporción de mensajes representa cada conteo. Como un mensaje puede tener varias emociones, los porcentajes no tienen que sumar 100 %.

### `resumen_polaridad.csv`

Cuenta mensajes por polaridad automática. Aquí cada mensaje aparece una sola vez y los porcentajes sí suman 100 %.

### `resumen_por_gestion.csv`

Desglosa la polaridad automática por año. El porcentaje se calcula dentro de cada gestión.

### `resumen_mensual.csv`

Cuenta polaridades por mes. Se utiliza para la evolución temporal.

### `comparacion_cobertura.csv`

Compara el diccionario original del PDF con la ampliación contextual:

- `mensajes`: total analizado;
- `clasificados`: mensajes con evidencia;
- `sin_coincidencia`: mensajes sin evidencia;
- `cobertura`: clasificados dividido entre mensajes.

### `cobertura_por_gestion.csv`

Muestra la cobertura del diccionario ampliado en cada año. Permite comprobar si el vocabulario funciona de manera distinta entre gestiones.

### `resumen_tipo_coincidencia.csv`

Cuenta cuántas detecciones fueron por término exacto, raíz, emoji o emoticono y qué nivel de confianza técnica recibieron.

### `resumen_no_clasificados.csv`

Agrupa los mensajes sin coincidencia por diagnóstico operativo: pregunta no cubierta, contexto insuficiente, contenido informativo, solo enlace, sin señal conocida u otra razón disponible.

### `terminos_sin_clasificar.csv`

Presenta las 100 palabras más frecuentes en mensajes sin coincidencia, después de retirar stopwords. Sirve para descubrir vocabulario que podría incorporarse a una versión futura del diccionario. Una palabra no debe añadirse sin revisar ejemplos y contexto.

### `coocurrencia_emociones.csv`

Cuenta pares de emociones detectadas en un mismo mensaje. Sirve para estudiar combinaciones y casos potencialmente mixtos.

### `bitacora_ejecuciones.csv`

Registra cada ejecución del análisis:

- fecha y hora;
- cantidad de HTML;
- mensajes y coincidencias;
- intervalo temporal;
- huellas MD5 de las entradas.

La huella MD5 permite saber si se utilizó exactamente la misma exportación, aunque no es una medida de anonimización.

## 13. Explicación de los CSV de `resultados/mineria_dataset/`

### `distribucion_sentimientos.csv`

Cuenta mensajes por `sentimiento_1` manual.

### `distribucion_polaridad.csv`

Cuenta mensajes por `polaridad_manual`.

### `distribucion_temas.csv`

Cuenta mensajes por tema manual.

Estos tres archivos describen la muestra etiquetada. Debido al muestreo enriquecido no deben confundirse con porcentajes directos del chat completo.

### `terminos_por_sentimiento.csv`

Contiene las 15 palabras con mayor frecuencia en cada sentimiento:

- `sentimiento_1`: grupo manual;
- `palabra`: token;
- `frecuencia`: número de apariciones dentro del grupo agregado.

### `tfidf_por_sentimiento.csv`

Contiene los términos más distintivos de cada sentimiento. Un TF-IDF alto indica que el término tiene presencia proporcional importante en ese grupo y menor presencia en otros.

### `bigramas_por_sentimiento.csv`

Contiene las diez secuencias de dos tokens más frecuentes por sentimiento. Ayuda a observar frases como `no entiendo`, que una lista de palabras separadas no conserva.

### `asociaciones_sentimiento_tema.csv`

Estudia pares de sentimiento y tema.


| Columna         | Significado                                              |
| ----------------- | ---------------------------------------------------------- |
| `juntos`        | Mensajes donde aparece la combinación                   |
| `soporte`       | Proporción de todo el dataset con la combinación       |
| `n_sentimiento` | Frecuencia total del sentimiento                         |
| `n_tema`        | Frecuencia total del tema                                |
| `confianza`     | Proporción del sentimiento vinculada al tema            |
| `lift`          | Fuerza relativa de la asociación frente a independencia |

### `comparacion_manual_syuzhet.csv`

Tiene una fila por mensaje y compara:

- polaridad humana;
- puntaje numérico de `syuzhet`;
- signo del puntaje convertido a positiva, negativa o sin puntaje.

### `tabla_manual_syuzhet.csv`

Resume la comparación anterior como tabla de contingencia. Facilita observar acuerdos, contradicciones y mensajes sin puntaje.

## 14. Explicación de los CSV de `resultados/preprocesamiento/`

### `muestra_tokenizacion_limpieza_normalizacion.csv`

Muestra 100 mensajes elegidos con semilla fija y sus transformaciones:

1. `original`;
2. `limpieza_tm`;
3. `normalizacion`;
4. `tokens_quanteda`;
5. `raices_stemming`;
6. `puntaje_syuzhet`.

Es el mejor archivo para demostrar visualmente el preprocesamiento durante la defensa.

### `frecuencia_tokens_quanteda.csv`

Lista los 200 tokens más frecuentes después de tokenizar y retirar elementos no deseados.

### `frecuencia_raices_stemming.csv`

Lista las 200 raíces más frecuentes después del stemming. Se compara con el archivo anterior para explicar el efecto de agrupar variantes.

### `resumen_documentos_syuzhet.csv`

Tiene una fila por mensaje con:

- número total de tokens;
- número de términos diferentes;
- puntaje `syuzhet`;
- polaridad derivada del signo del puntaje.

### `resumen_matriz_documento_termino.csv`

Resume la DFM:

- `documentos`: número de filas;
- `terminos`: número de columnas;
- `celdas_no_cero`: combinaciones mensaje-término observadas;
- `dispersion`: proporción de celdas vacías.

Una dispersión muy alta es normal en minería de texto porque cada mensaje utiliza solo una pequeña parte de todo el vocabulario.

## 15. Archivos que no son CSV

### Archivos `.rds`

`matriz_documento_termino_quanteda.rds` y `matriz_documento_termino_manual.rds` guardan objetos R con las matrices documento-término. El formato RDS preserva la estructura dispersa y evita convertir una matriz grande en un CSV pesado.

Se cargan con:

```r
matriz <- readRDS("ruta/del/archivo.rds")
```

### Gráficos `.png`

Son representaciones visuales de distribuciones, evolución, cobertura, tokens y puntajes. Se generan automáticamente y pueden reconstruirse desde los CSV.

### Informe `.html`

Es la salida reproducible de `Informe_analisis_sentimientos.Rmd`. Combina explicación, tablas y gráficos. Debe regenerarse después de integrar los resultados manuales y el acuerdo A–B.

## 16. Resultados actuales que pueden mencionarse

### Corpus completo y reglas

- 21.546 mensajes de texto.
- 6.030 coincidencias emoción-mensaje; pueden existir varias por mensaje.
- Diccionario original: 2.034 mensajes clasificados, cobertura de 9,4 %.
- Diccionario ampliado: 5.299 mensajes clasificados, cobertura de 24,6 %.
- La ampliación añadió contexto, emojis y expresiones locales, pero no eliminó la falta de evidencia.

### Polaridad automática sobre todo el corpus

- 16.247 sin coincidencia: 75,4 %.
- 2.035 positivos: 9,4 %.
- 1.638 neutros: 7,6 %.
- 1.443 negativos: 6,7 %.
- 183 mixtos: 0,8 %.

Estos valores describen la salida de las reglas, no la prevalencia verdadera de sentimientos.

### Dataset manual A

- 1.085 filas completas y estructuralmente válidas.
- 458 sin sentimiento: 42,2 %.
- 251 negativas: 23,1 %.
- 155 positivas: 14,3 %.
- 142 neutras: 13,1 %.
- 53 ambiguas: 4,9 %.
- 26 mixtas: 2,4 %.

La muestra fue enriquecida por estratos, por lo que estos porcentajes describen la muestra y no deben extrapolarse directamente al corpus.

### Matriz documento-término

- 21.546 documentos.
- 10.421 términos.
- 117.268 celdas no vacías.
- Dispersión aproximada de 99,95 %.

## 17. Pendientes antes de considerar finalizado el trabajo

1. Corregir la coherencia interna de algunas etiquetas A:
   - cuatro casos con `tiene_sentimiento = no` pero polaridad diferente;
   - cinco casos con sentimiento presente e intensidad `0`;
   - limpiar sentimientos secundarios duplicados o usados como `sin_sentimiento`.
2. Completar `etiquetado_anotador_b.csv` de manera independiente.
3. Volver a ejecutar el control de calidad.
4. Revisar los desacuerdos A–B y construir etiquetas por consenso.
5. Añadir al informe la distribución manual, kappa y comparación reglas–manual.
6. Regenerar el HTML final.
7. Si se desean estimaciones para el corpus completo, calcular pesos por estrato.

## 18. Limitaciones que deben reconocerse en la defensa

- El lenguaje del chat contiene errores ortográficos, abreviaciones, modismos e ironía.
- Un término puede cambiar de sentido según el contexto.
- Las raíces amplían cobertura pero pueden producir falsos positivos.
- `syuzhet` suma palabras y no comprende por completo negación, ironía o contexto conversacional.
- Los mensajes se analizan principalmente de forma individual; parte del sentido depende de mensajes anteriores.
- La muestra manual está estratificada y reforzada, no es una muestra aleatoria simple.
- Los códigos de participantes reducen exposición, pero el texto sigue siendo información privada.
- El segundo anotador y el consenso todavía están pendientes.

Reconocer una limitación no debilita el proyecto: muestra que el grupo comprende qué puede y qué no puede concluirse.

## 19. Preguntas probables del docente

### ¿Por qué no usaron un modelo de machine learning?

Porque el objetivo de la materia y del proyecto es desarrollar el proceso de minería de datos: crear el corpus, limpiar, normalizar, tokenizar, construir un dataset propio, descubrir patrones y evaluar reglas interpretables. Un modelo requeriría primero un dataset confiable, que precisamente es uno de los productos del trabajo.

### ¿Cuál es la verdad de referencia?

Las etiquetas humanas revisadas y, cuando B esté completo, las etiquetas consensuadas. El diccionario y `syuzhet` son métodos automáticos que deben evaluarse contra esa referencia.

### ¿Por qué se creó un diccionario ampliado?

El vocabulario general del documento no cubría emojis, abreviaciones y expresiones habituales del chat. La ampliación elevó la cobertura de 9,4 % a 24,6 %, manteniendo evidencia trazable.

### ¿Mayor cobertura significa mayor exactitud?

No. Mayor cobertura significa que se clasifican más mensajes. La exactitud debe medirse comparando con el dataset manual mediante una matriz de confusión y métricas por categoría.

### ¿Por qué separar la referencia automática del etiquetado?

Para evitar que el anotador copie o sea influido por la sugerencia de la regla. Esto reduce sesgo de confirmación.

### ¿Por qué usar dos anotadores?

Porque los sentimientos pueden ser ambiguos. El acuerdo permite cuantificar la reproducibilidad de los criterios y localizar categorías que necesitan mejores definiciones.

### ¿Por qué la muestra tiene refuerzo de `sin_evidencia`?

Porque uno de los problemas centrales era entender esos mensajes. El refuerzo permite estudiar por qué las reglas no los detectan y descubrir vocabulario faltante.

### ¿Se puede decir que el 42,2 % de todo el chat no tiene sentimiento?

No. Ese porcentaje pertenece a una muestra enriquecida. Para estimar el corpus se necesitan pesos según el tamaño poblacional y muestral de cada estrato.

### ¿Qué aporta `tm` si también se usa `quanteda`?

`tm` demuestra la construcción y limpieza clásica de un corpus. `quanteda` aporta tokenización eficiente, stemming, DFM, agrupación y n-gramas. Se utilizan con fines complementarios.

### ¿Qué aporta `syuzhet`?

Proporciona un puntaje auxiliar reproducible usando el mismo léxico en español. Permite comparar un enfoque de suma de palabras con las etiquetas humanas, pero no reemplaza el etiquetado.

### ¿Cómo se protege la privacidad?

Los nombres se sustituyen por códigos, no se publican los HTML ni los CSV con texto y Git ignora las carpetas privadas. Los resultados que se compartan deben ser agregados y no mostrar conversaciones individuales.

## 20. Propuesta de reparto para la exposición

### Integrante 1: problema y datos

- contexto del chat;
- pregunta y objetivos;
- extracción HTML;
- privacidad y pseudonimización.

### Integrante 2: preprocesamiento

- limpieza con `tm`;
- normalización;
- tokenización, stopwords y stemming con `quanteda`;
- matriz documento-término.

### Integrante 3: reglas y dataset manual

- diccionario base y ampliado;
- emociones multilabel y polaridad;
- muestreo estratificado;
- libro de códigos y anotadores;
- kappa y consenso.

### Integrante 4: minería, resultados y limitaciones

- frecuencias, TF-IDF y bigramas;
- soporte, confianza y lift;
- comparación con `syuzhet`;
- resultados principales;
- limitaciones y trabajo pendiente.

Todos los integrantes deberían poder explicar por qué `sin coincidencia` no equivale a neutral y por qué la muestra manual no representa directamente la prevalencia del corpus.

## 21. Orden de ejecución

Desde la raíz del proyecto:

```bash
Rscript scripts/00_instalar_paquetes.R
Rscript scripts/01_ejecutar_analisis.R
Rscript scripts/02_generar_dataset_manual.R
# Completar A y B sin consultar la referencia automática
Rscript scripts/03_validar_dataset_manual.R
Rscript scripts/04_mineria_descriptiva.R
Rscript scripts/05_preprocesamiento_librerias.R
```

Para regenerar únicamente el informe:

```r
rmarkdown::render("informe/Informe_analisis_sentimientos.Rmd")
```

## 22. Idea central para cerrar la defensa

El resultado más importante no es solamente una gráfica de positivo o negativo. El proyecto entrega un proceso auditable: corpus pseudonimizado, transformaciones observables, reglas con evidencia, medición de cobertura, dataset manual propio y mecanismos de validación. Esa trazabilidad permite saber de dónde sale cada resultado y reconocer con claridad sus límites.
