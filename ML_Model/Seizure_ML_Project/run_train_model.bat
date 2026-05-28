@echo off
cd /d %~dp0
call .venv\Scripts\Activate.bat
python scripts\train_model.py --data-path data/processed/seizure_dataset.csv
pause
