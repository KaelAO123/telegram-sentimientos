# Guía para comprender y defender el proyecto

## 1. Propósito de esta guía

Esta documentación permite que cualquier integrante del grupo pueda explicar:

- qué problema resuelve el proyecto;
- cómo circulan los datos desde Telegram hasta los resultados;
- para qué sirve cada archivo de código;
- qué hacen `tm`, `quanteda` y `syuzhet`;
- qué contiene cada CSV;
- por qué se comparan diccionario, TF-IDF, MiniLM y el modelo híbrido;
- cómo funcionan la validación cruzada agrupada y la clasificación multietiqueta;
- cómo interpretar precisión, recall, macro-F1, micro-F1, kappa y Hamming loss;
- cómo leer cada pantalla del dashboard;
- cómo interpretar los resultados sin confundir reglas, etiquetas humanas y predicciones;
- cuáles son las limitaciones, las decisiones metodológicas y los posibles errores.

Los datos numéricos de la sección de resultados corresponden a la ejecución final del 26 de octubre de 2026.

## 2. Explicación corta para iniciar la defensa

> El proyecto analiza sentimientos en el chat de temporada de Informática de la UMSA. Extraemos y pseudonimizamos 21.546 mensajes, limpiamos y tokenizamos el texto y aplicamos un diccionario interpretable. Construimos una muestra de 1.085 mensajes con dos anotaciones y adjudicación de desacuerdos. Comparamos reglas, TF-IDF, embeddings MiniLM y un modelo híbrido mediante validación cruzada agrupada. El híbrido obtiene el mejor macro-F1 y se utiliza para generar resultados agregados del corpus completo sin publicar textos ni participantes.

## 3. Pregunta, objetivo y alcance

### Pregunta central

¿Qué polaridades, emociones, temas y patrones textuales aparecen en el chat de
temporada, y qué tan bien pueden identificarlos las reglas, TF-IDF, embeddings
semánticos y una representación híbrida evaluados contra etiquetas humanas?

### Objetivo general

Construir un proceso reproducible de minería de texto que transforme una
exportación de Telegram en un corpus pseudonimizado, un dataset etiquetado por
personas, modelos evaluados fuera de muestra y resultados agregados que puedan
interpretarse sin exponer conversaciones individuales.

### Qué sí hace el proyecto

- Procesa 21.546 mensajes de texto.
- Conserva fechas, horas y códigos de participantes para análisis agregados.
- Limpia y normaliza el contenido textual.
- Tokeniza y crea matrices documento-término.
- Detecta evidencia de 15 categorías del diccionario mediante reglas interpretables.
- Modela diez emociones con soporte suficiente mediante clasificación multietiqueta.
- Compara el diccionario original con una ampliación contextual.
- Genera una muestra estratificada para etiquetado humano.
- Calcula frecuencias, TF-IDF, bigramas y asociaciones descriptivas.
- Usa `syuzhet` con un léxico propio en español como referencia auxiliar.
- Calcula kappa entre dos anotaciones independientes y conserva la adjudicación.
- Evalúa diccionario, TF-IDF, MiniLM y un modelo híbrido en cinco folds.
- Clasifica el corpus completo y exporta únicamente resultados sin texto ni participantes.

### Qué no hace

- No diagnostica el estado psicológico de los participantes.
- No ajusta internamente los pesos de MiniLM: utiliza embeddings congelados y regresión logística.
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
                       Validación + adjudicación
                                      │
                                      ▼
                    Validación cruzada TF-IDF/MiniLM
                                      │
                                      ▼
                     Modelo híbrido + informe final
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

### Polaridad y emoción no son lo mismo

La **polaridad** resume la orientación global de un mensaje. En el proyecto tiene
seis clases mutuamente excluyentes:

- `positiva`;
- `negativa`;
- `neutra`;
- `mixta`;
- `ambigua`;
- `sin_sentimiento`.

La **emoción** es más específica. El modelo final trabaja con diez emociones:

1. admiración;
2. alegría;
3. confusión;
4. curiosidad;
5. decepción;
6. enojo;
7. esperanza;
8. gratitud;
9. preocupación;
10. tristeza.

El diccionario exploratorio conserva 15 categorías: alegría, gratitud, esperanza,
amor, admiración, tranquilidad, sorpresa, confusión, preocupación, tristeza,
enojo, decepción, cansancio, vergüenza y curiosidad. Para el modelo se conservaron
las diez con soporte mínimo suficiente en las etiquetas finales. Amor,
tranquilidad, sorpresa, cansancio y vergüenza continúan siendo útiles en el análisis
por reglas, pero no se entrenaron como salidas del clasificador final.

Un mensaje tiene una sola polaridad, pero puede tener varias emociones. Por
ejemplo, una consulta puede expresar curiosidad y preocupación simultáneamente.
Por eso la polaridad es una tarea **multiclase** y las emociones son una tarea
**multietiqueta**.

### `neutra` y `sin_sentimiento`

No deben tratarse como sinónimos:

- `neutra`: existe contenido evaluable, pero no predomina una orientación positiva
  o negativa;
- `sin_sentimiento`: el mensaje es principalmente informativo o no existe señal
  afectiva suficiente;
- `ambigua`: sí puede existir una señal, pero no hay evidencia suficiente para
  decidir su orientación;
- `mixta`: coexisten señales positivas y negativas.

### Verdad de referencia u objetivo

Es la etiqueta contra la cual se evalúan los modelos. En este proyecto no proviene
del diccionario ni de MiniLM: proviene de las decisiones de los anotadores A y B,
seguidas de adjudicación cuando existía desacuerdo. Las columnas finales son
`polaridad_objetivo` y `sentimientos_objetivo`.

### Adjudicación

