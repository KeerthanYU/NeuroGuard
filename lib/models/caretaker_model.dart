// lib/models/caretaker_model.dart
import 'package:flutter/foundation.dart';

/// Immutable model representing the patient's caregiver/caretaker details.
@immutable
class CaretakerModel {
  final String name;
  final String phone;
  final DateTime updatedAt;

  const CaretakerModel({
    required this.name,
    required this.phone,
    required this.updatedAt,
  });

  /// Factory for creating an empty default placeholder caretaker.
  factory CaretakerModel.empty() {
    return CaretakerModel(
      name: '',
      phone: '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Converts the caretaker instance to a map for local/Firebase serialization.
  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Deserializes a caretaker instance from a map.
  factory CaretakerModel.fromMap(Map<dynamic, dynamic> map) {
    return CaretakerModel(
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(map['updatedAt'].toString()) ?? 0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Creates a copy of the current caretaker with optional field changes.
  CaretakerModel copyWith({
    String? name,
    String? phone,
    DateTime? updatedAt,
  }) {
    return CaretakerModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks if the caretaker details are empty or placeholder data.
  bool get isEmpty => name.trim().isEmpty || phone.trim().isEmpty;

  /// Robust verification to see if the contact details are medically actionable.
  /// Validates both the existence of a name and phone validation rules:
  /// Minimum of 10 digits, allowing international indicators (+).
  bool get isValid {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) return false;

    // Remove common formatting characters (spaces, dashes, parens)
    final digitCount = trimmedPhone.replaceAll(RegExp(r'\D'), '').length;
    if (digitCount < 10) return false;

    // Check against phone pattern (can start with '+' followed by numbers and spacing/dashes)
    final phoneRegex = RegExp(r'^\+?[0-9\-\s\(\)]+$');
    return phoneRegex.hasMatch(trimmedPhone);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaretakerModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          phone == other.phone &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => name.hashCode ^ phone.hashCode ^ updatedAt.hashCode;

  @override
  String toString() {
    return 'CaretakerModel(name: $name, phone: $phone, updatedAt: $updatedAt)';
  }
}
