// lib/services/emergency_audio_service.dart
//
// EmergencyAudioService — Offline Emergency Voice Assistant
//
// Responsibilities:
//   1. Play a high-pitch siren .mp3 (audioplayers, local asset)
//   2. Speak sequential first-aid voice instructions (flutter_tts, 100% offline,
//      uses device's built-in TTS engine — no API key, no internet required)
//   3. Guard against duplicate playback: once per seizure event
//   4. Provide stop() to silence everything when seizure is dismissed
//   5. Zero memory leaks — manages its own AudioPlayer lifecycle

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencyAudioService {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static final EmergencyAudioService _instance =
      EmergencyAudioService._internal();
  factory EmergencyAudioService() => _instance;
  EmergencyAudioService._internal();

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isPlaying = false;
  AudioPlayer? _sirenPlayer;
  FlutterTts? _tts;

  // ─── First-Aid Voice Script ───────────────────────────────────────────────
  // Spoken sequentially by the device's built-in TTS engine (offline).
  // Edit this list to customise the spoken instructions.
  static const List<String> _voiceInstructions = [
    'Seizure detected. Emergency alert activated.',
    'Do not panic. Stay calm.',
    'Do not restrain the patient.',
    'Gently turn the person onto their side.',
    'Cushion the head with something soft.',
    'Do not put anything in the patient\'s mouth.',
    'Call emergency services if the seizure lasts more than five minutes.',
    'Stay with the patient until the seizure ends.'
  ];

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Whether the emergency audio sequence is currently active.
  bool get isPlaying => _isPlaying;

  /// Call this when a seizure event is confirmed.
  /// Safe to call multiple times — will NOT restart if already playing.
  Future<void> playEmergencySequence() async {
    if (_isPlaying) return; // ← guard: one trigger per seizure event
    _isPlaying = true;

    try {
      await Future.wait([
        _playSiren(),
        _speakInstructions(),
      ]);
    } catch (_) {
      // Healthcare safety: never crash the app over audio failure
    }
  }

  /// Call this when the seizure alert is dismissed.
  /// Stops both siren and speech immediately.
  Future<void> stop() async {
    _isPlaying = false;
    await _sirenPlayer?.stop();
    _sirenPlayer?.dispose();
    _sirenPlayer = null;
    await _tts?.stop();
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /// Plays the siren audio file from assets/sounds/emergency_alarm.mp3.
  /// Falls back silently if the file is missing.
  Future<void> _playSiren() async {
    try {
      _sirenPlayer?.dispose();
      _sirenPlayer = AudioPlayer();

      // Set max volume
      await _sirenPlayer!.setVolume(1.0);

      // Release mode: keep playing until stop() is called
      await _sirenPlayer!.setReleaseMode(ReleaseMode.loop);

      await _sirenPlayer!.play(AssetSource('sounds/emergency_alarm.mp3'));
    } catch (_) {
      // Siren file missing or playback error — TTS still plays
    }
  }

  /// Speaks each instruction sequentially using the device's built-in TTS.
  /// 100% offline — uses Android TTS / iOS AVSpeechSynthesizer.
  Future<void> _speakInstructions() async {
    _tts ??= FlutterTts();

    // Configure TTS for maximum clarity and urgency
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.42);   // Slightly slower for emergency clarity
    await _tts!.setVolume(1.0);         // Maximum volume
    await _tts!.setPitch(1.0);          // Natural pitch

    // 1-second pause before voice starts (lets siren play first)
    await Future.delayed(const Duration(milliseconds: 1000));

    for (final instruction in _voiceInstructions) {
      if (!_isPlaying) break; // Aborts mid-sequence if stop() was called

      final completer = Completer<void>();

      // flutter_tts speaks asynchronously; we wait for each utterance
      // to complete before starting the next one.
      _tts!.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      _tts!.setCancelHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      await _tts!.speak(instruction);

      // Wait for this utterance to finish (max 8 seconds safety timeout)
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );

      // 400ms gap between instructions for natural pacing
      if (_isPlaying) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }
}
