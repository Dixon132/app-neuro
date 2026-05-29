# 🔧 SOLUCIÓN DE PROBLEMAS

## ❌ Error: Icons.brain no encontrado (Flutter)

**Problema:** `Error: Member not found: 'brain'`

**Solución:** ✅ YA CORREGIDO
- Cambiado `Icons.brain` por `Icons.psychology`
- Ejecutar: `flutter clean && flutter pub get && flutter run`

---

## ❌ Error: NumPy no compila (Backend)

**Problema:** `ERROR: Unknown compiler(s)`

**Causa:** NumPy necesita compilador C que no está instalado en Windows

### ✅ SOLUCIÓN 1: Usar script de instalación (RECOMENDADO)

```bash
cd backend
venv\Scripts\activate
install.bat
```

### ✅ SOLUCIÓN 2: Instalar paso a paso

```bash
cd backend
venv\Scripts\activate

# 1. Actualizar pip
python -m pip install --upgrade pip

# 2. Instalar dependencias básicas
pip install fastapi uvicorn python-multipart sqlalchemy

# 3. Instalar autenticación
pip install python-jose[cryptography] passlib[bcrypt] bcrypt

# 4. Instalar pydantic
pip install pydantic pydantic-settings python-dotenv aiofiles

# 5. Instalar NumPy (versión pre-compilada)
pip install numpy

# 6. Instalar SciPy y Pandas
pip install scipy pandas

# 7. Instalar PyTorch (versión CPU - más ligera)
pip install torch --index-url https://download.pytorch.org/whl/cpu

# 8. Instalar ML
pip install transformers huggingface-hub scikit-learn

# 9. Instalar EEG
pip install mne PyWavelets

# 10. Instalar PDF
pip install reportlab matplotlib seaborn
```

### ✅ SOLUCIÓN 3: Usar requirements mínimos

```bash
cd backend
venv\Scripts\activate
pip install -r requirements-minimal.txt
```

---

## ❌ Error: Microsoft Visual C++ requerido

**Problema:** `error: Microsoft Visual C++ 14.0 or greater is required`

### Solución A: Instalar Build Tools (Recomendado para desarrollo)

1. Descargar: https://visualstudio.microsoft.com/visual-cpp-build-tools/
2. Instalar "Desktop development with C++"
3. Reiniciar terminal
4. Ejecutar: `pip install -r requirements.txt`

### Solución B: Usar wheels pre-compilados (Más rápido)

```bash
# Instalar desde wheels pre-compilados
pip install --only-binary :all: numpy scipy pandas
```

### Solución C: Usar versiones más antiguas

```bash
pip install numpy==1.24.3 scipy==1.10.1 pandas==2.0.3
```

---

## ❌ Error: Port 8000 already in use

**Problema:** `Address already in use`

**Solución:**

```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <pid> /F

# O cambiar puerto en main.py
uvicorn.run(app, host="0.0.0.0", port=8001)
```

---

## ❌ Error: Flutter SDK not found

**Problema:** `flutter: command not found`

**Solución:**

1. Descargar Flutter: https://flutter.dev/docs/get-started/install
2. Extraer en `C:\flutter`
3. Agregar al PATH: `C:\flutter\bin`
4. Reiniciar terminal
5. Ejecutar: `flutter doctor`

---

## ❌ Error: No devices found (Flutter)

**Problema:** `No supported devices connected`

**Solución:**

```bash
# Habilitar Web
flutter config --enable-web

# Habilitar Windows Desktop
flutter config --enable-windows-desktop

# Verificar
flutter devices

# Ejecutar en Chrome
flutter run -d chrome

# Ejecutar en Windows
flutter run -d windows
```

---

## ❌ Error: Pub get failed (Flutter)

**Problema:** `pub get failed`

**Solución:**

```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

## ❌ Error: Module not found (Backend)

**Problema:** `ModuleNotFoundError: No module named 'fastapi'`

**Solución:**

```bash
# Verificar que el entorno virtual está activado
venv\Scripts\activate

# Reinstalar dependencias
pip install -r requirements.txt

# O instalar manualmente
pip install fastapi uvicorn
```

---

## ❌ Error: Database locked

**Problema:** `database is locked`

**Solución:**

```bash
# Cerrar todas las conexiones
# Eliminar archivo de base de datos
del eeg_analysis.db

# Reiniciar servidor
python -m app.main
```

---

## ❌ Error: CORS (Frontend no puede conectar)

**Problema:** `CORS policy: No 'Access-Control-Allow-Origin'`

**Solución:**

Ya está configurado en `app/main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

Si persiste, verificar que el backend esté corriendo en `http://localhost:8000`

---

## ❌ Error: Connection refused (Frontend)

**Problema:** `Failed to connect to localhost:8000`

**Solución:**

1. Verificar que el backend está corriendo
2. Si usas dispositivo físico, cambiar URL en `constants.dart`:
   ```dart
   static const String apiBaseUrl = 'http://192.168.1.X:8000/api';
   ```
3. Encontrar tu IP: `ipconfig` (Windows) o `ifconfig` (Linux/Mac)

---

## 🚀 INSTALACIÓN RÁPIDA (Sin errores)

### Backend:
```bash
cd backend
python -m venv venv
venv\Scripts\activate
install.bat
python -m app.main
```

### Frontend:
```bash
cd frontend
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 📞 Verificación de Instalación

### Backend:
```bash
# Test 1: Python
python --version  # Debe ser 3.10+

# Test 2: Pip
pip --version

# Test 3: Importar FastAPI
python -c "import fastapi; print('OK')"

# Test 4: Servidor
python -m app.main
# Abrir: http://localhost:8000/health
```

### Frontend:
```bash
# Test 1: Flutter
flutter --version  # Debe ser 3.7+

# Test 2: Doctor
flutter doctor

# Test 3: Devices
flutter devices

# Test 4: Análisis
flutter analyze
```

---

## 💡 TIPS

1. **Siempre activar el entorno virtual** antes de instalar paquetes
2. **Usar versiones flexibles** (>=) en lugar de exactas (==)
3. **Instalar PyTorch CPU** si no tienes GPU: más ligero y rápido
4. **Usar Chrome** para desarrollo web de Flutter: más rápido
5. **Limpiar cache** si hay errores extraños: `flutter clean`

---

## 🆘 Si nada funciona

### Plan B - Instalación Mínima:

```bash
# Backend mínimo
pip install fastapi uvicorn sqlalchemy pydantic python-jose passlib

# Comentar imports de ML en los archivos:
# - app/services/ml_predictor.py
# - app/services/eeg_processor.py

# Ejecutar sin ML (solo API)
python -m app.main
```

### Plan C - Usar Docker (Avanzado):

```bash
# Crear Dockerfile
docker build -t eeg-backend .
docker run -p 8000:8000 eeg-backend
```

---

**¿Sigues teniendo problemas? Revisa los logs y busca el error específico en esta guía.** 🔍
