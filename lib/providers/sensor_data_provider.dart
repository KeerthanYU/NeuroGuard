// lib/providers/sensor_data_provider.dart
//
// Provides a Stream<SensorData> that automatically selects the data source
// (mock or live) based on the current AppMode. All UI reads this provider
// – no mode checks inside widgets.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/models/sensor_data.dart';
import 'package:neuroguard/data/repositories/sensor_repository.dart';
import 'package:neuroguard/providers/app_mode_provider.dart';
import 'package:neuroguard/core/utils/constants.dart';

/// Independent patient ID holder — breaks the circular dependency between
/// sensorDataProvider and patientProvider. Updated by PatientNotifier.initialize().
final activePatientIdProvider = StateProvider<String>((ref) {
  return AppConstants.defaultPatientId;
});

// Provider that creates a repository for the current user/mode.
final sensorRepositoryProvider = Provider.autoDispose<SensorRepository>((ref) {
  ref.keepAlive();
  final mode = ref.watch(appModeProvider);
  final patientId = ref.watch(activePatientIdProvider);
  final targetId = patientId.isEmpty ? AppConstants.defaultPatientId : patientId;
  final repo = SensorRepository(mode: mode, uid: targetId);
  ref.onDispose(() => repo.dispose());
  return repo;
});

// StreamProvider exposing sensor data.
final sensorDataProvider = StreamProvider.autoDispose<SensorData?>((ref) {
  ref.keepAlive();
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.sensorStream;
});

// StreamProvider exposing connection status (true = online).
final connectionStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  ref.keepAlive();
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.connectionStatus;
});

// StreamProvider exposing device metadata (like lastSeen).
final deviceStreamProvider = StreamProvider.autoDispose<Map<dynamic, dynamic>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.deviceStream;
});
