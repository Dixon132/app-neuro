from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.config import settings
from app.database.connection import init_db, get_db
from app.api.routes import auth, analysis
from app.api.routes import admin

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("🚀 Iniciando servidor...")
    init_db()
    print("✅ Base de datos inicializada")
    # Ensure default admin exists
    from app.services.auth_service import ensure_admin_exists
    db = next(get_db())
    try:
        ensure_admin_exists(db)
    finally:
        db.close()
    print(f"📡 API disponible en: http://localhost:8000")
    print(f"📚 Documentación en: http://localhost:8000/docs")
    yield
    # Shutdown
    print("👋 Cerrando servidor...")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Rutas
app.include_router(auth.router, prefix=settings.API_PREFIX)
app.include_router(analysis.router, prefix=settings.API_PREFIX)
app.include_router(admin.router, prefix=settings.API_PREFIX)

@app.get("/")
def root():
    return {"message": "EEG Analysis API", "version": settings.VERSION, "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "api": "operational"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
