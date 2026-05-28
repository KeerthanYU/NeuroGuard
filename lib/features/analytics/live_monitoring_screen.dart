// lib/features/analytics/live_monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/patient_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';
import 'package:neuroguard/core/widgets/charts.dart';

class LiveMonitoringScreen extends ConsumerWidget {
  const LiveMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProvider);
    final patient = patientState.patient;
    print('[LiveMonitoringScreen] Rebuilding. Connected=${patient.connected}');
    final cleanHrHistory = patientState.heartRateHistory
        .where((x) => !x.isNaN && !x.isInfinite)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: const Row(children: [
          Icon(Icons.monitor_heart_rounded,
              color: AppTheme.primaryCyan, size: 22),
          SizedBox(width: 8),
          Text('Live Monitoring'),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              PulseIndicator(
                color: patient.connectionState == 'LIVE'
                    ? AppTheme.safeGreen
                    : (patient.connectionState == 'DEGRADED'
                        ? AppTheme.warningYellow
                        : (patient.connectionState == 'RECONNECTING'
                            ? AppTheme.warningYellow
                            : AppTheme.emergencyRed)),
              ),
              const SizedBox(width: 6),
              Text(
                patient.connectionState == 'LIVE'
                    ? 'LIVE'
                    : (patient.connectionState == 'DEGRADED'
                        ? 'DEGRADED'
                        : (patient.connectionState == 'RECONNECTING'
                            ? 'RECONNECTING'
                            : 'OFFLINE')),
                style: TextStyle(
                  fontFamily: AppTheme.fontInter,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: patient.connectionState == 'LIVE'
                      ? AppTheme.safeGreen
                      : (patient.connectionState == 'DEGRADED'
                          ? AppTheme.warningYellow
                          : (patient.connectionState == 'RECONNECTING'
                              ? AppTheme.warningYellow
                              : AppTheme.emergencyRed)),
                  letterSpacing: 1.2,
                ),
              ),
            ]),
          ),
        ],
      ),
      body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device info banner
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: patient.connectionState == 'LIVE'
                        ? AppTheme.safeGreen.withValues(alpha: 0.3)
                        : (patient.connectionState == 'DEGRADED'
                            ? AppTheme.warningYellow.withValues(alpha: 0.3)
                            : (patient.connectionState == 'RECONNECTING'
                                ? AppTheme.warningYellow.withValues(alpha: 0.3)
                                : AppTheme.emergencyRed.withValues(alpha: 0.2))),
                    child: Column(
                      children: [
                        Row(children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: patient.connectionState == 'LIVE'
                                    ? [
                                        AppTheme.safeGreen.withValues(alpha: 0.2),
                                        AppTheme.primaryCyan.withValues(alpha: 0.1)
                                      ]
                                    : (patient.connectionState == 'DEGRADED'
                                        ? [
                                            AppTheme.warningYellow.withValues(alpha: 0.2),
                                            AppTheme.warningYellow.withValues(alpha: 0.05)
                                          ]
                                        : (patient.connectionState == 'RECONNECTING'
                                            ? [
                                                AppTheme.warningYellow.withValues(alpha: 0.2),
                                                AppTheme.warningYellow.withValues(alpha: 0.05)
                                              ]
                                            : [
                                                AppTheme.emergencyRed.withValues(alpha: 0.15),
                                                AppTheme.emergencyRed.withValues(alpha: 0.05)
                                              ])),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.watch_rounded,
                                color: patient.connectionState == 'LIVE'
                                    ? AppTheme.safeGreen
                                    : (patient.connectionState == 'DEGRADED'
                                        ? AppTheme.warningYellow
                                        : (patient.connectionState == 'RECONNECTING'
                                            ? AppTheme.warningYellow
                                            : AppTheme.emergencyRed)),
                                size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(patient.deviceId,
                                  style: AppTheme.headingSM),
                              Text(
                                  patient.connectionState == 'LIVE'
                                      ? 'Connected — Streaming data'
                                      : (patient.connectionState == 'DEGRADED'
                                          ? 'Connection Degraded — High Jitter'
                                          : (patient.connectionState == 'RECONNECTING'
                                              ? 'Reconnecting — Restoring link'
                                              : 'Disconnected')),
                                  style: AppTheme.bodyMD),
                            ]),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                            Text('Battery',
                                style: AppTheme.label.copyWith(fontSize: 10)),
                            Text('${patient.battery}%',
                                style: TextStyle(
                                    fontFamily: AppTheme.fontPoppins,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: patient.battery > 20
                                        ? AppTheme.safeGreen
                                        : AppTheme.emergencyRed)),
                          ]),
                        ]),
                        if (patient.connected) ...[
                          const SizedBox(height: 12),
                          const Divider(color: AppTheme.divider, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bluetooth_audio_rounded,
                                      color: AppTheme.primaryCyan, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BLE v5.2',
                                    style: AppTheme.bodySM.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.signal_cellular_alt_rounded,
                                      color: AppTheme.accentCyan, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '-67 dBm (RSSI)',
                                    style: AppTheme.bodySM.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.cloud_done_rounded,
                                      color: AppTheme.safeGreen, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sync: 14ms',
                                    style: AppTheme.bodySM.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Real-Time Sinus ECG Waveform ───────────────────
                  const SectionHeader(title: 'Intensive Care Telemetry — ECG Waveform'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                PulseIndicator(
                                  color: patient.seizureDetected ? AppTheme.emergencyRed : AppTheme.accentCyan,
                                  size: 8,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  patient.seizureDetected ? 'SEIZURE ANOMALY TRACED' : 'SINUS RHYTHM ACTIVE',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontInter,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: patient.seizureDetected ? AppTheme.emergencyRed : AppTheme.accentCyan,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${patient.heartRate} bpm',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: patient.seizureDetected ? AppTheme.emergencyRed : AppTheme.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ECGChart(
                          heartRate: patient.heartRate,
                          isCritical: patient.seizureDetected,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── AI Epilepsy Risk Assessment ──────────────────────────
                  const SectionHeader(title: 'AI Seizure Risk Analysis'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          borderColor: patientState.seizureRiskScore > 75.0
                              ? AppTheme.emergencyRed.withValues(alpha: 0.5)
                              : AppTheme.glassBorder,
                          child: Column(
                            children: [
                              RadialGauge(
                                value: patientState.seizureRiskScore,
                                max: 100.0,
                                label: 'SEIZURE RISK',
                                color: patientState.seizureRiskScore > 75.0
                                    ? AppTheme.emergencyRed
                                    : (patientState.seizureRiskScore > 40.0 ? AppTheme.warningYellow : AppTheme.safeGreen),
                                size: 90,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                patientState.seizureRiskScore > 75.0
                                    ? 'CRITICAL ALERT'
                                    : (patientState.seizureRiskScore > 40.0 ? 'ELEVATED ACTIVITY' : 'SAFE RHYTHM'),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: patientState.seizureRiskScore > 75.0
                                      ? AppTheme.emergencyRed
                                      : (patientState.seizureRiskScore > 40.0 ? AppTheme.warningYellow : AppTheme.safeGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Column(
                            children: [
                              RadialGauge(
                                value: patientState.aiConfidenceScore,
                                max: 100.0,
                                label: 'AI CONFIDENCE',
                                color: AppTheme.primaryCyan,
                                size: 90,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'TINYML STATS: OK',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Heart rate trend chart
                  const SectionHeader(title: 'Heart Rate Trend — Vitals History'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('${patient.heartRate}',
                              style: const TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.emergencyRed,
                                  height: 1)),
                          const Text('bpm (Heart Rate)',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ]),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                          _infoChip('MIN',
                              cleanHrHistory.isEmpty ? '0' : '${cleanHrHistory.reduce((a, b) => a < b ? a : b).toInt()}',
                              AppTheme.primaryCyan),
                          const SizedBox(height: 6),
                          _infoChip('MAX',
                              cleanHrHistory.isEmpty ? '0' : '${cleanHrHistory.reduce((a, b) => a > b ? a : b).toInt()}',
                              AppTheme.emergencyRed),
                        ]),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                          height: 130,
                          child: HeartRateChart(
                              data: patientState.heartRateHistory)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Oxygen Saturation SpO2 Trend Chart
                  const SectionHeader(title: 'Oxygen Saturation Trend — SpO₂ History'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('${patient.spo2}%',
                              style: const TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryCyan,
                                  height: 1)),
                          const Text('Oxygen Level',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (patient.spo2 > 94 ? AppTheme.safeGreen : AppTheme.emergencyRed).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            patient.spo2 > 94 ? 'NORMAL' : 'HYPOXIC DROP',
                            style: TextStyle(
                              fontFamily: AppTheme.fontInter,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: patient.spo2 > 94 ? AppTheme.safeGreen : AppTheme.emergencyRed,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                          height: 130,
                          child: SpO2TrendChart(
                              data: patientState.spo2History)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Motion chart
                  const SectionHeader(title: 'Motion Intensity — Live Tremors'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              patient.motionLevel.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.warningYellow,
                                  height: 1)),
                          const Text('g-force (Movement)',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _motionStatusColor(patient.motionLevel)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _motionStatusColor(
                                        patient.motionLevel)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            patient.motionStatus.toUpperCase(),
                            style: TextStyle(
                                fontFamily: AppTheme.fontInter,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _motionStatusColor(
                                    patient.motionLevel),
                                letterSpacing: 0.5),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                          height: 130,
                          child: MotionChart(
                              data: patientState.motionHistory,
                              seizureDetected: patientState.patient.seizureDetected)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Sensor Data Grid
                  const SectionHeader(title: 'Sensor Readings'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _sensorTile('SpO₂', '${patient.spo2}%', Icons.air_rounded,
                          AppTheme.primaryCyan, patient.spo2 > 94 ? 'Normal' : 'Hypoxia'),
                      _sensorTile(
                          'Temp',
                          '36.8°C',
                          Icons.thermostat_rounded,
                          AppTheme.warningYellow,
                          'Normal'),
                      _sensorTile(
                          'Seizure',
                          patient.seizureDetected ? 'YES' : 'NO',
                          Icons.warning_amber_rounded,
                          patient.seizureDetected
                              ? AppTheme.emergencyRed
                              : AppTheme.safeGreen,
                          patient.seizureDetected ? 'Alert' : 'Safe'),
                      _sensorTile(
                          'Signal',
                          patient.connectionState == 'LIVE'
                              ? 'Strong'
                              : (patient.connectionState == 'DEGRADED'
                                  ? 'Jittery'
                                  : (patient.connectionState == 'RECONNECTING' ? 'Restoring' : 'Lost')),
                          Icons.wifi_rounded,
                          patient.connectionState == 'LIVE'
                              ? AppTheme.safeGreen
                              : (patient.connectionState == 'DEGRADED'
                                  ? AppTheme.warningYellow
                                  : (patient.connectionState == 'RECONNECTING'
                                      ? AppTheme.warningYellow
                                      : AppTheme.emergencyRed)),
                          patient.connectionState == 'LIVE'
                              ? 'Good'
                              : (patient.connectionState == 'DEGRADED'
                                  ? 'Degraded'
                                  : (patient.connectionState == 'RECONNECTING'
                                      ? 'Syncing'
                                      : 'Offline'))),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ',
          style: const TextStyle(
              fontFamily: AppTheme.fontInter,
              fontSize: 10,
              color: AppTheme.textMuted)),
      Text(value,
          style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color)),
    ]);
  }

  Widget _sensorTile(String label, String value, IconData icon,
      Color color, String status) {
    return GlassCard(
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text(status,
                style: TextStyle(
                    fontFamily: AppTheme.fontInter,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label, style: AppTheme.label.copyWith(fontSize: 10)),
      ]),
    );
  }

  Color _motionStatusColor(double val) {
    if (val >= 9) return AppTheme.emergencyRed;
    if (val >= 6) return AppTheme.warningYellow;
    return AppTheme.safeGreen;
  }
}
