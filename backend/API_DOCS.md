# 📚 Documentación de API

## Base URL
```
http://localhost:8000/api
```

## Autenticación

### Registro de Usuario
**POST** `/auth/register`

**Body:**
```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "password123",
  "full_name": "Full Name"
}
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "username",
  "full_name": "Full Name",
  "role": "user",
  "created_at": "2024-01-01T00:00:00"
}
```

### Login
**POST** `/auth/login`

**Body:**
```json
{
  "username": "username",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

## Análisis EEG

### Subir Archivo EEG
**POST** `/analysis/upload`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body:**
- `file`: Archivo EEG (EDF o CSV)
- `user_id`: ID del usuario (opcional)

**Response:**
```json
{
  "id": 1,
  "file_name": "eeg_sample.edf",
  "status": "completed",
  "risk_score": 75.5,
  "prediction": "Alto Riesgo",
  "created_at": "2024-01-01T00:00:00"
}
```

### Listar Análisis
**GET** `/analysis/list`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `user_id`: ID del usuario (opcional)

**Response:**
```json
[
  {
    "id": 1,
    "file_name": "eeg_sample.edf",
    "status": "completed",
    "risk_score": 75.5,
    "prediction": "Alto Riesgo",
    "created_at": "2024-01-01T00:00:00"
  }
]
```

### Detalle de Análisis
**GET** `/analysis/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": 1,
  "file_name": "eeg_sample.edf",
  "status": "completed",
  "risk_score": 75.5,
  "prediction": "Alto Riesgo",
  "created_at": "2024-01-01T00:00:00",
  "completed_at": "2024-01-01T00:05:00"
}
```

## Health Check

### Estado del Servidor
**GET** `/health`

**Response:**
```json
{
  "status": "healthy"
}
```

## Códigos de Estado

- `200` - OK
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

## Formatos de Archivo Soportados

- **EDF** (European Data Format)
- **CSV** (Comma Separated Values)

## Límites

- Tamaño máximo de archivo: 100 MB
- Tiempo de procesamiento: 1-5 minutos
- Rate limit: 100 requests/hora

## Ejemplos con cURL

### Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Upload EEG
```bash
curl -X POST http://localhost:8000/api/analysis/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@path/to/eeg_file.edf"
```

### List Analyses
```bash
curl -X GET http://localhost:8000/api/analysis/list \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Documentación Interactiva

Visita `http://localhost:8000/docs` para la documentación interactiva de Swagger.
