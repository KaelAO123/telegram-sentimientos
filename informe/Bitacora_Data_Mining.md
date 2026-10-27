---
title: "Bitácora técnica y de limpieza de datos"
subtitle: "Análisis de sentimientos y emociones — Telegram Temporada 2026"
author:
  - "Chavez Gutierrez Eddy Yojan"
  - "Copa Quispe Esther Sara"
  - "Rojas Condori Fidel Angel"
  - "Reyes Barja Carlos Eduardo"
date: "28 de octubre de 2026"
lang: es
---

<header class="hero" id="inicio">
  <div class="hero-topline">
    <span class="course-pill">DATA MINING · PARALELO A</span>
    <span class="status-pill"><span class="status-dot"></span> Proyecto concluido</span>
  </div>
  <p class="hero-kicker">Universidad Mayor de San Andrés · Facultad de Ciencias Puras y Naturales · Carrera de Informática</p>
  <h1>Bitácora técnica y de limpieza de datos</h1>
  <p class="hero-lead">Registro reproducible del análisis de sentimientos y emociones del grupo de Telegram de Temporada 2026.</p>
  <div class="hero-meta">
    <div><span>Docente</span><strong>M.Sc. Menfy Morales Rios</strong></div>
    <div><span>Periodo analizado</span><strong>16/12/2022 – 12/10/2026</strong></div>
    <div><span>Última actualización</span><strong>26/10/2026</strong></div>
  </div>
  <div class="hero-actions">
    <a class="primary-action" href="#linea-tiempo">Ver línea de tiempo</a>
    <button class="secondary-action" type="button" onclick="window.print()">Imprimir / guardar PDF</button>
  </div>
</header>

<nav class="quick-nav" aria-label="Navegación de la bitácora">
  <a href="#resumen">Resumen</a>
  <a href="#metodologia">Limpieza</a>
  <a href="#linea-tiempo">Cronología</a>
  <a href="#auditoria">Auditoría</a>
  <a href="#evidencias">Evidencias</a>
  <a href="#reproducibilidad">Reproducir</a>
</nav>

<main>

<section class="section-block" id="resumen">
  <div class="section-heading">
    <div><span class="section-number">01</span><p class="eyebrow">Estado del proyecto</p></div>
    <h2>Resumen ejecutivo de la bitácora</h2>
    <p>Esta página documenta las decisiones que transformaron 29 archivos HTML de Telegram en un corpus limpio, una referencia humana adjudicada y un modelo evaluado sin fuga de duplicados.</p>
  </div>

  <div class="kpi-grid">
    <article class="kpi-card teal"><span>Corpus final</span><strong>21.546</strong><small>mensajes válidos</small></article>
    <article class="kpi-card blue"><span>Muestra humana</span><strong>1.085</strong><small>filas × 2 anotadores</small></article>
    <article class="kpi-card violet"><span>Emociones modeladas</span><strong>10</strong><small>soporte mínimo ≥ 20</small></article>
    <article class="kpi-card amber"><span>Controles finales</span><strong>0</strong><small>errores y objetivos vacíos</small></article>
  </div>

  <div class="summary-grid">
    <article class="summary-card">
      <span class="icon-box">✓</span>
      <div><h3>Qué registra</h3><p>Problemas detectados, decisiones, filas verificadas, responsables, scripts y productos obtenidos.</p></div>
    </article>
    <article class="summary-card">
      <span class="icon-box">↻</span>
      <div><h3>Cómo se reproduce</h3><p>Cada etapa apunta al archivo R o Python que genera o valida el resultado.</p></div>
    </article>
    <article class="summary-card">
      <span class="icon-box">◈</span>
      <div><h3>Cómo se protege</h3><p>El texto queda en archivos privados; las salidas de presentación son agregadas.</p></div>
    </article>
  </div>

  <div class="callout info">
    <strong>Lectura recomendada:</strong> primero revise la línea de tiempo; luego use los filtros de la tabla de auditoría para localizar una acción, dataset o script específico.
  </div>
</section>

