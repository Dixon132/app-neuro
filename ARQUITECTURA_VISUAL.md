# 📊 ARQUITECTURA VISUAL DEL PROYECTO

## 🏗️ Diagrama de Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                     USUARIO FINAL                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   FLUTTER APP (Frontend)                     │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐  │
│  │  Login   │Dashboard │  Upload  │  Detail  │ Profile  │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘  │
│                            │                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         State Management (Riverpod)                  │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ AuthProvider │  │AnalysisProvider│               │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Services Layer                          │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │  ApiService  │  │StorageService│                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/REST
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  FASTAPI (Backend)                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  API Routes                           │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │   Auth   │  │ Analysis │  │  Health  │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Services Layer                           │  │
│  │  ┌──────────────┐  ┌──────────────┐                 │  │
│  │  │ AuthService  │  │ EEGProcessor │                 │  │
│  │  └──────────────┘  └──────────────┘                 │  │
│  │  ┌──────────────┐  ┌──────────────┐                 │  │
│  │  │ MLPredictor  │  │ReportGenerator│                │  │
│  │  └──────────────┘  └──────────────┘                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Data Layer                               │  │
│  │  ┌──────────────┐  ┌──────────────┐                 │  │
│  │  │   SQLite DB  │  │  HuggingFace │                 │  │
│  │  │   (Users,    │  │    Models    │                 │  │
│  │  │   Analysis)  │  │              │                 │  │
│  │  └──────────────┘  └──────────────┘                 │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Datos - Upload EEG

```
┌──────────┐
│  Usuario │
└────┬─────┘
     │ 1. Selecciona archivo EEG
     ▼
┌─────────────────┐
│  File Picker    │
│  (Flutter)      │
└────┬────────────┘
     │ 2. Archivo seleccionado
     ▼
┌─────────────────┐
│  ApiService     │
│  uploadEEG()    │
└────┬────────────┘
     │ 3. POST /api/analysis/upload
     ▼
┌─────────────────┐
│  FastAPI        │
│  /upload route  │
└────┬────────────┘
     │ 4. Guarda archivo
     ▼
┌─────────────────┐
│  EEGProcessor   │
│  - load_file()  │
│  - filter()     │
│  - normalize()  │
│  - extract_dwt()│
│  - extract_fft()│
└────┬────────────┘
     │ 5. Características extraídas
     ▼
┌─────────────────┐
│  MLPredictor    │
│  - load_model() │
│  - predict()    │
│  - calc_risk()  │
└────┬────────────┘
     │ 6. Predicción + Riesgo
     ▼
┌─────────────────┐
│ ReportGenerator │
│  - generate_pdf()│
└────┬────────────┘
     │ 7. PDF generado
     ▼
┌─────────────────┐
│  SQLite DB      │
│  - save()       │
└────┬────────────┘
     │ 8. Guardado en BD
     ▼
┌─────────────────┐
│  Response JSON  │
│  {id, risk,     │
│   prediction}   │
└────┬────────────┘
     │ 9. Retorna a Flutter
     ▼
┌─────────────────┐
│ AnalysisProvider│
│  - updateState()│
└────┬────────────┘
     │ 10. Actualiza UI
     ▼
┌─────────────────┐
│  Dashboard      │
│  - Muestra card │
│  - Permite ver  │
│    detalle      │
└─────────────────┘
```

---

## 🧠 Procesamiento de Señales EEG

```
┌─────────────────┐
│  Archivo EEG    │
│  (EDF/CSV)      │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  1. CARGA       │
│  - Lee archivo  │
│  - Extrae datos │
│  - Valida       │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  2. FILTRADO    │
│  - Butterworth  │
│  - Pasa banda   │
│  - 0.5-50 Hz    │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  3. NORMALIZACIÓN│
│  - Z-score      │
│  - Media = 0    │
│  - Std = 1      │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  4. DWT         │
│  - Wavelet db4  │
│  - Nivel 4      │
│  - Coeficientes │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  5. FFT         │
│  - Transformada │
│  - Frecuencias  │
│  - Bandas:      │
│    • Delta      │
│    • Theta      │
│    • Alpha      │
│    • Beta       │
│    • Gamma      │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  6. CARACTERÍSTICAS│
│  - Vector 100D  │
│  - DWT + FFT    │
│  - Normalizado  │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  7. PREDICCIÓN  │
│  - Modelo ML    │
│  - HuggingFace  │
│  - Riesgo %     │
└─────────────────┘
```

---

## 🗄️ Modelo de Base de Datos

```
┌─────────────────────────────────────┐
│             USERS                    │
├─────────────────────────────────────┤
│ id (PK)                              │
│ email (UNIQUE)                       │
│ username (UNIQUE)                    │
│ hashed_password                      │
│ full_name                            │
│ role                                 │
│ created_at                           │
└──────────┬──────────────────────────┘
           │ 1:N
           │
┌──────────▼──────────────────────────┐
│           ANALYSES                   │
├─────────────────────────────────────┤
│ id (PK)                              │
│ user_id (FK) ───────────────────────┤
│ file_path                            │
│ file_name                            │
│ status                               │
│ risk_score                           │
│ prediction                           │
│ created_at                           │
│ completed_at                         │
└──────────┬──────────────────────────┘
           │ 1:1
           │
┌──────────▼──────────────────────────┐
│            REPORTS                   │
├─────────────────────────────────────┤
│ id (PK)                              │
│ analysis_id (FK) ────────────────────┤
│ pdf_path                             │
│ metrics (JSON)                       │
│ created_at                           │
└─────────────────────────────────────┘
```

