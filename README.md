# 🧠 Sistema de Análisis EEG con IA

Sistema completo de análisis de señales EEG utilizando Machine Learning para detección de epilepsia.

## 📋 Estructura del Proyecto

```
proyecto/
├── backend/          # API Python FastAPI
└── frontend/         # App Flutter
```

## 🚀 Instalación y Ejecución

### Backend (Python FastAPI)

1. **Navegar al directorio del backend:**
```bash
cd backend
```

2. **Crear entorno virtual:**
```bash
python -m venv venv
```

3. **Activar entorno virtual:**
- Windows:
```bash
venv\Scripts\activate
```
- Linux/Mac:
```bash
source venv/bin/activate
```

4. **Instalar dependencias:**
```bash
pip install -r requirements.txt
```

5. **Configurar variables de entorno:**
```bash
copy .env.example .env
```

6. **Ejecutar el servidor:**
```bash
python -m app.main
```

El servidor estará disponible en: `http://localhost:8000`

**Documentación API:** `http://localhost:8000/docs`

### Frontend (Flutter)

1. **Navegar al directorio del frontend:**
```bash
cd frontend
```

2. **Instalar dependencias:**
```bash
flutter pub get
```

3. **Ejecutar la aplicación:**
```bash
flutter run
```

## 🔄 Flujo de Trabajo

1. **Usuario carga archivo EEG** (EDF/CSV)
2. **Flutter valida formato**
3. **Envía a Backend** (POST /api/analysis/upload)
4. **Backend procesa:**
   - Lee archivo EEG
   - Aplica filtros (Bandpass)
   - Normaliza datos
   - Extrae características (DWT, FFT)
5. **Predicción ML:**
   - Carga modelo pre-entrenado de HuggingFace
   - Realiza predicción
   - Calcula métricas
   - Genera riesgo (0-100%)
6. **Genera Reporte PDF**
7. **Guarda en Base de Datos**
8. **Retorna resultados a Flutter**
9. **Flutter visualiza gráficos y métricas**

## 🤖 Modelo de IA

Utilizamos el modelo pre-entrenado de HuggingFace:
- **Modelo:** ThomasCdnns/EEG-Seizure-Detection
- **Precisión:** ~92%
- **Tamaño:** 50 MB

## 📊 Características

### Backend
- ✅ API RESTful con FastAPI
- ✅ Autenticación JWT
- ✅ Procesamiento de señales EEG
- ✅ Modelo ML pre-entrenado
- ✅ Generación de reportes PDF
- ✅ Base de datos SQLite

### Frontend
- ✅ Interfaz moderna con Flutter
- ✅ Gestión de estado con Riverpod
- ✅ Carga de archivos EEG
- ✅ Visualización de resultados
- ✅ Gráficos interactivos
- ✅ Dashboard de análisis

## 🔑 Endpoints Principales

### Autenticación
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Iniciar sesión

### Análisis
- `POST /api/analysis/upload` - Subir y analizar EEG
- `GET /api/analysis/list` - Listar análisis
- `GET /api/analysis/{id}` - Detalle de análisis

## 📱 Pantallas Flutter

1. **Login/Registro** - Autenticación de usuarios
2. **Dashboard** - Vista general de análisis
3. **Upload EEG** - Carga de archivos
4. **Detalle de Análisis** - Resultados y métricas
5. **Visualización** - Gráficos de señales

## 🛠️ Tecnologías

### Backend
- Python 3.10+
- FastAPI
- SQLAlchemy
- PyTorch/TensorFlow
- HuggingFace Transformers
- MNE (procesamiento EEG)
- ReportLab (PDF)

### Frontend
- Flutter 3.7+
- Riverpod (State Management)
- HTTP/Dio (API calls)
- FL Chart (Gráficos)
- File Picker

## 📝 Notas Importantes

1. **Archivos soportados:** EDF, CSV
2. **Tamaño máximo:** 100 MB
3. **Modelo:** Se descarga automáticamente de HuggingFace
4. **Base de datos:** SQLite (desarrollo), PostgreSQL (producción)

## 🔐 Seguridad

- Autenticación JWT
- Validación de archivos
- Sanitización de datos
- CORS configurado

## 📄 Licencia

Este proyecto es de código abierto para fines educativos.

## 👥 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request.

## 📞 Soporte

Para soporte, contacta al equipo de desarrollo.

---

**Desarrollado con ❤️ para el análisis de señales EEG**
