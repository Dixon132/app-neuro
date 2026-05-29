@echo off
echo ========================================
echo   Instalacion Backend - EEG Analysis
echo ========================================
echo.

echo [1/5] Actualizando pip...
python -m pip install --upgrade pip
echo.

echo [2/5] Instalando dependencias basicas...
pip install fastapi uvicorn python-multipart sqlalchemy pydantic pydantic-settings python-dotenv aiofiles email-validator
echo.

echo [3/5] Instalando autenticacion...
pip install python-jose[cryptography] passlib[bcrypt] bcrypt
echo.

echo [4/5] Instalando librerias cientificas (puede tardar)...
pip install numpy scipy pandas scikit-learn matplotlib seaborn
echo.

echo [5/5] Instalando ML y EEG...
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install transformers huggingface-hub mne PyWavelets reportlab
echo.

echo ========================================
echo   Instalacion completada!
echo ========================================
echo.
echo Para ejecutar el servidor:
echo   python -m app.main
echo.
pause
