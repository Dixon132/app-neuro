# Guía Rápida de Instalación y Pruebas (NeuroScan AI)

Sigue estos pasos para levantar el proyecto desde cero al clonarlo en otra computadora. Todo está ordenado y simplificado.

---

## 1. Instalar y Levantar el Backend (Python)

El backend requiere Python 3.10 o superior.

1. **Abre una terminal** y navega a la carpeta del backend:
   ```powershell
   cd backend
   ```
2. **Crea y activa un entorno virtual:**
   ```powershell
   python -m venv venv
   .\venv\Scripts\activate
   ```
3. **Instala las dependencias:**
   *(He removido `pyedflib` de los requerimientos ya que `mne` soporta EDF nativamente y no tendrás errores de compilación de C++ en Windows).*
   ```powershell
   pip install -r requirements.txt
   ```
4. **Poblar datos de prueba (Resetear DB):**
   Para tener administradores, pacientes y reportes listos:
   ```powershell
   python seed_data.py
   ```
   > Esto creará al admin (`admin / Admin1234!`) y a un paciente de prueba (`paciente / Paciente1234!`).
5. **Inicia el servidor:**
   ```powershell
   python -m app.main
   ```
   > El backend estará corriendo en `http://localhost:8000`.

---

## 2. Instalar y Levantar el Frontend (Flutter)

El frontend requiere Flutter (recomendado 3.16 o superior).

1. **Abre otra terminal** y navega a la carpeta del frontend:
   ```powershell
   cd frontend
   ```
2. **Instala las dependencias:**
   ```powershell
   flutter pub get
   ```
3. **Inicia la aplicación web:**
   ```powershell
   flutter run -d chrome
   ```

---

## 3. Credenciales para Pruebas

Si ejecutaste el script `seed_data.py`, estas son tus cuentas listas para usar:

### 👤 Administrador (Dashboard Global)
- **Usuario:** `admin`
- **Contraseña:** `Admin1234!`
- *¿Dónde?* En la pantalla de login principal, baja y da clic en "Acceso Administrador".

### 🏥 Paciente de Prueba (Dashboard Personal)
- **Usuario:** `paciente`
- **Contraseña:** `Paciente1234!`
- *¿Dónde?* En el login normal principal.

*(Si quieres probar un registro desde cero, puedes darle al botón "Registrarse" y crear la cuenta que quieras).*

---

## Solución a posibles problemas
- **"Failed to load dependencies / flutter"**: Corre `flutter clean` y luego `flutter pub get`.
- **"Error conectando al servidor"**: Asegúrate de que no haya firewalls bloqueando el puerto 8000 en el backend. Si el frontend Web se queja de "Failed to load" a nivel CORS, revisa que entras a la IP local configurada en `lib/config/constants.dart`.
- **"AuthError al recargar"**: Esto ya fue arreglado; el sistema ahora rehidrata las sesiones en caliente usando Riverpod al recargar la ventana.
