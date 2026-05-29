# Archivo de ejemplo EEG en formato CSV
# Este es un ejemplo simplificado de datos EEG
# En producción, usar archivos EDF reales de PhysioNet u otras fuentes

# Columnas: timestamp, channel1, channel2, channel3, channel4
# Frecuencia de muestreo: 256 Hz
# Duración: 10 segundos (2560 muestras)

# Para generar datos de prueba reales, usar:
# import numpy as np
# t = np.linspace(0, 10, 2560)
# channel1 = np.sin(2 * np.pi * 10 * t) + np.random.normal(0, 0.1, 2560)
# channel2 = np.sin(2 * np.pi * 15 * t) + np.random.normal(0, 0.1, 2560)
# channel3 = np.sin(2 * np.pi * 20 * t) + np.random.normal(0, 0.1, 2560)
# channel4 = np.sin(2 * np.pi * 25 * t) + np.random.normal(0, 0.1, 2560)

# Guardar como CSV:
# np.savetxt('eeg_sample.csv', np.column_stack([t, channel1, channel2, channel3, channel4]), 
#            delimiter=',', header='timestamp,ch1,ch2,ch3,ch4', comments='')

# Para descargar datos EEG reales:
# https://physionet.org/content/chbmit/1.0.0/
# https://www.kaggle.com/datasets/harunshimanto/epileptic-seizure-recognition

# Nota: Este archivo es solo una referencia.
# Los datos reales deben ser archivos EDF o CSV con señales EEG válidas.
