import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

def tflite_to_c_array(tflite_path, output_path, array_name='model'):
    # Resolve absolute paths
    resolved_tflite = os.path.abspath(os.path.join(PROJECT_ROOT, tflite_path)) if not os.path.isabs(tflite_path) else tflite_path
    resolved_output = os.path.abspath(os.path.join(PROJECT_ROOT, output_path)) if not os.path.isabs(output_path) else output_path

    if not os.path.exists(resolved_tflite):
        print(f"[ERROR] TFLite model not found at {resolved_tflite}.")
        return

    with open(resolved_tflite, 'rb') as f:
        tflite_data = f.read()

    os.makedirs(os.path.dirname(resolved_output), exist_ok=True)

    # Write compact hex array
    with open(resolved_output, 'w') as f:
        f.write('#ifndef MODEL_H\n')
        f.write('#define MODEL_H\n')
        f.write(f'#define {array_name.upper()}_LEN {len(tflite_data)}\n')
        f.write(f'const unsigned char {array_name}[] = {{\n')
        hex_bytes = ','.join(f'0x{b:02x}' for b in tflite_data)
        f.write(hex_bytes)
        f.write('\n};\n')
        f.write(f'const unsigned int {array_name}_len = {len(tflite_data)};\n\n')
        f.write('#endif // MODEL_H\n')

    print(f'[SUCCESS] C header saved to {resolved_output}')
    print(f'  Array name: {array_name}')
    print(f'  Array size: {len(tflite_data)} bytes')


if __name__ == '__main__':
    tflite_to_c_array('models/seizure_quantized.tflite', 'output/model.h')
