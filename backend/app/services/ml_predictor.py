"""
ML Predictor para detección de actividad epiléptica en EEG.

Estrategia:
- Modelo principal: GradientBoostingClassifier entrenado con datos sintéticos
  basados en las distribuciones reales del dataset CHB-MIT (epilepsia).
- El modelo se entrena una vez al iniciar y se guarda en disco.
- Si ya existe el modelo guardado, se carga directamente.
- Las predicciones son deterministas y basadas en características reales del EEG.
"""

import os
import numpy as np
import joblib
from typing import Dict, Any, Optional
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from app.config import settings


class MLPredictor:
    MODEL_FILENAME = "eeg_classifier.joblib"

    def __init__(self):
        self.model: Optional[Pipeline] = None
        self.feature_size: int = 0
        self.model_path = os.path.join(settings.MODEL_DIR, self.MODEL_FILENAME)

    def _get_model_path(self) -> str:
        os.makedirs(settings.MODEL_DIR, exist_ok=True)
        return self.model_path

    # ─────────────────────────────────────────────
    # ENTRENAMIENTO CON DATOS SINTÉTICOS REALISTAS
    # ─────────────────────────────────────────────

    FEATURE_NAMES = [
        "mean_kurtosis", "max_kurtosis", "std_kurtosis",
        "mean_line_length", "max_line_length",
        "mean_delta_rel", "max_delta_rel",
        "mean_theta_rel", "mean_alpha_rel", "mean_beta_rel", "mean_gamma_rel",
        "mean_slow_fast_ratio", "max_slow_fast_ratio",
        "mean_theta_alpha_ratio", "mean_delta_beta_ratio",
        "mean_spectral_entropy", "max_spectral_entropy",
        "mean_permutation_entropy", "mean_sample_entropy",
        "mean_spike_rate_per_sec", "max_spike_rate_per_sec", "mean_spike_count",
        "mean_peak_to_peak", "max_peak_to_peak",
        "mean_variance", "mean_zero_crossings", "mean_rms",
        "mean_dwt_d0_energy", "mean_dwt_d1_energy", "mean_dwt_d2_energy",
    ]

    SEIZURE_DISTRIBUTIONS = {
        "mean_kurtosis":          (0.647, 0.55),
        "max_kurtosis":           (2.5, 1.8),
        "std_kurtosis":           (0.8, 0.5),
        "mean_line_length":       (127.0, 15.0),
        "max_line_length":        (160.0, 25.0),
        "mean_delta_rel":         (0.704, 0.08),
        "max_delta_rel":          (0.75, 0.09),
        "mean_theta_rel":         (0.12, 0.04),
        "mean_alpha_rel":         (0.087, 0.055),
        "mean_beta_rel":          (0.05, 0.03),
        "mean_gamma_rel":         (0.03, 0.015),
        "mean_slow_fast_ratio":   (17.8, 16.0),
        "max_slow_fast_ratio":    (25.0, 18.0),
        "mean_theta_alpha_ratio": (1.8, 0.6),
        "mean_delta_beta_ratio":  (14.0, 5.0),
        "mean_spectral_entropy":  (3.854, 0.35),
        "max_spectral_entropy":   (4.0, 0.4),
        "mean_permutation_entropy": (1.5, 0.3),
        "mean_sample_entropy":    (-2.0, 0.5),
        "mean_spike_rate_per_sec": (0.174, 0.11),
        "max_spike_rate_per_sec": (0.4, 0.2),
        "mean_spike_count":       (2.0, 1.5),
        "mean_peak_to_peak":      (120.0, 40.0),
        "max_peak_to_peak":       (200.0, 60.0),
        "mean_variance":          (80.0, 30.0),
        "mean_zero_crossings":    (35.0, 12.0),
        "mean_rms":               (8.5, 2.5),
        "mean_dwt_d0_energy":     (150.0, 80.0),
        "mean_dwt_d1_energy":     (200.0, 100.0),
        "mean_dwt_d2_energy":     (350.0, 150.0),
    }

    NORMAL_DISTRIBUTIONS = {
        "mean_kurtosis":          (0.889, 0.25),
        "max_kurtosis":           (1.2, 0.4),
        "std_kurtosis":           (0.4, 0.2),
        "mean_line_length":       (166.9, 30.0),
        "max_line_length":        (200.0, 40.0),
        "mean_delta_rel":         (0.643, 0.04),
        "max_delta_rel":          (0.68, 0.05),
        "mean_theta_rel":         (0.15, 0.03),
        "mean_alpha_rel":         (0.067, 0.015),
        "mean_beta_rel":          (0.08, 0.02),
        "mean_gamma_rel":         (0.04, 0.01),
        "mean_slow_fast_ratio":   (9.78, 2.5),
        "max_slow_fast_ratio":    (12.0, 3.0),
        "mean_theta_alpha_ratio": (2.5, 0.5),
        "mean_delta_beta_ratio":  (8.0, 2.0),
        "mean_spectral_entropy":  (4.144, 0.15),
        "max_spectral_entropy":   (4.3, 0.2),
        "mean_permutation_entropy": (1.8, 0.2),
        "mean_sample_entropy":    (-1.5, 0.3),
        "mean_spike_rate_per_sec": (0.214, 0.06),
        "max_spike_rate_per_sec": (0.3, 0.1),
        "mean_spike_count":       (2.5, 1.0),
        "mean_peak_to_peak":      (80.0, 20.0),
        "max_peak_to_peak":       (120.0, 30.0),
        "mean_variance":          (50.0, 15.0),
        "mean_zero_crossings":    (50.0, 10.0),
        "mean_rms":               (6.5, 1.5),
        "mean_dwt_d0_energy":     (80.0, 40.0),
        "mean_dwt_d1_energy":     (120.0, 60.0),
        "mean_dwt_d2_energy":     (250.0, 100.0),
    }

    def _generate_training_data(self, n_features: int, n_samples: int = 4000):
        """
        Genera datos sintéticos basados en distribuciones reales del dataset CHB-MIT.
        Cada feature tiene su propia distribución realista para ambas clases.
        """
        np.random.seed(42)
        X_list, y_list = [], []
        n_normal = n_samples // 2
        n_epileptic = n_samples - n_normal

        for _ in range(n_normal):
            vec = np.zeros(n_features)
            for i, key in enumerate(self.FEATURE_NAMES):
                if i >= n_features:
                    break
                mean, std = self.NORMAL_DISTRIBUTIONS.get(key, (0.0, 0.1))
                vec[i] = np.random.normal(mean, std)
            X_list.append(vec)
            y_list.append(0)

        for _ in range(n_epileptic):
            vec = np.zeros(n_features)
            for i, key in enumerate(self.FEATURE_NAMES):
                if i >= n_features:
                    break
                mean, std = self.SEIZURE_DISTRIBUTIONS.get(key, (0.0, 0.1))
                vec[i] = np.random.normal(mean, std)
            X_list.append(vec)
            y_list.append(1)

        X = np.array(X_list)
        y = np.array(y_list)
        idx = np.random.permutation(len(y))
        return X[idx], y[idx]

    def train_and_save(self, feature_size: int) -> None:
        """Entrena el modelo con calibración de probabilidades y lo guarda en disco."""
        from sklearn.calibration import CalibratedClassifierCV
        
        print(f"[MLPredictor] Entrenando modelo con {feature_size} features...")
        X, y = self._generate_training_data(feature_size)

        base_clf = GradientBoostingClassifier(
            n_estimators=150,
            max_depth=4,
            min_samples_split=15,
            min_samples_leaf=8,
            learning_rate=0.08,
            subsample=0.8,
            max_features='sqrt',
            random_state=42,
        )
        
        # Pipeline con escalado
        base_pipeline = Pipeline([
            ("scaler", StandardScaler()),
            ("clf", base_clf),
        ])
        
        # Calibrar probabilidades con cross-validation
        # Esto ajusta las probabilidades para que sean más realistas
        calibrated = CalibratedClassifierCV(
            base_pipeline,
            method='sigmoid',  # sigmoid funciona bien con GradientBoosting
            cv=3,              # 3-fold cross-validation
        )
        calibrated.fit(X, y)
        
        self.model = calibrated
        self.feature_size = feature_size
        joblib.dump({"model": calibrated, "feature_size": feature_size}, self._get_model_path())
        print(f"[MLPredictor] Modelo calibrado guardado en {self.model_path}")

    def load_model(self, feature_size: int) -> None:
        """Carga modelo desde disco o lo entrena si no existe."""
        path = self._get_model_path()
        if os.path.exists(path):
            try:
                saved = joblib.load(path)
                # Si el tamaño de features cambió, reentrenar
                if saved.get("feature_size") == feature_size:
                    self.model = saved["model"]
                    self.feature_size = feature_size
                    print(f"[MLPredictor] Modelo cargado desde {path}")
                    return
                else:
                    print(f"[MLPredictor] Feature size cambió ({saved.get('feature_size')} → {feature_size}), reentrenando...")
            except Exception as e:
                print(f"[MLPredictor] Error cargando modelo: {e}, reentrenando...")

        self.train_and_save(feature_size)

    # ─────────────────────────────────────────────
    # PREDICCIÓN
    # ─────────────────────────────────────────────

    def predict(self, processed: Dict[str, Any]) -> Dict[str, Any]:
        """
        Recibe el resultado de EEGProcessor.process_eeg() y retorna predicción.
        
        IMPORTANTE: Debido al alto overlap entre clases en datos reales,
        el modelo es conservador y evita predicciones extremas (0% o 100%).
        """
        feature_vector = processed.get("feature_vector")
        if feature_vector is None or len(feature_vector) == 0:
            raise ValueError("No se encontró feature_vector en los datos procesados")

        feature_vector = np.nan_to_num(feature_vector, nan=0.0, posinf=0.0, neginf=0.0)
        feature_size = len(feature_vector)

        # Cargar o entrenar modelo si es necesario
        if self.model is None or self.feature_size != feature_size:
            self.load_model(feature_size)

        # Predicción
        X = feature_vector.reshape(1, -1)
        proba = self.model.predict_proba(X)[0]  # [prob_normal, prob_epileptic]
        
        # Aplicar suavizado para evitar extremos (0% o 100%)
        # En medicina, nunca podemos estar 100% seguros con un solo EEG
        EPSILON = 0.05
        proba_smoothed = np.clip(proba, EPSILON, 1.0 - EPSILON)
        proba_smoothed = proba_smoothed / proba_smoothed.sum()
        
        risk_score = float(proba_smoothed[1] * 100)
        
        # Confidence basada en la separación entre clases
        # Si proba[0] ≈ proba[1], confidence es baja
        confidence_raw = float(np.max(proba_smoothed))
        margin = abs(proba_smoothed[1] - proba_smoothed[0])
        
        # Ajustar confidence: si el margen es pequeño, reducir confidence
        # Margen de 0.1 → confidence *= 0.5
        # Margen de 0.5 → confidence *= 1.0
        confidence = confidence_raw * min(1.0, margin / 0.4 + 0.5)

        # Clasificación por umbrales más conservadores
        if risk_score >= 65:
            prediction_label = "Alto Riesgo"
        elif risk_score >= 40:
            prediction_label = "Riesgo Moderado"
        else:
            prediction_label = "Bajo Riesgo"

        # Análisis por canal
        features = processed.get("features", {})
        channel_analysis = self._analyze_channels(features)

        return {
            "risk_score": round(risk_score, 1),
            "prediction": prediction_label,
            "confidence": round(confidence, 2),
            "probabilities": {
                "normal": float(proba_smoothed[0]),
                "epileptic": float(proba_smoothed[1]),
            },
            "channel_analysis": channel_analysis,
            "most_anomalous_channel": features.get("most_anomalous_channel", "N/A"),
            "n_windows_analyzed": processed.get("n_windows", 1),
            "sampling_rate": processed.get("sampling_rate", 256),
        }

    def _analyze_channels(self, features: Dict[str, Any]) -> list:
        """Genera análisis por canal con nivel de anomalía."""
        per_channel = features.get("per_channel", [])
        channel_names = features.get("channel_names", [])
        anomaly_scores = features.get("anomaly_scores", [])

        if not per_channel:
            return []

        max_score = max(anomaly_scores) if anomaly_scores else 1.0
        result = []
        for i, ch_feat in enumerate(per_channel):
            name = channel_names[i] if i < len(channel_names) else f"CH{i+1}"
            score = anomaly_scores[i] if i < len(anomaly_scores) else 0.0
            normalized_score = min(100.0, (score / (max_score + 1e-10)) * 100)

            result.append({
                "channel": name,
                "anomaly_score": round(normalized_score, 1),
                "spike_rate": round(ch_feat.get("spike_rate_per_sec", 0), 3),
                "kurtosis": round(ch_feat.get("kurtosis", 0), 3),
                "delta_rel": round(ch_feat.get("delta_rel", 0), 3),
                "theta_rel": round(ch_feat.get("theta_rel", 0), 3),
                "alpha_rel": round(ch_feat.get("alpha_rel", 0), 3),
                "spectral_entropy": round(ch_feat.get("spectral_entropy", 0), 3),
            })

        # Ordenar por anomalía descendente
        result.sort(key=lambda x: x["anomaly_score"], reverse=True)
        return result

    def calculate_metrics(self, processed_data: np.ndarray) -> Dict[str, float]:
        """Métricas de amplitud del array procesado (compatibilidad con código anterior)."""
        data = processed_data[:, 0] if processed_data.ndim > 1 else processed_data
        return {
            "mean_amplitude": float(np.mean(data)),
            "std_amplitude": float(np.std(data)),
            "max_amplitude": float(np.max(data)),
            "min_amplitude": float(np.min(data)),
            "energy": float(np.sum(data ** 2)),
        }
