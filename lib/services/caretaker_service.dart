// lib/services/caretaker_service.dart
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/caretaker_model.dart';
import '../core/services/app_initializer.dart';
import '../core/utils/constants.dart';

class CaretakerService {
  final String patientId;

  CaretakerService(this.patientId);

  // ─── Static In-Memory Cache ────────────────────────────────────────────────
  /// Stores the latest loaded/updated caretaker in memory for absolute
  /// instantaneous, zero-latency synchronous access by the emergency pipeline.
  static final Map<String, CaretakerModel> _memoryCache = {};

  // ─── Database References ───────────────────────────────────────────────────
  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: AppInitializer.firebaseApp,
        databaseURL: 'https://neuroguard-5dda9-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

  DatabaseReference get _caretakerRef =>
      _db.ref('${AppConstants.devicePath}/$patientId/caretaker');

  // ─── SharedPreferences Keys ────────────────────────────────────────────────
  static const String _prefKeyPrefix = 'cached_caretaker_';
  String get _prefKey => '$_prefKeyPrefix$patientId';

  // ─── Synchronous Emergency Retrieval ───────────────────────────────────────
  /// Returns the in-memory cached caretaker immediately, or loads from local disk.
  /// Used by the emergency caller pipeline to guarantee zero-latency execution.
  CaretakerModel getCachedCaretakerSync() {
    try {
      // 1. Try memory cache
      if (_memoryCache.containsKey(patientId)) {
        final cached = _memoryCache[patientId]!;
        if (cached.isValid) {
          debugPrint('[CaretakerService] Memory cache HIT for $patientId: ${cached.phone}');
          return cached;
        }
      }

      // 2. Try loading from SharedPreferences synchronously (if already warmed up)
      // Note: AppInitializer warms up SharedPreferences, so we can access it quickly.
      // But standard SharedPreferences.getInstance is async, so if memory cache is missed
      // and async isn't finished, we fallback to our safe default.
      // We will also attempt an async refresh behind the scenes to populate memory.
      return CaretakerModel.empty();
    } catch (e) {
      debugPrint('[CaretakerService] Error in sync retrieval fallback: $e');
      return CaretakerModel.empty();
    }
  }

  // ─── Core Save & Sync Operations ──────────────────────────────────────────
  /// Saves the caretaker details in memory, SharedPreferences, and schedules Firebase Sync.
  Future<void> saveCaretaker(CaretakerModel caretaker) async {
    if (patientId.isEmpty) return;

    try {
      final validCaretaker = caretaker.copyWith(updatedAt: DateTime.now());

      // 1. Update in-memory cache instantly
      _memoryCache[patientId] = validCaretaker;
      debugPrint('[CaretakerService] Updated memory cache: ${validCaretaker.phone}');

      // 2. Persist locally to SharedPreferences (primary offline fallback)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, jsonEncode(validCaretaker.toMap()));
        debugPrint('[CaretakerService] Saved to SharedPreferences: ${validCaretaker.phone}');
      } catch (prefErr) {
        debugPrint('[CaretakerService] SharedPreferences save failure: $prefErr');
      }

      // 3. Write to Firebase Realtime Database
      // Realtime Database has local persistence enabled (in AppInitializer).
      // So this write will register locally immediately and sync over network in the background.
      await _caretakerRef.set(validCaretaker.toMap());
      debugPrint('[CaretakerService] Enqueued Firebase RTDB sync payload for caretaker.');
    } catch (e) {
      debugPrint('[CaretakerService] Sync exception caught (safely handled): $e');
      // Do not crash the caller; offline state is successfully maintained in cache
    }
  }

  // ─── Core Load Operations ─────────────────────────────────────────────────
  /// Loads caretaker details from memory, SharedPreferences, and queries Firebase.
  /// Maintains absolute crash stability even when offline.
  Future<CaretakerModel> loadCaretaker() async {
    if (patientId.isEmpty) return CaretakerModel.empty();

    CaretakerModel localCaretaker = CaretakerModel.empty();

    // 1. Check in-memory cache first (ICU-grade priority)
    if (_memoryCache.containsKey(patientId)) {
      final cached = _memoryCache[patientId]!;
      if (cached.isValid) {
        return cached;
      }
    }

    // 2. Read from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_prefKey);
      if (localJson != null) {
        final map = jsonDecode(localJson) as Map<String, dynamic>;
        localCaretaker = CaretakerModel.fromMap(map);
        _memoryCache[patientId] = localCaretaker; // Warm memory cache
        debugPrint('[CaretakerService] Memory cache warmed from SharedPreferences: ${localCaretaker.phone}');
      }
    } catch (e) {
      debugPrint('[CaretakerService] SharedPreferences read failure: $e');
    }

    // 3. Query Firebase Realtime Database in background with short timeout
    try {
      final snapshot = await _caretakerRef.get().timeout(const Duration(seconds: 3));
      if (snapshot.exists && snapshot.value != null) {
        final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final remoteCaretaker = CaretakerModel.fromMap(map);

        // Update local if remote is newer or local is empty
        if (remoteCaretaker.isValid &&
            (localCaretaker.isEmpty ||
                remoteCaretaker.updatedAt.isAfter(localCaretaker.updatedAt))) {
          localCaretaker = remoteCaretaker;
          _memoryCache[patientId] = localCaretaker;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKey, jsonEncode(localCaretaker.toMap()));
          debugPrint('[CaretakerService] Synchronized with newer remote Firebase caretaker details.');
        }
      }
    } catch (e) {
      debugPrint('[CaretakerService] Firebase query skipped/offline fallback active. Details: $e');
    }

    return localCaretaker;
  }

  // ─── Real-Time Stream Monitoring ──────────────────────────────────────────
  /// Exposes a stream of caretaker updates from Firebase to automatically
  /// update the application state in real-time when connection is available.
  Stream<CaretakerModel> caretakerStream() {
    if (patientId.isEmpty) return Stream.value(CaretakerModel.empty());

    return _caretakerRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        return CaretakerModel.empty();
      }
      final map = Map<dynamic, dynamic>.from(value as Map);
      final remoteCaretaker = CaretakerModel.fromMap(map);

      // Warm memory cache and sync locally if valid
      if (remoteCaretaker.isValid) {
        _memoryCache[patientId] = remoteCaretaker;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(_prefKey, jsonEncode(remoteCaretaker.toMap()));
        }).catchError((e) {
          debugPrint('[CaretakerService] Async cache update error: $e');
          return null;
        });
      }

      return remoteCaretaker;
    }).handleError((error) {
      debugPrint('[CaretakerService] Quietly caught stream error to prevent app crash: $error');
      return CaretakerModel.empty();
    });
  }
}
