#!/usr/bin/env python3
"""Compara TF-IDF y embeddings congelados sin exponer el texto en resultados."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import unicodedata
from pathlib import Path

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    f1_score,
    hamming_loss,
)
from sklearn.multiclass import OneVsRestClassifier
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.preprocessing import MultiLabelBinarizer


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "datos" / "dataset_manual" / "dataset_consenso_umsa.csv"
ADJUDICATED_DATASET = ROOT / "datos" / "dataset_manual" / "dataset_modelado_umsa.csv"
OUTPUT = ROOT / "resultados" / "modelos_embeddings"
EMOTION_META = {"", "sin_sentimiento", "ambiguo", "otro"}


def normalize_text(value: object) -> str:
    text = unicodedata.normalize("NFC", str(value or ""))
    text = re.sub(r"https?://\S+|www\.\S+", " <URL> ", text, flags=re.I)
    return re.sub(r"\s+", " ", text).strip()


def normalize_group(value: object) -> str:
    text = normalize_text(value).lower()
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


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


def evaluate_polarity(name: str, truth: np.ndarray, prediction: np.ndarray) -> tuple[dict, pd.DataFrame]:
    labels = sorted(set(truth) | set(prediction))
    report = classification_report(
        truth,
        prediction,
        labels=labels,
        output_dict=True,
        zero_division=0,
    )
    summary = {
        "task": "polaridad",
        "model": name,
        "n_test": len(truth),
        "accuracy": accuracy_score(truth, prediction),
        "balanced_accuracy": balanced_accuracy_score(truth, prediction),
        "macro_f1": f1_score(truth, prediction, labels=labels, average="macro", zero_division=0),
        "micro_f1": f1_score(truth, prediction, labels=labels, average="micro", zero_division=0),
    }
    rows = []
    for label in labels:
        values = report[label]
        rows.append(
            {
                "task": "polaridad",
                "model": name,
                "class": label,
                "support": values["support"],
                "precision": values["precision"],
                "recall": values["recall"],
                "f1": values["f1-score"],
            }
        )
    return summary, pd.DataFrame(rows)


def evaluate_emotions(
    name: str,
    truth: np.ndarray,
    prediction: np.ndarray,
    classes: list[str],
) -> tuple[dict, pd.DataFrame]:
    summary = {
        "task": "emociones_multietiqueta",
        "model": name,
        "n_test": truth.shape[0],
        "accuracy": accuracy_score(truth, prediction),
        "balanced_accuracy": np.nan,
        "macro_f1": f1_score(truth, prediction, average="macro", zero_division=0),
        "micro_f1": f1_score(truth, prediction, average="micro", zero_division=0),
        "hamming_loss": hamming_loss(truth, prediction),
    }
    rows = []
    for index, label in enumerate(classes):
        rows.append(
            {
                "task": "emociones_multietiqueta",
                "model": name,
                "class": label,
                "support": int(truth[:, index].sum()),
                "precision": classification_report(
                    truth[:, index], prediction[:, index], output_dict=True, zero_division=0
                )["1"]["precision"],
                "recall": classification_report(
                    truth[:, index], prediction[:, index], output_dict=True, zero_division=0
                )["1"]["recall"],
                "f1": f1_score(truth[:, index], prediction[:, index], zero_division=0),
            }
        )
    return summary, pd.DataFrame(rows)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model",
        default="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
    )
    parser.add_argument("--min-emotion-support", type=int, default=20)
    args = parser.parse_args()

    dataset_path = ADJUDICATED_DATASET if ADJUDICATED_DATASET.exists() else DATASET
    if not dataset_path.exists():
        raise SystemExit(f"No se encontro {dataset_path}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    data = pd.read_csv(dataset_path, dtype=str, keep_default_na=False)
    data["text_model"] = data["texto"].map(normalize_text)
    data["text_group"] = data["texto"].map(normalize_group)

    if dataset_path == ADJUDICATED_DATASET:
        high_confidence = data[data["apto_test_alta_confianza"] == "TRUE"].copy()
        splitter = StratifiedGroupKFold(n_splits=5, shuffle=True, random_state=20261026)
        _, test_positions = next(
            splitter.split(
                high_confidence,
                high_confidence["polaridad_objetivo"],
                high_confidence["text_group"],
            )
        )
        test = high_confidence.iloc[test_positions].copy()
        train = data.drop(test.index).copy()
        polar_train_column = "polaridad_objetivo"
        polar_test_column = "polaridad_objetivo"
        emotion_train_column = "sentimientos_objetivo"
        emotion_test_column = "sentimientos_objetivo"
        test_definition = "fold estratificado y agrupado dentro de filas A/B adjudicadas"
    else:
        # Antes de adjudicar, la prueba usa solo acuerdos simultaneos A/B. Es un
        # diagnostico exploratorio y no una muestra poblacional.
        test = data[data["estado_consenso"] == "acuerdo_ab"].copy()
        train = data[data["estado_consenso"] != "acuerdo_ab"].copy()
        polar_train_column = "polaridad_manual"
        polar_test_column = "polaridad_consenso"
        emotion_train_column = "sentimientos_a"
        emotion_test_column = "sentimientos_consenso"
        test_definition = "acuerdo_ab en polaridad y conjunto de sentimientos"
    test_groups = set(test["text_group"])
    train = train[~train["text_group"].isin(test_groups)].copy()
    if len(test) < 50 or len(train) < 100:
        raise SystemExit("No hay suficientes filas separadas para entrenar y evaluar.")

    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        min_df=2,
        max_features=30000,
        sublinear_tf=True,
    )
    x_tfidf_train = vectorizer.fit_transform(train["text_model"])
    x_tfidf_test = vectorizer.transform(test["text_model"])

    model = SentenceTransformer(args.model)
    x_embedding_train = model.encode(
        train["text_model"].tolist(),
        batch_size=32,
        show_progress_bar=True,
        normalize_embeddings=True,
    )
    x_embedding_test = model.encode(
        test["text_model"].tolist(),
        batch_size=32,
        show_progress_bar=True,
        normalize_embeddings=True,
    )

    summaries: list[dict] = []
    class_tables: list[pd.DataFrame] = []
    prediction_output = pd.DataFrame({"message_id": test["message_id"]})

    y_polar_train = train[polar_train_column].to_numpy()
    y_polar_test = test[polar_test_column].to_numpy()
    majority_polarity = pd.Series(y_polar_train).mode().iloc[0]
    majority_prediction = np.repeat(majority_polarity, len(y_polar_test))
    summary, per_class = evaluate_polarity(
        "baseline_mayoritario", y_polar_test, majority_prediction
    )
    summaries.append(summary)
    class_tables.append(per_class)
    prediction_output["polaridad_baseline_mayoritario"] = majority_prediction

    rule_polarity = (
        test["polaridad_regla"]
        .replace({"sin coincidencia": "sin_sentimiento"})
        .to_numpy()
    )
    summary, per_class = evaluate_polarity(
        "diccionario_reglas", y_polar_test, rule_polarity
    )
    summaries.append(summary)
    class_tables.append(per_class)
    prediction_output["polaridad_diccionario_reglas"] = rule_polarity
    for name, x_train, x_test in (
        ("tfidf_logistica", x_tfidf_train, x_tfidf_test),
        ("minilm_logistica", x_embedding_train, x_embedding_test),
    ):
        classifier = logistic()
        classifier.fit(x_train, y_polar_train)
        prediction = classifier.predict(x_test)
        summary, per_class = evaluate_polarity(name, y_polar_test, prediction)
        summaries.append(summary)
        class_tables.append(per_class)
        prediction_output[f"polaridad_{name}"] = prediction

    train_emotions = train[emotion_train_column].map(emotion_set)
    test_emotions = test[emotion_test_column].map(emotion_set)
    support = pd.Series(label for labels in train_emotions for label in labels).value_counts()
    selected = sorted(support[support >= args.min_emotion_support].index.tolist())
    test_support = {label: sum(label in labels for labels in test_emotions) for label in selected}
    selected = [label for label in selected if test_support[label] > 0]
    if len(selected) < 8:
        raise SystemExit(
            f"Solo {len(selected)} emociones tienen soporte suficiente; se requieren al menos 8."
        )
    mlb = MultiLabelBinarizer(classes=selected)
    train_selected = train_emotions.map(
        lambda labels: [label for label in labels if label in selected]
    )
    test_selected = test_emotions.map(
        lambda labels: [label for label in labels if label in selected]
    )
    y_emotion_train = mlb.fit_transform(train_selected)
    y_emotion_test = mlb.transform(test_selected)

    no_emotion_prediction = np.zeros_like(y_emotion_test)
    summary, per_class = evaluate_emotions(
        "baseline_sin_emocion", y_emotion_test, no_emotion_prediction, selected
    )
    summaries.append(summary)
    class_tables.append(per_class)
    prediction_output["emociones_baseline_sin_emocion"] = ""

    rule_emotions = test["emociones_regla"].map(emotion_set).map(
        lambda labels: [label for label in labels if label in selected]
    )
    y_emotion_rule = mlb.transform(rule_emotions)
    summary, per_class = evaluate_emotions(
        "diccionario_reglas", y_emotion_test, y_emotion_rule, selected
    )
    summaries.append(summary)
    class_tables.append(per_class)
    prediction_output["emociones_diccionario_reglas"] = [
        ";".join(labels) for labels in mlb.inverse_transform(y_emotion_rule)
    ]

    for name, x_train, x_test in (
        ("tfidf_logistica", x_tfidf_train, x_tfidf_test),
        ("minilm_logistica", x_embedding_train, x_embedding_test),
    ):
        classifier = OneVsRestClassifier(logistic(), n_jobs=-1)
        classifier.fit(x_train, y_emotion_train)
        prediction = classifier.predict(x_test)
        summary, per_class = evaluate_emotions(
            name, y_emotion_test, prediction, selected
        )
        summaries.append(summary)
        class_tables.append(per_class)
        prediction_output[f"emociones_{name}"] = [
            ";".join(labels) for labels in mlb.inverse_transform(prediction)
        ]

    summary_df = pd.DataFrame(summaries)
    class_df = pd.concat(class_tables, ignore_index=True)
    summary_df.to_csv(OUTPUT / "comparacion_modelos.csv", index=False)
    class_df.to_csv(OUTPUT / "metricas_por_clase.csv", index=False)
    prediction_output.to_csv(OUTPUT / "predicciones_privadas.csv", index=False)
    with (OUTPUT / "configuracion_modelo.json").open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "embedding_model": args.model,
                "dataset": str(dataset_path.relative_to(ROOT)),
                "train_rows": len(train),
                "test_rows": len(test),
                "duplicate_groups_removed_from_train": int(
                    data[data["estado_consenso"] != "acuerdo_ab"]["text_group"].isin(test_groups).sum()
                ),
                "emotion_classes": selected,
                "min_emotion_support": args.min_emotion_support,
                "test_definition": test_definition,
            },
            handle,
            ensure_ascii=False,
            indent=2,
        )
    print(summary_df.to_string(index=False))
    print(f"\nEmociones modeladas ({len(selected)}): {', '.join(selected)}")
    print(f"Resultados: {OUTPUT}")


if __name__ == "__main__":
    main()