Es la revisión final de los desacuerdos entre A y B. No borra las decisiones
originales: las conserva para auditoría y crea una tercera decisión documentada.
El resultado es `dataset_modelado_umsa.csv`, con 1.085 objetivos completos.

### Precisión, recall y F1

Para una clase determinada:

```text
precisión = verdaderos positivos / predicciones positivas
recall    = verdaderos positivos / positivos reales
F1        = 2 × precisión × recall / (precisión + recall)
```

- precisión alta: cuando el modelo predice la clase, suele acertar;
- recall alto: encuentra gran parte de los casos reales de la clase;
- F1: equilibra ambas medidas.

Un modelo puede obtener recall alto y precisión baja si predice una emoción con
demasiada frecuencia.

### Macro-F1 y micro-F1

- **Macro-F1:** calcula F1 por clase y luego promedia dando el mismo peso a todas.
  Es la medida principal del proyecto porque hay clases desbalanceadas.
- **Micro-F1:** suma primero todos los aciertos y errores. Las clases frecuentes
  influyen más en el resultado.

Si micro-F1 es mayor que macro-F1, normalmente el modelo funciona mejor en las
clases abundantes que en las minoritarias.

### Accuracy y balanced accuracy

- **Accuracy:** proporción total de predicciones correctas.
- **Balanced accuracy:** promedio del recall de las clases; reduce el efecto de la
  clase mayoritaria.

En polaridad, un baseline que siempre diga `sin_sentimiento` alcanza accuracy de
0,422 porque esa clase representa 458 de las 1.085 etiquetas. Sin embargo, su
macro-F1 es solo 0,099 porque ignora las otras cinco clases.

### Hamming loss y exact match en multietiqueta

- **Hamming loss:** proporción de decisiones etiqueta-mensaje incorrectas. Menor
  es mejor.
- **Exact match accuracy:** exige que el conjunto completo de emociones coincida.
  Si acierta una emoción y falla otra, la fila completa cuenta como incorrecta.

Por eso la accuracy multietiqueta puede parecer baja incluso cuando parte del
conjunto emocional fue reconocido.

### Matriz de confusión

Las filas representan la etiqueta humana real y las columnas la predicción. La
diagonal contiene aciertos. Los valores fuera de la diagonal muestran qué clases
se confunden; por ejemplo, `neutra` con `sin_sentimiento` o `ambigua` con otras
polaridades.

### Validación cruzada y predicciones OOF

La validación cruzada divide los 1.085 ejemplos en cinco particiones. En cada
vuelta se entrena con cuatro y se prueba con la quinta. Cada fila recibe una
predicción **out-of-fold (OOF)** cuando no participó en el entrenamiento. Al juntar
las cinco partes se evalúa todo el dataset sin medir sobre los mismos ejemplos con
los que se entrenó.

### Agrupación de textos duplicados

La muestra tiene 1.085 filas, pero 1.008 grupos de texto normalizado; existen 77
repeticiones adicionales. El proyecto utiliza el hash SHA-256 del texto como grupo
en `StratifiedGroupKFold`. Todas las copias de un texto quedan juntas en
entrenamiento o prueba. Esto evita **fuga de información**.

### TF-IDF como representación para el modelo

Además de servir para análisis descriptivo, TF-IDF convierte cada mensaje en un
vector disperso de unigramas y bigramas. La configuración usa:

- `ngram_range=(1, 2)`;
- `min_df=2`;
- máximo de 30.000 características;
- frecuencia sublineal.

Su ventaja es reconocer vocabulario local. Su debilidad es que dos frases con
significado parecido pueden quedar lejos si usan palabras diferentes.

### Embeddings MiniLM

Un embedding es un vector numérico denso que representa el significado aproximado
de un texto. Se utiliza
`paraphrase-multilingual-MiniLM-L12-v2`, preparado para varios idiomas. Los
embeddings se normalizan y permanecen congelados: el proyecto no modifica los
pesos internos de MiniLM.

### Modelo híbrido

Concatena el vector TF-IDF y el embedding MiniLM:

```text
mensaje → [TF-IDF | embedding MiniLM] → regresión logística
```

TF-IDF aporta vocabulario específico del chat; MiniLM aporta información semántica.
La combinación obtuvo el mayor macro-F1 en polaridad y emociones.

### Regresión logística y One-vs-Rest

Para polaridad se entrena una regresión logística multiclase. Para emociones se
entrena un clasificador independiente por emoción mediante `OneVsRestClassifier`.
Cada emoción produce una probabilidad y se activa cuando es mayor o igual a 0,5.
Si ninguna supera el umbral, la salida se registra como `sin_sentimiento`.

### Confianza del modelo

`confianza_polaridad` es la mayor probabilidad estimada entre las clases de
polaridad. `confianza_emocion_max` es la mayor probabilidad entre las diez
emociones. No significan certeza absoluta ni acuerdo humano: son salidas internas
del clasificador y deben calibrarse antes de interpretarlas como probabilidades
reales.

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
| `pandas`, `numpy`    | Leer tablas y construir arreglos para el modelado             |
| `scikit-learn`       | TF-IDF, regresión logística, folds y métricas                 |
| `sentence-transformers` | Generar embeddings multilingües con MiniLM                 |
| `scipy.sparse`       | Concatenar TF-IDF disperso con embeddings densos              |
| `matplotlib`         | Crear gráficos de evaluación y del modelo final               |
| `joblib`             | Guardar vectorizador, clasificadores y codificador             |

## 7. Organización general del proyecto