<section class="section-block" id="metodologia">
  <div class="section-heading">
    <div><span class="section-number">02</span><p class="eyebrow">Metodología solicitada</p></div>
    <h2>Seis controles de limpieza aplicados</h2>
    <p>La guía de `bitacora.pdf` se adaptó a datos textuales. No se aplicaron reglas numéricas de manera mecánica cuando podían eliminar mensajes válidos.</p>
  </div>

  <div class="method-grid">
    <article class="method-card">
      <span class="method-index">1</span><h3>Auditoría inicial</h3>
      <p>Tipos, fechas, cardinalidades, ausencias, longitud, URL y emojis.</p>
      <ul><li>29 HTML</li><li>21.546 IDs únicos</li><li>0 textos o fechas faltantes</li></ul>
    </article>
    <article class="method-card">
      <span class="method-index">2</span><h3>Formatos</h3>
      <p>Fechas ISO-8601, hora entera, Unicode, espacios y etiquetas normalizadas.</p>
      <ul><li>Texto original preservado</li><li>URL convertidas a marcador</li></ul>
    </article>
    <article class="method-card">
      <span class="method-index">3</span><h3>Duplicados</h3>
      <p>No había IDs duplicados; los textos repetidos se conservaron como eventos reales.</p>
      <ul><li>17.457 textos únicos</li><li>Agrupación por hash en evaluación</li></ul>
    </article>
    <article class="method-card">
      <span class="method-index">4</span><h3>Faltantes</h3>
      <p>No se imputaron emociones ni texto. Un objetivo incompleto detiene el pipeline.</p>
      <ul><li>1.085 objetivos completos</li><li>Adjudicación humana</li></ul>
    </article>
    <article class="method-card">
      <span class="method-index">5</span><h3>Atípicos</h3>
      <p>Se perfilaron longitudes y señales, pero no se eliminó un mensaje solo por ser largo.</p>
      <ul><li>Mediana: 41 caracteres</li><li>Máximo: 2.646 caracteres</li></ul>
    </article>
    <article class="method-card">
      <span class="method-index">6</span><h3>Consistencia</h3>
      <p>Catálogos válidos, reglas entre variables, privacidad y pruebas sin fuga.</p>
      <ul><li>0 errores finales</li><li>10 emociones evaluadas</li></ul>
    </article>
  </div>

  <div class="decision-panel">
    <div>
      <p class="eyebrow">Decisión metodológica clave</p>
      <h3>Un dato extremo no es necesariamente un error</h3>
      <p>En datos textuales, una publicación larga puede ser un anuncio académico válido. IQR y Z-score se usaron como referencias de perfilado, no como órdenes automáticas de eliminación.</p>
    </div>
    <div class="decision-stats">
      <div><span>Texto faltante</span><strong>0</strong></div>
      <div><span>ID duplicado</span><strong>0</strong></div>
      <div><span>Mensajes con URL</span><strong>1.433</strong></div>
    </div>
  </div>
</section>

