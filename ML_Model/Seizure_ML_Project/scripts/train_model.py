import argparse
import os
os.environ.setdefault('TF_CPP_MIN_LOG_LEVEL', '3')
os.environ.setdefault('ABSL_CPP_MIN_LOG_LEVEL', '3')
os.environ.setdefault('TF_ENABLE_ONEDNN_OPTS', '0')

import warnings
import logging
# pyrefly: ignore [missing-import]
import numpy as np
from sklearn.preprocessing import StandardScaler
# pyrefly: ignore [missing-import]
import joblib
import pandas as pd

try:
    # pyrefly: ignore [missing-import]
    import absl.logging
except ImportError:
    absl = None

warnings.filterwarnings('ignore', category=UserWarning, module='tensorflow')
warnings.filterwarnings('ignore', category=FutureWarning)
warnings.filterwarnings('ignore', message='TensorFlow GPU support is not available.*')

if absl is not None:
    absl.logging.set_verbosity(absl.logging.ERROR)
    logging.getLogger('absl').setLevel(logging.ERROR)

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.model_selection import train_test_split

tf_logger = tf.get_logger()
tf_logger.setLevel('ERROR')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

TIMESTEPS = 200
FEATURES = 8
NUM_CLASSES = 2
EPOCHS = 30
BATCH_SIZE = 32
MODEL_DIR = os.path.join(PROJECT_ROOT, 'models')
DATA_PATH = os.path.join(PROJECT_ROOT, 'data', 'processed', 'seizure_dataset.csv')
OUTPUT_DIR = os.path.join(PROJECT_ROOT, 'output')


def resolve_path(path):
    if not path:
        return path
    if os.path.isabs(path):
        return path
    return os.path.abspath(os.path.join(PROJECT_ROOT, path))


def parse_args():
    parser = argparse.ArgumentParser(description='Train the seizure detection model from CSV data.')
    parser.add_argument('--data-path', default=DATA_PATH, help='CSV dataset path to use for training')
    return parser.parse_args()


def load_data(data_path):
    resolved_path = resolve_path(data_path)
    if not os.path.exists(resolved_path):
        raise FileNotFoundError(f"❌ Dataset file not found at: {resolved_path}")

    print(f"Loading dataset from: {resolved_path}")
    try:
        df = pd.read_csv(resolved_path)
    except Exception as exc:
        raise ValueError(f"❌ Failed to parse CSV file: {exc}")

    if df.empty:
        raise ValueError(f"❌ Dataset file at {resolved_path} is empty")

    num_cols = df.shape[1]

    if num_cols == FEATURES + 1:  # Real/timestep-per-row format (8 features + 1 label)
        print("   Detected real MPU6050 CSV format with heart rate.")
        expected_cols = ['accel_x', 'accel_y', 'accel_z', 'gyro_x', 'gyro_y', 'gyro_z', 'heart_rate', 'label']

        if all(col in df.columns for col in expected_cols):
            features_df = df[expected_cols[:-1]]  # all except label
            labels = df['label'].values
        else:
            print("   ⚠️ Column names mismatch, using positional mapping.")
            features_df = df.iloc[:, :FEATURES]
            labels = df.iloc[:, FEATURES].values

        # Compute energy feature and append
        accel = features_df[['accel_x','accel_y','accel_z']].values
        energy = np.sum(np.square(accel), axis=1, keepdims=True)
        X_raw = np.hstack([features_df.values, energy])
        
        # Segment into sequential windows of size TIMESTEPS
        num_windows = len(df) // TIMESTEPS
        if num_windows == 0:
            raise ValueError(f"❌ Dataset only has {len(df)} rows, but the window size requires at least {TIMESTEPS} timesteps.")

        X_list = []
        y_list = []
        for i in range(num_windows):
            start = i * TIMESTEPS
            end = start + TIMESTEPS
            window_X = X_raw[start:end]
            window_y = labels[start:end]

            # Use majority vote to find the most frequent label in this window
            int_labels = window_y.astype(np.int32)
            counts = np.bincount(int_labels)
            majority_label = counts.argmax()

            X_list.append(window_X)
            y_list.append(majority_label)

        X = np.array(X_list, dtype=np.float32)
        y = np.array(y_list, dtype=np.int32)
        print(f"   Successfully windowed {len(df)} rows into {num_windows} samples of shape ({TIMESTEPS}, {FEATURES})")

    elif num_cols == TIMESTEPS * 6 + 1:  # Synthetic format with 6 features (no heart rate)
        print("   Detected synthetic (sample-per-row) CSV format with 6 features.")
        if 'label' in df.columns:
            y = df['label'].values
            X_raw = df.drop('label', axis=1).values
        else:
            y = df.iloc[:, -1].values
            X_raw = df.iloc[:, :-1].values
        # Reshape to (samples, TIMESTEPS, 6)
        X = X_raw.reshape(-1, TIMESTEPS, 6).astype(np.float32)
        # Compute energy feature from accel columns (0,1,2)
        accel = X[..., :3]
        energy = np.sum(np.square(accel), axis=2, keepdims=True)
        # Create placeholder heart_rate column (zeros)
        hr_placeholder = np.zeros_like(energy)
        # Concatenate to get (samples, TIMESTEPS, 8)
        X = np.concatenate([X, hr_placeholder, energy], axis=2)
    elif num_cols == TIMESTEPS * 8 + 1:  # Synthetic format with 8 features (includes heart rate, no energy)
        print("   Detected synthetic (sample-per-row) CSV format with 8 features.")
        if 'label' in df.columns:
            y = df['label'].values
            X_raw = df.drop('label', axis=1).values
        else:
            y = df.iloc[:, -1].values
            X_raw = df.iloc[:, :-1].values
        # Reshape to (samples, TIMESTEPS, 8)
        X = X_raw.reshape(-1, TIMESTEPS, 8).astype(np.float32)
        # Compute energy from first three channels and replace last channel with energy
        accel = X[..., :3]
        energy = np.sum(np.square(accel), axis=2, keepdims=True)
        X[..., -1] = energy.squeeze()
    else:
        raise ValueError(
            f"❌ Unsupported dataset format. CSV has {num_cols} columns, but expected "
            f"{FEATURES + 1} (real timestep-per-row format) or "
            f"{TIMESTEPS * FEATURES + 1} (synthetic pre-flattened format)."
        )

    # Validate labels
    unique_labels = np.unique(y)
    for lbl in unique_labels:
        if lbl not in [0, 1]:
            raise ValueError(f"❌ Invalid label '{lbl}' detected. Labels must be strictly binary (0 or 1).")

    return X, y


