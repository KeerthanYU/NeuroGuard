// lib/features/dashboard/caregiver_dashboard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/patient_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';
import 'package:neuroguard/core/widgets/charts.dart';

class CaregiverDashboard extends ConsumerStatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  ConsumerState<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends ConsumerState<CaregiverDashboard> {
  bool _isOverlayMinimized = false;

  static const List<Map<String, String>> _contacts = [
    {'name': 'Dr. Sarah Chen', 'role': 'Neurologist', 'phone': '+1-555-0101'},
    {'name': 'Michael Johnson', 'role': 'Family Caregiver', 'phone': '+1-555-0102'},
    {'name': 'NeuroGuard Helpline', 'role': '24/7 Support', 'phone': '+1-800-NEURO'},
  ];

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final patient = patientState.patient;
    final alerts = patientState.alerts;

    // Automatically maximize overlay if a new seizure is triggered and overlay is minimized
    if (!patientState.hasSeizureAlert && _isOverlayMinimized) {
      setState(() {
        _isOverlayMinimized = false;
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: const Row(children: [
          Icon(Icons.people_rounded, color: AppTheme.primaryCyan, size: 22),
          SizedBox(width: 8),
          Text('Caregiver Dashboard'),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blinking Emergency Banner at top if seizure is active
                  if (patientState.hasSeizureAlert)
                    BlinkingEmergencyBanner(
                      patientName: patient.patientName.isNotEmpty ? patient.patientName : 'Alex Johnson',
                      heartRate: patient.heartRate,
                      motionLevel: patient.motionLevel,
                      onAcknowledge: () {
                        ref.read(patientProvider.notifier).dismissSeizureAlert();
                      },
                      onResolve: () {
                        ref.read(patientProvider.notifier).dismissSeizureAlert();
                      },
                      emergencyStatus: patientState.emergencyStatus,
                    ),

                  // ─── Patient Status Card ──────────────────────────────
                  GlassCard(
                    borderColor: patient.seizureDetected
                        ? AppTheme.emergencyRed.withValues(alpha: 0.5)
                        : (patient.connectionState == 'LIVE'
                            ? AppTheme.safeGreen.withValues(alpha: 0.3)
                            : AppTheme.emergencyRed.withValues(alpha: 0.3)),
                    gradientColors: patient.seizureDetected
                        ? [
                            AppTheme.emergencyRed.withValues(alpha: 0.12),
                            AppTheme.bgCard,
                          ]
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: patient.seizureDetected
                                      ? [
                                          AppTheme.emergencyRed.withValues(alpha: 0.2),
                                          AppTheme.emergencyOrange.withValues(alpha: 0.1)
                                        ]
                                      : [
                                          AppTheme.safeGreen.withValues(alpha: 0.2),
                                          AppTheme.primaryCyan.withValues(alpha: 0.1)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  (patient.patientName.isNotEmpty
                                          ? patient.patientName.substring(0, 1)
                                          : 'P')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontPoppins,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: patient.seizureDetected
                                        ? AppTheme.emergencyRed
                                        : AppTheme.safeGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.patientName.isNotEmpty ? patient.patientName : 'Alex Johnson',
                                  style: AppTheme.headingSM,
                                ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  PulseIndicator(
                                    color: patient.connectionState == 'LIVE'
                                        ? AppTheme.safeGreen
                                        : AppTheme.emergencyRed,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    patient.connectionState == 'LIVE'
                                        ? 'Device Connected'
                                        : 'Device Offline',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontInter,
                                      fontSize: 12,
                                      color: patient.connectionState == 'LIVE'
                                          ? AppTheme.safeGreen
                                          : AppTheme.emergencyRed,
                                    ),
                                  ),
                                ]),
                              ],
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: patient.seizureDetected
                                    ? AppTheme.emergencyRed.withValues(alpha: 0.15)
                                    : AppTheme.safeGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: patient.seizureDetected
                                      ? AppTheme.emergencyRed.withValues(alpha: 0.4)
                                      : AppTheme.safeGreen.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                patient.seizureDetected ? '⚠ ALERT' : '✓ Safe',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: patient.seizureDetected
                                      ? AppTheme.emergencyRed
                                      : AppTheme.safeGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.divider),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _statItem('Heart Rate',
                                    '${patient.heartRate} bpm',
                                    AppTheme.emergencyRed)),
                            Expanded(
                                child: _statItem('Motion',
                                    '${patient.motionLevel.toStringAsFixed(1)} g',
                                    AppTheme.warningYellow)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Remote Monitoring ──────────────────────────────────────
                  const SectionHeader(title: 'Remote Monitoring'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      SizedBox(
                          height: 100,
                          child: HeartRateChart(
                              data: patientState.heartRateHistory)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ─── Recent Alerts ────────────────────────────────────
                  SectionHeader(
                    title: 'Recent Alerts',
                    action: 'View All',
                    onAction: () => Navigator.pushNamed(context, '/history'),
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const GlassCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No recent alerts',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontFamily: AppTheme.fontInter)),
                        ),
                      ),
                    )
                  else
                    ...alerts.take(3).map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            borderColor: a.resolved
                                ? AppTheme.glassBorder
                                : AppTheme.emergencyRed.withValues(alpha: 0.3),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (a.isCritical
                                            ? AppTheme.emergencyRed
                                            : AppTheme.warningYellow)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    a.isCritical
                                        ? Icons.emergency_rounded
                                        : Icons.warning_rounded,
                                    color: a.isCritical
                                        ? AppTheme.emergencyRed
                                        : AppTheme.warningYellow,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(a.severity,
                                          style: TextStyle(
                                              fontFamily: AppTheme.fontPoppins,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: a.isCritical
                                                  ? AppTheme.emergencyRed
                                                  : AppTheme.warningYellow)),
                                      Text(a.formattedTime,
                                          style: AppTheme.bodySM),
                                    ],
                                  ),
                                ),
                                Text('HR: ${a.heartRate}',
                                    style: const TextStyle(
                                        fontFamily: AppTheme.fontInter,
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),

                  // ─── Emergency Contacts ───────────────────────────────
                  const SectionHeader(title: 'Emergency Contacts'),
                  const SizedBox(height: 12),
                  ..._contacts.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.primaryCyan
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  (c['name'] != null && c['name']!.isNotEmpty)
                                      ? c['name']!.substring(0, 1)
                                      : 'C',
                                  style: const TextStyle(
                                      fontFamily: AppTheme.fontPoppins,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name']!,
                                        style: AppTheme.headingSM
                                            .copyWith(fontSize: 13)),
                                    Text(c['role']!,
                                        style: AppTheme.bodyMD
                                            .copyWith(fontSize: 12)),
                                  ]),
                            ),
                            Row(children: [
                              _iconBtn(Icons.phone_rounded, AppTheme.safeGreen),
                            ]),
                          ]),
                        ),
                      )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // High impact Overlay screen takes over screen completely
          if (patientState.hasSeizureAlert && !_isOverlayMinimized)
            Positioned.fill(
              child: EmergencyCrisisOverlay(
                patientName: patient.patientName.isNotEmpty ? patient.patientName : 'Alex Johnson',
                heartRate: patient.heartRate,
                motionLevel: patient.motionLevel,
                latitude: patient.latitude,
                longitude: patient.longitude,
                onAcknowledge: () {
                  ref.read(patientProvider.notifier).dismissSeizureAlert();
                },
                onResolve: () {
                  ref.read(patientProvider.notifier).dismissSeizureAlert();
                },
                onMinimize: () {
                  setState(() {
                    _isOverlayMinimized = true;
                  });
                },
                emergencyStatus: patientState.emergencyStatus,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTheme.label),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontFamily: AppTheme.fontPoppins,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color)),
    ]);
  }

  Widget _iconBtn(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ─── Subcomponents ──────────────────────────────────────────────────────────

class BlinkingEmergencyBanner extends StatefulWidget {
  final String patientName;
  final int heartRate;
  final double motionLevel;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final String emergencyStatus;

  const BlinkingEmergencyBanner({
    super.key,
    required this.patientName,
    required this.heartRate,
    required this.motionLevel,
    required this.onAcknowledge,
    required this.onResolve,
    required this.emergencyStatus,
  });

  @override
  State<BlinkingEmergencyBanner> createState() => _BlinkingEmergencyBannerState();
}

class _BlinkingEmergencyBannerState extends State<BlinkingEmergencyBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF1744).withValues(alpha: _animation.value),
                const Color(0xFFFF5252).withValues(alpha: _animation.value * 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.3 * _animation.value),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '🚨 CRITICAL SEIZURE ALERT',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.emergencyStatus == 'guidance'
                          ? 'GUIDANCE'
                          : 'CALL SENT',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontInter,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Patient ${widget.patientName} has triggered a critical seizure alert. High frequency tremors and elevated heart rate are being recorded.',
                style: const TextStyle(
                  fontFamily: AppTheme.fontInter,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Heart Rate: ${widget.heartRate} bpm',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Motion: ${widget.motionLevel.toStringAsFixed(1)}g',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.emergencyStatus == 'guidance'
                          ? Icons.record_voice_over_rounded
                          : Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.emergencyStatus == 'guidance'
                            ? 'Emergency Guidance In Progress...'
                            : 'Emergency Call Sent to Caretaker (8792021456)',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontInter,
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF1744),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: widget.onAcknowledge,
                      child: const Text(
                        'Acknowledge Alert',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: widget.onResolve,
                      child: const Text(
                        'Resolve Event',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmergencyCrisisOverlay extends StatefulWidget {
  final String patientName;
  final int heartRate;
  final double motionLevel;
  final double latitude;
  final double longitude;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onMinimize;
  final String emergencyStatus;

  const EmergencyCrisisOverlay({
    super.key,
    required this.patientName,
    required this.heartRate,
    required this.motionLevel,
    required this.latitude,
    required this.longitude,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onMinimize,
    required this.emergencyStatus,
  });

  @override
  State<EmergencyCrisisOverlay> createState() => _EmergencyCrisisOverlayState();
}

class _EmergencyCrisisOverlayState extends State<EmergencyCrisisOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flashing Alarm Emblem
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.15 * _animation.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF1744).withValues(alpha: _animation.value),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.3 * _animation.value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.emergency_rounded,
                      color: const Color(0xFFFF1744).withValues(alpha: _animation.value),
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '⚠️ SEIZURE CRISIS DETECTED',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF1744),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Patient ${widget.patientName} requires immediate medical response!',
              style: const TextStyle(
                fontFamily: AppTheme.fontInter,
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Telemetry Data Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _crisisStat('HEART RATE', '${widget.heartRate}', 'bpm', const Color(0xFFFF1744)),
                      _crisisStat('MOTION VEC', widget.motionLevel.toStringAsFixed(1), 'g', const Color(0xFFFFC107)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppTheme.primaryCyan, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location: ${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontInter,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Automatic Phone Call Notification Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.emergencyStatus == 'guidance'
                            ? Icons.record_voice_over_rounded
                            : Icons.phone_in_talk_rounded,
                        color: widget.emergencyStatus == 'guidance'
                            ? AppTheme.warningYellow
                            : AppTheme.safeGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.emergencyStatus == 'guidance'
                            ? '🎙 EMERGENCY GUIDANCE IN PROGRESS'
                            : '📞 AUTOMATIC PHONE CALL SENT',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.emergencyStatus == 'guidance'
                        ? 'Seizure first-aid instructions are being spoken out loud to bystanders before contacting the caregiver.'
                        : 'An emergency call has been automatically placed to the caretaker (8792021456). A 2-minute cooldown is active to prevent spamming.',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontInter,
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Main CTA Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: widget.onAcknowledge,
                    child: const Text(
                      'ACKNOWLEDGE ALARM',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: widget.onResolve,
                    child: const Text(
                      'RESOLVE & SHUTDOWN',
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onMinimize,
              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.white54, size: 16),
              label: const Text(
                'Minimize Alert View',
                style: TextStyle(
                  fontFamily: AppTheme.fontInter,
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crisisStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontInter,
            fontSize: 10,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontFamily: AppTheme.fontInter,
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