<section class="section-block" id="linea-tiempo">
  <div class="section-heading">
    <div><span class="section-number">03</span><p class="eyebrow">Evolución verificable</p></div>
    <h2>Línea de tiempo del proyecto</h2>
    <p>La bitácora distingue resultados intermedios de resultados finales. Esto evita presentar como definitiva una métrica obtenida mientras el etiquetado aún estaba incompleto.</p>
  </div>

  <div class="timeline">
    <article class="timeline-entry" data-day="21">
      <div class="timeline-marker"><span>21</span><small>OCT</small></div>
      <div class="timeline-card">
        <div class="timeline-title"><div><span class="tag">Preparación</span><h3>Extracción, diccionario y privacidad</h3></div><span class="done">Completado</span></div>
        <ul>
          <li>Revisión de las 15 categorías del documento base.</li>
          <li>Lectura automática de `messages.html`, `messages2.html`, etc.</li>
          <li>Pseudonimización de 1.594 participantes.</li>
          <li>Separación entre polaridad neutral y ausencia de coincidencia.</li>
          <li>Clasificación multietiqueta y bitácora con huellas MD5.</li>
        </ul>
        <div class="result-strip"><span>Producto</span><strong>Corpus de 21.546 mensajes</strong><code>01_ejecutar_analisis.R</code></div>
      </div>
    </article>
    <article class="timeline-entry" data-day="21">
      <div class="timeline-marker"><span>21</span><small>OCT</small></div>
      <div class="timeline-card">
        <div class="timeline-title"><div><span class="tag">Cobertura</span><h3>Ampliación contextual del diccionario</h3></div><span class="done">Completado</span></div>
        <p>Se mantuvo el diccionario original como baseline y se creó `ampliado_v2` con expresiones del dominio, variantes, emojis y emoticonos.</p>
        <div class="coverage-comparison">
          <div><span>Original</span><strong>9,4%</strong><small>2.034 mensajes</small></div>
          <div class="arrow">→</div>
          <div><span>Ampliado</span><strong>24,6%</strong><small>5.299 mensajes</small></div>
        </div>
        <div class="result-strip"><span>Impacto</span><strong>+3.265 mensajes con evidencia</strong><code>crear_diccionario()</code></div>
      </div>
    </article>
    <article class="timeline-entry" data-day="21">
      <div class="timeline-marker"><span>21</span><small>OCT</small></div>
      <div class="timeline-card">
        <div class="timeline-title"><div><span class="tag">Dataset</span><h3>Muestra, librerías y libro de códigos</h3></div><span class="done">Completado</span></div>
        <ul>
          <li>Muestra estratificada por gestión y señal emocional, con refuerzo sin evidencia.</li>
          <li>Plantillas separadas para anotadores A y B.</li>
          <li>`tm` para corpus y limpieza; `quanteda` para tokens y DFM; `syuzhet` como referencia auxiliar.</li>
          <li>Matriz documento-término de 21.546 × 10.421.</li>
        </ul>
        <div class="result-strip"><span>Producto</span><strong>1.085 mensajes seleccionados</strong><code>02_generar_dataset_manual.R</code></div>
      </div>
    </article>
    <article class="timeline-entry interim" data-day="26">
      <div class="timeline-marker"><span>26</span><small>OCT</small></div>
      <div class="timeline-card">
        <div class="timeline-title"><div><span class="tag warning">Resultado intermedio</span><h3>Consenso parcial y benchmark preliminar</h3></div><span class="superseded">Superado</span></div>
        <p>En esta versión B tenía 713 filas completas. Se corrigieron tres valores mecánicos y se compararon modelos sobre 300 acuerdos. Las métricas no se consideraron finales.</p>
        <div class="mini-metrics"><span>Kappa polaridad <strong>0,481</strong></span><span>Kappa emoción <strong>0,498</strong></span><span>Filas B <strong>713</strong></span></div>
        <div class="result-strip"><span>Lección</span><strong>No presentar un benchmark parcial como conclusión</strong><code>08_modelo_embeddings.py</code></div>
      </div>
    </article>
    <article class="timeline-entry final" data-day="26">
      <div class="timeline-marker"><span>26</span><small>OCT</small></div>
      <div class="timeline-card">
        <div class="timeline-title"><div><span class="tag final-tag">Resultado final</span><h3>Doble anotación y adjudicación completa</h3></div><span class="done">Validado</span></div>
        <p>A y B completaron las 1.085 filas. Los desacuerdos se adjudicaron sin sobrescribir las decisiones originales.</p>
        <div class="mini-metrics"><span>Kappa polaridad <strong>0,418</strong></span><span>Kappa emoción <strong>0,432</strong></span><span>Errores finales <strong>0</strong></span></div>
        <div class="result-strip"><span>Producto</span><strong>`dataset_modelado_umsa.csv`</strong><code>07_consolidar_adjudicaciones.R</code></div>
      </div>
    </article>
    <article class="timeline-entry final" data-day="26">
      <div class="timeline-marker"><span>26</span><small>OCT</small></div>
      <div class="timeline-card">
        <div class="timeline-title"><div><span class="tag final-tag">Modelado</span><h3>Validación cruzada y clasificación final</h3></div><span class="done">Validado</span></div>
        <ul>
          <li>Cinco folds estratificados y agrupados por hash de texto.</li>
          <li>Comparación de baseline, diccionario, TF-IDF, MiniLM e híbrido.</li>
          <li>Selección de TF-IDF + MiniLM mediante macro-F1.</li>
          <li>Predicción de 21.546 mensajes sin exportar texto ni participante.</li>
        </ul>
        <div class="score-grid"><div><span>Macro-F1 polaridad</span><strong>0,393</strong></div><div><span>Macro-F1 emociones</span><strong>0,375</strong></div><div><span>Emociones</span><strong>10</strong></div></div>
        <div class="result-strip"><span>Scripts</span><strong>Evaluación y aplicación final</strong><code>09_validacion_cruzada.py · 10_clasificar_corpus.py</code></div>
      </div>
    </article>
  </div>
