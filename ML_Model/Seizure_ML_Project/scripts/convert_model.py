import os
import sys

# Ensure the scripts directory is in sys.path so train_model can be imported
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '3')
os.environ.setdefault('ABSL_CPP_MIN_LOG_LEVEL', '3')
os.environ.setdefault('TF_ENABLE_ONEDNN_OPTS', '0')

import warnings
import logging
# pyrefly: ignore [missing-import]
import numpy as np
import pandas as pd
import contextlib
import io

try:
    # pyrefly: ignore [missing-import]
    import absl.logging
except ImportError:
    absl = None

warnings.filterwarnings('ignore', category=UserWarning, module='tensorflow')
warnings.filterwarnings('ignore', category=FutureWarning)
warnings.filterwarnings('ignore', message='Statistics for quantized inputs were expected, but not specified; continuing anyway.')
warnings.filterwarnings('ignore', message='TensorFlow GPU support is not available.*')

if absl is not None:
    absl.logging.set_verbosity(absl.logging.ERROR)
    logging.getLogger('absl').setLevel(logging.ERROR)

import tensorflow as tf
from train_model import load_data

tf_logger = tf.get_logger()
tf_logger.setLevel('ERROR')

PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
MODEL_DIR = os.path.join(PROJECT_ROOT, 'models')
DATA_PATH = os.path.join(PROJECT_ROOT, 'data', 'processed', 'seizure_dataset.csv')


def make_representative_dataset(data_path):
    def representative_dataset():
        try:
            X, _ = load_data(data_path)
        except Exception as exc:
            print(f"\n[ERROR] Error loading representative dataset from {data_path}: {exc}")
            print("Please ensure you have generated or loaded a valid dataset first.")
            sys.exit(1)

        if len(X) > 100:
            indices = np.random.RandomState(42).choice(len(X), 100, replace=False)
            X = X[indices]
        for i in range(len(X)):
            yield [X[i:i+1]]
    return representative_dataset


def convert_to_tflite(data_path=DATA_PATH):
    os.makedirs(MODEL_DIR, exist_ok=True)

    print('=' * 50)
    print('TFLite Model Conversion')
    print('=' * 50)

    keras_model_path = os.path.join(MODEL_DIR, 'seizure_model.keras')
    if not os.path.exists(keras_model_path):
        print(f"[ERROR] Keras model not found at {keras_model_path}.")
        print("Please train the model first by running scripts/train_model.py.")
        sys.exit(1)

    print('1. Loading Keras model...')
    model = tf.keras.models.load_model(keras_model_path, compile=False)

    print('2. Converting to Float32 TFLite...')
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    with contextlib.redirect_stdout(io.StringIO()):
        tflite_float_model = converter.convert()
    float_size = len(tflite_float_model) / 1024.0
    float_path = os.path.join(MODEL_DIR, 'seizure_model_float32.tflite')
    with open(float_path, 'wb') as f:
        f.write(tflite_float_model)
    print(f'   Float32 model size: {float_size:.2f} KB')

    print('3. Converting to INT8 Quantized TFLite...')
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = make_representative_dataset(data_path)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8
    with contextlib.redirect_stdout(io.StringIO()):
        tflite_quantized_model = converter.convert()
    quantized_size = len(tflite_quantized_model) / 1024.0
    quant_path = os.path.join(MODEL_DIR, 'seizure_quantized.tflite')
    with open(quant_path, 'wb') as f:
        f.write(tflite_quantized_model)
    print(f'   Quantized model size: {quantized_size:.2f} KB')

    if quantized_size <= 20:
        print('   [SUCCESS] Model size is under 20KB - Good for ESP32!')
    else:
        print(f'   [WARN] Model size is {quantized_size:.2f} KB > 20KB')
        print('   Consider reducing model complexity or using a smaller architecture.')

    return quant_path, quantized_size


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(description='Convert trained Keras model to quantized TFLite.')
    parser.add_argument('--data-path', default=DATA_PATH, help='CSV dataset path to use for calibration')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    convert_to_tflite(args.data_path)

