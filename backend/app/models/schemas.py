from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List, Dict, Any

class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str
    full_name: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    full_name: str
    role: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class ChannelAnalysis(BaseModel):
    channel: str
    anomaly_score: float
    spike_rate: float
    kurtosis: float
    delta_rel: float
    alpha_rel: float
    spectral_entropy: float

class AnalysisResponse(BaseModel):
    id: int
    file_name: str
    status: str
    risk_score: Optional[float]
    prediction: Optional[str]
    confidence: Optional[float] = None
    most_anomalous_channel: Optional[str] = None
    n_windows_analyzed: Optional[int] = None
    sampling_rate: Optional[int] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

class ReportResponse(BaseModel):
    id: int
    analysis_id: int
    pdf_path: str
    created_at: datetime
    
    class Config:
        from_attributes = True
