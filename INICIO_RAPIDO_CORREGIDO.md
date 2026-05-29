# 🚀 INICIO RÁPIDO - Solución de Errores

## ✅ ERRORES CORREGIDOS

### 1. ❌ Icons.brain → ✅ Icons.psychology
- **Error:** `Member not found: 'brain'`
- **Solución:** Cambiado a `Icons.psychology` (icono de cerebro disponible)

### 2. ❌ NumPy compilation → ✅ Pre-compiled wheels
- **Error:** `Unknown compiler(s)`
- **Solución:** Usar versiones pre-compiladas

---

## 🎯 INSTALACIÓN CORRECTA

### 📱 FRONTEND (Flutter) - 2 minutos

```bash
cd frontend
flutter clean
flutter pub get
flutter run -d chrome
```

✅ **Listo!** La app debería abrir en Chrome.

---

### 🐍 BACKEND (Python) - 5 minutos

#### Opción 1: Script Automático (RECOMENDADO)

```bash
cd backend
python -m venv venv
venv\Scripts\activate
install.bat
```

Espera 5-10 minutos mientras se instalan las dependencias.

Luego ejecuta:
```bash
python -m app.main
```

✅ **Backend corriendo en:** http://localhost:8000

---

#### Opción 2: Instalación Manual (Paso a Paso)

```bash
cd backend
python -m venv venv
venv\Scripts\activate

# 1. Actualizar pip
python -m pip install --upgrade pip

# 2. Dependencias básicas (1 min)
pip install fastapi uvicorn python-multipart sqlalchemy pydantic pydantic-settings python-dotenv aiofiles

# 3. Autenticación (30 seg)
pip install python-jose[cryptography] passlib[bcrypt] bcrypt

# 4. Ciencia de datos (2-3 min)
pip install numpy scipy pandas scikit-learn matplotlib seaborn

# 5. PyTorch CPU (2-3 min)
pip install torch --index-url https://download.pytorch.org/whl/cpu

# 6. ML y EEG (2-3 min)
pip install transformers huggingface-hub mne PyWavelets reportlab

# 7. Ejecutar
python -m app.main
```

---

## 🧪 VERIFICAR QUE TODO FUNCIONA

### Backend:
```bash
# Terminal 1
cd backend
venv\Scripts\activate
python -m app.main
```

Deberías ver:
```
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Abrir en navegador: http://localhost:8000/docs

---

### Frontend:
```bash
# Terminal 2 (nueva terminal)
cd frontend
flutter run -d chrome
```

Deberías ver la app abrirse en Chrome con:
- Splash screen con icono de cerebro (psychology)
- Pantalla de login

---

## 🎮 PROBAR LA APLICACIÓN

1. **Registrarse:**
   - Click en "¿No tienes cuenta? Regístrate"
   - Llenar formulario
   - Click "Registrarse"

2. **Iniciar sesión:**
   - Usuario: el que creaste
   - Contraseña: la que creaste
   - Click "Iniciar Sesión"

3. **Dashboard:**
   - Verás estadísticas (0 análisis al inicio)
   - Click en botón flotante "Subir EEG"

4. **Subir archivo:**
   - Click "Seleccionar Archivo"
   - Elegir archivo .edf o .csv
   - Click "Subir y Analizar"
   - Esperar procesamiento

5. **Ver resultados:**
   - Dashboard mostrará el análisis
   - Click en la tarjeta para ver detalles
   - Ver gráfico de riesgo

---

## 📥 DATOS DE PRUEBA

### Opción 1: Crear archivo CSV simple

Crear archivo `test_eeg.csv`:
```csv
timestamp,channel1,channel2,channel3,channel4
0.0,0.5,0.3,0.2,0.1
0.004,0.6,0.4,0.3,0.2
0.008,0.4,0.2,0.1,0.3
```

### Opción 2: Descargar datos reales

PhysioNet: https://physionet.org/content/chbmit/1.0.0/
- Descargar cualquier archivo .edf
- Ejemplo: `chb01_03.edf`

---

## ❌ SI ALGO FALLA

### Frontend no compila:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Backend no instala:
```bash
# Usar script de instalación
cd backend
venv\Scripts\activate
install.bat
```

### Puerto 8000 ocupado:
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <pid> /F
```

### No encuentra módulos:
```bash
# Verificar que el entorno virtual está activado
# Deberías ver (venv) al inicio de la línea
venv\Scripts\activate
```

---

## 📚 DOCUMENTACIÓN COMPLETA

- `SOLUCION_PROBLEMAS.md` - Guía completa de errores
- `INSTALACION.md` - Instalación detallada
- `QUICKSTART.md` - Inicio rápido
- `README.md` - Documentación principal

---

## 🎯 RESUMEN

### ✅ Frontend:
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### ✅ Backend:
```bash
cd backend
venv\Scripts\activate
install.bat
python -m app.main
```

### ✅ Verificar:
- Backend: http://localhost:8000/docs
- Frontend: Abre automáticamente en Chrome

---

## 💡 TIPS

1. **Siempre activar venv** antes de ejecutar Python
2. **Usar Chrome** para Flutter web (más rápido)
3. **Esperar pacientemente** la instalación de dependencias
4. **Revisar logs** si algo falla

---

**¡Ahora sí debería funcionar todo! 🎉**

Si tienes problemas, revisa `SOLUCION_PROBLEMAS.md`
