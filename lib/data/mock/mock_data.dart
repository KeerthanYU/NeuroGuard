// lib/data/mock/mock_data.dart
//
// Generates realistic medical data for demo mode. Emits a new SensorData
// object every 2 seconds, simulating normal readings, seizure spikes, oxygen
// drops, movement spikes and occasional emergency triggers.

import 'dart:async';
import 'dart:math';
import 'package:neuroguard/models/sensor_data.dart';

class MockDataService {
  static const Duration _interval = Duration(seconds: 2);
  final _controller = StreamController<SensorData>.broadcast();
  Timer? _timer;

  // internal state for pattern generation
  bool _inSeizure = false;
  int _seizureStep = 0;
  int _fallStep = 0;
  final Random _random = Random();

  MockDataService() {
    _start();
  }

  Stream<SensorData> get stream => _controller.stream;

  void _start() {
    _timer = Timer.periodic(_interval, (_) => _emitData());
  }

  void _emitData() {
    // potentially start a seizure – low probability (≈1/90 per tick)
    if (!_inSeizure && _random.nextInt(90) == 0) {
      _inSeizure = true;
      _seizureStep = 0;
    }

    // potentially start a fall – very low probability (≈1/300 per tick)
    if (_fallStep == 0 && _random.nextInt(300) == 0) {
      _fallStep = 1; // will emit fall for one interval
    }

    // ----- Heart rate -----
    int heartRate;
    if (_inSeizure) {
      const seizureRates = [110, 135, 165];
      heartRate = seizureRates[_seizureStep % seizureRates.length];
      _seizureStep++;
      if (_seizureStep >= seizureRates.length) {
        _inSeizure = false;
        _seizureStep = 0;
      }
    } else {
      heartRate = 70 + _random.nextInt(9); // 70‑78 normal
    }

    // ----- SpO2 -----
    int spo2 = _inSeizure
        ? 84 + _random.nextInt(6) // 84‑89 during seizure (hypoxic drop)
        : 97 + _random.nextInt(3); // 97‑99 normal

    // ----- Movement level -----
    double movementLevel;
    if (_inSeizure) {
      // Simulate extreme physical seizure tremors > 6.0g
      movementLevel = 6.2 + _random.nextDouble() * 2.5; 
    } else if (_fallStep == 1) {
      movementLevel = 7.5; // fall impact spike
      _fallStep = 0;
    } else {
      movementLevel = 0.5 + _random.nextDouble() * 1.0; // normal micro-movement
    }

    bool seizureDetected = _inSeizure;
    bool fallDetected = _fallStep == 1;
    bool emergencyTriggered = seizureDetected || fallDetected || (_random.nextInt(200) == 0);

    final data = SensorData(
      heartRate: heartRate,
      spo2: spo2,
      seizureDetected: seizureDetected,
      fallDetected: fallDetected,
      movementLevel: movementLevel,
      emergencyTriggered: emergencyTriggered,
      timestamp: DateTime.now(),
    );

    _controller.add(data);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