</section>

<section class="section-block" id="auditoria">
  <div class="section-heading">
    <div><span class="section-number">04</span><p class="eyebrow">Audit trail</p></div>
    <h2>Registro de transformaciones</h2>
    <p>Busque por término o filtre por área. El contador se actualiza inmediatamente.</p>
  </div>

  <div class="audit-controls">
    <label class="search-control"><span>Buscar</span><input id="audit-search" type="search" placeholder="Ej.: duplicados, adjudicación, privacidad…"></label>
    <label><span>Área</span><select id="audit-area"><option value="all">Todas</option><option value="ingesta">Ingesta</option><option value="limpieza">Limpieza</option><option value="datos">Dataset</option><option value="modelo">Modelado</option><option value="privacidad">Privacidad</option></select></label>
    <label><span>Fecha</span><select id="audit-date"><option value="all">Todas</option><option value="21/10/2026">21/10/2026</option><option value="26/10/2026">26/10/2026</option></select></label>
    <div class="record-count"><strong id="visible-records">14</strong><span>registros visibles</span></div>
  </div>

  <div class="audit-list" id="audit-list">
    <article class="audit-row" data-area="ingesta" data-date="21/10/2026"><span class="audit-id">01</span><div><span class="audit-meta">21/10/2026 · INGESTA</span><h3>Orden de archivos HTML</h3><p>Se localizaron y ordenaron 29 archivos `messages*.html` antes de extraer el contenido.</p></div><div class="audit-impact"><span>Verificado</span><strong>29 archivos</strong><code>R/funciones.R</code></div></article>
    <article class="audit-row" data-area="ingesta" data-date="21/10/2026"><span class="audit-id">02</span><div><span class="audit-meta">21/10/2026 · INGESTA</span><h3>Extracción y fechas</h3><p>Se conservaron mensajes textuales con fecha válida y se transformaron las fechas al estándar ISO.</p></div><div class="audit-impact"><span>Resultado</span><strong>21.546 filas</strong><code>01_ejecutar_analisis.R</code></div></article>
    <article class="audit-row" data-area="privacidad" data-date="21/10/2026"><span class="audit-id">03</span><div><span class="audit-meta">21/10/2026 · PRIVACIDAD</span><h3>Pseudonimización</h3><p>Los autores se sustituyeron por códigos `P001`, `P002`, etc.</p></div><div class="audit-impact"><span>Protegido</span><strong>1.594 participantes</strong><code>extraer_mensajes()</code></div></article>
    <article class="audit-row" data-area="limpieza" data-date="21/10/2026"><span class="audit-id">04</span><div><span class="audit-meta">21/10/2026 · LIMPIEZA</span><h3>Normalización textual</h3><p>Unicode, espacios, URL, minúsculas y señales gráficas; el texto original se mantuvo para auditoría.</p></div><div class="audit-impact"><span>Verificado</span><strong>21.546 filas</strong><code>normalizar_texto()</code></div></article>
    <article class="audit-row" data-area="limpieza" data-date="21/10/2026"><span class="audit-id">05</span><div><span class="audit-meta">21/10/2026 · LIMPIEZA</span><h3>Unicidad de identificadores</h3><p>Se comprobó que cada mensaje tuviera un identificador único.</p></div><div class="audit-impact"><span>Anomalías</span><strong>0 duplicados de ID</strong><code>01_ejecutar_analisis.R</code></div></article>
    <article class="audit-row" data-area="limpieza" data-date="21/10/2026"><span class="audit-id">06</span><div><span class="audit-meta">21/10/2026 · LIMPIEZA</span><h3>Textos repetidos</h3><p>Las repeticiones reales se conservaron; en modelado se agruparon para evitar fuga.</p></div><div class="audit-impact"><span>Perfil</span><strong>17.457 textos únicos</strong><code>text_group()</code></div></article>
    <article class="audit-row" data-area="datos" data-date="21/10/2026"><span class="audit-id">07</span><div><span class="audit-meta">21/10/2026 · DICCIONARIO</span><h3>Ampliación contextual</h3><p>Se añadieron variantes, expresiones, emojis y emoticonos manteniendo el original como baseline.</p></div><div class="audit-impact"><span>Cobertura</span><strong>9,4% → 24,6%</strong><code>crear_diccionario()</code></div></article>
    <article class="audit-row" data-area="datos" data-date="21/10/2026"><span class="audit-id">08</span><div><span class="audit-meta">21/10/2026 · DATASET</span><h3>Muestreo reproducible</h3><p>Estratificación por gestión y señal emocional, más refuerzo de mensajes sin evidencia.</p></div><div class="audit-impact"><span>Seleccionado</span><strong>1.085 filas</strong><code>02_generar_dataset_manual.R</code></div></article>
    <article class="audit-row" data-area="datos" data-date="26/10/2026"><span class="audit-id">09</span><div><span class="audit-meta">26/10/2026 · VALIDACIÓN</span><h3>Correcciones mecánicas de B</h3><p>Se normalizaron tres valores inválidos documentados sin inferir etiquetas semánticas.</p></div><div class="audit-impact"><span>Corregido</span><strong>3 celdas</strong><code>06_corregir_etiquetado_b.R</code></div></article>
    <article class="audit-row" data-area="datos" data-date="26/10/2026"><span class="audit-id">10</span><div><span class="audit-meta">26/10/2026 · VALIDACIÓN</span><h3>Control final A/B</h3><p>Catálogos, obligatoriedad, duplicados y consistencia estructural.</p></div><div class="audit-impact"><span>Válido</span><strong>2.170 anotaciones</strong><code>03_validar_dataset_manual.R</code></div></article>
    <article class="audit-row" data-area="datos" data-date="26/10/2026"><span class="audit-id">11</span><div><span class="audit-meta">26/10/2026 · CONSENSO</span><h3>Adjudicación</h3><p>Los desacuerdos se resolvieron en un archivo separado y se registró la fuente del objetivo.</p></div><div class="audit-impact"><span>Resuelto</span><strong>447 polaridades · 604 emociones</strong><code>07_consolidar_adjudicaciones.R</code></div></article>
    <article class="audit-row" data-area="modelo" data-date="26/10/2026"><span class="audit-id">12</span><div><span class="audit-meta">26/10/2026 · MODELO</span><h3>Duplicados entre folds</h3><p>Los textos normalizados idénticos se agruparon mediante SHA-256.</p></div><div class="audit-impact"><span>Controlado</span><strong>77 repeticiones</strong><code>09_validacion_cruzada.py</code></div></article>
    <article class="audit-row" data-area="modelo" data-date="26/10/2026"><span class="audit-id">13</span><div><span class="audit-meta">26/10/2026 · SELECCIÓN</span><h3>Comparación justa</h3><p>Se usó macro-F1 para comparar cinco alternativas bajo las mismas predicciones OOF.</p></div><div class="audit-impact"><span>Ganador</span><strong>TF-IDF + MiniLM</strong><code>09_validacion_cruzada.py</code></div></article>
    <article class="audit-row" data-area="privacidad" data-date="26/10/2026"><span class="audit-id">14</span><div><span class="audit-meta">26/10/2026 · PRIVACIDAD</span><h3>Salida final minimizada</h3><p>Las predicciones excluyen texto y participante; solo conservan ID, tiempo, clase y confianza.</p></div><div class="audit-impact"><span>Protegido</span><strong>21.546 predicciones</strong><code>10_clasificar_corpus.py</code></div></article>
  </div>
  <p class="empty-state" id="audit-empty" hidden>No hay registros que coincidan con los filtros.</p>
