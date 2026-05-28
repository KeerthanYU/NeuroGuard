import 'package:intl/intl.dart';
import 'package:neuroguard/core/utils/safe_parser.dart';

/// Patient real-time data model (from Firebase)
class PatientModel {
  final String id;
  final String patientName;
  final String deviceId;
  final int heartRate;
  final double motionLevel;
  final bool seizureDetected;
  final int spo2;
  final int battery;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool connected;
  final String status; // 'safe', 'warning', 'critical'
  final String connectionState; // 'LIVE', 'RECONNECTING', 'OFFLINE'

  PatientModel({
    required this.id,
    required this.patientName,
    required this.deviceId,
    required this.heartRate,
    required this.motionLevel,
    required this.seizureDetected,
    required this.spo2,
    required this.battery,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.connected,
    required this.status,
    this.connectionState = 'OFFLINE',
  });

  factory PatientModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final int hr = SafeParser.parseInt(map['heartRate'], 0);
    final double motion = SafeParser.parseDouble(map['motionLevel'], 0.0);
    final bool seizure = SafeParser.parseBool(map['seizureDetected'], false);
    final int ox = SafeParser.parseInt(map['spo2'], 98);

    String status = 'safe';
    if (seizure || hr > 150 || motion > 9.0 || ox < 90) {
      status = 'critical';
    } else if (hr > 120 || motion > 6.0 || ox < 94) {
      status = 'warning';
    }

    return PatientModel(
      id: id,
      patientName: map['patientName']?.toString() ?? 'Unknown Patient',
      deviceId: map['deviceId']?.toString() ?? 'ESP32-NG-001',
      heartRate: hr,
      motionLevel: motion,
      seizureDetected: seizure,
      spo2: ox,
      battery: SafeParser.parseInt(map['battery'], 0),
      latitude: SafeParser.parseDouble(map['latitude'], 28.6139),
      longitude: SafeParser.parseDouble(map['longitude'], 77.2090),
      timestamp: SafeParser.parseDateTime(map['timestamp']),
      connected: SafeParser.parseBool(map['connected'], false),
      status: map['status']?.toString() ?? status,
      connectionState: map['connectionState']?.toString() ??
          (SafeParser.parseBool(map['connected'], false) ? 'LIVE' : 'OFFLINE'),
    );
  }

  factory PatientModel.empty() {
    return PatientModel(
      id: '',
      patientName: 'Connecting...',
      deviceId: 'ESP32-NG-001',
      heartRate: 0,
      motionLevel: 0.0,
      seizureDetected: false,
      spo2: 98,
      battery: 0,
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now(),
      connected: false,
      status: 'safe',
      connectionState: 'OFFLINE',
    );
  }

  factory PatientModel.mock() {
    return PatientModel(
      id: 'patient_001',
      patientName: 'Alex Johnson',
      deviceId: 'ESP32-NG-001',
      heartRate: 78,
      motionLevel: 2.3,
      seizureDetected: false,
      spo2: 98,
      battery: 85,
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now(),
      connected: true,
      status: 'safe',
      connectionState: 'LIVE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'deviceId': deviceId,
      'heartRate': heartRate,
      'motionLevel': motionLevel,
      'seizureDetected': seizureDetected,
      'spo2': spo2,
      'battery': battery,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'connected': connected,
      'connectionState': connectionState,
    };
  }

  String get formattedTimestamp {
    return DateFormat('MMM dd, HH:mm:ss').format(timestamp);
  }

  String get heartRateStatus {
    if (heartRate < 40 || heartRate > 150) return 'Critical';
    if (heartRate < 60 || heartRate > 120) return 'Elevated';
    return 'Normal';
  }

  String get motionStatus {
    if (motionLevel >= 9.0) return 'Seizure';
    if (motionLevel >= 6.0) return 'High';
    if (motionLevel >= 3.0) return 'Moderate';
    return 'Normal';
  }

  PatientModel copyWith({
    String? id,
    String? patientName,
    String? deviceId,
    int? heartRate,
    double? motionLevel,
    bool? seizureDetected,
    int? spo2,
    int? battery,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    bool? connected,
    String? status,
    String? connectionState,
  }) {
    return PatientModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      deviceId: deviceId ?? this.deviceId,
      heartRate: heartRate ?? this.heartRate,
      motionLevel: motionLevel ?? this.motionLevel,
      seizureDetected: seizureDetected ?? this.seizureDetected,
      spo2: spo2 ?? this.spo2,
      battery: battery ?? this.battery,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      connected: connected ?? this.connected,
      status: status ?? this.status,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}
