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

    def _generate_training_data(self, n_features: int, n_samples: int = 3000):
        """
        Genera datos de entrenamiento sintéticos basados en distribuciones REALES
        observadas del dataset CHB-MIT (3 seizure, 2 normal).
        
        VALORES REALES OBSERVADOS:
        - Seizure: kurtosis=0.647±0.497, line_length=127±11, delta_rel=0.704±0.068,
                   alpha_rel=0.087±0.048, slow_fast=17.8±14.7, spec_entropy=3.85±0.31,
                   spike_rate=0.174±0.097, dwt_energy=1015±322
        - Normal:  kurtosis=0.889±0.213, line_length=167±26, delta_rel=0.643±0.026,
                   alpha_rel=0.067±0.009, slow_fast=9.78±1.44, spec_entropy=4.14±0.12,
                   spike_rate=0.214±0.041, dwt_energy=934±132
        
        NOTA: Hay MUCHO overlap entre clases — el modelo debe ser conservador.
        """
        np.random.seed(42)
        X_list, y_list = [], []
        n_normal    = n_samples // 2
        n_epileptic = n_samples - n_normal

        # Índices EXACTOS verificados del feature vector (138 features)
        IDX_MEAN_KURTOSIS     = 6
        IDX_MEAN_LINE_LENGTH  = 12
        IDX_MEAN_DELTA_REL    = 36
        IDX_MEAN_ALPHA_REL    = 42
        IDX_MEAN_SLOW_FAST    = 57
        IDX_MEAN_SPEC_ENTROPY = 60
        IDX_MEAN_SPIKE_RATE   = 132
        IDX_MEAN_DWT_ENERGY   = 75

        # ── Clase 0: Normal ──
        # Basado en valores reales: chb01_19, chb01_20
        for _ in range(n_normal):
            vec = np.abs(np.random.randn(n_features)) * 0.05  # ruido de fondo reducido
            vec[IDX_MEAN_KURTOSIS]     = np.random.normal(0.889, 0.25)   # más varianza
            vec[IDX_MEAN_LINE_LENGTH]  = np.random.normal(166.9, 30.0)   # real: 167±26
            vec[IDX_MEAN_DELTA_REL]    = np.random.normal(0.643, 0.04)   # real: 0.643±0.026
            vec[IDX_MEAN_ALPHA_REL]    = np.random.normal(0.067, 0.015)  # real: 0.067±0.009
            vec[IDX_MEAN_SLOW_FAST]    = np.random.normal(9.78, 2.5)     # real: 9.78±1.44
            vec[IDX_MEAN_SPEC_ENTROPY] = np.random.normal(4.144, 0.15)   # real: 4.14±0.12
            vec[IDX_MEAN_SPIKE_RATE]   = np.random.normal(0.214, 0.06)   # real: 0.214±0.041
            vec[IDX_MEAN_DWT_ENERGY]   = np.random.normal(933.6, 180.0)  # real: 934±132
            X_list.append(vec)
            y_list.append(0)

        # ── Clase 1: Epiléptico ──
        # Basado en valores reales: chb01_16, chb01_18, chb01_21
        for _ in range(n_epileptic):
            vec = np.abs(np.random.randn(n_features)) * 0.05
            vec[IDX_MEAN_KURTOSIS]     = np.random.normal(0.647, 0.55)   # real: 0.647±0.497
            vec[IDX_MEAN_LINE_LENGTH]  = np.random.normal(127.0, 15.0)   # real: 127±11
            vec[IDX_MEAN_DELTA_REL]    = np.random.normal(0.704, 0.08)   # real: 0.704±0.068
            vec[IDX_MEAN_ALPHA_REL]    = np.random.normal(0.087, 0.055)  # real: 0.087±0.048
            vec[IDX_MEAN_SLOW_FAST]    = np.random.normal(17.8, 16.0)    # real: 17.8±14.7 (alta varianza!)
            vec[IDX_MEAN_SPEC_ENTROPY] = np.random.normal(3.854, 0.35)   # real: 3.85±0.31
            vec[IDX_MEAN_SPIKE_RATE]   = np.random.normal(0.174, 0.11)   # real: 0.174±0.097
            vec[IDX_MEAN_DWT_ENERGY]   = np.random.normal(1015.3, 360.0) # real: 1015±322
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

        # Modelo base más conservador (evita overfitting)
        base_clf = GradientBoostingClassifier(
            n_estimators=100,        # reducido de 200
            max_depth=3,             # reducido de 4 (menos complejo)
            min_samples_split=20,    # requiere más muestras para dividir
            min_samples_leaf=10,     # hojas más grandes
            learning_rate=0.05,
            subsample=0.8,
            max_features='sqrt',     # usa solo sqrt(n_features) por split
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
        EPSILON = 0.10  # mínimo 10% de incertidumbre (más conservador)
        proba_smoothed = np.clip(proba, EPSILON, 1.0 - EPSILON)
        proba_smoothed = proba_smoothed / proba_smoothed.sum()  # renormalizar
        
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