</section>

<section class="section-block" id="calidad">
  <div class="section-heading">
    <div><span class="section-number">05</span><p class="eyebrow">Controles finales</p></div>
    <h2>Calidad y trazabilidad</h2>
    <p>Las siguientes cifras corresponden al estado final, después de completar y adjudicar todas las filas.</p>
  </div>

  <div class="quality-layout">
    <div class="quality-card">
      <h3>Acuerdo humano</h3>
      <div class="metric-line"><span>Kappa polaridad</span><div><i style="width:41.8%"></i></div><strong>0,418</strong></div>
      <div class="metric-line"><span>Kappa emoción principal</span><div><i style="width:43.2%"></i></div><strong>0,432</strong></div>
      <div class="metric-line"><span>Jaccard emocional</span><div><i style="width:52.3%"></i></div><strong>0,523</strong></div>
      <p>El acuerdo moderado demuestra ambigüedad real y justifica la adjudicación.</p>
    </div>
    <div class="quality-card">
      <h3>Integridad del dataset</h3>
      <ul class="check-list">
        <li><span>✓</span>1.085 filas completas de A</li>
        <li><span>✓</span>1.085 filas completas de B</li>
        <li><span>✓</span>0 categorías inválidas finales</li>
        <li><span>✓</span>0 objetivos vacíos</li>
        <li><span>✓</span>Fuente de cada objetivo registrada</li>
      </ul>
    </div>
    <div class="quality-card">
      <h3>Evaluación del modelo</h3>
      <div class="model-score"><span>Polaridad</span><strong>0,393</strong><small>macro-F1 OOF</small></div>
      <div class="model-score"><span>Emociones</span><strong>0,375</strong><small>macro-F1 OOF</small></div>
      <p>Cinco folds, grupos de texto y selección entre modelos aprendidos.</p>
    </div>
  </div>

  <div class="callout warning-callout">
    <strong>Interpretación:</strong> una métrica moderada no se oculta. El acuerdo humano también es moderado, varias clases tienen pocos ejemplos y el mensaje se analiza sin toda la conversación anterior.
  </div>
