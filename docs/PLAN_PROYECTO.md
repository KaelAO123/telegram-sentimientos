# Plan del proyecto de minería de datos

## Pregunta de investigación

¿Qué sentimientos, polaridades y temas aparecen en el chat de temporada de la Carrera de Informática de la UMSA y cómo varían entre gestiones y periodos académicos?

## Objetivo general

Construir un dataset propio de mensajes etiquetados y aplicar técnicas descriptivas de minería de texto en R para identificar patrones emocionales, temáticos y temporales.

## Objetivos específicos

1. Extraer y anonimizar los mensajes de Telegram.
2. Limpiar y transformar el texto conservando señales como emojis y emoticonos.
3. Diseñar una muestra estratificada que cubra las gestiones y emociones poco frecuentes.
4. Etiquetar manualmente sentimiento, polaridad, intensidad, tema e ironía.
5. Medir calidad, completitud y acuerdo entre anotadores.
6. Encontrar términos frecuentes, n-gramas, asociaciones y patrones temporales.
7. Documentar un proceso replicable para nuevas gestiones.

## Adaptación de CRISP-DM

### 1. Comprensión del problema

- Contexto: comunicación estudiantil en cursos de temporada.
- Unidad de análisis: mensaje de texto.
- Restricción: no inferir estados psicológicos; analizar solo señales expresadas.

### 2. Comprensión de los datos

- Fuente: exportación HTML de Telegram.
- Cobertura: 21.546 mensajes entre 2022 y 2026.
- Riesgos: mensajes eliminados, multimedia sin transcripción, abreviaturas, ironía y desbalance de categorías.

### 3. Preparación

- Extracción con `rvest`.
- Anonimización de participantes.
- Limpieza del corpus con `tm`: URL, números, puntuación, palabras vacías y espacios.
- Tokenización con `quanteda`.
- Normalización de mayúsculas, tildes, variantes ortográficas, emojis y emoticonos.
- Stemming en español con `quanteda` y `SnowballC` como representación complementaria.
- Variables de longitud, signos, emojis, fecha, hora y gestión.
- Eliminación de eventos de servicio y filas sin fecha válida.

### 4. Construcción del dataset

- Corpus completo anonimizado: 21.546 filas.
- Muestra manual estratificada: 1.085 filas.
- Etiquetas: presencia de sentimiento, polaridad, sentimiento principal/secundario, intensidad, tema, ironía y confianza.
- Las sugerencias del léxico se mantienen ocultas durante el etiquetado.

### 5. Minería descriptiva

- Distribuciones y tablas cruzadas.
- Frecuencias de términos.
- TF-IDF por sentimiento.
- Bigramas y expresiones frecuentes.
- Puntuación de polaridad con `syuzhet` y un léxico propio en español.
- Coocurrencias emocionales.
- Asociaciones sentimiento–tema con soporte, confianza y *lift*.
- Evolución anual, mensual, semanal y horaria.

### 6. Evaluación

- Revisión de valores inválidos y duplicados.
- Porcentaje de filas completas.
- Kappa de Cohen para dos anotadores.
- Revisión manual de falsos positivos del léxico.
- Declaración explícita de limitaciones.

### 7. Presentación

- Informe HTML reproducible.
- Dataset manual documentado.
- Scripts numerados según el flujo de trabajo.
- Gráficos y tablas agregadas sin exponer nombres.

## Cronograma sugerido hasta el 28/10/2026

- 21–22 de octubre: preparación, muestreo y prueba piloto de 30 mensajes.
- 23–25 de octubre: etiquetado manual.
- 26 de octubre: validación y resolución de desacuerdos.
- 27 de octubre: minería descriptiva, interpretación y revisión del informe.
- 28 de octubre: entrega y presentación.

## Orden de ejecución

```bash
Rscript scripts/01_ejecutar_analisis.R
Rscript scripts/02_generar_dataset_manual.R
# Completar las etiquetas manuales
Rscript scripts/03_validar_dataset_manual.R
Rscript scripts/04_mineria_descriptiva.R
Rscript scripts/05_preprocesamiento_librerias.R
```

