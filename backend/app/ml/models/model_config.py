"""
Configuración del modelo CNN-LSTM para análisis de EEG
"""

MODEL_CONFIG = {
    'input_shape': (100,),  # Vector de características
    'hidden_layers': [64, 32],
    'output_classes': 2,  # Normal, Seizure
    'dropout_rate': 0.3,
    'learning_rate': 0.001,
}

# Modelos disponibles de HuggingFace
AVAILABLE_MODELS = {
    'seizure_detection': {
        'name': 'ThomasCdnns/EEG-Seizure-Detection',
        'accuracy': 0.92,
        'size_mb': 50,
        'description': 'CNN para clasificación binaria de epilepsia'
    },
    'epilepsy_6': {
        'name': 'Neurazum/bai-Epilepsy-6',
        'accuracy': 0.88,
        'size_mb': 200,
        'description': 'Modelo de IA para epilepsia'
    },
    'mind_64': {
        'name': 'Neurazum/bai-Mind-64',
        'accuracy': 0.85,
        'size_mb': 150,
        'description': 'Modelo general de EEG'
    }
}

# Parámetros de procesamiento de señales
SIGNAL_PROCESSING = {
    'sampling_rate': 256,  # Hz
    'lowcut': 0.5,  # Hz
    'highcut': 50.0,  # Hz
    'filter_order': 4,
    'wavelet': 'db4',
    'wavelet_level': 4,
}

# Bandas de frecuencia EEG
FREQUENCY_BANDS = {
    'delta': (0.5, 4),
    'theta': (4, 8),
    'alpha': (8, 13),
    'beta': (13, 30),
    'gamma': (30, 50),
}

# Umbrales de riesgo
RISK_THRESHOLDS = {
    'low': 40,
    'moderate': 70,
    'high': 100,
}