</section>

<section class="section-block" id="evidencias">
  <div class="section-heading">
    <div><span class="section-number">06</span><p class="eyebrow">Salidas reproducibles</p></div>
    <h2>Evidencias visuales</h2>
    <p>Las capturas se generan mediante scripts. No contienen nombres ni conversaciones privadas.</p>
  </div>
  <div class="evidence-grid">
    <figure><img src="../resultados/graficos_preprocesamiento/01_tokens_frecuentes.png" alt="Tokens frecuentes"><figcaption><strong>Preprocesamiento</strong><span>Frecuencia de tokens después de limpieza.</span></figcaption></figure>
    <figure><img src="../resultados/graficos/04_cobertura_gestion.png" alt="Cobertura por gestión"><figcaption><strong>Diccionario</strong><span>Cobertura contextual por gestión.</span></figcaption></figure>
    <figure><img src="../resultados/graficos/07_motivos_sin_clasificar.png" alt="Motivos sin clasificar"><figcaption><strong>Diagnóstico</strong><span>Motivos operativos de ausencia de evidencia.</span></figcaption></figure>
    <figure><img src="../resultados/validacion_cruzada/graficos/01_comparacion_macro_f1.png" alt="Comparación macro F1"><figcaption><strong>Modelos</strong><span>Comparación fuera de muestra.</span></figcaption></figure>
    <figure><img src="../resultados/validacion_cruzada/graficos/02_matriz_confusion_polaridad.png" alt="Matriz de confusión"><figcaption><strong>Polaridad</strong><span>Matriz de confusión del híbrido.</span></figcaption></figure>
    <figure><img src="../resultados/validacion_cruzada/graficos/03_f1_por_emocion.png" alt="F1 por emoción"><figcaption><strong>Emociones</strong><span>Rendimiento de las diez clases.</span></figcaption></figure>
  </div>
</section>

<section class="section-block" id="reproducibilidad">
  <div class="section-heading">
    <div><span class="section-number">07</span><p class="eyebrow">Cómo repetirlo</p></div>
    <h2>Secuencia reproducible</h2>
    <p>Los comandos deben ejecutarse desde la raíz del proyecto.</p>
  </div>

