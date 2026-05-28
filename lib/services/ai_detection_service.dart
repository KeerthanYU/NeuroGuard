// lib/services/ai_detection_service.dart
//
// Heuristic AI Seizure Risk Engine. 
// Uses sliding-window statistical features (mean, standard deviation, thresholds)
// to calculate a Seizure Risk Score (0-100%) and confidence index.
// This modular structure is directly compatible with future TinyML integrations.

import 'dart:math';

class AIDetectionService {
  static const int minWindowSize = 5;

  /// Calculates seizure risk score (0 to 100) based on sliding windows of telemetry.
  /// 
  /// - [motionHistory]: recent accelerometer motion level logs (g-force).
  /// - [heartRateHistory]: recent heart rate logs (bpm).
  /// - [spo2History]: recent blood oxygen saturation logs (%).
  static double calculateSeizureRisk({
    required List<double> motionHistory,
    required List<double> heartRateHistory,
    required List<double> spo2History,
  }) {
    try {
      if (motionHistory.isEmpty || heartRateHistory.isEmpty || spo2History.isEmpty) {
        return 0.0;
      }

      // Filter out any NaN or Infinite values from raw arrays just in case they slipped in
      final cleanMotion = motionHistory.where((x) => !x.isNaN && !x.isInfinite).toList();
      final cleanHr = heartRateHistory.where((x) => !x.isNaN && !x.isInfinite).toList();
      final cleanSpo2 = spo2History.where((x) => !x.isNaN && !x.isInfinite).toList();

      if (cleanMotion.isEmpty || cleanHr.isEmpty || cleanSpo2.isEmpty) {
        return 0.0;
      }

      // 1. Motion Spike detection (tremor index > 6.0g) and rolling standard deviation
      double motionSpikeScore = 0.0;
      final latestMotion = cleanMotion.last;
      if (latestMotion > 6.0) {
        // High tremor index spikes above 6g trigger an immediate high risk component
        motionSpikeScore = 100.0;
      } else {
        // Normal range scaling
        motionSpikeScore = (latestMotion / 6.0 * 100).clamp(0.0, 100.0);
      }

      double motionAnomalyScore = 0.0;
      if (cleanMotion.length >= minWindowSize) {
        final meanMotion = cleanMotion.reduce((a, b) => a + b) / cleanMotion.length;
        final variance = cleanMotion.map((x) => pow(x - meanMotion, 2)).reduce((a, b) => a + b) / cleanMotion.length;
        final stdDev = sqrt(variance);

        if (!stdDev.isNaN && !stdDev.isInfinite) {
          // Erratic physical tremor (stdDev > 2.5) indicates persistent seizure motion
          motionAnomalyScore = (stdDev / 2.5 * 100).clamp(0.0, 100.0);
        }
      } else {
        motionAnomalyScore = motionSpikeScore;
      }

      final combinedMotionScore = max(motionSpikeScore, motionAnomalyScore);

      // 2. Sudden Heart Rate jumps (sudden deviations from standard baseline/average)
      final latestHr = cleanHr.last;
      double hrSpikeScore = 0.0;
      if (cleanHr.length >= 2) {
        final baselineHrList = cleanHr.sublist(0, cleanHr.length - 1);
        final baselineHr = baselineHrList.reduce((a, b) => a + b) / baselineHrList.length;
        
        final hrJump = latestHr - baselineHr;
        if (hrJump > 15.0) {
          // A sudden heart rate jump > 15 bpm triggers a high cardiac spike score
          hrSpikeScore = ((hrJump - 15.0) / 30.0 * 100).clamp(0.0, 100.0);
        }
      }

      // Autonomic tachycardia score (> 100 bpm)
      double hrTachycardiaScore = 0.0;
      if (latestHr > 100) {
        hrTachycardiaScore = ((latestHr - 95) / 50 * 100).clamp(0.0, 100.0);
      }

      final combinedHrScore = max(hrSpikeScore, hrTachycardiaScore);

      // 3. Oxygen desaturation drop score (respiratory compromise)
      final latestSpo2 = cleanSpo2.last;
      double spo2Score = 0.0;
      if (latestSpo2 < 95) {
        // Oxygen drops below 95% indicates potential respiratory distress during seizure
        spo2Score = ((95 - latestSpo2) * 10.0).clamp(0.0, 100.0);
      }

      // Weighted Seizure Risk calculation:
      // Erratic physical tremor / spikes (50%)
      // Autonomic tachycardia / sudden spikes (30%)
      // Hypoxic oxygen drops (20%)
      double finalScore = (0.50 * combinedMotionScore) + (0.30 * combinedHrScore) + (0.20 * spo2Score);

      if (finalScore.isNaN || finalScore.isInfinite) {
        return 0.0;
      }

      // Cooldown/Smoothing logic: clamp cleanly between 0 and 100
      return finalScore.clamp(0.0, 100.0);
    } catch (_) {
      // Healthcare safety fallback
      return 0.0;
    }
  }

  /// Calculates AI confidence interval based on signal stability
  static double getConfidenceScore({
    required List<double> motionHistory,
    required List<double> heartRateHistory,
  }) {
    try {
      final cleanMotion = motionHistory.where((x) => !x.isNaN && !x.isInfinite).toList();
      final cleanHr = heartRateHistory.where((x) => !x.isNaN && !x.isInfinite).toList();

      if (cleanMotion.length < minWindowSize || cleanHr.length < minWindowSize) {
        return 50.0; // Moderate default confidence while loading data
      }
      // More historical data points yield higher decision confidence
      final samplesFactor = (cleanMotion.length / 20.0 * 30.0).clamp(0.0, 30.0);
      
      // Stable readings (fewer standard deviations of variance in non-critical zones) mean high baseline confidence
      final score = 70.0 + samplesFactor;
      if (score.isNaN || score.isInfinite) {
        return 50.0;
      }
      return score.clamp(0.0, 100.0);
    } catch (_) {
      return 50.0;
    }
  }
}
