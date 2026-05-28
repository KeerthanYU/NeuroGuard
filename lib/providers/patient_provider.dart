// lib/providers/patient_provider.dart
//
// Governs global patient state, telemetry logs, and the seizure detection loop.
// 100% Pure Riverpod state provider.

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neuroguard/models/patient_model.dart';
import 'package:neuroguard/models/alert_model.dart';
import 'package:neuroguard/models/app_mode.dart';
import 'package:neuroguard/services/firebase_service.dart';
import 'package:neuroguard/services/ai_detection_service.dart';
import 'package:neuroguard/services/notification_service.dart';
import 'package:neuroguard/core/utils/constants.dart';
import 'package:neuroguard/core/utils/safe_parser.dart';
import 'package:neuroguard/models/sensor_data.dart';
import 'package:neuroguard/providers/app_mode_provider.dart';
import 'package:neuroguard/providers/sensor_data_provider.dart';
import 'package:neuroguard/providers/auth_provider.dart';
import 'package:neuroguard/services/emergency_alert_service.dart';
import 'package:neuroguard/services/caretaker_service.dart';

class PatientState {
  final PatientModel patient;
  final List<AlertModel> alerts;
  final List<double> heartRateHistory;
  final List<double> motionHistory;
  final List<double> spo2History;
  final double seizureRiskScore;
  final double aiConfidenceScore;
  final bool hasSeizureAlert;
  final bool isLoading;
  final String? error;
  final String emergencyStatus; // 'none', 'guidance', 'calling'

  const PatientState({
    required this.patient,
    this.alerts = const [],
    this.heartRateHistory = const [],
    this.motionHistory = const [],
    this.spo2History = const [],
    this.seizureRiskScore = 0.0,
    this.aiConfidenceScore = 100.0,
    this.hasSeizureAlert = false,
    this.isLoading = false,
    this.error,
    this.emergencyStatus = 'none',
  });

