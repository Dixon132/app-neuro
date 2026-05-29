# 📦 Guía de Instalación Completa

## Requisitos Previos

### 1. Python 3.10 o superior
```bash
# Verificar instalación
python --version

# Descargar desde: https://www.python.org/downloads/
```

### 2. Flutter SDK 3.7 o superior
```bash
# Verificar instalación
flutter --version

# Descargar desde: https://flutter.dev/docs/get-started/install
```

### 3. Git (opcional)
```bash
git --version
```

---

## 🐍 Instalación del Backend

### Paso 1: Navegar al directorio
```bash
cd backend
```

### Paso 2: Crear entorno virtual
```bash
# Windows
python -m venv venv

# Linux/Mac
python3 -m venv venv
```

### Paso 3: Activar entorno virtual
```bash
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

Deberías ver `(venv)` al inicio de tu línea de comandos.

### Paso 4: Actualizar pip
```bash
python -m pip install --upgrade pip
```

### Paso 5: Instalar dependencias
```bash
pip install -r requirements.txt
```

**Nota:** La instalación puede tardar 5-10 minutos dependiendo de tu conexión.

### Paso 6: Configurar variables de entorno
```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

Editar `.env` si es necesario (opcional para desarrollo).

### Paso 7: Verificar instalación
```bash
python -c "import fastapi; print('FastAPI OK')"
python -c "import torch; print('PyTorch OK')"
python -c "import mne; print('MNE OK')"
```

### Paso 8: Ejecutar servidor
```bash
python -m app.main
```

✅ **Backend corriendo en:** http://localhost:8000
📚 **Documentación API:** http://localhost:8000/docs

---

## 📱 Instalación del Frontend

### Paso 1: Navegar al directorio
```bash
cd frontend
```

### Paso 2: Verificar Flutter
```bash
flutter doctor
```

Resolver cualquier problema que aparezca (marcado con ❌).

### Paso 3: Instalar dependencias
```bash
flutter pub get
```

### Paso 4: Verificar dispositivos disponibles
```bash
flutter devices
```

### Paso 5: Ejecutar aplicación
```bash
# Ejecutar en el dispositivo por defecto
flutter run

# Ejecutar en Chrome (Web)
flutter run -d chrome

# Ejecutar en Windows
flutter run -d windows

# Ejecutar en Android
flutter run -d <device-id>
```

✅ **App Flutter iniciada**

---

## 🔧 Solución de Problemas Comunes

### Backend

#### Error: "No module named 'fastapi'"
```bash
# Asegurarse de que el entorno virtual está activado
venv\Scripts\activate
pip install -r requirements.txt
```

#### Error: "Port 8000 already in use"
```bash
# Windows - Encontrar proceso
netstat -ano | findstr :8000
taskkill /PID <pid> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

#### Error al instalar PyTorch
```bash
# Instalar versión CPU (más ligera)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```

#### Error con MNE
```bash
# Instalar dependencias del sistema primero
# Windows: Instalar Visual C++ Build Tools
# Linux: sudo apt-get install build-essential
```

### Frontend

#### Error: "Flutter SDK not found"
```bash
# Agregar Flutter al PATH
# Windows: Agregar C:\flutter\bin al PATH
# Linux/Mac: export PATH="$PATH:`pwd`/flutter/bin"
```

#### Error: "Pub get failed"
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

#### Error: "No devices found"
```bash
# Para Web
flutter config --enable-web

# Para Windows Desktop
flutter config --enable-windows-desktop

# Verificar
flutter devices
```

#### Error de compilación Android
```bash
# Limpiar y reconstruir
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

## 🧪 Verificación de Instalación

### Backend
```bash
# Test 1: Health check
curl http://localhost:8000/health

# Test 2: API docs
# Abrir en navegador: http://localhost:8000/docs

# Test 3: Ejecutar tests
pytest
```

### Frontend
```bash
# Test 1: Análisis de código
flutter analyze

# Test 2: Ejecutar tests
flutter test

# Test 3: Build (verificar que compila)
flutter build apk --debug
```

---

## 📊 Verificar Funcionalidad Completa

### 1. Iniciar Backend
```bash
cd backend
venv\Scripts\activate
python -m app.main
```

### 2. Iniciar Frontend (nueva terminal)
```bash
cd frontend
flutter run
```

### 3. Probar flujo completo
1. Abrir app
2. Registrarse con usuario nuevo
3. Iniciar sesión
4. Ver dashboard
5. Intentar subir archivo (puede fallar sin archivo real, pero debe mostrar selector)

---

## 🎯 Próximos Pasos

1. ✅ Backend instalado y corriendo
2. ✅ Frontend instalado y corriendo
3. ✅ Conexión entre frontend y backend funcionando
4. 📥 Descargar datos de prueba EEG
5. 🧪 Probar análisis completo

---

## 📥 Obtener Datos de Prueba

### Opción 1: PhysioNet (Recomendado)
```bash
# Descargar dataset CHB-MIT
# https://physionet.org/content/chbmit/1.0.0/

# Ejemplo: chb01_03.edf (archivo EDF real)
```

### Opción 2: Kaggle
```bash
# Epileptic Seizure Recognition
# https://www.kaggle.com/datasets/harunshimanto/epileptic-seizure-recognition
```

### Opción 3: Generar datos sintéticos
```python
# En Python
import numpy as np
import pandas as pd

# Generar señal EEG sintética
t = np.linspace(0, 10, 2560)  # 10 segundos a 256 Hz
signal = np.sin(2 * np.pi * 10 * t) + np.random.normal(0, 0.1, 2560)

# Guardar como CSV
df = pd.DataFrame({'timestamp': t, 'channel1': signal})
df.to_csv('eeg_test.csv', index=False)
```

---

## 🔐 Credenciales de Prueba

**Usuario:** admin  
**Contraseña:** admin123

(Crear cuenta nueva en la pantalla de registro)

---

## 📞 Soporte

Si encuentras problemas:

1. Revisar esta guía completa
2. Verificar `COMANDOS_UTILES.md`
3. Revisar logs del backend
4. Ejecutar `flutter doctor`
5. Buscar el error específico en la documentación oficial

---

## ✅ Checklist de Instalación

- [ ] Python 3.10+ instalado
- [ ] Flutter SDK instalado
- [ ] Backend: entorno virtual creado
- [ ] Backend: dependencias instaladas
- [ ] Backend: servidor corriendo en puerto 8000
- [ ] Frontend: dependencias instaladas
- [ ] Frontend: app ejecutándose
- [ ] Conexión backend-frontend funcionando
- [ ] Datos de prueba descargados (opcional)

---

**¡Instalación completa! 🎉**

El sistema está listo para analizar señales EEG.