| Ruta                           | Para qué sirve                                                      |
| -------------------------------- | ---------------------------------------------------------------------- |
| `ChatExport_*/`                | Entrada privada de Telegram; no debe subirse a Git                   |
| `sentimientos_documento.pdf`   | Documento metodológico y fuente inicial de las 15 categorías       |
| `configuracion.R`              | Centraliza rutas, años seleccionados y zona horaria                 |
| `R/`                           | Funciones reutilizables; aquí está la lógica del análisis        |
| `scripts/`                     | Programas ejecutables en el orden `00` a `10`                        |
| `datos/dataset_manual/`        | Corpus pseudonimizado, plantillas, validación y dataset manual      |
| `resultados/datos/`            | Resultados del análisis automático del corpus completo             |
| `resultados/preprocesamiento/` | Evidencias de limpieza, tokenización, stemming y DFM                |
| `resultados/mineria_dataset/`  | Minería descriptiva del dataset etiquetado manualmente              |
| `resultados/graficos*/`        | Imágenes creadas por los scripts                                    |
| `resultados/validacion_cruzada/` | Métricas OOF, folds, clases y gráficos de comparación             |
| `resultados/modelo_final/`     | Predicciones agregables y artefactos del modelo híbrido              |
| `informe/`                     | Fuentes Markdown/R Markdown, estilos, dashboard e informes locales   |
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

El dataset descriptivo conserva A por compatibilidad. En paralelo, el script crea
el consenso A/B y mantiene sincronizadas las plantillas de adjudicación sin borrar
decisiones existentes.

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

### `scripts/06_corregir_etiquetado_b.R` y `07_consolidar_adjudicaciones.R`

El script 06 aplica correcciones mecánicas documentadas al archivo del anotador B.
Su finalidad es normalizar errores de formato o consistencia previamente
identificados, sin inventar nuevas decisiones emocionales. Conserva una tabla de
correcciones para que el cambio sea auditable.

El script 07:

1. lee el consenso y la plantilla de adjudicación;
2. comprueba que todas las discrepancias obligatorias tengan decisión;
3. valida polaridades y emociones permitidas;
4. conserva la decisión de A y B;
5. elige acuerdo A/B cuando coinciden;
6. utiliza la adjudicación cuando difieren;
7. crea `polaridad_objetivo` y `sentimientos_objetivo`;
8. registra si cada objetivo proviene de acuerdo o adjudicación;
9. detiene la ejecución si todavía falta alguna decisión;
10. exporta `dataset_modelado_umsa.csv`.

El resultado tiene 638 polaridades provenientes de acuerdo y 447 adjudicadas. En
emociones hay 481 acuerdos exactos y 604 adjudicaciones.

### `scripts/08_modelo_embeddings.py` y `09_validacion_cruzada.py`

El script 08 es un benchmark exploratorio. Permite comprobar que el dataset, TF-IDF,
MiniLM, la regresión logística y la tarea multietiqueta funcionan antes de ejecutar
el experimento completo. No es la evaluación final porque utiliza una sola
separación de entrenamiento y prueba.

El script 09 realiza la evaluación oficial:

1. exige `dataset_modelado_umsa.csv`;
2. normaliza las URL y espacios sin eliminar información semántica importante;
3. agrupa textos iguales mediante SHA-256;
4. selecciona emociones con soporte mínimo de 20;
5. binariza las diez emociones con `MultiLabelBinarizer`;
6. calcula MiniLM una sola vez para las 1.085 filas;
7. crea cinco folds con `StratifiedGroupKFold`;
8. ajusta TF-IDF únicamente con el entrenamiento de cada fold;
9. compara baseline, diccionario, TF-IDF, MiniLM e híbrido;
10. genera predicciones OOF para todas las filas;
11. calcula métricas globales, por fold y por clase;
12. selecciona el mejor modelo aprendido por macro-F1;
13. crea gráficos y guarda la configuración final.

La regresión logística utiliza `class_weight="balanced"`, `solver="lbfgs"`,
`max_iter=3000` y semilla `20261026`.

### `scripts/10_clasificar_corpus.py`

Entrena el híbrido ganador con las 1.085 etiquetas y lo aplica a los 21.546
mensajes:

1. comprueba que la validación cruzada seleccionó el híbrido;
2. ajusta TF-IDF con las 1.085 filas etiquetadas;
3. calcula embeddings para entrenamiento y corpus;
4. concatena ambas representaciones;
5. entrena el clasificador de polaridad;
6. entrena diez clasificadores One-vs-Rest para emociones;
7. aplica el umbral emocional de 0,5;
8. exporta predicciones sin texto ni participante;
9. crea resúmenes por polaridad, emoción, gestión y mes;
10. genera dos gráficos agregados;
11. guarda los artefactos con `joblib` y la configuración JSON.

La salida conserva ID, gestión, fecha, hora, predicciones y confianza. Esto permite
auditar y agregar resultados sin publicar el contenido del mensaje.

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

Segunda plantilla con los mismos 1.085 mensajes, completada independientemente para medir acuerdo y detectar categorías ambiguas.

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

`dataset_sentimientos_umsa.csv` conserva A por compatibilidad; el consenso definitivo
para modelado es `dataset_modelado_umsa.csv`.

### `dataset_consenso_umsa.csv`, `desacuerdos_modelado.csv` y `dataset_modelado_umsa.csv`

El primero registra acuerdos y desacuerdos A/B. El segundo contiene la revisión de
los casos discrepantes. El tercero es la referencia final de 1.085 filas, sin objetivos
vacíos, utilizada en validación cruzada y entrenamiento.

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

## 14. Resultados de validación cruzada y modelo final

En `resultados/validacion_cruzada/`:

- `comparacion_modelos.csv`: métricas agregadas de las predicciones fuera de muestra;
- `metricas_por_fold.csv` y `resumen_folds.csv`: variación entre los cinco folds;
- `metricas_por_clase.csv`: precisión, exhaustividad y F1 por polaridad o emoción;
- `predicciones_oof_privadas.csv`: auditoría por ID, sin texto;
- `graficos/`: comparación macro-F1, matriz de confusión y F1 por emoción.