  PatientState copyWith({
    PatientModel? patient,
    List<AlertModel>? alerts,
    List<double>? heartRateHistory,
    List<double>? motionHistory,
    List<double>? spo2History,
    double? seizureRiskScore,
    double? aiConfidenceScore,
    bool? hasSeizureAlert,
    bool? isLoading,
    String? error,
    String? emergencyStatus,
  }) {
    return PatientState(
      patient: patient ?? this.patient,
      alerts: alerts ?? this.alerts,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
      motionHistory: motionHistory ?? this.motionHistory,
      spo2History: spo2History ?? this.spo2History,
      seizureRiskScore: seizureRiskScore ?? this.seizureRiskScore,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      hasSeizureAlert: hasSeizureAlert ?? this.hasSeizureAlert,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      emergencyStatus: emergencyStatus ?? this.emergencyStatus,
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  final Ref ref;
  String? _currentPatientId;

  // Programmatic stream listeners to prevent listener stacking
  StreamSubscription? _telemetrySub;
  StreamSubscription? _deviceSub;
  StreamSubscription? _alertsSub;

  // Timer-driven controls
  Timer? _uiThrottleTimer;

  // Local sliding-window buffers to run at high-frequency
  final List<double> _bufferedHeartRates = [];
  final List<double> _bufferedMotions = [];
  final List<double> _bufferedSpo2s = [];

  // Cached telemetry updates for throttled UI flushing
  SensorData? _latestSensorData;
  double _latestSeizureRisk = 0.0;
  double _latestConfidence = 100.0;

  PatientNotifier(this.ref) : super(PatientState(patient: PatientModel.empty())) {
    ref.listen(appModeProvider, (previous, next) {
      if (_currentPatientId != null) {
        initialize(_currentPatientId!);
      }
    });
  }

  void disposePatient() {
    _telemetrySub?.cancel();
    _telemetrySub = null;
    _deviceSub?.cancel();
    _deviceSub = null;
    _alertsSub?.cancel();
    _alertsSub = null;
    _uiThrottleTimer?.cancel();
    _uiThrottleTimer = null;
  }

  void initialize(String patientId) async {
    if (_currentPatientId == patientId && _telemetrySub != null && _deviceSub != null) {
      // Already running for this patient, do not tear down
      return;
    }

    // Preload caretaker cache before telemetry starts to ensure absolute offline availability
    try {
      final caretakerService = CaretakerService(patientId);
      await caretakerService.loadCaretaker();
      print('[PatientNotifier] Warmed caretaker cache offline-first.');
    } catch (e) {
      print('[PatientNotifier] Pre-warmup exception safely handled: $e');
    }

    // Tear down any active streams/timers to prevent memory leaks or listener stacking
    disposePatient();

    _currentPatientId = patientId;

    // Reset local sliding window buffers
    _bufferedHeartRates.clear();
    _bufferedMotions.clear();
    _bufferedSpo2s.clear();
    _latestSensorData = null;
    _latestSeizureRisk = 0.0;
    _latestConfidence = 100.0;

    // Inform Riverpod of the active patient to load the correct db paths
    ref.read(activePatientIdProvider.notifier).state = patientId;

    final mode = ref.read(appModeProvider);

    String initialConnStateStr = 'OFFLINE';
    bool initialConnected = false;

    // Initial setup with realistic seed lists (historical baseline)
    state = state.copyWith(
      patient: mode == AppMode.demo
          ? PatientModel.mock().copyWith(id: patientId, connectionState: 'LIVE', connected: true)
          : PatientModel.empty().copyWith(id: patientId, connectionState: initialConnStateStr, connected: initialConnected),
      alerts: [],
      heartRateHistory: List.generate(15, (i) => 72.0 + (i % 3) * 2),
      motionHistory: List.generate(15, (i) => 1.1 + (i % 4) * 0.2),
      spo2History: List.generate(15, (i) => 98.0 - (i % 2) * 0.5),
      seizureRiskScore: 5.0,
      aiConfidenceScore: 92.0,
      hasSeizureAlert: false,
      isLoading: true,
      emergencyStatus: 'none',
    );

    // Populate buffers with initial seed lists
    _bufferedHeartRates.addAll(state.heartRateHistory);
    _bufferedMotions.addAll(state.motionHistory);
    _bufferedSpo2s.addAll(state.spo2History);

    final repo = ref.read(sensorRepositoryProvider);

    // 2. Sub to telemetry sensor stream (unified)
    _telemetrySub = repo.sensorStream.listen((sensorData) {
      _handleSensorDataUpdate(sensorData);
    }, onError: (err) {
      print('[PatientProvider] Telemetry stream error: $err');
      _updateConnectionState(false);
      state = state.copyWith(error: err.toString(), isLoading: false);
    });

    // 3. Sub to device metadata stream (unified)
    _deviceSub = repo.deviceStream.listen((deviceData) {
      _handleDeviceDataUpdate(deviceData);
    }, onError: (err) {
      state = state.copyWith(error: err.toString(), isLoading: false);
    });

    if (mode == AppMode.demo) {
      state = state.copyWith(
        alerts: AlertModel.mockAlerts(),
        isLoading: false,
      );
    } else {
      final fbService = FirebaseService(patientId);
      
      // Sub to live alerts stream
      _alertsSub = fbService.alertsStream(patientId).listen((alertsData) {
        state = state.copyWith(alerts: alertsData);
      }, onError: (err) {
        state = state.copyWith(error: err.toString(), isLoading: false);
      });

      // Save Caregiver FCM token on app initialization
      final authState = ref.read(authProvider);
      final caregiverId = authState.uid;
      if (caregiverId.isNotEmpty) {
        NotificationService().getFcmToken().then((token) {
          if (token != null) {
            fbService.saveCaregiverFcmToken(caregiverId, token);
          }
        });
      }
    }
  }

  void _updateConnectionState(bool connected) {
    final stateString = connected ? 'LIVE' : 'OFFLINE';
    if (state.patient.connected != connected || state.patient.connectionState != stateString) {
      print('[PatientNotifier] Setting connection status to $stateString (connected=$connected)');
      state = state.copyWith(
        patient: state.patient.copyWith(
          connected: connected,
          connectionState: stateString,
        ),
      );
    }
  }

  void _handleDeviceDataUpdate(Map<dynamic, dynamic> deviceData) {
    if (deviceData.isEmpty) return;
    
    // Pull other metadata securely
    final battery = SafeParser.parseInt(deviceData['battery'], state.patient.battery);
    final lat = SafeParser.parseDouble(deviceData['latitude'], state.patient.latitude);
    final lng = SafeParser.parseDouble(deviceData['longitude'], state.patient.longitude);
    final deviceId = deviceData['deviceId']?.toString() ?? state.patient.deviceId;
    final patientName = deviceData['patientName']?.toString() ?? state.patient.patientName;

    state = state.copyWith(
      patient: state.patient.copyWith(
        // ✅ FIX: removed false battery floor (battery == 0 ? 85 : battery)
        //    0% is a real critical state and must not be masked.
        battery: battery,
        latitude: lat,
        longitude: lng,
        deviceId: deviceId,
        patientName: patientName,
      ),
    );
  }

  void _handleSensorDataUpdate(SensorData? sensorData) {
    if (sensorData == null) {
      _updateConnectionState(false);
      return;
    }
    _updateConnectionState(true);
    // 1. Process EVERY packet immediately for seizure detection
    _bufferedHeartRates.add(sensorData.heartRate.toDouble());
    if (_bufferedHeartRates.length > 25) _bufferedHeartRates.removeAt(0);

    _bufferedMotions.add(sensorData.movementLevel);
    if (_bufferedMotions.length > 25) _bufferedMotions.removeAt(0);

    _bufferedSpo2s.add(sensorData.spo2.toDouble());
    if (_bufferedSpo2s.length > 25) _bufferedSpo2s.removeAt(0);

    // AI seizure risk calculations
    final calculatedRisk = AIDetectionService.calculateSeizureRisk(
      motionHistory: _bufferedMotions,
      heartRateHistory: _bufferedHeartRates,
      spo2History: _bufferedSpo2s,
    );

    final calculatedConfidence = AIDetectionService.getConfidenceScore(
      motionHistory: _bufferedMotions,
      heartRateHistory: _bufferedHeartRates,
    );

    final isSeizure = sensorData.seizureDetected || calculatedRisk > 85.0;

    _latestSensorData = sensorData;
    _latestSeizureRisk = calculatedRisk;
    _latestConfidence = calculatedConfidence;

    // 2. Seizure path: Bypass throttles to trigger immediate emergency alert and UI update
    if (isSeizure && !state.hasSeizureAlert) {
      const patientStatus = 'critical';
      final tempPatient = state.patient.copyWith(
        heartRate: sensorData.heartRate,
        motionLevel: sensorData.movementLevel,
        seizureDetected: true,
        spo2: sensorData.spo2,
        // ✅ FIX: battery was missing from seizure path — added
        battery: sensorData.battery ?? state.patient.battery,
        status: patientStatus,
        timestamp: sensorData.timestamp,
      );
      
      _triggerEmergencyAlert(tempPatient);
      
      _uiThrottleTimer?.cancel();
      _uiThrottleTimer = null;
      _flushUiUpdate();
      return;
    }

    // 3. Normal updates: Throttle StateNotifier state updates to at most once per 200ms
    _uiThrottleTimer ??= Timer(const Duration(milliseconds: 200), () {
      _uiThrottleTimer = null;
      _flushUiUpdate();
    });
  }

  void _flushUiUpdate() {
    if (_latestSensorData == null) return;
    final sensorData = _latestSensorData!;

    final hrHistory = List<double>.from(_bufferedHeartRates);
    final motHistory = List<double>.from(_bufferedMotions);
    final spHistory = List<double>.from(_bufferedSpo2s);

    final isSeizure = state.hasSeizureAlert || sensorData.seizureDetected || _latestSeizureRisk > 85.0;

    String patientStatus = 'safe';
    if (isSeizure) {
      patientStatus = 'critical';
    } else if (_latestSeizureRisk > 45.0) {
      patientStatus = 'warning';
    }

    final updatedPatient = state.patient.copyWith(
      heartRate: sensorData.heartRate,
      motionLevel: sensorData.movementLevel,
      seizureDetected: isSeizure,
      spo2: sensorData.spo2,
      // ✅ FIX: battery was missing from normal update path — this was the primary bug
      //    SensorData carried battery correctly from Firebase, but it was never
      //    written into PatientModel state, causing the UI to always show a stale value.
      battery: sensorData.battery ?? state.patient.battery,
      status: patientStatus,
      timestamp: sensorData.timestamp,
    );

    state = state.copyWith(
      patient: updatedPatient,
      heartRateHistory: hrHistory,
      motionHistory: motHistory,
      spo2History: spHistory,
      seizureRiskScore: _latestSeizureRisk,
      aiConfidenceScore: _latestConfidence,
      isLoading: false,
    );
  }

  /// Siren trigger, GPS extraction, and emergency dispatch
  void _triggerEmergencyAlert(PatientModel p) async {
    // 1. Physical GPS Geotracking
    double lat = p.latitude;
    double lng = p.longitude;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}

    // 2. Trigger the emergency audio sequence + caretaker voice call sequentially.
    //    The service manages cooldowns, countdown, dynamic caretaker fetching, and dials.
    EmergencyAlertService().triggerEmergencyAlert(
      patientId: p.id,
      patientName: p.patientName,
      knownLat: lat,
      knownLng: lng,
      onGuidanceStarted: () {
        state = state.copyWith(emergencyStatus: 'guidance');
      },
      onCallStarted: () {
        state = state.copyWith(emergencyStatus: 'calling');
      },
    );

    // Generate unique collision-proof alertId: patientId_timestamp_randomSuffix
    final timestampSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final randomSuffix = Random().nextInt(10000).toString().padLeft(4, '0');
    final alertId = '${p.id}_${timestampSeconds}_$randomSuffix';

    final newAlert = AlertModel(
      id: alertId,
      patientId: p.id,
      patientName: p.patientName,
      type: 'Seizure Detected',
      eventType: 'SEIZURE',
      severity: 'CRITICAL',
      time: DateTime.now(),
      resolved: false,
      heartRate: p.heartRate,
      motionLevel: p.motionLevel,
      location: 'Living Room', // Optional text description of location
      latitude: lat,
      longitude: lng,
      spo2: p.spo2,
    );

    // 3. Push Seizure Alert to Firebase Realtime Database alerts node
    final mode = ref.read(appModeProvider);
    if (mode == AppMode.live) {
      final fb = FirebaseService(p.id);
      await fb.saveAlert(newAlert);
    }

    // 4. Trigger Caregiver push notification (FCM)
    final notifService = NotificationService();
    await notifService.showEmergencyAlert(
      title: '🚨 CRITICAL SEIZURE DETECTED',
      body: 'Patient ${p.patientName} is having a seizure! Immediate attention required at: Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}',
    );

    // 5. Offline backup caching
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_emergency_location', '$lat,$lng');
      await prefs.setInt('last_emergency_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('offline_alert_cached', true);
    } catch (_) {}

    state = state.copyWith(
      alerts: [newAlert, ...state.alerts],
      hasSeizureAlert: true,
    );
  }

  Future<void> refresh([String? patientId]) async {
    final pid = patientId ?? _currentPatientId ?? AppConstants.defaultPatientId;
    initialize(pid);
  }

  void simulateSeizure() {
    final updatedPatient = state.patient.copyWith(
      heartRate: 155,
      motionLevel: 9.8,
      seizureDetected: true,
      spo2: 86,
      status: 'critical',
      timestamp: DateTime.now(),
    );

    _triggerEmergencyAlert(updatedPatient);
  }

  Future<void> dismissSeizureAlert() async {
    // Stop siren + voice instructions when seizure is dismissed & reset state machine
    EmergencyAlertService().cancelEmergency();

    if (ref.read(appModeProvider) == AppMode.demo) {
      final updatedPatient = state.patient.copyWith(
        seizureDetected: false,
        status: 'safe',
        heartRate: 74,
        motionLevel: 1.2,
        spo2: 98,
        timestamp: DateTime.now(),
      );

      final resolvedAlerts = state.alerts.map((alert) {
        if (alert.type == 'Seizure Detected' && !alert.resolved) {
          return alert.copyWith(resolved: true);
        }
        return alert;
      }).toList();

      state = state.copyWith(
        patient: updatedPatient,
        hasSeizureAlert: false,
        alerts: resolvedAlerts,
        seizureRiskScore: 4.0,
        emergencyStatus: 'none',
      );
    } else {
      final pid = _currentPatientId ?? AppConstants.defaultPatientId;
      final fbService = FirebaseService(pid);
      await fbService.dismissSeizureAlert(pid);

      state = state.copyWith(
        hasSeizureAlert: false,
        seizureRiskScore: 4.0,
        emergencyStatus: 'none',
      );
    }
  }

  Future<void> dismissAlert() => dismissSeizureAlert();

  @override
  void dispose() {
    disposePatient();
    super.dispose();
  }
}

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  return PatientNotifier(ref);
});