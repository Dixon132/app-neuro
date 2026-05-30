import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), "app", "..", "eeg_analysis.db")
db_path = os.path.abspath(db_path)

print(f"Borrando datos de {db_path}...")
try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Limpiar tablas
    cursor.execute("DELETE FROM reports;")
    cursor.execute("DELETE FROM analyses;")
    cursor.execute("DELETE FROM users;")
    
    conn.commit()
    conn.close()
    print("Datos borrados. El usuario admin se recreará al reiniciar o al llamar a ensure_admin_exists().")
except Exception as e:
    print(f"Error: {e}")