```bash
Rscript scripts/01_ejecutar_analisis.R
Rscript scripts/02_generar_dataset_manual.R
Rscript scripts/06_corregir_etiquetado_b.R
Rscript scripts/03_validar_dataset_manual.R
Rscript scripts/07_consolidar_adjudicaciones.R
Rscript scripts/04_mineria_descriptiva.R
Rscript scripts/05_preprocesamiento_librerias.R

HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
  .venv-embeddings/bin/python scripts/09_validacion_cruzada.py

HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
  .venv-embeddings/bin/python scripts/10_clasificar_corpus.py --batch-size 256
```

  <div class="trace-grid">
    <article><span>Bitácora humana</span><code>BITACORA.md</code><p>Decisiones, cambios de alcance y resultados.</p></article>
    <article><span>Bitácora automática</span><code>bitacora_ejecuciones.csv</code><p>Fechas, cantidades y huellas MD5.</p></article>
    <article><span>Referencia final</span><code>dataset_modelado_umsa.csv</code><p>Objetivos y fuente de la adjudicación.</p></article>
    <article><span>Evaluación final</span><code>comparacion_modelos.csv</code><p>Métricas fuera de muestra.</p></article>
  </div>
</section>

<section class="section-block" id="observaciones">
  <div class="section-heading">
    <div><span class="section-number">08</span><p class="eyebrow">Cierre</p></div>
    <h2>Observaciones y decisiones abiertas</h2>
  </div>

  <div class="closing-grid">
    <article><h3>Documento base</h3><p>El pie del PDF de emociones contiene una nota ambigua sobre posibles reemplazos de categorías. Se conservaron las quince categorías definidas en el cuerpo y se recomienda confirmar esa interpretación con la docente.</p></article>
    <article><h3>Privacidad</h3><p>Los CSV con texto se entregan solo con fines académicos. No deben publicarse en un repositorio abierto. Las figuras y predicciones de presentación no incluyen participantes.</p></article>
    <article><h3>Alcance</h3><p>El resultado identifica señales lingüísticas agregadas. No diagnostica emociones reales de estudiantes ni debe utilizarse para evaluar individuos.</p></article>
  </div>

  <div class="signatures">
    <p><strong>Responsables del proyecto</strong></p>
    <div class="signature-grid">
      <span>Chavez Gutierrez Eddy Yojan</span>
      <span>Copa Quispe Esther Sara</span>
      <span>Rojas Condori Fidel Angel</span>
      <span>Reyes Barja Carlos Eduardo</span>
    </div>
  </div>
</section>

</main>

<footer class="page-footer">
  <div><strong>Bitácora Data Mining</strong><span>UMSA · Carrera de Informática · 2026</span></div>
  <a href="#inicio">Volver arriba ↑</a>
</footer>

<script>
(() => {
  const search = document.getElementById('audit-search');
  const area = document.getElementById('audit-area');
  const date = document.getElementById('audit-date');
  const rows = [...document.querySelectorAll('.audit-row')];
  const count = document.getElementById('visible-records');
  const empty = document.getElementById('audit-empty');

  function normalize(value) {
    return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  }

  function filterAudit() {
    const query = normalize(search.value.trim());
    let visible = 0;
    rows.forEach(row => {
      const matchesText = !query || normalize(row.textContent).includes(query);
      const matchesArea = area.value === 'all' || row.dataset.area === area.value;
      const matchesDate = date.value === 'all' || row.dataset.date === date.value;
      const show = matchesText && matchesArea && matchesDate;
      row.hidden = !show;
      if (show) visible += 1;
    });
    count.textContent = visible;
    empty.hidden = visible !== 0;
  }

  [search, area, date].forEach(control => control.addEventListener('input', filterAudit));

  const sections = [...document.querySelectorAll('main section[id]')];
  const links = [...document.querySelectorAll('.quick-nav a')];
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      links.forEach(link => link.classList.toggle('active', link.getAttribute('href') === `#${entry.target.id}`));
    });
  }, { rootMargin: '-25% 0px -65% 0px' });
  sections.forEach(section => observer.observe(section));
})();
</script>
