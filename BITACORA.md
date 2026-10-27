# Bitácora del proyecto

## 2026-10-21 — Preparación inicial

- Se revisó `sentimientos_documento.pdf` y se transcribieron sus 15 categorías.
- Se corrigieron comillas tipográficas y cortes de línea que impedían usar el texto como código R.
- La marca `F` de decepción se implementó como palabra exacta, no como raíz, para evitar que coincida con casi todos los mensajes.
- Se implementó lectura automática de `messages.html`, `messages2.html`, etc.
- Se decidió anonimizar autores antes de exportar resultados.
- Se separó `neutral` de `sin coincidencia` y se permitió clasificación multietiqueta.
- Se agregó selección de gestión, resúmenes, gráficos, informe HTML y bitácora automática con huellas MD5.

## Observación pendiente

El pie del PDF dice: “Amor por (frustración – cansancio), seguridad / Vergüenza por (satisfacción-tranquilidad), ironía”. La instrucción no permite determinar con certeza si pide reemplazar cuatro categorías. Por ahora se conservaron las 15 categorías completamente definidas en el cuerpo del documento. Conviene confirmar este punto con la docente.

## 2026-10-21 — Ampliación y control de cobertura

- Se conservó el diccionario original como línea base reproducible.
- Se creó `ampliado_v2` con emojis, emoticonos, variantes ortográficas y expresiones frecuentes del corpus.
- La cobertura aumentó de 2.034 a 5.299 mensajes: de 9,4 % a 24,6 %.
- Cada coincidencia registra evidencia, mecanismo (`termino_exacto`, `raiz`, `emoji` o `emoticon`) y confianza técnica.
- Se añadieron diagnósticos por gestión, índice mensual, mapa de cobertura por día/hora y coocurrencias emocionales.
- Se prepararon muestras para etiquetado manual y auditoría estratificada.

## 2026-10-21 — Reorientación a minería de datos

- Se retiró el clasificador supervisado para mantener el proyecto centrado en minería descriptiva y construcción de datos.
- Se creó un corpus anonimizado con variables textuales, temporales y estructurales.
- Se diseñó una muestra estratificada por gestión y señal emocional para construir un dataset propio.
- Se separaron las sugerencias del léxico de las plantillas manuales para reducir sesgo de confirmación.
- Se añadió un libro de códigos con polaridad, sentimientos, intensidad, tema, ironía y confianza de anotación.
- Se implementó validación de valores, control de completitud y acuerdo de Cohen entre dos anotadores.
- La etapa analítica usa frecuencias, TF-IDF, bigramas, coocurrencias y asociaciones sentimiento–tema, sin entrenar modelos predictivos.

## 2026-10-21 — Alineación con contenidos de la materia

- Se restauró `datos/dataset_manual` con el corpus, las dos plantillas, el libro de códigos y los controles de calidad.
- Se incorporó `tm` para la creación y limpieza del corpus.
- Se incorporó `quanteda` para tokenización, palabras vacías, stemming y matriz documento-término.
- Se incorporó `syuzhet` con el léxico personalizado en español para calcular un puntaje auxiliar de polaridad.
- Se generó una tabla con las etapas original, limpia, normalizada, tokenizada y reducida a raíces.
- La matriz documento-término resultante contiene 21.546 documentos y 10.421 términos.

## 2026-10-26 — Consenso y benchmark preliminar de embeddings

- Se corrigieron tres valores mecánicamente inválidos del anotador B, conservando
  sin completar una fila que requiere decisión humana.
- B quedó con 713 filas completas válidas y 713 filas comunes con A.
- El acuerdo fue moderado: kappa 0,481 en polaridad y 0,498 en sentimiento principal.
- Se creó un dataset de consenso, una plantilla de adjudicación y trazabilidad de
  las correcciones.
- Se compararon el diccionario, TF-IDF y embeddings MiniLM sobre 300 acuerdos A/B,
  eliminando duplicados entre entrenamiento y prueba.
- El diccionario obtuvo mejor macro-F1 preliminar que MiniLM tanto en polaridad como
  en ocho emociones. La evaluación no es final por el desbalance del test y por el
  muestreo enriquecido mediante reglas.

## 2026-10-26 — Adjudicación, validación cruzada y modelo final

- Se completaron las 1.085 anotaciones de A y B y se corrigieron todas las etiquetas
  inválidas. Antes de adjudicar, kappa fue 0,418 en polaridad y 0,432 en emoción principal.
- Se resolvieron los desacuerdos y se generó `dataset_modelado_umsa.csv` sin objetivos vacíos.
- La evaluación final usa cinco folds estratificados por polaridad y agrupados por hash
  de texto, de modo que un texto duplicado nunca aparece a ambos lados de un fold.
- Se compararon mayoría/sin emoción, diccionario, TF-IDF, MiniLM y el híbrido
  TF-IDF+MiniLM sobre predicciones fuera de muestra de las 1.085 filas.
- El híbrido obtuvo el mejor macro-F1: 0,393 en polaridad y 0,375 en diez emociones.
- Se entrenó el híbrido con todo el dataset y se clasificaron los 21.546 mensajes.
  Las predicciones exportadas excluyen texto y participantes y se interpretan de
  forma agregada y exploratoria.

