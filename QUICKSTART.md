# 🚀 Guía de Inicio Rápido

## Paso 1: Iniciar Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m app.main
```

✅ Backend corriendo en: http://localhost:8000

## Paso 2: Iniciar Frontend

```bash
cd frontend
flutter pub get
flutter run
```

✅ App Flutter iniciada

## Paso 3: Probar la Aplicación

1. **Registrarse:**
   - Abrir la app
   - Ir a "Registrarse"
   - Completar formulario
   - Iniciar sesión

2. **Subir archivo EEG:**
   - Click en "Subir EEG"
   - Seleccionar archivo .edf o .csv
   - Click en "Subir y Analizar"
   - Esperar procesamiento

3. **Ver resultados:**
   - Dashboard muestra análisis
   - Click en análisis para ver detalles
   - Ver gráfico de riesgo
   - Descargar reporte PDF

## 🧪 Datos de Prueba

Puedes usar archivos EEG de ejemplo de:
- https://physionet.org/content/chbmit/1.0.0/
- Formato: EDF
- Tamaño: < 100MB

## 🔧 Solución de Problemas

### Backend no inicia
- Verificar Python 3.10+
- Instalar todas las dependencias
- Verificar puerto 8000 disponible

### Flutter no compila
- Ejecutar `flutter doctor`
- Verificar SDK instalado
- Ejecutar `flutter clean`

### Error de conexión
- Verificar backend corriendo
- Cambiar URL en `constants.dart` si es necesario
- Verificar firewall

## 📱 Credenciales de Prueba

Usuario: `admin`
Contraseña: `admin123`

(Crear cuenta nueva en registro)

## 🎯 Próximos Pasos

1. Explorar dashboard
2. Subir múltiples archivos
3. Comparar análisis
4. Descargar reportes
5. Ver visualizaciones

---

¡Listo para analizar señales EEG! 🧠