En `resultados/modelo_final/`:

- `predicciones_corpus.csv`: predicción para 21.546 IDs sin texto ni participante;
- `resumen_polaridad.csv` y `resumen_emociones.csv`: resultados agregados;
- `polaridad_por_gestion.csv` y `polaridad_por_mes.csv`: evolución temporal;
- `artefactos/`: vectorizador y clasificadores reproducibles;
- `configuracion_modelo_final.json`: modelo, umbral y categorías utilizadas.

### Comparación OOF de polaridad

| Modelo | Accuracy | Balanced accuracy | Macro-F1 |
|---|---:|---:|---:|
| Baseline mayoritario | 0,422 | 0,167 | 0,099 |
| Diccionario de reglas | **0,540** | 0,376 | 0,354 |
| TF-IDF + logística | 0,399 | 0,319 | 0,305 |
| MiniLM + logística | 0,471 | 0,382 | 0,369 |
| **Híbrido TF-IDF + MiniLM** | 0,530 | **0,401** | **0,393** |

El diccionario alcanza la mayor accuracy porque funciona bien en algunas clases
frecuentes, pero el híbrido obtiene el mejor macro-F1 y balanced accuracy. Por eso
se selecciona el híbrido: distribuye mejor su capacidad entre las seis polaridades.

### Comparación OOF de emociones

| Modelo | Exact match | Macro-F1 | Micro-F1 | Hamming loss |
|---|---:|---:|---:|---:|
| Baseline sin emoción | 0,492 | 0,000 | 0,000 | 0,052 |
| Diccionario de reglas | **0,478** | 0,333 | 0,323 | 0,071 |
| TF-IDF + logística | 0,386 | 0,312 | 0,325 | 0,091 |
| MiniLM + logística | 0,291 | 0,336 | 0,340 | 0,133 |
| **Híbrido TF-IDF + MiniLM** | 0,444 | **0,375** | **0,382** | 0,088 |

El baseline parece tener exact match alto porque casi la mitad de las filas no tiene
ninguna de las diez emociones. Sin embargo, su macro-F1 y micro-F1 son cero: nunca
encuentra una emoción. Esta es una demostración de por qué no debe elegirse un
modelo usando solamente accuracy.

### F1 del híbrido por emoción

| Emoción | Soporte | Precisión | Recall | F1 |
|---|---:|---:|---:|---:|
| Gratitud | 43 | 0,878 | 0,837 | **0,857** |
| Admiración | 24 | 0,516 | 0,667 | 0,582 |
| Curiosidad | 143 | 0,434 | 0,643 | 0,518 |
| Preocupación | 108 | 0,314 | 0,546 | 0,399 |
| Decepción | 60 | 0,246 | 0,517 | 0,333 |
| Alegría | 28 | 0,225 | 0,571 | 0,323 |
| Tristeza | 29 | 0,148 | 0,586 | 0,236 |
| Esperanza | 51 | 0,167 | 0,216 | 0,188 |
| Enojo | 24 | 0,154 | 0,167 | 0,160 |
| Confusión | 52 | 0,120 | 0,231 | 0,158 |

La variación demuestra que un único macro-F1 no cuenta toda la historia. Gratitud
es reconocida con mucha mayor estabilidad que confusión o enojo. Las emociones con
poco soporte y expresiones lingüísticas variadas siguen siendo las más difíciles.

### Métrica OOF y promedio de folds

`comparacion_modelos.csv` calcula una métrica final juntando todas las predicciones
OOF. `resumen_folds.csv` calcula la media y desviación estándar de las cinco
particiones. Los valores son cercanos, pero no tienen que ser idénticos porque los
folds pueden tener tamaños ligeramente diferentes. Para el resumen del proyecto se
utiliza la métrica OOF sobre las 1.085 filas.

## 15. Explicación de los CSV de `resultados/preprocesamiento/`

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

## 16. Archivos que no son CSV

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

### Dashboard interactivo

`informe/Dashboard_Data_Mining.html` es una aplicación autónoma: contiene HTML,
CSS, JavaScript y datos agregados en un solo archivo. No necesita Internet y no
incluye texto de mensajes ni participantes.

Sus cinco vistas sirven para:

1. **Resumen:** presentar tamaño del corpus, muestra, número de emociones y mejor
   macro-F1.
2. **Polaridad:** comparar las seis clases y su evolución por gestión.
3. **Emociones:** mostrar las diez emociones y su F1 por clase.
4. **Modelos:** explicar por qué ganó TF-IDF + MiniLM.
5. **Calidad y límites:** presentar kappa, Jaccard, cobertura, controles y
   limitaciones.

El filtro de gestión modifica los conteos del corpus, pero no cambia las métricas
del modelo, porque estas se calcularon una sola vez sobre el dataset manual
completo. El botón CSV descarga la tabla de la vista actual y el botón PDF utiliza
la función de impresión del navegador.

### Fuentes editables del informe

- `Informe_defensa_Data_Mining.md`: fuente principal del contenido detallado;
- `Informe_final_Data_Mining.Rmd`: alternativa reproducible desde R;
- `estilo_dashboard.css`: presentación del informe HTML;
- `Bitacora_Data_Mining.md`: fuente de la bitácora;
- `estilo_bitacora.css`: diseño de la bitácora HTML.

El DOCX sirve para edición visual final, pero los cambios hechos en Word no se
sincronizan automáticamente con Markdown.

## 17. Resultados actuales que pueden mencionarse

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

### Dataset manual adjudicado

