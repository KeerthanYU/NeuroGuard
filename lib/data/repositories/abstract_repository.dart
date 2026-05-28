// lib/data/repositories/abstract_repository.dart

import '../../models/sensor_data.dart';

/// A simple abstract repository defining the contract for sensor data
/// and connection status streams.
abstract class BaseRepository {
  /// Stream emitting the latest [SensorData] readings.
  Stream<SensorData> get sensorStream;

  /// Stream emitting a boolean indicating whether a data source is
  /// currently connected (true) or offline (false).
  Stream<bool> get connectionStatus;
}
