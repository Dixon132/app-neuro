import csv
from datetime import datetime
from typing import List, Optional, Dict, Any

import numpy as np
import pywt
from scipy import signal
from scipy.fft import fft, fftfreq
from scipy.stats import kurtosis, skew, entropy as scipy_entropy
from scipy.signal import welch
import mne


class EEGProcessor:
    def __init__(self):
        self.sampling_rate = 256  # default, se detecta del archivo
        self.lowcut = 0.5
        self.highcut = 50.0
        self.notch_freq = 50.0       # ruido eléctrico (50 Hz Europa/LatAm, 60 Hz USA)
        self.window_size_sec = 5     # ventanas de 5 segundos
        self.overlap = 0.5           # 50% overlap
        self.artifact_threshold = 500.0  # µV — amplitud máxima antes de considerar artefacto
        self.channel_names: List[str] = []

    # ─────────────────────────────────────────────
    # CARGA DE ARCHIVOS
    # ─────────────────────────────────────────────

    def _parse_timestamp_to_seconds(self, value: str) -> Optional[float]:
        try:
            return float(value)
        except Exception:
            pass
        value = value.strip()
        try:
            normalized = value.replace("Z", "+00:00")
            dt = datetime.fromisoformat(normalized)
            return dt.timestamp()
        except Exception:
            pass
        for fmt in (
            "%Y-%m-%d %H:%M:%S.%f",
            "%Y-%m-%d %H:%M:%S",
            "%Y/%m/%d %H:%M:%S.%f",
            "%Y/%m/%d %H:%M:%S",
        ):
            try:
                dt = datetime.strptime(value, fmt)
                return dt.timestamp()
            except Exception:
                continue
        return None

    def _parse_float(self, value: str) -> Optional[float]:
        try:
            return float(value)
        except Exception:
            return None

    def load_eeg_file(self, file_path: str) -> np.ndarray:
        """Carga EDF o CSV. Retorna array (n_samples, n_channels).
        Para EDF grandes, busca el segmento más activo en vez de tomar siempre el inicio."""

        SEGMENT_DURATION_SEC = 60   # duración del segmento a analizar
        SCAN_STEP_SEC = 60          # cada cuántos segundos escanear para encontrar el más activo
        MAX_SCAN_SEC = 600          # escanear máximo los primeros 10 minutos

        if file_path.endswith(".edf"):
            raw = mne.io.read_raw_edf(file_path, preload=False, verbose=False)
            self.sampling_rate = int(raw.info["sfreq"])
            self.channel_names = list(raw.ch_names)
            total_sec = raw.times[-1]

            print(f"[EEGProcessor] EDF: {len(self.channel_names)} canales, "
                  f"{self.sampling_rate} Hz, {total_sec:.1f}s totales")

            # Si el archivo es corto, cargarlo completo
            if total_sec <= SEGMENT_DURATION_SEC:
                data, _ = raw[:, :]
                return (data * 1e6).T

            # Buscar el segmento con mayor actividad (mayor amplitud media entre canales)
            # Esto encuentra el seizure aunque no esté al inicio
            best_start = 0
            best_score = -1
            scan_limit = min(total_sec - SEGMENT_DURATION_SEC, MAX_SCAN_SEC)
            step_samples = int(SCAN_STEP_SEC * self.sampling_rate)
            seg_samples = int(SEGMENT_DURATION_SEC * self.sampling_rate)

            start_sec = 0.0
            while start_sec + SEGMENT_DURATION_SEC <= scan_limit + SEGMENT_DURATION_SEC:
                start_s = int(start_sec * self.sampling_rate)
                end_s = start_s + seg_samples
                chunk, _ = raw[:, start_s:end_s]
                # Convertir a µV para comparación correcta
                chunk_uv = chunk * 1e6
                # Score = amplitud máxima media entre canales (más robusto que varianza)
                score = float(np.mean(np.max(np.abs(chunk_uv), axis=1)))
                if score > best_score:
                    best_score = score
                    best_start = start_s
                start_sec += SCAN_STEP_SEC

            best_start_sec = best_start / self.sampling_rate
            print(f"[EEGProcessor] Segmento más activo: {best_start_sec:.1f}s–"
                  f"{best_start_sec + SEGMENT_DURATION_SEC:.1f}s (max_amp={best_score:.2f} µV)")

            data, _ = raw[:, best_start: best_start + seg_samples]
            # Convertir de voltios a microvoltios (estándar clínico)
            return (data * 1e6).T

        if not file_path.endswith(".csv"):
            raise ValueError("Formato no soportado. Use EDF o CSV.")

        with open(file_path, "r", encoding="utf-8", newline="") as f:
            reader = csv.reader(f)
            rows: List[List[str]] = list(reader)

        if not rows:
            raise ValueError("CSV vacío")

        # Detectar encabezado
        header = rows[0]
        has_header = any(
            self._parse_float(x) is None and self._parse_timestamp_to_seconds(x) is None
            for x in header
        )
        start_row_idx = 1 if has_header else 0

        # Guardar nombres de canales si hay encabezado
        if has_header:
            # Ignorar primera columna si es timestamp
            cols = header[1:] if len(header) > 1 else header
            self.channel_names = cols
            # Intentar detectar sampling rate desde timestamps
            if len(rows) > 2:
                t0 = self._parse_timestamp_to_seconds(rows[1][0])
                t1 = self._parse_timestamp_to_seconds(rows[2][0])
                if t0 is not None and t1 is not None and t1 > t0:
                    detected_sr = round(1.0 / (t1 - t0))
                    if 64 <= detected_sr <= 2048:
                        self.sampling_rate = detected_sr

        data_rows: List[List[float]] = []
        for row in rows[start_row_idx:]:
            if not row or all(cell.strip() == "" for cell in row):
                continue
            parsed_row: List[float] = []
            for i, cell in enumerate(row):
                cell = cell.strip()
                if i == 0:
                    ts = self._parse_timestamp_to_seconds(cell)
                    parsed_row.append(ts if ts is not None else float("nan"))
                else:
                    val = self._parse_float(cell)
                    parsed_row.append(val if val is not None else float("nan"))
            data_rows.append(parsed_row)

        data = np.array(data_rows, dtype=np.float64)

        # Timestamp relativo
        if data.shape[1] >= 1 and np.isfinite(data[0, 0]):
            first = data[0, 0]
            if first > 1e6:
                data[:, 0] = data[:, 0] - first

        # Eliminar filas con NaN
        if np.isnan(data).any():
            data = data[~np.isnan(data).any(axis=1)]

        if data.size == 0:
            raise ValueError("No se pudo convertir el CSV a datos numéricos")

        # Quitar columna de timestamp — quedamos con solo canales
        # (n_samples, n_channels)
        return data[:, 1:] if data.shape[1] > 1 else data

    # ─────────────────────────────────────────────
    # PREPROCESAMIENTO
    # ─────────────────────────────────────────────

    def apply_notch_filter(self, data: np.ndarray) -> np.ndarray:
        """Elimina ruido eléctrico a 50 Hz (y armónico 100 Hz)."""
        nyq = 0.5 * self.sampling_rate
        for freq in [self.notch_freq, self.notch_freq * 2]:
            if freq < nyq:
                b, a = signal.iirnotch(freq, Q=30, fs=self.sampling_rate)
                data = signal.filtfilt(b, a, data, axis=0)
        return data

    def apply_bandpass_filter(self, data: np.ndarray) -> np.ndarray:
        """Filtro pasa banda 0.5–50 Hz."""
        nyq = 0.5 * self.sampling_rate
        low = self.lowcut / nyq
        high = min(self.highcut, nyq * 0.99) / nyq
        b, a = signal.butter(4, [low, high], btype="band")
        return signal.filtfilt(b, a, data, axis=0)

    def remove_artifacts(self, data: np.ndarray) -> np.ndarray:
        """Marca como NaN muestras con amplitud fuera de rango (artefactos)."""
        clean = data.copy()
        mask = np.abs(clean) > self.artifact_threshold
        clean[mask] = np.nan
        # Interpolar NaNs linealmente por canal
        for ch in range(clean.shape[1]):
            col = clean[:, ch]
            nans = np.isnan(col)
            if nans.any() and not nans.all():
                idx = np.arange(len(col))
                col[nans] = np.interp(idx[nans], idx[~nans], col[~nans])
                clean[:, ch] = col
        return clean

    def normalize_data(self, data: np.ndarray) -> np.ndarray:
        """Z-score por canal."""
        mean = np.mean(data, axis=0, keepdims=True)
        std = np.std(data, axis=0, keepdims=True)
        return (data - mean) / (std + 1e-8)

    def segment_signal(self, data: np.ndarray) -> List[np.ndarray]:
        """Divide la señal en ventanas con overlap.
        Retorna lista de arrays (window_samples, n_channels)."""
        window_samples = int(self.window_size_sec * self.sampling_rate)
        step = int(window_samples * (1 - self.overlap))

        if len(data) < window_samples:
            # Señal muy corta — usar toda como una sola ventana
            return [data]

        windows = []
        start = 0
        while start + window_samples <= len(data):
            windows.append(data[start : start + window_samples])
            start += step
        return windows

    # ─────────────────────────────────────────────
    # EXTRACCIÓN DE CARACTERÍSTICAS
    # ─────────────────────────────────────────────

    def extract_temporal_features(self, channel: np.ndarray) -> Dict[str, float]:
        """Características temporales de un canal."""
        rms = float(np.sqrt(np.mean(channel ** 2)))
        variance = float(np.var(channel))
        kurt = float(kurtosis(channel))
        skewness = float(skew(channel))
        # Line length: suma de diferencias absolutas consecutivas
        line_length = float(np.sum(np.abs(np.diff(channel))))
        peak_to_peak = float(np.max(channel) - np.min(channel))
        zero_crossings = int(np.sum(np.diff(np.sign(channel)) != 0))

        return {
            "rms": rms,
            "variance": variance,
            "kurtosis": kurt,
            "skewness": skewness,
            "line_length": line_length,
            "peak_to_peak": peak_to_peak,
            "zero_crossings": zero_crossings,
        }

    def extract_frequency_features(self, channel: np.ndarray) -> Dict[str, float]:
        """Potencia por banda usando Welch (más robusto que FFT simple)."""
        nperseg = min(len(channel), self.sampling_rate * 2)
        freqs, psd = welch(channel, fs=self.sampling_rate, nperseg=nperseg)

        def band_power(lo, hi):
            idx = (freqs >= lo) & (freqs < hi)
            return float(np.trapezoid(psd[idx], freqs[idx])) if idx.any() else 0.0

        delta = band_power(0.5, 4)
        theta = band_power(4, 8)
        alpha = band_power(8, 13)
        beta = band_power(13, 30)
        gamma = band_power(30, 50)
        total = delta + theta + alpha + beta + gamma + 1e-10

        return {
            "delta_power": delta,
            "theta_power": theta,
            "alpha_power": alpha,
            "beta_power": beta,
            "gamma_power": gamma,
            # Potencias relativas (más informativas)
            "delta_rel": delta / total,
            "theta_rel": theta / total,
            "alpha_rel": alpha / total,
            "beta_rel": beta / total,
            "gamma_rel": gamma / total,
            # Ratios clave en epilepsia
            "theta_alpha_ratio": theta / (alpha + 1e-10),
            "delta_beta_ratio": delta / (beta + 1e-10),
            "slow_fast_ratio": (delta + theta) / (alpha + beta + 1e-10),
        }

    def extract_entropy_features(self, channel: np.ndarray) -> Dict[str, float]:
        """Entropía espectral y aproximada."""
        # Spectral entropy
        nperseg = min(len(channel), self.sampling_rate * 2)
        _, psd = welch(channel, fs=self.sampling_rate, nperseg=nperseg)
        psd_norm = psd / (psd.sum() + 1e-10)
        spectral_ent = float(-np.sum(psd_norm * np.log2(psd_norm + 1e-10)))

        # Sample entropy aproximada (usando diferencias)
        # Versión simplificada sin dependencias externas
        diffs = np.abs(np.diff(channel))
        sample_ent = float(np.log(np.mean(diffs) + 1e-10))

        # Permutation entropy (orden 3)
        perm_ent = self._permutation_entropy(channel, order=3)

        return {
            "spectral_entropy": spectral_ent,
            "sample_entropy": sample_ent,
            "permutation_entropy": perm_ent,
        }

    def _permutation_entropy(self, x: np.ndarray, order: int = 3) -> float:
        """Permutation entropy vectorizada — mucho más rápida que loop Python."""
        import math
        n = len(x)
        if n < order:
            return 0.0
        # Construir matriz de patrones de forma vectorizada
        shape = (n - order + 1, order)
        strides = (x.strides[0], x.strides[0])
        embedded = np.lib.stride_tricks.as_strided(x, shape=shape, strides=strides)
        # Obtener el orden de cada patrón
        sorted_idx = np.argsort(embedded, axis=1)
        # Convertir a entero único por patrón usando base factorial
        multipliers = np.array([math.factorial(order - 1 - i) for i in range(order)])
        pattern_ids = np.sum(sorted_idx * multipliers, axis=1)
        # Calcular probabilidades
        _, counts = np.unique(pattern_ids, return_counts=True)
        probs = counts / counts.sum()
        return float(-np.sum(probs * np.log2(probs + 1e-10)))

    def extract_dwt_features(self, channel: np.ndarray) -> Dict[str, float]:
        """DWT con Daubechies 4, nivel 4."""
        try:
            coeffs = pywt.wavedec(channel, "db4", level=4)
        except Exception:
            coeffs = pywt.wavedec(channel, "db4", level=2)

        features = {}
        for i, coeff in enumerate(coeffs):
            if len(coeff) == 0:
                continue
            name = f"dwt_d{i}"
            features[f"{name}_mean"] = float(np.mean(coeff))
            features[f"{name}_std"] = float(np.std(coeff))
            features[f"{name}_energy"] = float(np.sum(coeff ** 2))
            features[f"{name}_max"] = float(np.max(np.abs(coeff)))
        return features

    def detect_spikes(self, channel: np.ndarray) -> Dict[str, float]:
        """Detección básica de spikes epilépticos.
        Busca picos de alta amplitud y corta duración (20–70 ms)."""
        spike_min_samples = int(0.020 * self.sampling_rate)  # 20 ms
        spike_max_samples = int(0.070 * self.sampling_rate)  # 70 ms
        threshold = np.mean(np.abs(channel)) + 3 * np.std(np.abs(channel))

        # Encontrar picos que superen el umbral
        abs_ch = np.abs(channel)
        peaks, properties = signal.find_peaks(
            abs_ch,
            height=threshold,
            width=(spike_min_samples, spike_max_samples),
        )

        spike_count = len(peaks)
        spike_rate = spike_count / (len(channel) / self.sampling_rate)  # spikes/segundo
        mean_spike_amplitude = float(np.mean(abs_ch[peaks])) if spike_count > 0 else 0.0

        return {
            "spike_count": float(spike_count),
            "spike_rate_per_sec": float(spike_rate),
            "mean_spike_amplitude": mean_spike_amplitude,
        }

    def extract_channel_features(self, channel: np.ndarray) -> Dict[str, float]:
        """Todas las características de un canal."""
        features = {}
        features.update(self.extract_temporal_features(channel))
        features.update(self.extract_frequency_features(channel))
        features.update(self.extract_entropy_features(channel))
        features.update(self.extract_dwt_features(channel))
        features.update(self.detect_spikes(channel))
        return features

    def extract_all_features(self, data: np.ndarray) -> Dict[str, Any]:
        """Extrae características de todos los canales y agrega estadísticas globales.
        data: (n_samples, n_channels)
        """
        n_channels = data.shape[1]
        per_channel: List[Dict[str, float]] = []

        for ch in range(n_channels):
            ch_features = self.extract_channel_features(data[:, ch])
            per_channel.append(ch_features)

        # Agregar: media y max entre canales para cada feature
        feature_keys = list(per_channel[0].keys())
        aggregated: Dict[str, float] = {}
        for key in feature_keys:
            vals = [ch[key] for ch in per_channel if key in ch]
            aggregated[f"mean_{key}"] = float(np.mean(vals))
            aggregated[f"max_{key}"] = float(np.max(vals))
            aggregated[f"std_{key}"] = float(np.std(vals))

        # Canal con mayor actividad anómala (spike_rate + kurtosis alta)
        anomaly_scores = [
            ch.get("spike_rate_per_sec", 0) * 2 + max(0, ch.get("kurtosis", 0))
            for ch in per_channel
        ]
        most_anomalous_ch = int(np.argmax(anomaly_scores))
        ch_name = (
            self.channel_names[most_anomalous_ch]
            if most_anomalous_ch < len(self.channel_names)
            else f"CH{most_anomalous_ch + 1}"
        )

        return {
            "per_channel": per_channel,
            "aggregated": aggregated,
            "n_channels": n_channels,
            "most_anomalous_channel": ch_name,
            "most_anomalous_channel_idx": most_anomalous_ch,
            "anomaly_scores": anomaly_scores,
            "channel_names": self.channel_names or [f"CH{i+1}" for i in range(n_channels)],
        }

    SELECTED_FEATURE_KEYS = [
        "mean_kurtosis",
        "max_kurtosis",
        "std_kurtosis",
        "mean_line_length",
        "max_line_length",
        "mean_delta_rel",
        "max_delta_rel",
        "mean_theta_rel",
        "mean_alpha_rel",
        "mean_beta_rel",
        "mean_gamma_rel",
        "mean_slow_fast_ratio",
        "max_slow_fast_ratio",
        "mean_theta_alpha_ratio",
        "mean_delta_beta_ratio",
        "mean_spectral_entropy",
        "max_spectral_entropy",
        "mean_permutation_entropy",
        "mean_sample_entropy",
        "mean_spike_rate_per_sec",
        "max_spike_rate_per_sec",
        "mean_spike_count",
        "mean_peak_to_peak",
        "max_peak_to_peak",
        "mean_variance",
        "mean_zero_crossings",
        "mean_rms",
        "mean_dwt_d0_energy",
        "mean_dwt_d1_energy",
        "mean_dwt_d2_energy",
    ]

    def build_feature_vector(self, features: Dict[str, Any]) -> np.ndarray:
        """Construye vector numpy con features selectos discriminativos."""
        agg = features["aggregated"]
        values = []
        for key in self.SELECTED_FEATURE_KEYS:
            values.append(agg.get(key, 0.0))
        vec = np.array(values, dtype=np.float64)
        vec = np.nan_to_num(vec, nan=0.0, posinf=0.0, neginf=0.0)
        return vec

    # ─────────────────────────────────────────────
    # PIPELINE COMPLETO
    # ─────────────────────────────────────────────

    def process_eeg(self, file_path: str) -> Dict[str, Any]:
        """Pipeline completo: carga → preprocesa → segmenta → extrae características."""

        # 1. Cargar
        raw_data = self.load_eeg_file(file_path)

        # 2. Filtro Notch (ruido eléctrico)
        notched = self.apply_notch_filter(raw_data)

        # 3. Filtro pasa banda
        filtered = self.apply_bandpass_filter(notched)

        # 4. Eliminar artefactos
        clean = self.remove_artifacts(filtered)

        # 5. Normalizar
        normalized = self.normalize_data(clean)

        # 6. Segmentar en ventanas
        windows = self.segment_signal(normalized)

        # 7. Extraer características por ventana — máximo 10 ventanas
        MAX_WINDOWS = 10
        windows_to_process = windows[:MAX_WINDOWS]
        all_window_features = [self.extract_all_features(w) for w in windows_to_process]

        # Promediar features agregados entre ventanas
        agg_keys = list(all_window_features[0]["aggregated"].keys())
        averaged_agg: Dict[str, float] = {}
        for key in agg_keys:
            vals = [wf["aggregated"][key] for wf in all_window_features]
            averaged_agg[key] = float(np.mean(vals))

        # Usar la ventana con mayor anomalía como representativa
        anomaly_totals = [
            sum(wf["anomaly_scores"]) for wf in all_window_features
        ]
        best_window_idx = int(np.argmax(anomaly_totals))
        best_features = all_window_features[best_window_idx]
        best_features["aggregated"] = averaged_agg

        # Vector de características para el modelo
        feature_vector = self.build_feature_vector(best_features)

        return {
            "processed_data": normalized,
            "features": best_features,
            "feature_vector": feature_vector,
            "n_windows": len(windows_to_process),
            "sampling_rate": self.sampling_rate,
            "channel_names": best_features["channel_names"],
            # Compatibilidad con código anterior
            "dwt_features": feature_vector[:50] if len(feature_vector) >= 50 else feature_vector,
            "fft_features": feature_vector[50:55] if len(feature_vector) >= 55 else np.zeros(5),
        }