def create_seizure_detection_model():
    model = keras.Sequential([
        layers.Reshape((TIMESTEPS, FEATURES, 1), input_shape=(TIMESTEPS * FEATURES,)),
        layers.Conv2D(8, (3,3), activation='relu'),
        layers.MaxPooling2D((2,2)),
        layers.Conv2D(16, (3,3), activation='relu'),
        layers.Flatten(),
        layers.Dense(16, activation='relu'),
        layers.Dense(1, activation='sigmoid')
    ])
    return model


def train_model(data_path):
    os.makedirs(MODEL_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print('=' * 50)
    print('Seizure Detection Model Training')
    print('=' * 50)

    # Load raw data (samples, 200, 6) and labels
    X, y = load_data(data_path)
    # Flatten the 3‑D input (samples, 200, 6) into a 2‑D matrix (samples, 1200)
    X = X.reshape(X.shape[0], -1)
    print(f'   Flattened X shape: {X.shape}')
    print(f'   y shape: {y.shape}')

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    # Scale features using StandardScaler (fit on training data only)
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_test = scaler.transform(X_test)
    # Save scaler for deployment
    scaler_path = os.path.join(MODEL_DIR, 'scaler.save')
    joblib.dump(scaler, scaler_path)
    print(f'   Scaling parameters saved to {scaler_path}')
    print(f'   Training: {len(X_train)} samples')
    print(f'   Testing: {len(X_test)} samples')

    model = create_seizure_detection_model()
    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy', tf.keras.metrics.Precision(name='precision'), tf.keras.metrics.Recall(name='recall')]
    )

    # Compute class weights to handle imbalance
    from sklearn.utils import class_weight
    class_weights = class_weight.compute_class_weight('balanced', classes=np.unique(y_train), y=y_train)
    class_weight_dict = {i: class_weights[i] for i in range(len(class_weights))}
    history = model.fit(
        X_train, y_train,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_split=0.2,
        class_weight=class_weight_dict,
        verbose=1
    )

    test_loss, test_acc, test_prec, test_rec = model.evaluate(X_test, y_test, verbose=0)
    print(f'   Test Accuracy: {test_acc:.4f} ({test_acc * 100:.2f}%)')
    print(f'   Test Precision: {test_prec:.4f}')
    print(f'   Test Recall: {test_rec:.4f}')

    model_path = os.path.join(MODEL_DIR, 'seizure_model.keras')
    model.save(model_path)
    print(f'\n[SUCCESS] Model saved to {model_path}')

    history_path = os.path.join(OUTPUT_DIR, 'training_history.png')
    try:
        # pyrefly: ignore [missing-import]
        import matplotlib.pyplot as plt
        plt.figure(figsize=(8, 5))
        plt.plot(history.history['accuracy'], label='Train')
        plt.plot(history.history['val_accuracy'], label='Validation')
        plt.title('Training Accuracy')
        plt.xlabel('Epoch')
        plt.ylabel('Accuracy')
        plt.legend()
        plt.tight_layout()
        plt.savefig(history_path)
        print(f'[SUCCESS] Training plot saved to {history_path}')
    except Exception as exc:
        print(f'⚠️ Could not save training plot: {exc}')

    with open(os.path.join(OUTPUT_DIR, 'test_results.txt'), 'w') as f:
        f.write(f'Test Accuracy: {test_acc:.4f}\n')
        f.write(f'Test Loss: {test_loss:.4f}\n')

    return model, history, test_acc


if __name__ == '__main__':
    args = parse_args()
    train_model(args.data_path)