---

## 📱 Navegación de Pantallas Flutter

```
┌─────────────┐
│   Splash    │
│   Screen    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Login     │◄──────┐
│   Screen    │       │
└──────┬──────┘       │
       │              │
       ▼              │
┌─────────────┐       │
│  Register   │       │
│   Screen    │───────┘
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Dashboard  │◄──────┐
│   Screen    │       │
└──────┬──────┘       │
       │              │
       ├──────────────┤
       │              │
       ▼              │
┌─────────────┐       │
│  EEG Upload │       │
│   Screen    │───────┤
└──────┬──────┘       │
       │              │
       ▼              │
┌─────────────┐       │
│  Analysis   │       │
│   Detail    │───────┘
│   Screen    │
└─────────────┘
```

---

## 🔐 Flujo de Autenticación

```
┌──────────┐
│  Usuario │
└────┬─────┘
     │ 1. Ingresa credenciales
     ▼
┌─────────────────┐
│  Login Screen   │
└────┬────────────┘
     │ 2. Valida formulario
     ▼
┌─────────────────┐
│  AuthProvider   │
│  login()        │
└────┬────────────┘
     │ 3. POST /api/auth/login
     ▼
┌─────────────────┐
│  Backend        │
│  AuthService    │
└────┬────────────┘
     │ 4. Verifica usuario
     ▼
┌─────────────────┐
│  Database       │
│  Query user     │
└────┬────────────┘
     │ 5. Usuario encontrado
     ▼
┌─────────────────┐
│  Verify         │
│  Password       │
│  (bcrypt)       │
└────┬────────────┘
     │ 6. Password OK
     ▼
┌─────────────────┐
│  Generate JWT   │
│  Token          │
└────┬────────────┘
     │ 7. Token generado
     ▼
┌─────────────────┐
│  Response       │
│  {token, type}  │
└────┬────────────┘
     │ 8. Retorna a Flutter
     ▼
┌─────────────────┐
│  StorageService │
│  saveToken()    │
└────┬────────────┘
     │ 9. Token guardado
     ▼
┌─────────────────┐
│  AuthProvider   │
│  updateState()  │
└────┬────────────┘
     │ 10. isAuthenticated = true
     ▼
┌─────────────────┐
│  Navigate to    │
│  Dashboard      │
└─────────────────┘
```

---

## 📊 Estado de la Aplicación (Riverpod)

```
┌─────────────────────────────────────┐
│         Application State            │
├─────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────┐    │
│  │      AuthState             │    │
│  ├────────────────────────────┤    │
│  │ - isAuthenticated: bool    │    │
│  │ - user: UserModel?         │    │
│  │ - isLoading: bool          │    │
│  │ - error: String?           │    │
│  └────────────────────────────┘    │
│                                      │
│  ┌────────────────────────────┐    │
│  │    AnalysisState           │    │
│  ├────────────────────────────┤    │
│  │ - analyses: List<Analysis> │    │
│  │ - currentAnalysis: Analysis?│   │
│  │ - isLoading: bool          │    │
│  │ - error: String?           │    │
│  └────────────────────────────┘    │
│                                      │
└─────────────────────────────────────┘
```

---

## 🎨 Estructura de Widgets

```
MaterialApp
│
├── Splash Screen
│   └── Logo + Loading
│
├── Login Screen
│   ├── Logo
│   ├── Form
│   │   ├── Username Field
│   │   └── Password Field
│   ├── Login Button
│   └── Register Link
│
├── Dashboard Screen
│   ├── AppBar
│   ├── Welcome Card
│   ├── Stats Row
│   │   ├── Total Card
│   │   └── Completed Card
│   ├── Analysis List
│   │   └── Analysis Card (x N)
│   └── FAB (Upload)
│
├── Upload Screen
│   ├── AppBar
│   ├── Upload Icon
│   ├── Instructions
│   ├── File Card (if selected)
│   ├── Select Button
│   └── Upload Button
│
└── Detail Screen
    ├── AppBar
    ├── File Info Card
    ├── Risk Gauge Chart
    ├── Recommendations Card
    └── FAB (Download)
```

---

## 🔄 Ciclo de Vida de un Análisis

```
┌─────────────┐
│   PENDING   │ ← Archivo subido
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ PROCESSING  │ ← Procesando señal
└──────┬──────┘
       │
       ├─────────┐
       │         │
       ▼         ▼
┌─────────┐ ┌─────────┐
│COMPLETED│ │ FAILED  │
└─────────┘ └─────────┘
```

---

## 📈 Métricas y Monitoreo

```
Backend Logs:
├── INFO: Request received
├── INFO: File uploaded
├── INFO: Processing started
├── INFO: Features extracted
├── INFO: Prediction completed
├── INFO: Report generated
└── INFO: Response sent

Frontend States:
├── Loading: true/false
├── Error: null/message
├── Data: null/loaded
└── Success: true/false
```

---

**Este diagrama visual te ayuda a entender la arquitectura completa del proyecto** 🎯
