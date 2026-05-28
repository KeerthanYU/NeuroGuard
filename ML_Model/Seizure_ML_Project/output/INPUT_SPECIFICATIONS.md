# Model Input Specifications for ESP32 Firmware

## Model Overview
- **Model Type**: 1D-CNN for seizure detection
- **Output Classes**: 0 = Normal, 1 = Seizure
- **Quantization**: INT8 (fully quantized)
- **Model Size**: 7.58 KB

## Input Tensor Specifications
| Parameter | Value |
|-----------|-------|
| Shape | [1, 200, 6] |
| Data Type | int8 |
| Timesteps | 200 (2 seconds @ 100Hz) |
| Features | 6 (MPU6050 accelerometer XYZ + gyroscope XYZ) |

## Dataset CSV column order
The generated CSV rows use the following channel order:
1. `accel_x`
2. `accel_y`
3. `accel_z`
4. `gyro_x`
5. `gyro_y`
6. `gyro_z`

## Input Preprocessing Required
Before feeding data to the model, the ESP32 must:

1. **Collect 200 samples** at 100Hz (10ms intervals)
2. **Use MPU6050 acceleration and gyroscope values**:
   - `accel_x`, `accel_y`, `accel_z`
   - `gyro_x`, `gyro_y`, `gyro_z`
3. **Normalize accelerometer data**:
   ```cpp
   float accel_x_n = accel_x / 16.0f;
   float accel_y_n = accel_y / 16.0f;
   float accel_z_n = accel_z / 16.0f;
   ```
4. **Normalize gyroscope data**:
   ```cpp
   float gyro_x_n = gyro_x / 250.0f;
   float gyro_y_n = gyro_y / 250.0f;
   float gyro_z_n = gyro_z / 250.0f;
   ```
5. **Quantize to int8**:
   ```cpp
   int8_t accel_x_q = (int8_t)round(accel_x_n * 127.0f);
   int8_t accel_y_q = (int8_t)round(accel_y_n * 127.0f);
   int8_t accel_z_q = (int8_t)round(accel_z_n * 127.0f);
   int8_t gyro_x_q = (int8_t)round(gyro_x_n * 127.0f);
   int8_t gyro_y_q = (int8_t)round(gyro_y_n * 127.0f);
   int8_t gyro_z_q = (int8_t)round(gyro_z_n * 127.0f);
   ```

## ESP32 Code Snippet
```cpp
float accel_x = event.acceleration.x;
float accel_y = event.acceleration.y;
float accel_z = event.acceleration.z;
float gyro_x = event.gyro.x;
float gyro_y = event.gyro.y;
float gyro_z = event.gyro.z;

float accel_x_n = accel_x / 16.0f;
float accel_y_n = accel_y / 16.0f;
float accel_z_n = accel_z / 16.0f;
float gyro_x_n = gyro_x / 250.0f;
float gyro_y_n = gyro_y / 250.0f;
float gyro_z_n = gyro_z / 250.0f;

int8_t input_buffer[1200];
input_buffer[sample_index * 6 + 0] = (int8_t)round(accel_x_n * 127.0f);
input_buffer[sample_index * 6 + 1] = (int8_t)round(accel_y_n * 127.0f);
input_buffer[sample_index * 6 + 2] = (int8_t)round(accel_z_n * 127.0f);
input_buffer[sample_index * 6 + 3] = (int8_t)round(gyro_x_n * 127.0f);
input_buffer[sample_index * 6 + 4] = (int8_t)round(gyro_y_n * 127.0f);
input_buffer[sample_index * 6 + 5] = (int8_t)round(gyro_z_n * 127.0f);
```

## Expected Output
| Output Value | Meaning |
|--------------|---------|
| Class 0 | Normal activity |
| Class 1 | Seizure detected |

**Threshold Recommendation**: Trigger an alert if probability of class 1 > 0.85.
