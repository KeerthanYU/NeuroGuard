import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import 'package:neuroguard/core/services/app_initializer.dart';
import '../models/patient_model.dart';
import '../models/alert_model.dart';
import '../models/sensor_data.dart';

import 'package:neuroguard/core/utils/constants.dart';
import 'package:neuroguard/core/utils/safe_parser.dart';
import 'package:neuroguard/services/signal_processor.dart';

/// ICU-grade Firebase service (single-source, stable, no duplicate sockets)
class FirebaseService {
  final String? uid;

  FirebaseService([this.uid]);

  /// 🔥 IMPORTANT: SINGLE SOURCE OF TRUTH (using explicit database URL)
  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: AppInitializer.firebaseApp,
        databaseURL: 'https://neuroguard-5dda9-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

  Timer? _mockTimer;

  // Signal processor (per instance)
  final SignalProcessor _signalProcessor = SignalProcessor();

  // ─────────────────────────────────────────────────────────────
  // 🟢 CONNECTION STATUS STREAM (DRIVEN BY TELEMETRY STREAM)
  // ─────────────────────────────────────────────────────────────
  Stream<bool> get connectionStatus {
    return sensorStream.map((event) => event != null);
  }

  // ─────────────────────────────────────────────────────────────
  // 📡 SENSOR STREAM (DIRECT FIREBASE STREAM WITH VERBOSE LOGGING)
  // ─────────────────────────────────────────────────────────────
  Stream<SensorData?> get sensorStream {
    final patientId =
        (uid == null || uid!.isEmpty)
            ? AppConstants.defaultPatientId
            : uid!;

    print('[FirebaseService] Subscribing to live telemetry stream for patient: $patientId');

    return _db
        .ref('${AppConstants.telemetryPath}/$patientId')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        print('[FirebaseService] Telemetry data is null for patient: $patientId (Connection is OFFLINE)');
        return null;
      }

      print('[FirebaseService] Telemetry snapshot received for patient $patientId: $value');
      final map = Map<dynamic, dynamic>.from(value as Map);

      final ax = SafeParser.parseDouble(map['ax'] ?? (map['motion'] is Map ? map['motion']['ax'] : null), 0.0);
      final ay = SafeParser.parseDouble(map['ay'] ?? (map['motion'] is Map ? map['motion']['ay'] : null), 0.0);
      final az = SafeParser.parseDouble(map['az'] ?? (map['motion'] is Map ? map['motion']['az'] : null), 0.0);
      final ir = SafeParser.parseInt(map['ir'], 0);
      final heartRate = SafeParser.parseInt(map['heartRate'], 0);
      final spo2 = SafeParser.parseInt(map['spo2'] ?? map['spO2'], 0);
      final seizure = SafeParser.parseBool(map['seizure'] ?? map['seizureDetected'], false);
      final battery = SafeParser.parseInt(map['battery'], 100);

      final ts = SafeParser.parseDateTime(map['timestamp']);
      // Normalize raw sensor magnitude to a 0–10 g-force scale.
      // Raw ax/ay/az from ESP32 (MPU6050 default ±2g, 16-bit) produce values
      // in the 0–30000 range. Dividing by 3000 maps to approx 0–10 g units,
      // which is consistent with all downstream thresholds (seizure >9, warning >6).
      double movementLevel = map['motion'] is num
          ? SafeParser.parseDouble(map['motion'], 0.0)
          : (sqrt(ax * ax + ay * ay + az * az) / 3000.0).clamp(0.0, 10.0);

      int finalHr = heartRate;
      int finalSpo2 = spo2;
      if (finalHr == 0 && ir > 0) {
        final vitals = _signalProcessor.processSample(ir, ts);
        finalHr = vitals['heartRate'] ?? 75;
        finalSpo2 = vitals['spo2'] ?? 98;
      } else {
        if (finalHr == 0) finalHr = 75;
        if (finalSpo2 == 0) finalSpo2 = 98;
      }

      final fallDetected = movementLevel > 8.0;

      print('[FirebaseService] Parsed sensor packet: HR=$finalHr, SpO2=$finalSpo2, motion=${movementLevel.toStringAsFixed(2)}, seizure=$seizure, battery=$battery');

