import os
# pyrefly: ignore [missing-import]
import numpy as np
import pandas as pd


def generate_seizure_sample(duration_seconds=2, sample_rate=100):
    """
    Generate a synthetic MPU6050 seizure sample with accelerometer XYZ and gyroscope XYZ.
    """
    t = np.linspace(0, duration_seconds, int(duration_seconds * sample_rate), endpoint=False)
    base_freq = np.random.uniform(4, 7)
    envelope = np.exp(-((t - duration_seconds / 2) ** 2) / (2 * (0.35 ** 2)))
    envelope = envelope / np.max(envelope)

    acc_signals = []
    gyro_signals = []
    for axis in range(3):
        phase = np.random.uniform(0, 2 * np.pi)
        sine = np.sin(2 * np.pi * base_freq * t + phase)
        noise = np.random.normal(0, 0.15, len(t))
        acc = sine * envelope * np.random.uniform(3.5, 4.5) + noise * 0.3
        acc_signals.append(np.clip(acc, -16, 16))

        gyro = np.sin(2 * np.pi * base_freq * t + phase + np.pi / 4) * envelope * np.random.uniform(80, 120)
        gyro += np.random.normal(0, 5.0, len(t))
        gyro_signals.append(np.clip(gyro, -250, 250))

    return np.stack(acc_signals + gyro_signals, axis=-1)


def generate_normal_sample(duration_seconds=2, sample_rate=100, activity_type='rest'):
    """
    Generate a synthetic MPU6050 normal sample with accelerometer XYZ and gyroscope XYZ.
    """
    t = np.linspace(0, duration_seconds, int(duration_seconds * sample_rate), endpoint=False)
    acc_signals = []
    gyro_signals = []

    for axis in range(3):
        phase = np.random.uniform(0, 2 * np.pi)
        if activity_type == 'rest':
            acc = np.random.normal(0, 0.05, len(t))
            gyro = np.random.normal(0, 0.5, len(t))
        elif activity_type == 'walk':
            freq = np.random.uniform(1, 2)
            acc = np.sin(2 * np.pi * freq * t + phase) * 0.8 + np.random.normal(0, 0.2, len(t))
            gyro = np.sin(2 * np.pi * freq * t + phase + np.pi / 6) * 20 + np.random.normal(0, 3.0, len(t))
        else:
            freq = np.random.uniform(2, 3.5)
            acc = np.sin(2 * np.pi * freq * t + phase) * 1.4 + np.random.normal(0, 0.3, len(t))
            gyro = np.sin(2 * np.pi * freq * t + phase + np.pi / 6) * 45 + np.random.normal(0, 5.0, len(t))

        acc_signals.append(np.clip(acc, -16, 16))
        gyro_signals.append(np.clip(gyro, -250, 250))

    return np.stack(acc_signals + gyro_signals, axis=-1)


def create_dataset(samples_per_class=500, window_size=200, output_path='data/processed/seizure_dataset.csv'):
    seizure_data = []
    normal_data = []
    duration_seconds = window_size / 100.0

    print('Generating seizure samples...')
    for i in range(samples_per_class):
        sample = generate_seizure_sample(duration_seconds=duration_seconds, sample_rate=100)
        seizure_data.append(sample)
        if (i + 1) % 100 == 0:
            print(f'  Generated {i+1}/{samples_per_class} seizure samples')

    print('Generating normal samples...')
    activity_types = ['rest', 'walk', 'run']
    for i in range(samples_per_class):
        activity = np.random.choice(activity_types)
        sample = generate_normal_sample(duration_seconds=duration_seconds, sample_rate=100, activity_type=activity)
        normal_data.append(sample)
        if (i + 1) % 100 == 0:
            print(f'  Generated {i+1}/{samples_per_class} normal samples')

    X_seizure = np.array(seizure_data)
    X_normal = np.array(normal_data)
    y_seizure = np.ones(samples_per_class, dtype=np.int32)
    y_normal = np.zeros(samples_per_class, dtype=np.int32)

    X = np.vstack([X_seizure, X_normal])
    y = np.hstack([y_seizure, y_normal])
    indices = np.random.permutation(len(X))
    X = X[indices]
    y = y[indices]

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    df = pd.DataFrame(X.reshape(X.shape[0], -1))
    df['label'] = y
    df.to_csv(output_path, index=False)

    print('\nDataset created:')
    print(f'  X shape: {X.shape}')
    print(f'  y shape: {y.shape}')
    print(f'  Seizure samples: {np.sum(y == 1)}')
    print(f'  Normal samples: {np.sum(y == 0)}')
    print(f'\n[SUCCESS] Dataset saved to {output_path}')
    return X, y


if __name__ == '__main__':
    create_dataset(samples_per_class=500, window_size=200)
