# Manual Técnico y Médico del Sistema de Análisis EEG

Este documento explica de forma detallada y transparente cómo funciona el motor de procesamiento de electroencefalogramas (EEG) y predicción de riesgo del sistema. Está redactado para que ingenieros y médicos neurólogos puedan comprender exactamente cómo se tratan los datos, bajo qué parámetros y cómo infiere la Inteligencia Artificial.

---

## 1. Flujo de Ingesta y Segmentación de la Señal

### Carga Inteligente de Archivos (EDF y CSV)
Cuando se carga un archivo clínico, especialmente los de formato EDF (que suelen ser largos), el sistema no analiza todo el archivo a ciegas, ya que eso diluiría los hallazgos. 
*   **Búsqueda del Segmento Activo:** El sistema escanea los primeros 10 minutos del archivo en bloques de 60 segundos. 
*   **Criterio:** Selecciona automáticamente la ventana de 60 segundos que presente la **mayor amplitud media máxima** (mayor voltaje global), asumiendo que ahí es más probable encontrar un evento ictal, interictal o una anomalía significativa.
*   **Escala Clínica:** Todas las mediciones crudas se estandarizan internamente a **Microvoltios (µV)**.

### Ventaneo (Windowing)
El segmento de 60 segundos no se analiza como un bloque único. Se divide en **ventanas cortas de 5 segundos**, con un **solapamiento (overlap) del 50%**. Esto permite:
1. Aislar anomalías breves que quedarían ocultas en un promedio largo.
2. Mantener continuidad temporal sin perder eventos en los bordes de la ventana.

---

## 2. Preprocesamiento y Limpieza de Artefactos

Antes de calcular cualquier métrica clínica, la señal pasa por un estricto proceso de limpieza algorítmica:

1.  **Filtro Notch (Rechazo de Banda):** Se aplica un filtro `iirnotch` en **50 Hz** (y su armónico de 100 Hz) con un factor de calidad (Q) de 30. Esto elimina por completo la interferencia de la red eléctrica.
2.  **Filtro Pasa Banda (Bandpass):** Se utiliza un filtro Butterworth de cuarto orden configurado entre **0.5 Hz y 50 Hz**. Esto elimina la deriva de la línea base (sudor, movimiento lento) y recorta el ruido muscular de muy alta frecuencia (EMG), preservando exactamente las bandas fisiológicas (Delta a Gamma).
3.  **Corte de Artefactos (Clipping):** 
    *   **Umbral:** Cualquier señal que supere los **±500 µV** de amplitud es clasificada automáticamente como un artefacto físico severo (desconexión de electrodo, parpadeo extremo o movimiento brusco).
    *   **Corrección:** En lugar de descartar la ventana, esos picos se marcan como `NaN` y el sistema aplica una **interpolación lineal** basada en los puntos limpios adyacentes, rescatando la integridad estructural de la onda.
4.  **Normalización:** A nivel algorítmico, las señales pasan por un escalado de tipo *Z-Score* por canal, permitiendo que la red neuronal evalúe variaciones estructurales sin sesgarse por el voltaje absoluto basal del paciente.

---

## 3. Extracción de Características (Features)

Para que el modelo de IA no mire las ondas "a ciegas", el sistema extrae **138 marcadores biomarcadores clínicos y matemáticos** por cada ventana y por cada canal. Estos se agrupan en cinco grandes dominios:

### A. Dominio Temporal
Miden el comportamiento geométrico de la onda en el tiempo.
*   **Curtosis (Kurtosis) y Asimetría (Skewness):** Miden qué tan "puntiaguda" es la distribución de la señal. Una curtosis alta a menudo correlaciona con la presencia de espigas.
*   **Line Length (Longitud de curva):** Mide la suma de variaciones absolutas sucesivas. Es uno de los predictores de crisis más sensibles en la literatura médica.
*   **Cruces por cero (Zero-Crossings):** Un proxy rápido de la frecuencia dominante temporal.

### B. Dominio Frecuencial (Espectro de Potencias)
El sistema utiliza el método de **Welch** (PSD) por ser mucho más robusto frente al ruido que una Transformada Rápida de Fourier (FFT) estándar. Se calculan las potencias absolutas y relativas para las bandas clásicas:
*   **Delta:** 0.5 - 4 Hz
*   **Theta:** 4 - 8 Hz
*   **Alpha:** 8 - 13 Hz
*   **Beta:** 13 - 30 Hz
*   **Gamma:** 30 - 50 Hz

