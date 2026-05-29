# 🛠️ Comandos Útiles

## Backend (Python)

### Instalación
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### Ejecutar servidor
```bash
python -m app.main
```

### Ejecutar con recarga automática
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Tests
```bash
pytest
pytest -v
pytest tests/test_auth.py
```

### Crear migración de base de datos
```bash
alembic revision --autogenerate -m "descripcion"
alembic upgrade head
```

### Limpiar cache
```bash
find . -type d -name __pycache__ -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
```

### Actualizar dependencias
```bash
pip freeze > requirements.txt
```

---

## Frontend (Flutter)

### Instalación
```bash
cd frontend
flutter pub get
```

### Ejecutar app
```bash
flutter run
flutter run -d chrome          # Web
flutter run -d windows         # Windows
```

### Build
```bash
flutter build apk              # Android APK
flutter build appbundle        # Android Bundle
flutter build ios              # iOS
flutter build web              # Web
flutter build windows          # Windows
```

### Limpiar
```bash
flutter clean
flutter pub get
```

### Analizar código
```bash
flutter analyze
```

### Tests
```bash
flutter test
flutter test --coverage
```

### Generar iconos
```bash
flutter pub run flutter_launcher_icons:main
```

### Actualizar dependencias
```bash
flutter pub upgrade
flutter pub outdated
```

---

## Git

### Inicializar repositorio
```bash
git init
git add .
git commit -m "Initial commit"
```

### Crear rama
```bash
git checkout -b feature/nueva-funcionalidad
```

### Push
```bash
git push origin main
```

---

## Docker (Opcional)

### Backend Dockerfile
```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "-m", "app.main"]
```

### Construir imagen
```bash
docker build -t eeg-backend .
docker run -p 8000:8000 eeg-backend
```

---

## Base de Datos

### SQLite
```bash
# Ver base de datos
sqlite3 eeg_analysis.db
.tables
.schema users
SELECT * FROM users;
.quit
```

### PostgreSQL (Producción)
```bash
# Conectar
psql -U postgres -d eeg_analysis

# Comandos
\dt                    # Listar tablas
\d users              # Describir tabla
SELECT * FROM users;  # Query
\q                    # Salir
```

---

## Debugging

### Backend
```python
# Agregar breakpoint
import pdb; pdb.set_trace()

# O usar debugpy
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()
```

### Flutter
```dart
// Print debug
print('Debug: $variable');
debugPrint('Debug message');

// Breakpoint en VS Code: F9
```

---

## Monitoreo

### Ver logs backend
```bash
tail -f app.log
```

### Ver requests
```bash
# En el código
import logging
logging.basicConfig(level=logging.DEBUG)
```

---

## Performance

### Backend
```bash
# Profiling
python -m cProfile -o output.prof app/main.py
```

### Flutter
```bash
flutter run --profile
flutter run --release
```

---

## Producción

### Backend
```bash
# Gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker

# Systemd service
sudo systemctl start eeg-backend
sudo systemctl enable eeg-backend
```

### Frontend
```bash
# Build release
flutter build apk --release
flutter build web --release
```

---

## Útiles

### Verificar puertos
```bash
netstat -ano | findstr :8000
```

### Matar proceso
```bash
taskkill /PID <pid> /F
```

### Ver versiones
```bash
python --version
flutter --version
pip --version
```

### Limpiar todo
```bash
# Backend
rm -rf venv __pycache__ *.pyc *.db

# Frontend
flutter clean
rm -rf build/
```

---

## Shortcuts VS Code

- `Ctrl + Shift + P` - Command Palette
- `Ctrl + `` - Terminal
- `F5` - Debug
- `Ctrl + Shift + F` - Buscar en archivos
- `Ctrl + P` - Buscar archivo
- `Ctrl + /` - Comentar línea

---

## Recursos

- FastAPI Docs: https://fastapi.tiangolo.com
- Flutter Docs: https://flutter.dev/docs
- HuggingFace: https://huggingface.co
- PhysioNet: https://physionet.org
