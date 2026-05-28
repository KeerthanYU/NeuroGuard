# Seizure Detection ML Pipeline

This repository contains a complete pipeline for generating synthetic accelerometer seizure data, training a lightweight 1D-CNN model, converting it to a quantized TensorFlow Lite model, and exporting a C header file for ESP32 firmware integration.

## What was implemented

- Synthetic dataset generation for seizure vs. normal activity
- 1D-CNN model training with 200 timesteps × 6 features input shape
- Saved Keras model in `models/seizure_model.keras`
- Converted float32 and INT8 quantized TFLite models
- Generated ESP32-ready `output/model.h` C array header
- Created firmware input specification documentation in `output/INPUT_SPECIFICATIONS.md`

## Repository structure

```markdown
Seizure_ML_Project/
├── data/
│   └── processed/seizure_dataset.csv
├── models/
│   ├── seizure_model.keras
│   ├── seizure_model_float32.tflite
│   └── seizure_quantized.tflite
├── output/
│   ├── INPUT_SPECIFICATIONS.md
│   ├── model.h
│   ├── test_results.txt
│   └── training_history.png
├── scripts/
│   ├── convert_model.py
│   ├── data_generator.py
│   ├── generate_header.py
│   └── train_model.py
└── README.md
```

## Requirements

- Python 3.11+ (the workspace uses Python 3.13)
- TensorFlow
- NumPy
- pandas
- scikit-learn
- matplotlib
- pyserial (for real MPU6050 serial logging)

## Setup

Create and activate the project virtual environment, then install dependencies:

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

If you already have `.venv`, just activate it before running scripts:

```powershell
.\.venv\Scripts\Activate.ps1
```

### VS Code users

If you run scripts from VS Code, make sure the workspace Python interpreter is set to the project virtual environment:

1. Open the Command Palette
2. Run `Python: Select Interpreter`
3. Choose `./.venv/Scripts/python.exe`

This repository also includes `.vscode/settings.json` and `.vscode/launch.json` so VS Code can use the correct interpreter automatically.

Install the real-data logger dependency if needed (this is also included in `requirements.txt`):

```powershell
python -m pip install pyserial
```

## How to run

### 1. Generate synthetic dataset

```bash
python scripts/data_generator.py
```

This creates `data/processed/seizure_dataset.csv` with 1000 samples (500 seizure, 500 normal).

### 2. Train the model

```bash
python scripts/train_model.py
```

This trains a tiny 1D-CNN, saves the trained model to `models/seizure_model.keras`, and writes a test result file at `output/test_results.txt`.

### 3. Convert the model to TFLite

```bash
python scripts/convert_model.py
```

This produces:

- `models/seizure_model_float32.tflite`
- `models/seizure_quantized.tflite`

It also prints the model sizes and verifies the quantized model is under 20 KB.

### 4. Generate the ESP32 header file

```bash
python scripts/generate_header.py
```

This creates `output/model.h` containing the quantized TFLite model as a C array named `model` and a length variable `model_len`.

## Collect real MPU6050 data

To capture real ESP32 + MPU6050 recordings, use `scripts/serial_logger.py`.
The ESP32 firmware should print six comma-separated values per line:

```text
accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z
```

Run the logger with a label for the session:

```bash
python scripts/serial_logger.py --port COM5 --baud 115200 --label 0 --output data/processed/real_mpu6050_dataset.csv --max-lines 10000
```

Use `--label 0` for normal activities and `--label 1` for seizure-like activity.
If you want to keep adding sessions to the same file, include `--append`.

After collecting real data, train with the new CSV path:

```bash
python scripts/train_model.py --data-path data/processed/real_mpu6050_dataset.csv
```

The existing `scripts/data_generator.py` remains available for synthetic dataset testing and pipeline validation.

## Output files

- `output/model.h` — ESP32-compatible header containing the quantized model
- `output/INPUT_SPECIFICATIONS.md` — firmware input preprocessing and inference details
- `output/test_results.txt` — validation test accuracy and loss
- `output/training_history.png` — training accuracy plot

## Model input specs

- Input shape: `[1, 200, 6]`
- Timesteps: `200` (2 seconds at 100Hz)
- Features: `6` (MPU6050 accelerometer XYZ + gyroscope XYZ)
- Quantization: `int8` input/output

## Dataset CSV column order

The generated CSV rows follow this feature order after reshaping:

1. `accel_x`
2. `accel_y`
3. `accel_z`
4. `gyro_x`
5. `gyro_y`
6. `gyro_z`

## Notes for firmware team

- Read accelerometer XYZ and gyroscope XYZ values from MPU6050
- Normalize accelerometer data to the ±16g range
- Normalize gyroscope data to the ±250°/s range
- Quantize each of the 6 channels to int8 and store them in a [200, 6] buffer

## Validation

The synthetic dataset and current model achieved `100.00%` test accuracy on the held-out synthetic test set.

## Recommended next steps

- Evaluate the model on real MPU6050 accelerometer+gyroscope data
- If needed, retrain using more real MPU6050 recordings and a larger dataset
- Validate ESP32 inference with the generated `model.h` file and preprocessing pipeline

## Recent fixes (May 2026)

- Added guidance to activate the project virtual environment and select the correct interpreter, ensuring that scripts run with the project's dependencies (including `numpy`).
- Updated `train_model.py` and `convert_model.py` with `# pyrefly: ignore [missing-import]` comments to silence static analysis warnings (runtime error resolved by using the correct interpreter).
- Included step‑by‑step instructions for Windows users to avoid the system Python path and use `.venv\Scripts\python.exe`.
- Documented how to verify the environment with `python -c "import numpy; print(numpy.__version__)"`.
