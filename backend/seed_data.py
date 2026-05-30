import sys
import os
from sqlalchemy.orm import Session

# Add backend directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database.connection import init_db, get_db
from app.models.schemas import UserCreate
from app.services.auth_service import create_user
from app.models.user import User, Analysis
from app.main import app

def seed_database():
    print("Inicializando base de datos...")
    
    # 1. Borrar archivo DB si existe para empezar limpio
    db_path = os.path.join(os.path.dirname(__file__), "eeg_analysis.db")
    if os.path.exists(db_path):
        try:
            os.remove(db_path)
            print("Base de datos anterior eliminada.")
        except Exception as e:
            print(f"No se pudo eliminar la DB (puede que el servidor este corriendo): {e}")

    # 2. Crear tablas
    init_db()
    print("Tablas creadas.")

    db = next(get_db())
    
    try:
        # 3. Crear Admin
        admin_data = UserCreate(
            email="admin@eeganalysis.com",
            username="admin",
            password="Admin1234!",
            full_name="Administrador del Sistema"
        )
        create_user(db, admin_data, role="admin")
        print("Admin creado: (User: admin / Pass: Admin1234!)")

        # 4. Crear un Paciente de Prueba
        paciente_data = UserCreate(
            email="paciente@prueba.com",
            username="paciente",
            password="Paciente1234!",
            full_name="Paciente de Prueba"
        )
        paciente = create_user(db, paciente_data, role="user")
        print("Paciente creado: (User: paciente / Pass: Paciente1234!)")

        # 5. Insertar algunos análisis falsos para que el admin vea datos
        print("Insertando datos de prueba...")
        a1 = Analysis(
            user_id=paciente.id,
            file_name="EEG_normal_descanso.edf",
            status="completed",
            prediction="Bajo Riesgo",
            risk_score=15.5,
            confidence=0.92,
            most_anomalous_channel="O1",
            n_windows_analyzed=10,
            sampling_rate=256
        )
        a2 = Analysis(
            user_id=paciente.id,
            file_name="EEG_crisis_focal.edf",
            status="completed",
            prediction="Alto Riesgo",
            risk_score=85.2,
            confidence=0.89,
            most_anomalous_channel="F3",
            n_windows_analyzed=8,
            sampling_rate=256
        )
        db.add(a1)
        db.add(a2)
        db.commit()
        print("Analisis de prueba insertados.")
        print("\nBase de datos lista!")

    except Exception as e:
        print(f"❌ Error poblando base de datos: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
