#!/usr/bin/env python3
"""Entrena el modelo final y clasifica el corpus anonimizado completo."""

from __future__ import annotations

import argparse
import json
import os
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
os.environ.setdefault("MPLCONFIGDIR", str(ROOT / ".cache" / "matplotlib"))

import joblib
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import sparse
from sentence_transformers import SentenceTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.multiclass import OneVsRestClassifier
from sklearn.preprocessing import MultiLabelBinarizer


DATASET = ROOT / "datos" / "dataset_manual" / "dataset_modelado_umsa.csv"
CORPUS = ROOT / "datos" / "dataset_manual" / "corpus_anonimizado.csv"
CV_CONFIG = ROOT / "resultados" / "validacion_cruzada" / "configuracion_modelo.json"
OUTPUT = ROOT / "resultados" / "modelo_final"
EMOTION_META = {"", "sin_sentimiento", "ambiguo", "otro"}


def normalize_text(value: object) -> str:
    text = unicodedata.normalize("NFC", str(value or ""))
    text = re.sub(r"https?://\S+|www\.\S+", " <URL> ", text, flags=re.I)
    return re.sub(r"\s+", " ", text).strip()


def emotion_set(value: object) -> list[str]:
    labels = {part.strip() for part in str(value or "").split(";")}
    return sorted(labels - EMOTION_META)


def logistic() -> LogisticRegression:
    return LogisticRegression(
        max_iter=3000,
        class_weight="balanced",
        solver="lbfgs",
        random_state=20261026,
    )