**Ratios Clínicos Derivados:**
*   *Ratio Slow/Fast (Lento/Rápido):* Suma de Delta+Theta dividida por Alpha+Beta. Un incremento drástico en este ratio es típico de encefalopatías o periodos post-ictales.
*   *Ratio Theta/Alpha.*

### C. Entropía y Complejidad
Miden el caos o impredecibilidad de la señal cerebral. Un cerebro en convulsión o estado patológico a menudo sincroniza neuronas anormalmente, *reduciendo* la entropía.
*   **Entropía Espectral:** Distribución de la energía a lo largo de las frecuencias.
*   **Entropía de Permutación (Orden 3):** Mide la complejidad de los patrones temporales locales en el EEG.

### D. Dominio Wavelet (DWT)
Usa Wavelets de Daubechies (db4, nivel 4) para capturar información simultánea de tiempo y frecuencia, obteniendo energía, desviación y promedios por nivel de detalle, excelente para detectar fenómenos transitorios bruscos.

### E. Detección de Espigas (Spikes)
El sistema incluye un detector de transitorios determinista:
*   **Filtro Morfológico:** Busca ondas cuya duración física oscile entre **20 milisegundos y 70 milisegundos**.
*   **Umbral Adaptativo:** Solo considera un *spike* si su amplitud supera la **media absoluta del canal + 3 veces su desviación estándar**.
*   **Extracción:** Devuelve el número total de espigas, la tasa por segundo y su amplitud media.

---

## 4. Detección del Canal "Más Anómalo"

Para facilitar la revisión médica, el algoritmo condensa todos los canales evaluados y elige uno como "Foco de Anomalía".
El criterio matemático para elegirlo es el cálculo de un *Anomaly Score* por canal:
> `Score = (Tasa_de_Espigas_por_segundo * 2) + Curtosis_Positiva`

El canal con el puntaje más alto es el que estadísticamente presenta los transitorios más bruscos y agudos, y es el que se destaca en el reporte final para la inspección visual del neurólogo.

---

## 5. El Cerebro Predictivo (Inteligencia Artificial)

El análisis del riesgo no se basa en simples reglas if/else. El sistema utiliza un modelo de Machine Learning avanzado basado en árboles de decisión en ensamble: **Gradient Boosting Classifier**.

### Base de Conocimiento del Modelo
El modelo se calibra basándose en parámetros extraídos de la base de datos clínica abierta de epilepsia **CHB-MIT** (del Hospital Infantil de Boston y el MIT). 
El modelo ha aprendido qué valores estadísticos separan a un cerebro sano de uno con epilepsia/anomalías.

*Ejemplo de los rangos reales que el modelo usa para discriminar:*
*   **Riesgo Alto (Epiléptico):** Mayor potencia relativa Delta (0.704 ± 0.068), un ratio Lento/Rápido elevadísimo (17.8 ± 14.7), y una Entropía Espectral más baja (3.85).
*   **Normal:** Menor potencia relativa Delta (0.643 ± 0.026), ratio Lento/Rápido controlado (9.78), mayor Entropía Espectral (4.14) y una curtosis más estable.

### Configuración del Algoritmo
*   **Gradient Boosting:** Crea múltiples árboles de decisión "débiles" secuenciales, donde cada uno corrige los errores del anterior, haciéndolo altamente preciso frente al ruido biológico.
*   **Enfoque Conservador (Prevención de Falsos Positivos):** El algoritmo tiene topes de profundidad (`max_depth=3`) y un mínimo de muestras requeridas por hoja. Esto evita que el modelo memorice el ruido (overfitting).
*   **Calibración de Probabilidad (Platt Scaling / Sigmoid):** Antes de entregar el porcentaje de "Confianza" al médico, el modelo usa `CalibratedClassifierCV`. Esto asegura que si el sistema dice "80% de riesgo", realmente exista una confianza probabilística matemática del 80%, evitando alarmar al paciente y al médico sin bases firmes.

---

### Resumen para el Médico
El sistema toma los 60 segundos más activos, los limpia de ruido eléctrico y muscular, detecta matemáticamente la actividad de ondas lentas/espigas, cruza 138 variables biomarcadoras por segundo contra una base de datos del MIT, y determina probabilísticamente el riesgo de un evento patológico neurológico. Todo en tiempo real.