- 1.085 filas completas y estructuralmente válidas.
- 458 sin sentimiento: 42,2 %.
- 251 negativas: 23,1 %.
- 155 positivas: 14,3 %.
- 142 neutras: 13,1 %.
- 53 ambiguas: 4,9 %.
- 26 mixtas: 2,4 %.

La muestra fue enriquecida por estratos, por lo que estos porcentajes describen la muestra y no deben extrapolarse directamente al corpus.

### Acuerdo y modelos

- A y B tienen 1.085 etiquetas completas y válidas.
- Antes de adjudicar, kappa es 0,418 para polaridad y 0,432 para emoción principal.
- El híbrido TF-IDF+MiniLM obtiene macro-F1 de 0,393 en polaridad y 0,375 en diez emociones.
- El diccionario obtiene 0,354 y 0,333, respectivamente, y se conserva como baseline interpretable.
- La evaluación usa predicciones fuera de muestra de cinco folds y separa textos duplicados por grupo.

### Predicción del corpus completo

- 8.974 mensajes sin sentimiento predicho: 41,7 %.
- 5.055 neutros: 23,5 %.
- 3.694 negativos: 17,1 %.
- 2.378 positivos: 11,0 %.
- 1.030 ambiguos: 4,8 %.
- 415 mixtos: 1,9 %.

Estas cantidades son estimaciones del modelo, no etiquetas humanas ni diagnósticos.

### Emociones predichas en el corpus completo

| Categoría | Mensajes | % del corpus |
|---|---:|---:|
| Sin sentimiento | 8.919 | 41,4 % |
| Curiosidad | 5.558 | 25,8 % |
| Preocupación | 2.280 | 10,6 % |
| Tristeza | 1.783 | 8,3 % |
| Confusión | 1.531 | 7,1 % |
| Decepción | 1.309 | 6,1 % |
| Esperanza | 879 | 4,1 % |
| Gratitud | 731 | 3,4 % |
| Alegría | 694 | 3,2 % |
| Admiración | 513 | 2,4 % |
| Enojo | 467 | 2,2 % |

Los porcentajes emocionales no suman 100 % porque un mensaje puede activar más de
una emoción. `sin_sentimiento` se usa cuando ninguna probabilidad emocional supera
el umbral de 0,5.

### Matriz documento-término

- 21.546 documentos.
- 10.421 términos.
- 117.268 celdas no vacías.
- Dispersión aproximada de 99,95 %.

## 18. Comprobaciones antes de la entrega y exposición

1. Abrir `Dashboard_Data_Mining.html` y probar navegación, filtro y descarga CSV.
2. Abrir el PDF y comprobar carátula, nombres, docente, paralelo y fecha.
3. Confirmar que el RAR contiene dataset, código R/Python, informe, bitácora,
   dashboard y resultados necesarios.
4. Ejecutar la prueba de integridad del RAR.
5. Ensayar la interpretación de macro-F1, micro-F1, kappa y matriz de confusión.
6. Acordar quién explicará cada parte y cómo se realizará el cambio de expositor.
7. Mantener la exportación original y los CSV con texto fuera de un GitHub público.
8. Llevar una copia local del dashboard porque funciona sin Internet.

## 19. Limitaciones que deben reconocerse en la defensa

- El lenguaje del chat contiene errores ortográficos, abreviaciones, modismos e ironía.
- Un término puede cambiar de sentido según el contexto.
- Las raíces amplían cobertura pero pueden producir falsos positivos.
- `syuzhet` suma palabras y no comprende por completo negación, ironía o contexto conversacional.
- Los mensajes se analizan principalmente de forma individual; parte del sentido depende de mensajes anteriores.
- La muestra manual está estratificada y reforzada, no es una muestra aleatoria simple.
- Los códigos de participantes reducen exposición, pero el texto sigue siendo información privada.
- Algunas emociones siguen teniendo pocos ejemplos, aunque se modelan diez con soporte mínimo de veinte casos.
- La muestra fue enriquecida con señales del diccionario; las prevalencias del modelo son exploratorias.

Reconocer una limitación no debilita el proyecto: muestra que el grupo comprende qué puede y qué no puede concluirse.

## 20. Preguntas probables del docente

### ¿Qué modelo de machine learning utilizaron y por qué?

Se compararon regresiones logísticas sobre TF-IDF, embeddings MiniLM congelados y
la concatenación de ambas representaciones. El híbrido fue elegido porque obtuvo el
mejor macro-F1 fuera de muestra en las dos tareas. No se hizo *fine-tuning* de una
red neuronal porque el dataset es pequeño y se prefirió un modelo más reproducible.

### ¿Cuál es la verdad de referencia?

Las etiquetas humanas de A y B después de adjudicar los desacuerdos. El diccionario,
`syuzhet` y los clasificadores se evalúan contra esa referencia.

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

### ¿Por qué el diccionario tiene 15 categorías y el modelo solo diez emociones?

El diccionario conserva las categorías metodológicas originales y sirve para
exploración. Para entrenar modelos se exigió un soporte mínimo de 20 casos. Se
excluyeron metacategorías como `sin_sentimiento`, `ambiguo` y `otro`, y se
modelaron las diez emociones con evidencia suficiente. No se eliminaron para
mejorar artificialmente el resultado: se aplicó una regla de soporte explícita.

### ¿Qué es un embedding explicado de forma sencilla?

Es una lista de números que resume el significado aproximado de un texto. Frases
con significado parecido pueden obtener vectores cercanos aunque no compartan las
mismas palabras. En este proyecto se usa MiniLM multilingüe.

### ¿MiniLM es el clasificador final?

No por sí solo. MiniLM genera la representación semántica. La clasificación la
realiza una regresión logística entrenada con las etiquetas del proyecto. El modelo
ganador concatena MiniLM con TF-IDF.

