"""
Script para generar archivo EEG de prueba en formato CSV
"""
import numpy as np
import pandas as pd

# Parámetros
sampling_rate = 256  # Hz
duration = 10  # segundos
num_samples = sampling_rate * duration

# Generar tiempo
time = np.linspace(0, duration, num_samples)

# Generar señales EEG sintéticas (4 canales)
# Simulando diferentes bandas de frecuencia

# Canal 1: Mezcla de Alpha (8-13 Hz) y ruido
channel1 = (
    np.sin(2 * np.pi * 10 * time) +  # Alpha
    0.5 * np.sin(2 * np.pi * 20 * time) +  # Beta
    np.random.normal(0, 0.2, num_samples)  # Ruido
)

# Canal 2: Mezcla de Theta (4-8 Hz) y ruido
channel2 = (
    np.sin(2 * np.pi * 6 * time) +  # Theta
    0.3 * np.sin(2 * np.pi * 15 * time) +  # Beta
    np.random.normal(0, 0.2, num_samples)  # Ruido
)

# Canal 3: Mezcla de Beta (13-30 Hz) y ruido
channel3 = (
    np.sin(2 * np.pi * 18 * time) +  # Beta
    0.4 * np.sin(2 * np.pi * 25 * time) +  # Beta alto
    np.random.normal(0, 0.2, num_samples)  # Ruido
)

# Canal 4: Mezcla de Delta (0.5-4 Hz) y ruido
channel4 = (
    np.sin(2 * np.pi * 2 * time) +  # Delta
    0.3 * np.sin(2 * np.pi * 12 * time) +  # Alpha
    np.random.normal(0, 0.2, num_samples)  # Ruido
)

# Crear DataFrame
df = pd.DataFrame({
    'timestamp': time,
    'channel1': channel1,
    'channel2': channel2,
    'channel3': channel3,
    'channel4': channel4
})

# Guardar como CSV
output_file = 'eeg_test_sample.csv'
df.to_csv(output_file, index=False)

print(f"✅ Archivo EEG generado: {output_file}")
print(f"📊 Duración: {duration} segundos")
print(f"📈 Frecuencia de muestreo: {sampling_rate} Hz")
print(f"🔢 Total de muestras: {num_samples}")
print(f"📁 Tamaño: {len(df)} filas x {len(df.columns)} columnas")
print(f"\n🎯 Usa este archivo para probar la aplicación!")
