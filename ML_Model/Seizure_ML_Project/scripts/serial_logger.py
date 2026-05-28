import argparse
import csv
import os
import sys
import time

try:
    import serial
except ImportError:
    print('Missing dependency: pyserial')
    print('Install it with: python -m pip install pyserial')
    sys.exit(1)

HEADER = ['accel_x', 'accel_y', 'accel_z', 'gyro_x', 'gyro_y', 'gyro_z', 'label']


def parse_line(line):
    parts = [part.strip() for part in line.split(',') if part.strip() != '']
    if len(parts) < 6:
        return None
    try:
        return [float(parts[i]) for i in range(6)]
    except ValueError:
        return None


def open_csv(path, append):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    mode = 'a' if append and os.path.exists(path) else 'w'
    csv_file = open(path, mode, newline='')
    writer = csv.writer(csv_file)
    if mode == 'w':
        writer.writerow(HEADER)
    return csv_file, writer


def build_parser():
    parser = argparse.ArgumentParser(
        description='Read MPU6050 serial output from ESP32 and save as a labeled CSV dataset.'
    )
    parser.add_argument('--port', required=True, help='Serial port for ESP32 (e.g. COM5)')
    parser.add_argument('--baud', default=115200, type=int, help='Serial baud rate')
    parser.add_argument('--output', default='data/processed/real_mpu6050_dataset.csv', help='Output CSV file path')
    parser.add_argument('--label', required=True, type=int, choices=[0, 1], help='Label for this recording: 0 = normal, 1 = seizure-like')
    parser.add_argument('--append', action='store_true', help='Append to an existing CSV instead of overwriting it')
    parser.add_argument('--duration', type=float, default=0, help='Recording duration in seconds (0 = unlimited)')
    parser.add_argument('--max-lines', type=int, default=0, help='Stop after this many valid lines (0 = unlimited)')
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    try:
        csv_file, writer = open_csv(args.output, args.append)
    except OSError as exc:
        print(f'❌ Error opening output file: {exc}')
        sys.exit(1)

    print(f'Logging MPU6050 data from {args.port} at {args.baud} baud')
    print(f'Output file: {args.output}')
    print(f'Label: {args.label}  (0=normal, 1=seizure-like)')
    if args.duration > 0:
        print(f'Duration: {args.duration} seconds')
    if args.max_lines > 0:
        print(f'Max lines: {args.max_lines}')
    print('Press Ctrl+C to stop early.')

    # Try to open the serial port first
    try:
        ser = serial.Serial(args.port, args.baud, timeout=2)
    except serial.SerialException as exc:
        print(f'❌ Could not open serial port {args.port}: {exc}')
        csv_file.close()
        sys.exit(1)

    print(f'✓ Successfully opened serial port {args.port}. Starting logging loop...')

    valid_count = 0
    try:
        with ser:
            start_time = time.time()
            while True:
                try:
                    raw_line = ser.readline().decode('utf-8', errors='replace').strip()
                except (serial.SerialException, OSError) as exc:
                    print(f'\n⚠️ Serial connection lost during recording: {exc}')
                    break

                if not raw_line:
                    if not ser.is_open:
                        print('\n⚠️ Serial port is closed.')
                        break
                    continue

                values = parse_line(raw_line)
                if values is None:
                    print(f'\nSkipped invalid line: {raw_line}', file=sys.stderr)
                    continue

                writer.writerow(values + [args.label])
                csv_file.flush()
                valid_count += 1
                print(f'Recorded {valid_count}: {values}', end='\r', flush=True)

                if args.max_lines > 0 and valid_count >= args.max_lines:
                    break
                if args.duration > 0 and (time.time() - start_time) >= args.duration:
                    break

    except KeyboardInterrupt:
        print('\nStopped by user.')
    finally:
        csv_file.close()

    print(f'\nSaved {valid_count} labeled samples to {args.output}')


if __name__ == '__main__':
    main()