### ¿Por qué no se hizo fine-tuning de un transformer?

El dataset tiene 1.085 filas y varias clases minoritarias. Ajustar toda una red
neuronal aumentaría costo, riesgo de sobreajuste y dificultad de reproducción. Los
embeddings congelados con un clasificador lineal ofrecen una comparación más
estable y apropiada para el tamaño del proyecto.

### ¿Por qué el macro-F1 no es más alto?

La tarea contiene lenguaje informal, mensajes cortos, contexto perdido, ironía,
errores ortográficos y clases con pocos ejemplos. Además, el macro-F1 penaliza que
el modelo falle en `mixta`, `ambigua` y emociones minoritarias. El valor moderado se
declara como limitación; no se oculta detrás de la accuracy.

### ¿Por qué elegir el híbrido si el diccionario tiene mayor accuracy en polaridad?

Porque la accuracy favorece clases frecuentes. El híbrido tiene mayor macro-F1
(0,393 frente a 0,354) y balanced accuracy (0,401 frente a 0,376), por lo que se
comporta mejor de manera equilibrada entre las seis polaridades.

### ¿Por qué el baseline emocional tiene accuracy de 0,492 y F1 igual a cero?

El baseline siempre predice ausencia de emociones. Acertará las filas que realmente
no tienen ninguna, pero nunca detectará una emoción positiva. Por eso el exact match
parece alto mientras macro-F1 y micro-F1 son cero.

### ¿Cómo se evitó que mensajes repetidos inflaran el resultado?

Los textos normalizados se agruparon por hash SHA-256. `StratifiedGroupKFold`
mantiene todas las copias del mismo texto en el mismo lado del fold. Así, el modelo
no puede memorizar una copia en entrenamiento y recibir otra idéntica en prueba.

### ¿Por qué se usan cinco folds?

Permiten que cada fila se evalúe una vez fuera de muestra y aprovechan mejor un
dataset pequeño que una única división. Cinco ofrece un equilibrio entre estabilidad
y tiempo de cómputo.

### ¿Qué significa el umbral emocional de 0,5?

Cada uno de los diez clasificadores devuelve una puntuación. Una emoción se activa
si su valor es al menos 0,5. Si ninguna supera el umbral, se registra
`sin_sentimiento`. Cambiar el umbral modifica el equilibrio entre precisión y recall,
por lo que debe volver a evaluarse y no cambiarse solo para obtener más etiquetas.

### ¿Las predicciones del corpus son la verdad?

No. Son estimaciones del modelo entrenado con 1.085 etiquetas. Sirven para análisis
agregado y exploratorio. No sustituyen una revisión humana y no deben usarse para
evaluar personas.

### ¿Por qué las emociones del dashboard no suman 100 %?

Porque la tarea es multietiqueta. Un mensaje puede contribuir simultáneamente a
curiosidad y preocupación. La polaridad sí suma 100 % porque asigna una sola clase
por mensaje.

### ¿Por qué se llama Temporada 2026 si existen mensajes desde 2022?

Ese es el nombre actual del grupo exportado, pero Telegram conserva su historial.
El corpus cubre del 16 de diciembre de 2022 al 12 de octubre de 2026 y el dashboard
permite filtrar cada gestión.

## 21. Propuesta de reparto para la exposición

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
- validación cruzada, modelo híbrido y resultados principales;
- limitaciones y trabajo pendiente.

Todos los integrantes deberían poder explicar por qué `sin coincidencia` no equivale a neutral y por qué la muestra manual no representa directamente la prevalencia del corpus.

## 22. Orden de ejecución

Desde la raíz del proyecto:

```bash
Rscript scripts/00_instalar_paquetes.R
Rscript scripts/01_ejecutar_analisis.R
Rscript scripts/02_generar_dataset_manual.R
# Completar A y B sin consultar la referencia automática
Rscript scripts/06_corregir_etiquetado_b.R
Rscript scripts/03_validar_dataset_manual.R
Rscript scripts/07_consolidar_adjudicaciones.R
Rscript scripts/04_mineria_descriptiva.R
Rscript scripts/05_preprocesamiento_librerias.R
python3 -m venv .venv-embeddings
.venv-embeddings/bin/pip install -r requirements-embeddings.txt
# Benchmark exploratorio opcional
.venv-embeddings/bin/python scripts/08_modelo_embeddings.py
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 .venv-embeddings/bin/python scripts/09_validacion_cruzada.py
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 .venv-embeddings/bin/python scripts/10_clasificar_corpus.py --batch-size 256
```

Para regenerar únicamente el informe:

```r
rmarkdown::render("informe/Informe_analisis_sentimientos.Rmd")
```

Para abrir el dashboard no se requiere servidor:

```text
informe/Dashboard_Data_Mining.html
```

Se abre directamente en Chrome o Firefox.

## 23. Idea central para cerrar la defensa

El resultado más importante no es solamente una gráfica de positivo o negativo. El
proyecto entrega un proceso auditable: corpus pseudonimizado, transformaciones
observables, reglas con evidencia, doble etiquetado, adjudicación, validación cruzada
sin fuga de duplicados y predicciones agregadas sin texto. Esa trazabilidad permite
saber de dónde sale cada resultado y reconocer con claridad sus límites.

## 24. Mapa rápido: entrada, proceso y salida de cada script

