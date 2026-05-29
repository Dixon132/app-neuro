from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "EEG Analysis API"
    VERSION: str = "1.0.0"
    API_PREFIX: str = "/api"
    
    # Database
    DATABASE_URL: str = "sqlite:///./eeg_analysis.db"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # File Upload
    UPLOAD_DIR: str = "./data/uploads"
    MAX_FILE_SIZE: int = 100 * 1024 * 1024  # 100MB
    
    # ML Models
    MODEL_DIR: str = "./data/models"
    HUGGINGFACE_MODEL: str = "ThomasCdnns/EEG-Seizure-Detection"
    
    class Config:
        env_file = ".env"

settings = Settings()
