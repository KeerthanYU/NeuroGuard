// lib/core/utils/safe_parser.dart
//
// Healthcare-grade type parsing with extreme fault tolerance.
// Guarantees parsing never throws exceptions or crashes the app.

class SafeParser {
  /// Safely converts any value to [int] with a fallback default.
  static int parseInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) {
      if (val.isNaN || val.isInfinite) return defaultValue;
      return val.toInt();
    }
    if (val is String) {
      final d = double.tryParse(val);
      if (d == null || d.isNaN || d.isInfinite) return defaultValue;
      return d.toInt();
    }
    return defaultValue;
  }

  /// Safely converts any value to [double] with a fallback default.
  static double parseDouble(dynamic val, double defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) {
      final d = val.toDouble();
      if (d.isNaN || d.isInfinite) return defaultValue;
      return d;
    }
    if (val is String) {
      final d = double.tryParse(val);
      if (d == null || d.isNaN || d.isInfinite) return defaultValue;
      return d;
    }
    return defaultValue;
  }

  /// Safely converts any value to [bool] with a fallback default.
  static bool parseBool(dynamic val, bool defaultValue) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is String) {
      final s = val.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    if (val is num) return val != 0;
    return defaultValue;
  }

  /// Safely converts dynamic timestamps/strings to a robust [DateTime].
  static DateTime parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is num) {
      final numVal = val.toInt();
      // Heuristic: values below 10,000,000,000 are interpreted as seconds rather than milliseconds
      if (numVal < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(numVal);
    }
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
