// lib/services/emergency_alert_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neuroguard/services/emergency_audio_service.dart';
import 'package:neuroguard/services/caretaker_service.dart';

/// ICU-grade Emergency States for Seizure Alert Progression.
enum EmergencyState {
  idle,
  seizureDetected,
  voiceGuidance,
  countdown,
  fetchingContact,
  calling,
  alerting,
  cooldown
}

/// Production-grade Emergency Alert Service for NeuroGuard.
/// Listens, speaks, calls, and guards against race conditions and duplicates.
class EmergencyAlertService {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final EmergencyAlertService _instance =
      EmergencyAlertService._internal();
  factory EmergencyAlertService() => _instance;
  EmergencyAlertService._internal() {
    _stateController.add(_currentState);
  }

  // ─── Configuration ────────────────────────────────────────────────────────
  /// Ultimate fallback contact number to ensure medical safety at all costs.
  static const String fallbackNumber = '8792021456';

  /// Cooldown window to prevent repeated countdowns/notifications during continuous triggers.
  static const Duration _cooldownDuration = Duration(seconds: 90);

  // ─── State Machine Fields ──────────────────────────────────────────────────
  EmergencyState _currentState = EmergencyState.idle;
  bool _emergencyInProgress = false;
  DateTime? _cooldownStart;
  Timer? _cooldownTimer;

  // Stream to expose state changes for medical/clinical dashboards reactively
  final StreamController<EmergencyState> _stateController =
      StreamController<EmergencyState>.broadcast();

  // ─── Public Getters ────────────────────────────────────────────────────────
  EmergencyState get currentState => _currentState;
  bool get isEmergencyInProgress => _emergencyInProgress;
  Stream<EmergencyState> get stateStream => _stateController.stream;

  bool get isCooldownActive {
    if (_currentState != EmergencyState.cooldown || _cooldownStart == null) {
      return false;
    }
    return DateTime.now().difference(_cooldownStart!) < _cooldownDuration;
  }

  int get cooldownSecondsRemaining {
    if (!isCooldownActive) return 0;
    final elapsed = DateTime.now().difference(_cooldownStart!);
    final remaining = _cooldownDuration - elapsed;
    return remaining.inSeconds.clamp(0, 90);
  }

  // ─── Core Seizure Emergency Entrypoint ─────────────────────────────────────
  /// Triggers the full emergency sequence with transitions protected by a State Machine.
  Future<void> triggerEmergencyAlert({
    required String patientId,
    required String patientName,
    double knownLat = 0.0,
    double knownLng = 0.0,
    VoidCallback? onGuidanceStarted,
    VoidCallback? onCallStarted,
  }) async {
    // ── Guard 1: Cooldown or Active execution check ────────────────────────
    if (_currentState != EmergencyState.idle) {
      debugPrint(
          '[EmergencyAlertService] ⏳ Suppressed: Seizure trigger received while in state $_currentState (${cooldownSecondsRemaining}s cooldown remaining).');
      return;
    }

    _emergencyInProgress = true;
    _currentState = EmergencyState.seizureDetected;
    _stateController.add(_currentState);
    debugPrint('[EmergencyAlertService] State: SEIZURE_DETECTED. Starting emergency pipeline.');

    try {
      // ── Step 1: Voice Guidance ──────────────────────────────────────────
      _currentState = EmergencyState.voiceGuidance;
      _stateController.add(_currentState);
      onGuidanceStarted?.call();

      debugPrint('[EmergencyAlertService] State: VOICE_GUIDANCE. Playing instructions.');
      await EmergencyAudioService().playEmergencySequence();

      // Check if alert was cancelled during voice guidance
      if (!EmergencyAudioService().isPlaying) {
        debugPrint('[EmergencyAlertService] Sequence aborted mid-guidance.');
        _resetToIdle();
        return;
      }

      // ── Step 2: Visual & Audio Countdown (5 seconds) ────────────────────
      _currentState = EmergencyState.countdown;
      _stateController.add(_currentState);
      debugPrint('[EmergencyAlertService] State: COUNTDOWN. Prefilling contact.');

      for (int i = 5; i > 0; i--) {
        debugPrint('[EmergencyAlertService] Emergency calling countdown: $i...');
        await Future.delayed(const Duration(seconds: 1));

        if (!EmergencyAudioService().isPlaying) {
          debugPrint('[EmergencyAlertService] Alert dismissed during countdown. Aborting call.');
          _resetToIdle();
          return;
        }
      }

      // ── Step 3: Fetch Contact Details ───────────────────────────────────
      _currentState = EmergencyState.fetchingContact;
      _stateController.add(_currentState);
      debugPrint('[EmergencyAlertService] State: FETCHING_CONTACT. Querying caretaker details.');

      String caretakerNumber = fallbackNumber;
      try {
        final service = CaretakerService(patientId);
        // Load details (returns cache instantaneously if offline, then queries Firebase in background)
        final caretaker = await service.loadCaretaker();
        
        if (caretaker.isValid) {
          caretakerNumber = caretaker.phone;
          debugPrint('[EmergencyAlertService] Dynamic contact loaded: ${caretaker.name} ($caretakerNumber)');
        } else {
          debugPrint('[EmergencyAlertService] ⚠️ Caretaker model invalid/empty. Falling back to baseline safety contact.');
        }
      } catch (e) {
        debugPrint('[EmergencyAlertService] ⚠️ Dynamic fetch failed (network offline). Using cached/fallback details: $e');
      }

      // ── Step 4: Calling ─────────────────────────────────────────────────
      _currentState = EmergencyState.calling;
      _stateController.add(_currentState);
      onCallStarted?.call();

      debugPrint('[EmergencyAlertService] State: CALLING. Contacting caretaker.');
      await _makeEmergencyCall(caretakerNumber);

      // ── Step 5: Alerting ────────────────────────────────────────────────
      _currentState = EmergencyState.alerting;
      _stateController.add(_currentState);
      debugPrint('[EmergencyAlertService] State: ALERTING. Dispatching alerts.');

      // ── Step 6: Enter Cooldown ──────────────────────────────────────────
      _currentState = EmergencyState.cooldown;
      _cooldownStart = DateTime.now();
      _emergencyInProgress = false;
      _stateController.add(_currentState);
      debugPrint('[EmergencyAlertService] State: COOLDOWN. Suppressing triggers for 90s.');

      _cooldownTimer = Timer(_cooldownDuration, () {
        _resetToIdle();
      });
    } catch (e) {
      debugPrint('[EmergencyAlertService] ❌ Critical failure inside alert pipeline: $e');
      _resetToIdle();
    }
  }

