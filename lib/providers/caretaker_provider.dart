// lib/providers/caretaker_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/caretaker_model.dart';
import '../services/caretaker_service.dart';
import 'sensor_data_provider.dart';

/// State representation for caretakers.
class CaretakerState {
  final CaretakerModel caretaker;
  final bool isLoading;
  final String? error;

  const CaretakerState({
    required this.caretaker,
    this.isLoading = false,
    this.error,
  });

  CaretakerState copyWith({
    CaretakerModel? caretaker,
    bool? isLoading,
    String? error,
  }) {
    return CaretakerState(
      caretaker: caretaker ?? this.caretaker,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier responsible for managing caregiver states and syncing them.
class CaretakerNotifier extends StateNotifier<CaretakerState> {
  final Ref ref;
  final String patientId;
  StreamSubscription? _caretakerSubscription;

  CaretakerNotifier(this.ref, this.patientId)
      : super(CaretakerState(caretaker: CaretakerModel.empty(), isLoading: true)) {
    _initializeCaretaker();
  }

  /// Bootstrapping: Loads cached data synchronously/instantly, then listens to live updates.
  Future<void> _initializeCaretaker() async {
    _caretakerSubscription?.cancel();
    _caretakerSubscription = null;

    if (patientId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    final service = CaretakerService(patientId);

    // 1. Immediately fetch from cache (memory or SharedPreferences) to prevent blank UI or startup lag
    final cached = await service.loadCaretaker();
    state = CaretakerState(caretaker: cached, isLoading: false);

    // 2. Establish single, stable background stream listener on Firebase Realtime Database
    _caretakerSubscription = service.caretakerStream().listen(
      (updatedCaretaker) {
        if (updatedCaretaker.isEmpty) {
          // If remote is empty, but we already have valid cached caretaker, prioritize local details
          return;
        }

        // De-duplicate updates to prevent rebuild loops/storms
        if (state.caretaker.phone != updatedCaretaker.phone ||
            state.caretaker.name != updatedCaretaker.name ||
            state.caretaker.updatedAt != updatedCaretaker.updatedAt) {
          state = state.copyWith(caretaker: updatedCaretaker);
        }
      },
      onError: (err) {
        state = state.copyWith(
          error: 'Firebase stream error: $err',
          isLoading: false,
        );
      },
    );
  }

  /// Updates caretaker details, persists them locally, and triggers Firebase Realtime Database synchronization.
  Future<bool> updateCaretaker({
    required String name,
    required String phone,
  }) async {
    if (patientId.isEmpty) return false;

    state = state.copyWith(isLoading: true);

    final updated = CaretakerModel(
      name: name.trim(),
      phone: phone.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      final service = CaretakerService(patientId);
      await service.saveCaretaker(updated);
      state = CaretakerState(caretaker: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update caretaker: $e',
        isLoading: false,
      );
      return false;
    }
  }

  @override
  void dispose() {
    _caretakerSubscription?.cancel();
    super.dispose();
  }
}

/// Provider exposing the reactive caretaker state, automatically reinitializing on active patient changes.
final caretakerProvider =
    StateNotifierProvider.autoDispose<CaretakerNotifier, CaretakerState>((ref) {
  // Watch activePatientIdProvider to rebuild and reload the caretaker details whenever patientId changes.
  final patientId = ref.watch(activePatientIdProvider);
  final notifier = CaretakerNotifier(ref, patientId);
  
  // Keep alive so states are retained during quick transitions
  ref.keepAlive();
  return notifier;
});
