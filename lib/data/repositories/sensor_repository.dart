// lib/data/repositories/sensor_repository.dart
//
// Provides a unified Stream<SensorData> depending on the current AppMode.
// In demo mode it returns the MockDataService stream. In live mode it returns
// the Firebase service stream.

import 'dart:async';
import '../../models/app_mode.dart';
import '../../models/sensor_data.dart';
import '../mock/mock_data.dart';
import '../../services/firebase_service.dart';

class SensorRepository {
  final AppMode mode;
  final String uid; // Firebase user id

  MockDataService? _mockService;
  FirebaseService? _firebaseService;

  SensorRepository({required this.mode, required this.uid}) {
    if (mode == AppMode.demo) {
      _mockService = MockDataService();
    } else {
      _firebaseService = FirebaseService(uid);
    }
  }

  /// Stream that emits the latest SensorData from the appropriate source.
  Stream<SensorData?> get sensorStream {
    if (mode == AppMode.demo) {
      return _mockService!.stream;
    } else {
      return _firebaseService!.sensorStream;
    }
  }

  /// Device metadata stream (like lastSeen and status)
  Stream<Map<dynamic, dynamic>> get deviceStream {
    if (mode == AppMode.demo) {
      return Stream<Map<dynamic, dynamic>>.periodic(const Duration(seconds: 2), (_) {
        return {
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
          'status': 'LIVE',
        };
      }).asBroadcastStream();
    } else {
      return _firebaseService!.deviceStream(uid);
    }
  }

  /// Connection status (true = at least one source online)
  Stream<bool> get connectionStatus {
    if (mode == AppMode.demo) {
      return Stream<bool>.periodic(const Duration(seconds: 5), (_) => true);
    } else {
      return _firebaseService!.connectionStatus;
    }
  }

  void dispose() {
    _mockService?.dispose();
    _firebaseService?.dispose();
  }
}