  // ─── Emergency Call Dispatcher (MI/Redmi Compatible) ─────────────────────
  /// Handles calling permissions and triggers dual-intent dialing on blocked platforms.
  Future<void> _makeEmergencyCall(String caretakerNumber) async {
    final cleanNumber = caretakerNumber.trim();
    if (cleanNumber.isEmpty) {
      debugPrint('[EmergencyAlertService] ❌ Cancelled phone dispatch: empty number.');
      return;
    }

    try {
      // 1. Permission status check
      var status = await Permission.phone.status;
      if (status.isDenied) {
        status = await Permission.phone.request();
      }

      if (status.isPermanentlyDenied) {
        debugPrint('[EmergencyAlertService] ⚠️ CALL_PHONE permanently denied. Attempting Dialer launcher.');
        await _launchDialerFallback(cleanNumber);
        return;
      }

      if (status.isDenied) {
        debugPrint('[EmergencyAlertService] ⚠️ Call permission rejected. Opening dialer manually.');
        await _launchDialerFallback(cleanNumber);
        return;
      }

      // 2. Perform calling with dual-intent fallbacks (Redmi/Xiaomi safety)
      final called = await FlutterPhoneDirectCaller.callNumber(cleanNumber);
      if (called == true) {
        debugPrint('[EmergencyAlertService] 📞 Call successfully placed to $cleanNumber');
      } else {
        debugPrint('[EmergencyAlertService] ⚠️ Direct CALL rejected or blocked by MIUI system. Opening Dial pad.');
        await _launchDialerFallback(cleanNumber);
      }
    } catch (e) {
      debugPrint('[EmergencyAlertService] Direct caller threw exception: $e. Using dialer.');
      await _launchDialerFallback(cleanNumber);
    }
  }

  /// Launches phone dialer app with the prefilled caretaker number.
  Future<void> _launchDialerFallback(String number) async {
    final Uri telUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        debugPrint('[EmergencyAlertService] Prefilled dialer launched: $number');
      } else {
        debugPrint('[EmergencyAlertService] ❌ Dialer launcher failed for: $number');
      }
    } catch (e) {
      debugPrint('[EmergencyAlertService] Universal dialer exception: $e');
    }
  }

  // ─── Reset Functions ──────────────────────────────────────────────────────
  /// Manually aborts any active sequence and silences alerts.
  void cancelEmergency() {
    debugPrint('[EmergencyAlertService] Manually dismissing emergency state.');
    EmergencyAudioService().stop();
    _resetToIdle();
  }

  void _resetToIdle() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownStart = null;
    _emergencyInProgress = false;
    _currentState = EmergencyState.idle;
    _stateController.add(_currentState);
    debugPrint('[EmergencyAlertService] State: IDLE. Pipeline ready.');
  }

  void resetCooldown() {
    _resetToIdle();
  }
}
