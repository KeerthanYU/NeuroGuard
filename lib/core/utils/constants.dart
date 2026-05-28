/// NeuroGuard App Constants
class AppConstants {
  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'NeuroGuard';
  static const String appTagline = '24/7 Smart Epilepsy Guardian';
  static const String appVersion = '1.0.0';

  // ─── Firebase Paths ───────────────────────────────────────────────────────
  static const String patientsPath = 'patients';
  static const String telemetryPath = 'telemetry';
  static const String devicePath = 'device';
  static const String alertsPath = 'alerts';
  static const String caregiverPath = 'caregivers';

  // ─── Firebase Fields ──────────────────────────────────────────────────────
  static const String heartRateField = 'heartRate';
  static const String motionLevelField = 'motionLevel';
  static const String seizureDetectedField = 'seizureDetected';
  static const String batteryField = 'battery';
  static const String latitudeField = 'latitude';
  static const String longitudeField = 'longitude';
  static const String timestampField = 'timestamp';

  // ─── Default Patient (for demo/hackathon) ─────────────────────────────────
  static const String defaultPatientId = 'patient_001';

  // ─── Thresholds ───────────────────────────────────────────────────────────
  static const int heartRateNormalMin = 60;
  static const int heartRateNormalMax = 100;
  static const int heartRateWarning = 120;
  static const int heartRateCritical = 150;
  static const double motionWarningThreshold = 6.0;
  static const double motionCriticalThreshold = 9.0;

  // ─── Map Defaults ─────────────────────────────────────────────────────────
  static const double defaultLat = 28.6139;
  static const double defaultLng = 77.2090;
  static const double defaultMapZoom = 15.0;

  // ─── Notification IDs ─────────────────────────────────────────────────────
  static const int emergencyNotifId = 9001;
  static const int heartRateNotifId = 9002;
  static const int deviceNotifId = 9003;

  // ─── Alert Severity ───────────────────────────────────────────────────────
  static const String severityCritical = 'CRITICAL';
  static const String severityWarning = 'WARNING';
  static const String severityInfo = 'INFO';

  // ─── Mock Data (for demo when no hardware) ────────────────────────────────
  static const Map<String, dynamic> mockPatientData = {
    'heartRate': 78,
    'motionLevel': 2.3,
    'seizureDetected': false,
    'battery': 85,
    'latitude': 28.6139,
    'longitude': 77.2090,
    'timestamp': 0,
    'patientName': 'Alex Johnson',
    'deviceId': 'ESP32-NG-001',
    'connected': true,
  };
}

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String emergency = '/emergency';
  static const String liveMonitoring = '/live-monitoring';
  static const String gpsTracking = '/gps-tracking';
  static const String history = '/history';
  static const String caregiver = '/caregiver';
  static const String settings = '/settings';
  static const String caretakerSetup = '/caretaker-setup';
}