def save_aggregate_plots(polarity: pd.DataFrame, emotions: pd.DataFrame) -> None:
    plot_dir = OUTPUT / "graficos"
    plot_dir.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(polarity["polaridad_predicha"], polarity["mensajes"], color="#2C7FB8")
    ax.set_ylabel("Mensajes")
    ax.set_xlabel("")
    ax.tick_params(axis="x", rotation=30)
    ax.set_title("Polaridad predicha en el corpus completo")
    plt.tight_layout()
    plt.savefig(plot_dir / "01_polaridad_corpus.png", dpi=180)
    plt.close()

    chart = emotions.sort_values("mensajes")
    fig, ax = plt.subplots(figsize=(9, 6))
    ax.barh(chart["emocion_predicha"], chart["mensajes"], color="#41B6C4")
    ax.set_xlabel("Mensajes")
    ax.set_ylabel("")
    ax.set_title("Emociones predichas en el corpus completo")
    plt.tight_layout()
    plt.savefig(plot_dir / "02_emociones_corpus.png", dpi=180)
    plt.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--emotion-threshold", type=float, default=0.5)
    args = parser.parse_args()
    for path in (DATASET, CORPUS, CV_CONFIG):
        if not path.exists():
            raise SystemExit(f"No se encontro {path}.")
    if not 0 < args.emotion_threshold < 1:
        raise SystemExit("--emotion-threshold debe estar entre 0 y 1.")

    with CV_CONFIG.open(encoding="utf-8") as handle:
        cv_config = json.load(handle)
    selected = cv_config["selected_learned_models"]
    if set(selected.values()) != {"hibrido_tfidf_minilm"}:
        raise SystemExit(
            "Este script implementa el hibrido seleccionado. Ejecute nuevamente "
            "la validacion cruzada o revise configuracion_modelo.json."
        )

    labeled = pd.read_csv(DATASET, dtype=str, keep_default_na=False)
    corpus = pd.read_csv(CORPUS, dtype=str, keep_default_na=False)
    labeled_text = labeled["texto"].map(normalize_text)
    corpus_text = corpus["texto"].map(normalize_text)

    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        min_df=2,
        max_features=30000,
        sublinear_tf=True,
    )
    tfidf_labeled = vectorizer.fit_transform(labeled_text)
    tfidf_corpus = vectorizer.transform(corpus_text)

    model_name = cv_config["embedding_model"]
    encoder = SentenceTransformer(model_name)
    print(f"Calculando embeddings de entrenamiento: {len(labeled)} mensajes...")
    embedding_labeled = encoder.encode(
        labeled_text.tolist(),
        batch_size=args.batch_size,
        show_progress_bar=True,
        normalize_embeddings=True,
    )
    print(f"Calculando embeddings del corpus: {len(corpus)} mensajes...")
    embedding_corpus = encoder.encode(
        corpus_text.tolist(),
        batch_size=args.batch_size,
        show_progress_bar=True,
        normalize_embeddings=True,
    )

    x_labeled = sparse.hstack(
        [tfidf_labeled, sparse.csr_matrix(embedding_labeled)], format="csr"
    )
    x_corpus = sparse.hstack(
        [tfidf_corpus, sparse.csr_matrix(embedding_corpus)], format="csr"
    )

    polarity_classifier = logistic()
    polarity_classifier.fit(x_labeled, labeled["polaridad_objetivo"])
    polarity_prediction = polarity_classifier.predict(x_corpus)
    polarity_probability = polarity_classifier.predict_proba(x_corpus)

    emotion_classes = cv_config["emotion_classes"]
    mlb = MultiLabelBinarizer(classes=emotion_classes)
    emotion_truth = mlb.fit_transform(
        labeled["sentimientos_objetivo"].map(emotion_set).map(
            lambda labels: [label for label in labels if label in emotion_classes]
        )
    )
    emotion_classifier = OneVsRestClassifier(logistic(), n_jobs=-1)
    emotion_classifier.fit(x_labeled, emotion_truth)
    emotion_probability = emotion_classifier.predict_proba(x_corpus)
    emotion_prediction = (emotion_probability >= args.emotion_threshold).astype(int)
    emotion_labels = [
        ";".join(labels) if labels else "sin_sentimiento"
        for labels in mlb.inverse_transform(emotion_prediction)
    ]

    OUTPUT.mkdir(parents=True, exist_ok=True)
    predictions = pd.DataFrame(
        {
            "message_id": corpus["message_id"],
            "gestion": corpus["gestion"],
            "fecha": corpus["fecha"],
            "hora": corpus["hora"],
            "es_muestra_manual": corpus["message_id"].isin(set(labeled["message_id"])),
            "polaridad_predicha": polarity_prediction,
            "confianza_polaridad": polarity_probability.max(axis=1),
            "emociones_predichas": emotion_labels,
            "confianza_emocion_max": emotion_probability.max(axis=1),
        }
    )
    predictions.to_csv(OUTPUT / "predicciones_corpus.csv", index=False)

    polarity_summary = (
        predictions.groupby("polaridad_predicha", as_index=False)
        .size()
        .rename(columns={"size": "mensajes"})
        .sort_values("mensajes", ascending=False)
    )
    polarity_summary["porcentaje"] = polarity_summary["mensajes"] / len(predictions)
    emotion_rows = predictions.assign(
        emocion_predicha=predictions["emociones_predichas"].str.split(";")
    ).explode("emocion_predicha")
    emotion_summary = (
        emotion_rows.groupby("emocion_predicha", as_index=False)
        .size()
        .rename(columns={"size": "mensajes"})
        .sort_values("mensajes", ascending=False)
    )
    emotion_summary["porcentaje_mensajes"] = (
        emotion_summary["mensajes"] / len(predictions)
    )
    by_year = (
        predictions.groupby(["gestion", "polaridad_predicha"], as_index=False)
        .size()
        .rename(columns={"size": "mensajes"})
    )
    by_year["porcentaje_gestion"] = by_year["mensajes"] / by_year.groupby(
        "gestion"
    )["mensajes"].transform("sum")
    by_month = (
        predictions.assign(mes=predictions["fecha"].str.slice(0, 7))
        .groupby(["mes", "polaridad_predicha"], as_index=False)
        .size()
        .rename(columns={"size": "mensajes"})
    )

    polarity_summary.to_csv(OUTPUT / "resumen_polaridad.csv", index=False)
    emotion_summary.to_csv(OUTPUT / "resumen_emociones.csv", index=False)
    by_year.to_csv(OUTPUT / "polaridad_por_gestion.csv", index=False)
    by_month.to_csv(OUTPUT / "polaridad_por_mes.csv", index=False)
    save_aggregate_plots(polarity_summary, emotion_summary)

    artifact_dir = OUTPUT / "artefactos"
    artifact_dir.mkdir(parents=True, exist_ok=True)
    joblib.dump(vectorizer, artifact_dir / "vectorizador_tfidf.joblib")
    joblib.dump(polarity_classifier, artifact_dir / "clasificador_polaridad.joblib")
    joblib.dump(emotion_classifier, artifact_dir / "clasificador_emociones.joblib")
    joblib.dump(mlb, artifact_dir / "codificador_emociones.joblib")
    with (OUTPUT / "configuracion_modelo_final.json").open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "model": "hibrido_tfidf_minilm",
                "embedding_model": model_name,
                "training_rows": len(labeled),
                "corpus_rows": len(corpus),
                "emotion_threshold": args.emotion_threshold,
                "emotion_classes": emotion_classes,
                "text_is_excluded_from_predictions": True,
            },
            handle,
            ensure_ascii=False,
            indent=2,
        )

    print(f"Corpus clasificado: {len(predictions)} mensajes.")
    print(f"Resultados: {OUTPUT}")


if __name__ == "__main__":
    main()
