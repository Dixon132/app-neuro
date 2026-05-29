# 🐍 Backend - EEG Analysis API

API REST desarrollada con FastAPI para análisis de señales EEG utilizando Machine Learning.

## 🚀 Inicio Rápido

```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m app.main
```

**API:** http://localhost:8000  
**Docs:** http://localhost:8000/docs

## 📋 Características

- ✅ API RESTful con FastAPI
- ✅ Autenticación JWT
- ✅ Base de datos SQLite/PostgreSQL
- ✅ Procesamiento de señales EEG
- ✅ Modelo ML pre-entrenado (HuggingFace)
- ✅ Generación de reportes PDF
- ✅ Documentación automática (Swagger)

## 🏗️ Arquitectura

```
app/
├── main.py              # Entry point
├── config.py            # Configuración
├── api/
│   └── routes/          # Endpoints
├── models/              # Modelos de datos
├── services/            # Lógica de negocio
├── database/            # Conexión BD
├── ml/                  # Machine Learning
└── utils/               # Utilidades
```

## 📡 Endpoints

### Autenticación
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Iniciar sesión

### Análisis
- `POST /api/analysis/upload` - Subir y analizar EEG
- `GET /api/analysis/list` - Listar análisis
- `GET /api/analysis/{id}` - Detalle de análisis

### Health
- `GET /health` - Estado del servidor

## 🔧 Configuración

Crear archivo `.env`:

```env
DATABASE_URL=sqlite:///./eeg_analysis.db
SECRET_KEY=your-secret-key
HUGGINGFACE_MODEL=ThomasCdnns/EEG-Seizure-Detection
```

## 🧪 Tests

```bash
pytest
pytest -v
pytest --cov
```

## 📦 Dependencias Principales

- **FastAPI** - Framework web
- **SQLAlchemy** - ORM
- **PyTorch** - Deep Learning
- **HuggingFace** - Modelos pre-entrenados
- **MNE** - Procesamiento EEG
- **PyWavelets** - Transformada Wavelet
- **SciPy** - Procesamiento de señales
- **ReportLab** - Generación PDF

## 🤖 Modelo de IA

**Modelo:** ThomasCdnns/EEG-Seizure-Detection  
**Fuente:** HuggingFace  
**Precisión:** ~92%  
**Tarea:** Detección de epilepsia

## 📊 Procesamiento de Señales

1. **Carga de archivo** (EDF/CSV)
2. **Filtrado** (Bandpass 0.5-50 Hz)
3. **Normalización** (Z-score)
4. **Extracción de características:**
   - DWT (Discrete Wavelet Transform)
   - FFT (Fast Fourier Transform)
   - Bandas de frecuencia (Delta, Theta, Alpha, Beta, Gamma)
5. **Predicción ML**
6. **Generación de reporte**

## 🔐 Seguridad

- Autenticación JWT
- Validación de archivos
- Sanitización de datos
- Rate limiting (producción)
- CORS configurado

## 📝 Logging

Los logs se guardan en `app.log` y consola.

```python
from app.utils.logger import log_info, log_error
log_info("Mensaje informativo")
log_error("Mensaje de error")
```

## 🚀 Producción

### Con Gunicorn
```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

### Con Docker
```bash
docker build -t eeg-backend .
docker run -p 8000:8000 eeg-backend
```

## 📚 Documentación

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **OpenAPI JSON:** http://localhost:8000/openapi.json

## 🛠️ Desarrollo

### Agregar nueva ruta
```python
# app/api/routes/nueva_ruta.py
from fastapi import APIRouter

router = APIRouter(prefix="/nueva", tags=["Nueva"])

@router.get("/")
def get_nueva():
    return {"message": "Nueva ruta"}
```

### Agregar al main
```python
# app/main.py
from app.api.routes import nueva_ruta
app.include_router(nueva_ruta.router, prefix="/api")
```

## 📄 Licencia

MIT License

## 👥 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crear rama feature
3. Commit cambios
4. Push a la rama
5. Abrir Pull Request

---

**Desarrollado con ❤️ para análisis de señales EEG**
