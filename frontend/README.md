# 📱 Frontend - EEG Analysis App

Aplicación móvil desarrollada con Flutter para análisis de señales EEG.

## 🚀 Inicio Rápido

```bash
flutter pub get
flutter run
```

## 📋 Características

- ✅ Interfaz moderna Material Design 3
- ✅ State Management con Riverpod
- ✅ Autenticación de usuarios
- ✅ Carga de archivos EEG
- ✅ Visualización de resultados
- ✅ Gráficos interactivos
- ✅ Dashboard de análisis
- ✅ Soporte multiplataforma

## 🏗️ Arquitectura

```
lib/
├── main.dart            # Entry point
├── config/              # Configuración
├── models/              # Modelos de datos
├── services/            # Servicios (API, Storage)
├── providers/           # State Management
├── screens/             # Pantallas
├── widgets/             # Componentes reutilizables
├── utils/               # Utilidades
└── routes/              # Navegación
```

## 📱 Pantallas

1. **Splash Screen** - Pantalla de carga
2. **Login** - Autenticación
3. **Registro** - Crear cuenta
4. **Dashboard** - Vista general
5. **Upload EEG** - Subir archivos
6. **Detalle Análisis** - Resultados

## 🎨 Tema

Colores principales:
- Primary: `#6366F1` (Indigo)
- Secondary: `#8B5CF6` (Purple)
- Accent: `#10B981` (Green)
- Error: `#EF4444` (Red)

## 📦 Dependencias

```yaml
dependencies:
  flutter_riverpod: ^2.4.9    # State Management
  http: ^1.1.2                # HTTP Client
  shared_preferences: ^2.2.2  # Storage
  file_picker: ^6.1.1         # File Selection
  fl_chart: ^0.65.0           # Charts
  intl: ^0.19.0               # Internationalization
```

## 🔧 Configuración

### API URL
Editar `lib/config/constants.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:8000/api';
```

Para dispositivo físico, usar IP de tu computadora:
```dart
static const String apiBaseUrl = 'http://192.168.1.X:8000/api';
```

## 🧪 Tests

```bash
flutter test
flutter test --coverage
```

## 📱 Build

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Windows
```bash
flutter build windows --release
```

## 🎯 State Management

Usando **Riverpod** para gestión de estado:

```dart
// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Consumer
Consumer(
  builder: (context, ref, child) {
    final authState = ref.watch(authProvider);
    return Text(authState.user?.name ?? 'Guest');
  },
)
```

## 🌐 Navegación

Rutas definidas en `lib/routes/app_routes.dart`:

```dart
Navigator.pushNamed(context, '/dashboard');
Navigator.pushNamed(context, '/upload');
Navigator.pushNamed(context, '/analysis-detail', arguments: analysisId);
```

## 🎨 Widgets Personalizados

### AnalysisCard
```dart
AnalysisCard(
  analysis: analysis,
  onTap: () => Navigator.pushNamed(context, '/detail'),
)
```

### RiskGaugeChart
```dart
RiskGaugeChart(riskScore: 75.5)
```

## 📊 Servicios

### ApiService
```dart
final apiService = ApiService();
await apiService.login(username, password);
await apiService.uploadEEG(filePath);
```

### StorageService
```dart
final storage = StorageService();
await storage.saveToken(token);
final token = await storage.getToken();
```

## 🔐 Autenticación

El token JWT se guarda en SharedPreferences y se incluye en todas las peticiones:

```dart
headers: {
  'Authorization': 'Bearer $token',
}
```

## 🎨 Personalización

### Cambiar colores
Editar `lib/config/theme.dart`:

```dart
static const Color primaryColor = Color(0xFF6366F1);
```

### Agregar nueva pantalla
1. Crear archivo en `lib/screens/`
2. Agregar ruta en `lib/routes/app_routes.dart`
3. Navegar con `Navigator.pushNamed()`

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🐛 Debug

```bash
flutter run --debug
flutter logs
flutter analyze
```

## 🚀 Performance

```bash
flutter run --profile
flutter run --release
```

## 📦 Assets

Agregar imágenes en `assets/images/` y actualizar `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/logo.png
```

## 🌍 Internacionalización

Agregar traducciones en `lib/l10n/`:

```dart
import 'package:intl/intl.dart';
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

**Desarrollado con ❤️ usando Flutter**