| Script | Entrada principal | Qué hace | Salida principal |
|---|---|---|---|
| `00_instalar_paquetes.R` | Lista de dependencias | Comprueba e instala paquetes de R | Entorno preparado |
| `01_ejecutar_analisis.R` | `ChatExport_*/messages*.html` | Extrae, pseudonimiza, aplica reglas y resume | `resultados/datos/` y gráficos |
| `02_generar_dataset_manual.R` | Mensajes clasificados | Diseña muestra y separa referencia automática | Plantillas A/B y diseño muestral |
| `03_validar_dataset_manual.R` | Etiquetados A/B | Valida campos, mide acuerdo y prepara consenso | Calidad, errores, consenso y desacuerdos |
| `04_mineria_descriptiva.R` | Dataset manual válido | Frecuencias, TF-IDF, bigramas y asociaciones | `resultados/mineria_dataset/` |
| `05_preprocesamiento_librerias.R` | Corpus anonimizado | Demuestra `tm`, `quanteda`, stemming, DFM y `syuzhet` | `resultados/preprocesamiento/` |
| `06_corregir_etiquetado_b.R` | Plantilla B y correcciones | Aplica correcciones mecánicas auditables | B corregido y registro de cambios |
| `07_consolidar_adjudicaciones.R` | Consenso y adjudicación | Construye los objetivos finales | `dataset_modelado_umsa.csv` |
| `08_modelo_embeddings.py` | Dataset final o consenso | Benchmark exploratorio de una partición | `resultados/modelos_embeddings/` |
| `09_validacion_cruzada.py` | Dataset final | Cinco folds agrupados y selección de modelo | `resultados/validacion_cruzada/` |
| `10_clasificar_corpus.py` | Dataset final, corpus y configuración CV | Entrena híbrido y predice todo el corpus | `resultados/modelo_final/` |

Una forma sencilla de memorizar el flujo es:

```text
extraer → preparar muestra → anotar → validar → adjudicar
        → describir → comparar modelos → clasificar corpus → comunicar
```

## 25. Guion sugerido para presentar el dashboard

### Vista 1: Resumen ejecutivo

Frase sugerida:

> Analizamos 21.546 mensajes históricos del grupo entre 2022 y 2026. Para no
> depender únicamente de un diccionario, construimos 1.085 etiquetas humanas con
> dos anotadores y adjudicación. Evaluamos seis polaridades y diez emociones.

Señalar las cuatro tarjetas:

- 21.546 mensajes;
- 1.085 ejemplos manuales;
- diez emociones;
- macro-F1 de polaridad 0,393.

Después explicar que la mayor parte de la conversación es informativa o neutral,
algo razonable en un grupo académico.

### Vista 2: Polaridad

Explicar primero las seis categorías. Luego mostrar el filtro por gestión y aclarar:

- los porcentajes suman 100 % porque cada mensaje tiene una sola polaridad;
- `sin_sentimiento` no significa negativo;
- los conteos son predicciones del modelo final;
- la comparación anual es descriptiva y no prueba causalidad.

### Vista 3: Emociones

Explicar que es multietiqueta y que los porcentajes no suman 100 %. Comparar:

- frecuencia estimada en el corpus;
- F1 medido fuera de muestra.

La emoción frecuente no es necesariamente la mejor reconocida. Curiosidad es la
más frecuente, mientras gratitud tiene el mejor F1.

### Vista 4: Modelos

Presentar los modelos en orden:

1. baseline;
2. diccionario;
3. TF-IDF;
4. MiniLM;
5. híbrido.

La conclusión no debe ser “MiniLM entiende perfectamente el texto”, sino:

> La combinación de vocabulario local y representación semántica obtuvo el mejor
> macro-F1 bajo las mismas particiones de validación.

### Vista 5: Calidad y límites

Explicar que kappa moderado confirma que la tarea también es difícil para personas.
Mencionar doble anotación, adjudicación, agrupación de duplicados y privacidad.
Cerrar indicando que los resultados son exploratorios y agregados.

## 26. Plan de estudio para los cuatro integrantes

Cada integrante debe estudiar primero las secciones 2, 3, 4, 5, 17, 19 y 20. Esas
secciones contienen la historia completa, resultados, limitaciones y preguntas.

### Integrante encargado de problema y datos

Debe dominar:

- por qué se eligió el grupo de Telegram;
- fechas y cantidad de mensajes;
- extracción desde HTML;
- diferencia entre anonimización y pseudonimización;
- variables temporales;
- privacidad y alcance.

Debe poder responder:

1. ¿por qué hay datos desde 2022 si el grupo se llama Temporada 2026?;
2. ¿qué se descartó durante la extracción?;
3. ¿qué información privada sigue existiendo en los CSV locales?;
4. ¿por qué los resultados no representan a toda la carrera?

### Integrante encargado de preprocesamiento

Debe dominar:

- limpieza y normalización;
- tratamiento de URL, tildes y emojis;
- tokens y stopwords;
- negaciones conservadas;
- stemming;
- DFM, dispersión, unigramas y bigramas;
- papel complementario de `tm`, `quanteda` y `syuzhet`.

Debe poder transformar verbalmente un mensaje de ejemplo desde texto original
hasta tokens o raíces.

### Integrante encargado de anotación y reglas

Debe dominar:

- diccionario base y ampliado;
- diferencia entre cobertura y exactitud;
- muestreo estratificado y enriquecido;
- libro de códigos;
- campos de las plantillas A/B;
- kappa, Jaccard y acuerdo exacto;
- adjudicación y objetivos finales;
- diferencia entre `neutra`, `ambigua` y `sin_sentimiento`.

Debe poder explicar por qué la referencia automática se ocultó durante la
anotación.

### Integrante encargado de modelos y resultados

Debe dominar:

- baseline, TF-IDF, MiniLM e híbrido;
- regresión logística y One-vs-Rest;
- cinco folds agrupados;
- precisión, recall, F1, macro, micro y Hamming loss;
- criterio de selección del híbrido;
- resultados finales de polaridad y emociones;
- dashboard y limitaciones del modelo.