      return SensorData(
        heartRate: finalHr,
        spo2: finalSpo2,
        seizureDetected: seizure,
        fallDetected: fallDetected,
        movementLevel: movementLevel,
        emergencyTriggered: fallDetected || seizure,
        timestamp: ts,
        battery: battery,
      );
    }).handleError((error) {
      print('[FirebaseService] Error in telemetry stream for patient $patientId: $error');
      throw error;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 📱 DEVICE STREAM
  // ─────────────────────────────────────────────────────────────
  Stream<Map<dynamic, dynamic>> deviceStream(String patientId) {
    return _db
        .ref('${AppConstants.devicePath}/$patientId')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <dynamic, dynamic>{};
      return Map<dynamic, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 👤 PATIENT STREAM
  // ─────────────────────────────────────────────────────────────
  Stream<PatientModel> patientStream(String patientId) {
    return _db
        .ref('${AppConstants.devicePath}/$patientId')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return PatientModel.mock();
      }

      final data = Map<dynamic, dynamic>.from(
        event.snapshot.value as Map,
      );

      return PatientModel.fromMap(patientId, data);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ✍️ WRITE PATIENT DATA (SAFE ROUTING)
  // ─────────────────────────────────────────────────────────────
  Future<void> updatePatientData(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    final telemetryData = <String, dynamic>{};
    final deviceData = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final val = entry.value;

      if (key == 'ax' ||
          key == 'ay' ||
          key == 'az' ||
          key == 'ir' ||
          key == 'timestamp') {
        telemetryData[key] = val;
      } else if (key == 'lastSeen' ||
          key == 'connected' ||
          key == 'connectionState' ||
          key == 'battery' ||
          key == 'latitude' ||
          key == 'longitude' ||
          key == 'deviceId' ||
          key == 'patientName' ||
          key == 'status') {
        deviceData[key] = val;
      }
    }

    if (telemetryData.isNotEmpty) {
      await _db
          .ref('${AppConstants.telemetryPath}/$patientId')
          .update(telemetryData);
    }

    if (deviceData.isNotEmpty) {
      await _db
          .ref('${AppConstants.devicePath}/$patientId')
          .update(deviceData);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 🚨 ALERTS
  // ─────────────────────────────────────────────────────────────
  Future<List<AlertModel>> getAlerts(String patientId) async {
    try {
      final snapshot = await _db
          .ref('${AppConstants.alertsPath}/$patientId')
          .limitToLast(50)
          .get();

      if (snapshot.value == null) return AlertModel.mockAlerts();

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      final alerts = data.entries.map((e) {
        return AlertModel.fromMap(
          e.key.toString(),
          Map<dynamic, dynamic>.from(e.value as Map),
        );
      }).toList();

      alerts.sort((a, b) => b.time.compareTo(a.time));
      return alerts;
    } catch (_) {
      return AlertModel.mockAlerts();
    }
  }

  Stream<List<AlertModel>> alertsStream(String patientId) {
    return _db
        .ref('${AppConstants.alertsPath}/$patientId')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return AlertModel.mockAlerts();

      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      final alerts = data.entries.map((e) {
        return AlertModel.fromMap(
          e.key.toString(),
          Map<dynamic, dynamic>.from(e.value as Map),
        );
      }).toList();

      alerts.sort((a, b) => b.time.compareTo(a.time));
      return alerts;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 💾 SAVE ALERT (WITH AUTHORITATIVE SERVER TIMESTAMP & NESTED SENSOR SNAPSHOT)
  // ─────────────────────────────────────────────────────────────
  Future<void> saveAlert(AlertModel alert) async {
    final timestampSeconds =
        alert.time.millisecondsSinceEpoch ~/ 1000;
    final randomSuffix =
        Random().nextInt(10000).toString().padLeft(4, '0');

    final alertId =
        '${alert.patientId}_${timestampSeconds}_$randomSuffix';

    print('[FirebaseService] Initiating write of collision-proof Seizure Alert: alertId=$alertId under /alerts/${alert.patientId}/$alertId');

    final alertData = {
      'id': alertId,
      'type': 'SEIZURE',
      'eventType': 'SEIZURE',
      'severity': 'CRITICAL',
      'patientId': alert.patientId,
      'patientName': alert.patientName,
      'notes': alert.notes.isNotEmpty ? alert.notes : 'Clinical Seizure Detected',
      'resolved': false,
      'heartRate': alert.heartRate,
      'motionLevel': alert.motionLevel,
      'latitude': alert.latitude,
      'longitude': alert.longitude,
      'time': alert.time.millisecondsSinceEpoch ~/ 1000,
      'timestamp': ServerValue.timestamp, // server-side timestamp authoritative
      'gps': alert.latitude != null && alert.longitude != null ? {
        'lat': alert.latitude,
        'lng': alert.longitude,
      } : null,
      'sensorSnapshot': {
        'heartRate': alert.heartRate,
        'motionLevel': alert.motionLevel,
        'spo2': alert.spo2 ?? 98,
        'timestamp': alert.time.millisecondsSinceEpoch ~/ 1000,
      }
    };

    try {
      await _db
          .ref('${AppConstants.alertsPath}/${alert.patientId}/$alertId')
          .set(alertData);
      print('[FirebaseService] Successfully wrote Seizure Alert payload to RTDB path: /alerts/${alert.patientId}/$alertId');
    } catch (e) {
      print('[FirebaseService] Failed to write Seizure Alert: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 📡 FCM TOKEN
  // ─────────────────────────────────────────────────────────────
  Future<void> saveCaregiverFcmToken(
    String caregiverId,
    String token,
  ) async {
    await _db
        .ref('${AppConstants.caregiverPath}/$caregiverId')
        .update({'fcmToken': token});
  }

  // ─────────────────────────────────────────────────────────────
  // 🧠 MOCK SIMULATION (ESP32 EMULATION)
  // ─────────────────────────────────────────────────────────────
  void startMockDataSimulation(String patientId) {
    _mockTimer?.cancel();
    int tick = 0;
    final random = Random();

    _mockTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      tick++;

      final isSeizure = tick % 60 == 0;

      final ax = isSeizure
          ? 5.0 + random.nextDouble() * 4.0
          : 0.5 + random.nextDouble() * 0.5;

      final ay = isSeizure
          ? 5.0 + random.nextDouble() * 4.0
          : 0.5 + random.nextDouble() * 0.5;

      final az = isSeizure
          ? 5.0 + random.nextDouble() * 4.0
          : 0.5 + random.nextDouble() * 0.5;

      final ir = 500 +
          (sin(tick * 0.5) * 100).round() +
          (isSeizure ? random.nextInt(150) : random.nextInt(20));

      await _db
          .ref('${AppConstants.telemetryPath}/$patientId')
          .set({
        'ax': ax,
        'ay': ay,
        'az': az,
        'ir': ir,
        'timestamp': ServerValue.timestamp,
      });

      await _db
          .ref('${AppConstants.devicePath}/$patientId')
          .set({
        'lastSeen': ServerValue.timestamp,
        'status': 'LIVE',
        'battery': (90 - tick ~/ 30).clamp(10, 100),
        'latitude': 28.6139 + (tick % 5) * 0.0001,
        'longitude': 77.2090 + (tick % 5) * 0.0001,
        'deviceId': 'ESP32-NG-001',
        'patientName': 'Alex Johnson',
      });
    });
  }

  // ─────────────────────────────────────────────────────────────
  // 🧹 DISMISS SEIZURE ALERTS
  // ─────────────────────────────────────────────────────────────
  Future<void> dismissSeizureAlert(String patientId) async {
    try {
      final snapshot = await _db
          .ref('${AppConstants.alertsPath}/$patientId')
          .get();

      if (snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final updates = <String, dynamic>{};

        for (final entry in data.entries) {
          final alertId = entry.key.toString();
          final alertData = Map<dynamic, dynamic>.from(entry.value as Map);
          if (alertData['resolved'] == false || alertData['resolved'] == 'false') {
            updates['$alertId/resolved'] = true;
          }
        }

        if (updates.isNotEmpty) {
          await _db
              .ref('${AppConstants.alertsPath}/$patientId')
              .update(updates);
        }
      }
    } catch (e) {
      print('Error dismissing seizure alerts: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 🧹 DISPOSE
  // ─────────────────────────────────────────────────────────────
  void dispose() {
    _mockTimer?.cancel();
    _signalProcessor.clear();
  }
}