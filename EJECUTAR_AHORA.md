# ⚡ EJECUTA ESTOS COMANDOS AHORA

## 🎯 PASO 1: Arreglar Frontend (30 segundos)

Abre una terminal en la carpeta del proyecto y ejecuta:

```bash
cd frontend
flutter clean
flutter pub get
flutter run -d chrome
```

✅ **Resultado esperado:** La app se abre en Chrome sin errores

---

## 🎯 PASO 2: Arreglar Backend (5-10 minutos)

### Abre OTRA terminal (nueva) y ejecuta:

```bash
cd backend
venv\Scripts\activate
```

Deberías ver `(venv)` al inicio de la línea.

### Ahora ejecuta el script de instalación:

```bash
install.bat
```

**Espera pacientemente** mientras se instalan las dependencias (5-10 minutos).

### Cuando termine, ejecuta:

```bash
python -m app.main
```

✅ **Resultado esperado:** 
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

---

## 🧪 PASO 3: Verificar que funciona

### Verificar Backend:
Abre en tu navegador: http://localhost:8000/docs

Deberías ver la documentación de la API (Swagger UI).

### Verificar Frontend:
La app ya debería estar abierta en Chrome mostrando:
1. Splash screen (2 segundos)
2. Pantalla de login

---

## 🎮 PASO 4: Probar la app

1. En la app (Chrome), click en "¿No tienes cuenta? Regístrate"
2. Llenar el formulario:
   - Nombre: Test User
   - Email: test@test.com
   - Usuario: test
   - Contraseña: test123
3. Click "Registrarse"
4. Deberías ver el Dashboard

---

## ❌ SI HAY ERRORES

### Error en Frontend:
```bash
# Limpiar y reintentar
cd frontend
flutter clean
rm -rf build
flutter pub get
flutter run -d chrome
```

### Error en Backend (install.bat falla):

Ejecuta manualmente:

```bash
cd backend
venv\Scripts\activate

# Instalar uno por uno
pip install fastapi uvicorn python-multipart
pip install sqlalchemy pydantic pydantic-settings
pip install python-jose[cryptography] passlib bcrypt
pip install python-dotenv aiofiles
pip install numpy scipy pandas
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install transformers huggingface-hub
pip install mne PyWavelets reportlab matplotlib

# Ejecutar
python -m app.main
```

### Error: "Port 8000 already in use"
```bash
netstat -ano | findstr :8000
taskkill /PID <número> /F
```

---

## 📊 ESTADO ACTUAL

Después de ejecutar estos comandos deberías tener:

✅ Frontend corriendo en Chrome (http://localhost:XXXXX)  
✅ Backend corriendo en http://localhost:8000  
✅ Documentación API en http://localhost:8000/docs  
✅ App funcional lista para usar  

---

## 🎯 SIGUIENTE PASO

Una vez que todo funcione:

1. Registrarte en la app
2. Iniciar sesión
3. Explorar el dashboard
4. Intentar subir un archivo (puede fallar sin archivo real, pero debe mostrar el selector)

---

## 📞 AYUDA ADICIONAL

Si algo no funciona:
1. Copia el error exacto
2. Revisa `SOLUCION_PROBLEMAS.md`
3. Busca el error específico en ese archivo

---

**¡Ejecuta estos comandos y todo debería funcionar! 🚀**