Debe poder explicar por qué una accuracy alta no basta y por qué el macro-F1 del
híbrido es el principal criterio.

### Conocimiento mínimo común

Todos deben memorizar:

- 21.546 mensajes;
- 1.085 etiquetas finales;
- periodo 16/12/2022–12/10/2026;
- seis polaridades y diez emociones;
- cinco folds agrupados;
- kappa 0,418 en polaridad y 0,432 en emoción principal;
- macro-F1 del híbrido: 0,393 en polaridad y 0,375 en emociones;
- cobertura del diccionario: 9,4 % original y 24,6 % ampliado;
- el resultado es exploratorio y no es un diagnóstico.

## 27. Errores frecuentes al explicar el proyecto

| Explicación incorrecta | Explicación correcta |
|---|---|
| “El diccionario tiene 24,6 % de precisión.” | Tiene 24,6 % de cobertura; su calidad se evalúa contra etiquetas humanas. |
| “El 42,2 % de todo el chat no tiene sentimiento.” | 42,2 % corresponde al dataset manual enriquecido; el corpus completo tiene predicciones del modelo. |
| “MiniLM es una red que entrenamos desde cero.” | Se usó un MiniLM preentrenado y congelado para generar embeddings. |
| “El híbrido tiene 39,3 % de accuracy.” | Tiene macro-F1 0,393; su accuracy de polaridad es 0,530. |
| “Cada mensaje tiene una emoción.” | Puede tener ninguna, una o varias emociones. |
| “Neutral y sin sentimiento son iguales.” | Neutral tiene contenido evaluable sin orientación dominante; sin sentimiento carece de señal suficiente. |
| “El modelo entiende el contexto completo del chat.” | Clasifica principalmente cada mensaje de forma individual. |
| “La anonimización elimina todo riesgo.” | Seudonimizar nombres reduce exposición, pero el texto sigue siendo privado. |
| “La validación usó el mismo conjunto para entrenar y probar.” | Cada predicción OOF se produjo sin entrenar con esa fila. |
| “Los textos repetidos se repartieron al azar.” | Los duplicados se agruparon por hash y no cruzaron entre entrenamiento y prueba. |
| “Mayor frecuencia significa mayor F1.” | Frecuencia en el corpus y calidad de clasificación son conceptos distintos. |
| “Los porcentajes emocionales deberían sumar 100 %.” | No suman 100 % porque la tarea es multietiqueta. |

## 28. Glosario rápido para repasar

| Término | Definición breve |
|---|---|
| Corpus | Conjunto de mensajes analizados. |
| Token | Unidad textual, normalmente una palabra. |
| Stopword | Palabra frecuente con poco poder descriptivo. |
| Stemming | Reducción de palabras a una raíz. |
| DFM | Matriz de documentos por términos. |
| TF-IDF | Peso que destaca términos distintivos. |
| Embedding | Vector denso que representa significado aproximado. |
| Etiqueta | Categoría humana o predicha asociada a un mensaje. |
| Multiclase | Se elige una sola clase entre varias. |
| Multietiqueta | Se pueden elegir varias etiquetas simultáneas. |
| Baseline | Referencia mínima que un modelo debe superar. |
| Fold | Una partición de la validación cruzada. |
| OOF | Predicción obtenida cuando la fila estaba fuera del entrenamiento. |
| Fuga de información | Uso accidental de información de prueba durante entrenamiento. |
| Precisión | Qué proporción de las predicciones positivas fue correcta. |
| Recall | Qué proporción de los positivos reales fue encontrada. |
| F1 | Equilibrio armónico entre precisión y recall. |
| Macro-F1 | Promedio de F1 dando igual peso a cada clase. |
| Micro-F1 | F1 calculado acumulando todas las decisiones. |
| Kappa | Acuerdo humano corregido por azar. |
| Jaccard | Similitud entre dos conjuntos de emociones. |
| Hamming loss | Proporción de decisiones multietiqueta incorrectas. |
| Cobertura | Proporción de mensajes reconocidos por el diccionario. |
| Adjudicación | Decisión final documentada sobre un desacuerdo. |
| Pseudonimización | Sustitución de nombres por códigos; no elimina todo riesgo. |

## 29. Autoevaluación del grupo

Cada integrante debería responder sin leer:

1. ¿Cuál es el objetivo y cuál es la unidad de análisis?
2. ¿Cómo se pasó de HTML a un corpus de 21.546 mensajes?
3. ¿Qué diferencia existe entre limpieza y normalización?
4. ¿Por qué se conservan las palabras `no`, `nunca`, `sin` y `ni`?
5. ¿Qué diferencia hay entre polaridad y emoción?
6. ¿Por qué las emociones son multietiqueta?
7. ¿Cómo se construyó la muestra de 1.085 mensajes?
8. ¿Por qué se usaron dos anotadores y adjudicación?
9. ¿Qué significan kappa 0,418 y 0,432?
10. ¿Cuál es la diferencia entre cobertura y exactitud?
11. ¿Qué representa TF-IDF?
12. ¿Qué aporta MiniLM?
13. ¿Qué combina el modelo híbrido?
14. ¿Cómo evita la validación cruzada la fuga de duplicados?
15. ¿Por qué macro-F1 es más importante que accuracy en este proyecto?
16. ¿Por qué el baseline emocional tiene accuracy distinta de cero y F1 cero?
17. ¿Qué modelo ganó y con qué resultados?
18. ¿Qué emociones reconoce mejor y peor?
19. ¿Por qué los resultados del corpus no son diagnósticos?
20. ¿Cuáles son las tres limitaciones más importantes?

Si el grupo puede responder estas veinte preguntas con ejemplos, tiene cubiertos
los puntos esenciales para defender el proyecto.
