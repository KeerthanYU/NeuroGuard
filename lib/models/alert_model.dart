import 'package:intl/intl.dart';
import 'package:neuroguard/core/utils/safe_parser.dart';

/// Seizure alert event model (stored in Firebase alerts/)
class AlertModel {
  final String id;
  final DateTime time;
  final String severity;
  final int heartRate;
  final double motionLevel;
  final double? latitude;
  final double? longitude;
  final String patientId;
  final String notes;
  final String patientName;
  final String type;
  final String eventType;
  final bool resolved;
  final String? location;
  final int? spo2;

  AlertModel({
    required this.id,
    required this.time,
    required this.severity,
    required this.heartRate,
    required this.motionLevel,
    this.latitude,
    this.longitude,
    required this.patientId,
    this.notes = '',
    this.patientName = '',
    this.type = 'Seizure Detected',
    this.eventType = 'SEIZURE',
    this.resolved = false,
    this.location,
    this.spo2,
  });

  static double? _parseOptionalDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) {
      final d = val.toDouble();
      if (d.isNaN || d.isInfinite) return null;
      return d;
    }
    if (val is String) {
      final d = double.tryParse(val);
      if (d == null || d.isNaN || d.isInfinite) return null;
      return d;
    }
    return null;
  }

  factory AlertModel.fromMap(String id, Map<dynamic, dynamic> map) {
    double? lat;
    double? lng;
    String? locText;

    if (map['location'] != null) {
      if (map['location'] is Map) {
        final locMap = Map<dynamic, dynamic>.from(map['location'] as Map);
        lat = _parseOptionalDouble(locMap['lat']);
        lng = _parseOptionalDouble(locMap['lng']);
        locText = locMap['text']?.toString();
      } else {
        locText = map['location']?.toString();
      }
    }

    return AlertModel(
      id: id,
      time: SafeParser.parseDateTime(map['time']),
      severity: map['severity']?.toString() ?? 'WARNING',
      heartRate: SafeParser.parseInt(map['heartRate'], 0),
      motionLevel: SafeParser.parseDouble(map['motionLevel'], 0.0),
      latitude: lat ?? _parseOptionalDouble(map['latitude']),
      longitude: lng ?? _parseOptionalDouble(map['longitude']),
      patientId: map['patientId']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      type: map['type']?.toString() ?? map['eventType']?.toString() ?? 'Seizure Detected',
      eventType: map['eventType']?.toString() ?? 'SEIZURE',
      resolved: SafeParser.parseBool(map['resolved'], false),
      location: locText,
      spo2: SafeParser.parseInt(map['spo2'] ?? (map['sensorSnapshot'] is Map ? map['sensorSnapshot']['spo2'] : null), 98),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time.millisecondsSinceEpoch ~/ 1000,
      'severity': severity,
      'heartRate': heartRate,
      'motionLevel': motionLevel,
      'patientId': patientId,
      'notes': notes,
      'patientName': patientName,
      'type': type,
      'eventType': eventType,
      'resolved': resolved,
      'spo2': spo2,
      'location': {
        'lat': latitude,
        'lng': longitude,
        'text': location ?? 'Unknown',
      },
    };
  }

  AlertModel copyWith({
    String? id,
    DateTime? time,
    String? severity,
    int? heartRate,
    double? motionLevel,
    double? latitude,
    double? longitude,
    String? patientId,
    String? notes,
    String? patientName,
    String? type,
    String? eventType,
    bool? resolved,
    String? location,
    int? spo2,
  }) {
    return AlertModel(
      id: id ?? this.id,
      time: time ?? this.time,
      severity: severity ?? this.severity,
      heartRate: heartRate ?? this.heartRate,
      motionLevel: motionLevel ?? this.motionLevel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      patientId: patientId ?? this.patientId,
      notes: notes ?? this.notes,
      patientName: patientName ?? this.patientName,
      type: type ?? this.type,
      eventType: eventType ?? this.eventType,
      resolved: resolved ?? this.resolved,
      location: location ?? this.location,
      spo2: spo2 ?? this.spo2,
    );
  }

  String get formattedTime => DateFormat('MMM dd, yyyy HH:mm:ss').format(time);
  String get formattedDate => DateFormat('MMM dd, yyyy').format(time);
  String get formattedTimeOnly => DateFormat('HH:mm:ss').format(time);

  String get coordinates {
    if (latitude == null || longitude == null) return 'No GPS Data';
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }

  bool get isCritical => severity == 'CRITICAL' || severity == 'Critical';
  bool get isWarning => severity == 'WARNING' || severity == 'Warning';

  /// Mock alerts for demo
  static List<AlertModel> mockAlerts() {
    return [
      AlertModel(
        id: 'alert_001',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        severity: 'CRITICAL',
        heartRate: 162,
        motionLevel: 9.4,
        latitude: 28.6145,
        longitude: 77.2088,
        patientId: 'patient_001',
        notes: 'Tonic-clonic seizure detected',
        patientName: 'Alex Johnson',
        type: 'Seizure Detected',
        resolved: false,
        location: 'Living Room',
      ),
      AlertModel(
        id: 'alert_002',
        time: DateTime.now().subtract(const Duration(hours: 8)),
        severity: 'WARNING',
        heartRate: 128,
        motionLevel: 7.1,
        latitude: 28.6139,
        longitude: 77.2090,
        patientId: 'patient_001',
        notes: 'Elevated motion and heart rate',
        patientName: 'Alex Johnson',
        type: 'High Motion Alert',
        resolved: false,
        location: 'Kitchen',
      ),
      AlertModel(
        id: 'alert_003',
        time: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        severity: 'CRITICAL',
        heartRate: 171,
        motionLevel: 9.8,
        latitude: 28.6120,
        longitude: 77.2075,
        patientId: 'patient_001',
        notes: 'Major seizure event',
        patientName: 'Alex Johnson',
        type: 'Seizure Detected',
        resolved: true,
        location: 'Bedroom',
      ),
      AlertModel(
        id: 'alert_004',
        time: DateTime.now().subtract(const Duration(days: 2)),
        severity: 'WARNING',
        heartRate: 115,
        motionLevel: 6.3,
        latitude: 28.6139,
        longitude: 77.2090,
        patientId: 'patient_001',
        notes: 'Mild tremor episode',
        patientName: 'Alex Johnson',
        type: 'Minor Tremor Alert',
        resolved: true,
        location: 'Living Room',
      ),
      AlertModel(
        id: 'alert_005',
        time: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        severity: 'CRITICAL',
        heartRate: 158,
        motionLevel: 9.2,
        latitude: 28.6150,
        longitude: 77.2100,
        patientId: 'patient_001',
        notes: 'Nocturnal seizure',
        patientName: 'Alex Johnson',
        type: 'Seizure Detected',
        resolved: true,
        location: 'Bedroom',
      ),
    ];
  }
}
