from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from app.database.connection import get_db
from app.models.user import User, Analysis
from app.models.schemas import UserCreate
from app.services.auth_service import create_user, authenticate_user, get_current_user, create_access_token
from pydantic import BaseModel
from datetime import datetime

router = APIRouter(prefix="/admin", tags=["Admin"])

class AdminLoginRequest(BaseModel):
    username: str
    password: str

class CreateAdminRequest(BaseModel):
    email: str
    username: str
    password: str
    full_name: str

@router.post("/login")
def admin_login(body: AdminLoginRequest, db: Session = Depends(get_db)):
    """Login exclusivo para administradores"""
    db_user = authenticate_user(db, body.username, body.password)
    if not db_user:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    if db_user.role != "admin":
        raise HTTPException(status_code=403, detail="Acceso denegado. Solo administradores.")
    
    access_token = create_access_token(data={"sub": db_user.username})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": db_user.role,
        "user": {
            "id": db_user.id,
            "email": db_user.email,
            "username": db_user.username,
            "full_name": db_user.full_name,
            "role": db_user.role,
        }
    }

@router.get("/patients")
def list_patients(db: Session = Depends(get_db)):
    """Lista todos los pacientes con su resumen de actividad"""
    patients = db.query(User).filter(User.role == "user").all()
    result = []
    for patient in patients:
        analyses = db.query(Analysis).filter(Analysis.user_id == patient.id).all()
        completed = [a for a in analyses if a.status == "completed"]
        last_analysis = max(completed, key=lambda a: a.created_at) if completed else None
        
        result.append({
            "id": patient.id,
            "full_name": patient.full_name,
            "username": patient.username,
            "email": patient.email,
            "created_at": patient.created_at.isoformat(),
            "total_uploads": len(analyses),
            "completed_analyses": len(completed),
            "last_analysis": {
                "id": last_analysis.id,
                "file_name": last_analysis.file_name,
                "prediction": last_analysis.prediction,
                "risk_score": last_analysis.risk_score,
                "confidence": last_analysis.confidence,
                "most_anomalous_channel": last_analysis.most_anomalous_channel,
                "n_windows_analyzed": last_analysis.n_windows_analyzed,
                "sampling_rate": last_analysis.sampling_rate,
                "created_at": last_analysis.created_at.isoformat(),
                "completed_at": last_analysis.completed_at.isoformat() if last_analysis.completed_at else None,
                "status": last_analysis.status,
            } if last_analysis else None,
        })
    return result

@router.get("/patients/{patient_id}/detail")
def patient_detail(patient_id: int, db: Session = Depends(get_db)):
    """Detalle completo de un paciente con todas sus análisis"""
    patient = db.query(User).filter(User.id == patient_id, User.role == "user").first()
    if not patient:
        raise HTTPException(status_code=404, detail="Paciente no encontrado")
    
    analyses = db.query(Analysis).filter(Analysis.user_id == patient_id).order_by(Analysis.created_at.desc()).all()
    return {
        "id": patient.id,
        "full_name": patient.full_name,
        "username": patient.username,
        "email": patient.email,
        "created_at": patient.created_at.isoformat(),
        "analyses": [{
            "id": a.id,
            "file_name": a.file_name,
            "status": a.status,
            "prediction": a.prediction,
            "risk_score": a.risk_score,
            "confidence": a.confidence,
            "most_anomalous_channel": a.most_anomalous_channel,
            "n_windows_analyzed": a.n_windows_analyzed,
            "sampling_rate": a.sampling_rate,
            "created_at": a.created_at.isoformat(),
            "completed_at": a.completed_at.isoformat() if a.completed_at else None,
        } for a in analyses]
    }

@router.post("/create-admin")
def create_admin_user(body: CreateAdminRequest, db: Session = Depends(get_db)):
    """Crear un nuevo usuario administrador"""
    existing = db.query(User).filter(
        (User.email == body.email) | (User.username == body.username)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email o username ya existen")
    
    from app.models.schemas import UserCreate
    user_data = UserCreate(
        email=body.email,
        username=body.username,
        password=body.password,
        full_name=body.full_name
    )
    new_admin = create_user(db, user_data, role="admin")
    return {
        "id": new_admin.id,
        "email": new_admin.email,
        "username": new_admin.username,
        "full_name": new_admin.full_name,
        "role": new_admin.role,
        "created_at": new_admin.created_at.isoformat(),
    }

@router.get("/admins")
def list_admins(db: Session = Depends(get_db)):
    """Lista todos los administradores"""
    admins = db.query(User).filter(User.role == "admin").all()
    return [{
        "id": admin.id,
        "email": admin.email,
        "username": admin.username,
        "full_name": admin.full_name,
        "created_at": admin.created_at.isoformat(),
    } for admin in admins]

@router.delete("/admins/{admin_id}")
def delete_admin(admin_id: int, db: Session = Depends(get_db), current_user: str = Depends(get_current_user)):
    """Elimina un administrador. Previene eliminar al admin principal si es el único."""
    # Verificar que haya más de un admin antes de borrar
    admin_count = db.query(User).filter(User.role == "admin").count()
    if admin_count <= 1:
        raise HTTPException(status_code=400, detail="No se puede eliminar al único administrador del sistema.")
        
    admin_to_delete = db.query(User).filter(User.id == admin_id, User.role == "admin").first()
    if not admin_to_delete:
        raise HTTPException(status_code=404, detail="Administrador no encontrado.")
        
    # Opcional: Evitar que se borre a sí mismo (opcional pero buena práctica)
    if admin_to_delete.username == current_user:
        raise HTTPException(status_code=400, detail="No puedes eliminar tu propia cuenta de administrador.")
        
    db.delete(admin_to_delete)
    db.commit()
    return {"detail": "Administrador eliminado correctamente"}

@router.get("/stats")
def get_global_stats(db: Session = Depends(get_db)):
    """Estadísticas globales del sistema para el dashboard del admin"""
    total_patients = db.query(User).filter(User.role == "user").count()
    total_analyses = db.query(Analysis).count()
    completed_analyses = db.query(Analysis).filter(Analysis.status == "completed").count()
    
    high_risk = db.query(Analysis).filter(
        Analysis.status == "completed",
        Analysis.risk_score >= 65
    ).count()
    medium_risk = db.query(Analysis).filter(
        Analysis.status == "completed",
        Analysis.risk_score >= 40,
        Analysis.risk_score < 65
    ).count()
    low_risk = db.query(Analysis).filter(
        Analysis.status == "completed",
        Analysis.risk_score < 40
    ).count()
    
    return {
        "total_patients": total_patients,
        "total_analyses": total_analyses,
        "completed_analyses": completed_analyses,
        "risk_distribution": {
            "high": high_risk,
            "medium": medium_risk,
            "low": low_risk,
        }
    }
