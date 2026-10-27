#!/usr/bin/env python3
"""Validacion cruzada agrupada para polaridad y emociones multietiqueta."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
os.environ.setdefault("MPLCONFIGDIR", str(ROOT / ".cache" / "matplotlib"))

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import sparse
from sentence_transformers import SentenceTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    ConfusionMatrixDisplay,
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    f1_score,
    hamming_loss,
)
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.multiclass import OneVsRestClassifier
from sklearn.preprocessing import MultiLabelBinarizer


DATASET = ROOT / "datos" / "dataset_manual" / "dataset_modelado_umsa.csv"
OUTPUT = ROOT / "resultados" / "validacion_cruzada"
EMOTION_META = {"", "sin_sentimiento", "ambiguo", "otro"}
LEARNED_MODELS = ("tfidf_logistica", "minilm_logistica", "hibrido_tfidf_minilm")


def normalize_text(value: object) -> str:
    text = unicodedata.normalize("NFC", str(value or ""))
    text = re.sub(r"https?://\S+|www\.\S+", " <URL> ", text, flags=re.I)
    return re.sub(r"\s+", " ", text).strip()


def text_group(value: object) -> str:
    normalized = normalize_text(value).lower()
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


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


def polarity_summary(
    model: str,
    truth: np.ndarray,
    prediction: np.ndarray,
    labels: list[str],
    fold: int | str,
) -> dict:
    return {
        "task": "polaridad",
        "model": model,
        "fold": fold,
        "n_test": len(truth),
        "accuracy": accuracy_score(truth, prediction),
        "balanced_accuracy": balanced_accuracy_score(truth, prediction),
        "macro_f1": f1_score(
            truth, prediction, labels=labels, average="macro", zero_division=0
        ),
        "micro_f1": f1_score(
            truth, prediction, labels=labels, average="micro", zero_division=0
        ),
        "hamming_loss": np.nan,
    }


def emotion_summary(
    model: str,
    truth: np.ndarray,
    prediction: np.ndarray,
    fold: int | str,
) -> dict:
    return {
        "task": "emociones_multietiqueta",
        "model": model,
        "fold": fold,
        "n_test": truth.shape[0],
        "accuracy": accuracy_score(truth, prediction),
        "balanced_accuracy": np.nan,
        "macro_f1": f1_score(truth, prediction, average="macro", zero_division=0),
        "micro_f1": f1_score(truth, prediction, average="micro", zero_division=0),
        "hamming_loss": hamming_loss(truth, prediction),
    }


def per_class_polarity(
    model: str,
    truth: np.ndarray,
    prediction: np.ndarray,
    labels: list[str],
) -> pd.DataFrame:
    report = classification_report(
        truth,
        prediction,
        labels=labels,
        output_dict=True,
        zero_division=0,
    )
    return pd.DataFrame(
        [
            {
                "task": "polaridad",
                "model": model,
                "class": label,
                "support": int(report[label]["support"]),
                "precision": report[label]["precision"],
                "recall": report[label]["recall"],
                "f1": report[label]["f1-score"],
            }
            for label in labels
        ]
    )


def per_class_emotions(
    model: str,
    truth: np.ndarray,
    prediction: np.ndarray,
    classes: list[str],
) -> pd.DataFrame:
    rows = []
    for index, label in enumerate(classes):
        report = classification_report(
            truth[:, index],
            prediction[:, index],
            labels=[0, 1],
            output_dict=True,
            zero_division=0,
        )
        rows.append(
            {
                "task": "emociones_multietiqueta",
                "model": model,
                "class": label,
                "support": int(truth[:, index].sum()),
                "precision": report["1"]["precision"],
                "recall": report["1"]["recall"],
                "f1": report["1"]["f1-score"],
            }
        )
    return pd.DataFrame(rows)


def save_plots(
    summaries: pd.DataFrame,
    per_class: pd.DataFrame,
    truth_polarity: np.ndarray,
    polar_predictions: dict[str, np.ndarray],
    selected_models: dict[str, str],
    labels: list[str],
) -> None:
    plot_dir = OUTPUT / "graficos"
    plot_dir.mkdir(parents=True, exist_ok=True)

    comparison = summaries.pivot(index="model", columns="task", values="macro_f1")
    comparison = comparison.rename(
        columns={"polaridad": "Polaridad", "emociones_multietiqueta": "Emociones"}
    )
    comparison = comparison.rename(
        index={
            "baseline_mayoritario": "Mayoritaria",
            "baseline_sin_emocion": "Sin emoción",
            "diccionario_reglas": "Diccionario",
            "tfidf_logistica": "TF-IDF",
            "minilm_logistica": "MiniLM",
            "hibrido_tfidf_minilm": "TF-IDF + MiniLM",
        }
    )
    ax = comparison.plot(kind="bar", figsize=(10, 5), color=["#2C7FB8", "#7FCDBB"])
    ax.set_ylabel("Macro-F1")
    ax.set_xlabel("")
    ax.set_ylim(0, max(0.5, float(np.nanmax(comparison.to_numpy())) * 1.2))
    ax.legend(title="Tarea")
    ax.tick_params(axis="x", rotation=25)
    plt.tight_layout()
    plt.savefig(plot_dir / "01_comparacion_macro_f1.png", dpi=180)
    plt.close()

    best_polar = selected_models["polaridad"]
    fig, ax = plt.subplots(figsize=(8, 7))
    ConfusionMatrixDisplay.from_predictions(
        truth_polarity,
        polar_predictions[best_polar],
        labels=labels,
        display_labels=[label.replace("_", " ") for label in labels],
        xticks_rotation=35,
        cmap="Blues",
        colorbar=False,
        ax=ax,
    )
    ax.set_xlabel("Predicción")
    ax.set_ylabel("Etiqueta real")
    ax.set_title("Matriz de confusión OOF: TF-IDF + MiniLM")
    plt.tight_layout()
    plt.savefig(plot_dir / "02_matriz_confusion_polaridad.png", dpi=180)
    plt.close()

    best_emotion = selected_models["emociones_multietiqueta"]
    emotion_table = per_class[
        (per_class["task"] == "emociones_multietiqueta")
        & (per_class["model"] == best_emotion)
    ].sort_values("f1")
    fig, ax = plt.subplots(figsize=(9, 6))
    ax.barh(emotion_table["class"], emotion_table["f1"], color="#41B6C4")
    ax.set_xlabel("F1")
    ax.set_ylabel("")
    ax.set_xlim(0, 1)
    ax.set_title("F1 por emoción: TF-IDF + MiniLM")
    plt.tight_layout()
    plt.savefig(plot_dir / "03_f1_por_emocion.png", dpi=180)
    plt.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model",
        default="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
    )
    parser.add_argument("--folds", type=int, default=5)
    parser.add_argument("--min-emotion-support", type=int, default=20)
    args = parser.parse_args()

    if not DATASET.exists():
        raise SystemExit(f"No se encontro {DATASET}; ejecute primero el script 07.")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    data = pd.read_csv(DATASET, dtype=str, keep_default_na=False)
    required = {
        "message_id",
        "texto",
        "polaridad_objetivo",
        "sentimientos_objetivo",
        "polaridad_regla",
        "emociones_regla",
    }
    missing = required - set(data.columns)
    if missing:
        raise SystemExit(f"Faltan columnas en el dataset: {sorted(missing)}")

    data["text_model"] = data["texto"].map(normalize_text)
    data["text_group"] = data["texto"].map(text_group)
    polarity_labels = sorted(data["polaridad_objetivo"].unique().tolist())
    emotion_lists = data["sentimientos_objetivo"].map(emotion_set)
    emotion_support = pd.Series(
        [label for labels in emotion_lists for label in labels], dtype="object"
    ).value_counts()
    selected_emotions = sorted(
        emotion_support[emotion_support >= args.min_emotion_support].index.tolist()
    )
    if len(selected_emotions) < 8:
        raise SystemExit(
            f"Solo {len(selected_emotions)} emociones tienen soporte suficiente; se requieren 8."
        )
    mlb = MultiLabelBinarizer(classes=selected_emotions)
    y_emotions = mlb.fit_transform(
        emotion_lists.map(
            lambda labels: [label for label in labels if label in selected_emotions]
        )
    )
    y_polarity = data["polaridad_objetivo"].to_numpy()

    print(f"Calculando embeddings de {len(data)} mensajes una sola vez...")
    encoder = SentenceTransformer(args.model)
    embeddings = encoder.encode(
        data["text_model"].tolist(),
        batch_size=32,
        show_progress_bar=True,
        normalize_embeddings=True,
    )

    splitter = StratifiedGroupKFold(
        n_splits=args.folds,
        shuffle=True,
        random_state=20261026,
    )
    splits = list(
        splitter.split(data, y_polarity, groups=data["text_group"].to_numpy())
    )
    model_names = (
        "baseline_mayoritario",
        "diccionario_reglas",
        *LEARNED_MODELS,
    )
    polar_oof = {name: np.empty(len(data), dtype=object) for name in model_names}
    emotion_oof = {
        "baseline_sin_emocion": np.zeros_like(y_emotions),
        "diccionario_reglas": np.zeros_like(y_emotions),
        **{name: np.zeros_like(y_emotions) for name in LEARNED_MODELS},
    }
    fold_rows: list[dict] = []
    fold_assignment = np.zeros(len(data), dtype=int)

    rule_polarity = data["polaridad_regla"].replace(
        {"sin coincidencia": "sin_sentimiento", "sin_coincidencia": "sin_sentimiento"}
    ).to_numpy()
    rule_emotions = mlb.transform(
        data["emociones_regla"].map(emotion_set).map(
            lambda labels: [label for label in labels if label in selected_emotions]
        )
    )

    for fold, (train_index, test_index) in enumerate(splits, start=1):
        fold_assignment[test_index] = fold
        train_groups = set(data.iloc[train_index]["text_group"])
        test_groups = set(data.iloc[test_index]["text_group"])
        if train_groups & test_groups:
            raise RuntimeError("Un texto duplicado cruzo entrenamiento y prueba.")

        vectorizer = TfidfVectorizer(
            ngram_range=(1, 2),
            min_df=2,
            max_features=30000,
            sublinear_tf=True,
        )
        tfidf_train = vectorizer.fit_transform(data.iloc[train_index]["text_model"])
        tfidf_test = vectorizer.transform(data.iloc[test_index]["text_model"])
        embedding_train = embeddings[train_index]
        embedding_test = embeddings[test_index]
        hybrid_train = sparse.hstack(
            [tfidf_train, sparse.csr_matrix(embedding_train)], format="csr"
        )
        hybrid_test = sparse.hstack(
            [tfidf_test, sparse.csr_matrix(embedding_test)], format="csr"
        )
        feature_sets = {
            "tfidf_logistica": (tfidf_train, tfidf_test),
            "minilm_logistica": (embedding_train, embedding_test),
            "hibrido_tfidf_minilm": (hybrid_train, hybrid_test),
        }

        majority = pd.Series(y_polarity[train_index]).mode().iloc[0]
        polar_oof["baseline_mayoritario"][test_index] = majority
        polar_oof["diccionario_reglas"][test_index] = rule_polarity[test_index]
        emotion_oof["diccionario_reglas"][test_index] = rule_emotions[test_index]

        for name, (x_train, x_test) in feature_sets.items():
            polar_classifier = logistic()
            polar_classifier.fit(x_train, y_polarity[train_index])
            polar_oof[name][test_index] = polar_classifier.predict(x_test)

            emotion_classifier = OneVsRestClassifier(logistic(), n_jobs=-1)
            emotion_classifier.fit(x_train, y_emotions[train_index])
            emotion_oof[name][test_index] = emotion_classifier.predict(x_test)

        for name in model_names:
            fold_rows.append(
                polarity_summary(
                    name,
                    y_polarity[test_index],
                    polar_oof[name][test_index],
                    polarity_labels,
                    fold,
                )
            )
        for name in emotion_oof:
            fold_rows.append(
                emotion_summary(
                    name,
                    y_emotions[test_index],
                    emotion_oof[name][test_index],
                    fold,
                )
            )
        print(f"Fold {fold}/{args.folds} terminado: {len(test_index)} mensajes de prueba.")

    summaries = []
    class_tables = []
    for name, prediction in polar_oof.items():
        summaries.append(
            polarity_summary(name, y_polarity, prediction, polarity_labels, "OOF")
        )
        class_tables.append(
            per_class_polarity(name, y_polarity, prediction, polarity_labels)
        )
    for name, prediction in emotion_oof.items():
        summaries.append(emotion_summary(name, y_emotions, prediction, "OOF"))
        class_tables.append(
            per_class_emotions(name, y_emotions, prediction, selected_emotions)
        )

    summary_df = pd.DataFrame(summaries).drop(columns="fold")
    fold_df = pd.DataFrame(fold_rows)
    fold_aggregate = (
        fold_df.groupby(["task", "model"], as_index=False)
        .agg(
            folds=("fold", "nunique"),
            macro_f1_mean=("macro_f1", "mean"),
            macro_f1_sd=("macro_f1", "std"),
            micro_f1_mean=("micro_f1", "mean"),
            micro_f1_sd=("micro_f1", "std"),
            accuracy_mean=("accuracy", "mean"),
            accuracy_sd=("accuracy", "std"),
        )
    )
    class_df = pd.concat(class_tables, ignore_index=True)
    learned_summary = summary_df[summary_df["model"].isin(LEARNED_MODELS)]
    selected_models = {
        task: group.loc[group["macro_f1"].idxmax(), "model"]
        for task, group in learned_summary.groupby("task")
    }

    predictions = pd.DataFrame(
        {
            "message_id": data["message_id"],
            "fold": fold_assignment,
            "polaridad_real": y_polarity,
            "emociones_reales": [";".join(labels) for labels in mlb.inverse_transform(y_emotions)],
        }
    )
    for name, prediction in polar_oof.items():
        predictions[f"polaridad_{name}"] = prediction
    for name, prediction in emotion_oof.items():
        predictions[f"emociones_{name}"] = [
            ";".join(labels) for labels in mlb.inverse_transform(prediction)
        ]

    summary_df.to_csv(OUTPUT / "comparacion_modelos.csv", index=False)
    fold_df.to_csv(OUTPUT / "metricas_por_fold.csv", index=False)
    fold_aggregate.to_csv(OUTPUT / "resumen_folds.csv", index=False)
    class_df.to_csv(OUTPUT / "metricas_por_clase.csv", index=False)
    predictions.to_csv(OUTPUT / "predicciones_oof_privadas.csv", index=False)
    save_plots(
        summary_df,
        class_df,
        y_polarity,
        polar_oof,
        selected_models,
        polarity_labels,
    )
    with (OUTPUT / "configuracion_modelo.json").open("w", encoding="utf-8") as handle:
        json.dump(
            {
                "embedding_model": args.model,
                "dataset": str(DATASET.relative_to(ROOT)),
                "rows": len(data),
                "folds": args.folds,
                "unique_text_groups": int(data["text_group"].nunique()),
                "duplicate_rows_beyond_first": int(
                    len(data) - data["text_group"].nunique()
                ),
                "emotion_classes": selected_emotions,
                "min_emotion_support": args.min_emotion_support,
                "selected_learned_models": selected_models,
                "split_definition": "StratifiedGroupKFold por polaridad y hash de texto",
            },
            handle,
            ensure_ascii=False,
            indent=2,
        )

    print("\nMetricas agregadas con predicciones fuera de muestra:")
    print(summary_df.to_string(index=False))
    print(f"\nModelos aprendidos seleccionados: {selected_models}")
    print(f"Resultados: {OUTPUT}")


if __name__ == "__main__":
    main()
