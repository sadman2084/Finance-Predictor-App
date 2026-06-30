@echo off
echo Starting Finance Predictor Backend Server...
cd /d "%~dp0..\backend"
call backend_env\Scripts\activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pause