// lib/models/sensor_data.dart

class SensorData {
  final int heartRate; // beats per minute
  final int spo2; // oxygen saturation percentage
  final bool seizureDetected;
  final bool fallDetected;
  final double movementLevel;
  final bool emergencyTriggered;
  final DateTime timestamp;
  final int? battery;

  const SensorData({
    required this.heartRate,
    required this.spo2,
    required this.seizureDetected,
    required this.fallDetected,
    required this.movementLevel,
    required this.emergencyTriggered,
    required this.timestamp,
    this.battery,
  });
}
