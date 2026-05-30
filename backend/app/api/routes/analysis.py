from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional
import os
import shutil
from app.database.connection import get_db
from app.models.user import Analysis, Report, User
from app.models.schemas import AnalysisResponse
from app.services.eeg_processor import EEGProcessor
from app.services.ml_predictor import MLPredictor
from app.services.report_generator import ReportGenerator
from app.services.auth_service import get_current_user
from app.config import settings
import json

router = APIRouter(prefix="/analysis", tags=["Analysis"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def _get_user_id(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> int:
    """Obtiene el user_id real del token JWT."""
    username = get_current_user(token)
    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
    return user.id


@router.post("/upload", response_model=AnalysisResponse)
async def upload_eeg(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user_id: int = Depends(_get_user_id),
):
    """Subir y analizar archivo EEG — usuario autenticado por JWT"""

    # Validar formato
    if not file.filename.endswith((".edf", ".csv")):
        raise HTTPException(
            status_code=400, detail="Formato no soportado. Use EDF o CSV"
        )

    # Crear directorio si no existe
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

    # Guardar archivo
    file_path = os.path.join(
        settings.UPLOAD_DIR, f"{datetime.now().timestamp()}_{file.filename}"
    )
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Crear registro en BD
    analysis = Analysis(
        user_id=user_id,
        file_path=file_path,
        file_name=file.filename,
        status="processing",
    )
    db.add(analysis)
    db.commit()
    db.refresh(analysis)

    try:
        # Procesar EEG (pipeline completo: notch + bandpass + artefactos + ventanas + features)
        processor = EEGProcessor()
        processed = processor.process_eeg(file_path)

        # Predicción ML con modelo real entrenado
        predictor = MLPredictor()
        prediction = predictor.predict(processed)
        metrics = predictor.calculate_metrics(processed["processed_data"])

        # Guardar métricas extendidas (incluye análisis por canal)
        extended_metrics = {
            **metrics,
            "n_windows": processed.get("n_windows", 1),
            "sampling_rate": processed.get("sampling_rate", 256),
            "channel_names": processed.get("channel_names", []),
            "most_anomalous_channel": prediction.get("most_anomalous_channel", "N/A"),
        }

        # Generar reporte PDF mejorado
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        report_path = os.path.join(settings.UPLOAD_DIR, f"report_{analysis.id}.pdf")
        report_gen = ReportGenerator()
        report_gen.generate_pdf(
            {
                "file_name": file.filename,
                "user": "Usuario",
                "prediction": prediction,
                "metrics": metrics,
            },
            report_path,
        )

        # Guardar reporte en BD
        report = Report(
            analysis_id=analysis.id,
            pdf_path=report_path,
            metrics=json.dumps(extended_metrics),
        )
        db.add(report)

        # Actualizar análisis — todo en un solo commit
        analysis.status = "completed"
        analysis.risk_score = prediction["risk_score"]
        analysis.prediction = prediction["prediction"]
        analysis.confidence = prediction.get("confidence")
        analysis.most_anomalous_channel = prediction.get("most_anomalous_channel")
        analysis.n_windows_analyzed = prediction.get("n_windows_analyzed")
        analysis.sampling_rate = prediction.get("sampling_rate")
        analysis.completed_at = datetime.utcnow()

        db.commit()
        db.refresh(analysis)

        return analysis

    except Exception as e:
        analysis.status = "failed"
        db.commit()
        raise HTTPException(
            status_code=500, detail=f"Error procesando archivo: {str(e)}"
        )


@router.get("/list", response_model=list[AnalysisResponse])
def list_analyses(
    db: Session = Depends(get_db),
    user_id: int = Depends(_get_user_id),
):
    """Listar análisis del usuario autenticado (solo los suyos)"""
    analyses = db.query(Analysis).filter(Analysis.user_id == user_id).order_by(Analysis.created_at.desc()).all()
    return analyses




@router.get("/{analysis_id}", response_model=AnalysisResponse)
def get_analysis(analysis_id: int, db: Session = Depends(get_db)):
    """Obtener detalle de análisis"""
    analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
    if not analysis:
        raise HTTPException(status_code=404, detail="Análisis no encontrado")
    return analysis


@router.get("/{analysis_id}/report")
def download_report(analysis_id: int, db: Session = Depends(get_db)):
    """Descargar reporte PDF del análisis"""
    analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
    if not analysis:
        raise HTTPException(status_code=404, detail="Análisis no encontrado")

    if analysis.status != "completed":
        raise HTTPException(
            status_code=400,
            detail=f"El análisis no está listo (estado actual: {analysis.status})",
        )

    report = analysis.report
    if report is None or not report.pdf_path:
        raise HTTPException(status_code=404, detail="Reporte no encontrado en la base de datos")

    pdf_path = report.pdf_path

    # Si el PDF no existe en disco, regenerarlo con los datos guardados
    if not os.path.exists(pdf_path):
        try:
            os.makedirs(os.path.dirname(pdf_path), exist_ok=True)
            metrics = json.loads(report.metrics) if report.metrics else {}
            prediction_data = {
                "prediction": analysis.prediction or "N/A",
                "risk_score": analysis.risk_score or 0.0,
                "confidence": 0.0,
            }
            report_gen = ReportGenerator()
            report_gen.generate_pdf(
                {
                    "file_name": analysis.file_name,
                    "user": "Usuario",
                    "prediction": prediction_data,
                    "metrics": metrics,
                },
                pdf_path,
            )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"No se pudo regenerar el reporte PDF: {str(e)}",
            )

    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=f"reporte_eeg_{analysis_id}.pdf",
    )


@router.get("/{analysis_id}/signal")
def get_signal_data(
    analysis_id: int,
    channel: Optional[int] = 0,
    start_sec: Optional[float] = 0,
    duration_sec: Optional[float] = 10,
    db: Session = Depends(get_db),
):
    """
    Obtiene datos de la señal EEG para visualización de ondas cerebrales.
    
    Parámetros:
    - channel: índice del canal (0-based)
    - start_sec: segundo de inicio
    - duration_sec: duración en segundos a retornar (máximo 30s)
    """
    analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
    if not analysis:
        raise HTTPException(status_code=404, detail="Análisis no encontrado")

    if not os.path.exists(analysis.file_path):
        raise HTTPException(status_code=404, detail="Archivo EEG no encontrado")

    try:
        # Limitar duración máxima
        duration_sec = min(duration_sec, 30)
        
        # Cargar y procesar el archivo
        processor = EEGProcessor()
        raw_data = processor.load_eeg_file(analysis.file_path)
        
        # Aplicar filtros básicos para visualización limpia
        filtered = processor.apply_notch_filter(raw_data)
        filtered = processor.apply_bandpass_filter(filtered)
        
        sampling_rate = processor.sampling_rate
        channel_names = processor.channel_names or [f"CH{i+1}" for i in range(raw_data.shape[1])]
        
        # Validar canal
        if channel >= raw_data.shape[1]:
            channel = 0
        
        # Extraer segmento
        start_sample = int(start_sec * sampling_rate)
        end_sample = int((start_sec + duration_sec) * sampling_rate)
        
        if start_sample >= len(filtered):
            start_sample = 0
            end_sample = min(int(duration_sec * sampling_rate), len(filtered))
        
        end_sample = min(end_sample, len(filtered))
        
        signal_segment = filtered[start_sample:end_sample, channel].tolist()
        time_axis = [start_sec + i / sampling_rate for i in range(len(signal_segment))]
        
        # Calcular estadísticas del segmento
        import numpy as np
        signal_array = np.array(signal_segment)
        
        return {
            "analysis_id": analysis_id,
            "channel_index": channel,
            "channel_name": channel_names[channel] if channel < len(channel_names) else f"CH{channel+1}",
            "sampling_rate": sampling_rate,
            "start_time": start_sec,
            "duration": duration_sec,
            "n_samples": len(signal_segment),
            "time": time_axis,
            "amplitude": signal_segment,
            "unit": "µV",
            "statistics": {
                "mean": float(np.mean(signal_array)),
                "std": float(np.std(signal_array)),
                "min": float(np.min(signal_array)),
                "max": float(np.max(signal_array)),
            },
            "available_channels": [
                {"index": i, "name": name} for i, name in enumerate(channel_names)
            ],
            "total_duration": len(filtered) / sampling_rate,
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo señal: {str(e)}")
