// lib/features/notifications/emergency_alert_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:neuroguard/providers/patient_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';

class EmergencyAlertScreen extends ConsumerStatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  ConsumerState<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends ConsumerState<EmergencyAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _bgCtrl;

  late Animation<double> _scaleAnim;
  late Animation<double> _bgAnim;

  Timer? _vibrateTimer;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(_scaleCtrl);
    _bgAnim = Tween<double>(begin: 0.85, end: 1.0).animate(_bgCtrl);

    _startVibration();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _startVibration() {
    _vibrateTimer =
        Timer.periodic(const Duration(milliseconds: 700), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _bgCtrl.dispose();
    _vibrateTimer?.cancel();
    super.dispose();
  }

  Future<void> _callCaregiver() async {
    final Uri uri = Uri(scheme: 'tel', path: '8792021456');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _dismissAlert() {
    ref.read(patientProvider.notifier).dismissAlert();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final patient = patientState.patient;

    return Scaffold(
          body: AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1A0000),
                      const Color(0xFF330000),
                      _bgAnim.value,
                    )!,
                    const Color(0xFF050A18),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: child,
            ),

            child: SafeArea(
              child: Column(
                children: [
                  // ─── Top Bar ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EMERGENCY',
                          style: TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.emergencyRed,
                            letterSpacing: 1.5,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _dismissAlert,
                          icon: const Icon(Icons.close,
                              color: AppTheme.textSecondary, size: 18),
                          label: const Text('Dismiss',
                              style: TextStyle(
                                  color: AppTheme.textSecondary)),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // SOS Circle
                          AnimatedBuilder(
                            animation: _scaleAnim,
                            builder: (_, __) => Transform.scale(
                              scale: _scaleAnim.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF1744),
                                      Color(0xFFFF6D00),
                                    ],
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emergency_rounded,
                                        color: Colors.white, size: 48),
                                    Text('SOS',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          const Text(
                            'SEIZURE DETECTED',
                            style: TextStyle(
                              fontFamily: AppTheme.fontPoppins,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.emergencyRed,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            patient.formattedTimestamp,
                            style: AppTheme.bodyMD,
                          ),

                          const SizedBox(height: 24),

                          // Heart Rate
                          GlassCard(
                            borderColor:
                                AppTheme.emergencyRed.withValues(alpha: 0.4),
                            child: Column(
                              children: [
                                const Icon(Icons.favorite,
                                    color: AppTheme.emergencyRed),
                                const SizedBox(height: 8),
                                Text(
                                  '${patient.heartRate}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.emergencyRed,
                                  ),
                                ),
                                const Text('Heart Rate'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Motion
                          GlassCard(
                            borderColor:
                                AppTheme.warningYellow.withValues(alpha: 0.4),
                            child: Column(
                              children: [
                                const Icon(Icons.vibration,
                                    color: AppTheme.warningYellow),
                                const SizedBox(height: 8),
                                Text(
                                  patient.motionLevel.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningYellow,
                                  ),
                                ),
                                const Text('Motion'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Location
                          GlassCard(
                            borderColor:
                                AppTheme.primaryCyan.withValues(alpha: 0.3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Patient Location'),
                                const SizedBox(height: 6),
                                Text(
                                  '${patient.latitude}, ${patient.longitude}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontFamily: AppTheme.fontInter,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Emergency Action Status Banner
                          if (patientState.emergencyStatus != 'none') ...[
                            GlassCard(
                              borderColor: patientState.emergencyStatus == 'guidance'
                                  ? AppTheme.warningYellow.withValues(alpha: 0.4)
                                  : AppTheme.safeGreen.withValues(alpha: 0.4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (patientState.emergencyStatus == 'guidance'
                                              ? AppTheme.warningYellow
                                              : AppTheme.safeGreen)
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      patientState.emergencyStatus == 'guidance'
                                          ? Icons.record_voice_over_rounded
                                          : Icons.phone_in_talk_rounded,
                                      color: patientState.emergencyStatus == 'guidance'
                                          ? AppTheme.warningYellow
                                          : AppTheme.safeGreen,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          patientState.emergencyStatus == 'guidance'
                                              ? 'Emergency Guidance In Progress'
                                              : 'Calling Caretaker...',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontPoppins,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: patientState.emergencyStatus == 'guidance'
                                                ? AppTheme.warningYellow
                                                : AppTheme.safeGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          patientState.emergencyStatus == 'guidance'
                                              ? 'Speaking first-aid instructions clearly to bystanders...'
                                              : 'Automatic caretaker connection is active.',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontInter,
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Buttons
                          GradientButton(
                            text: 'Call Caregiver Now',
                            onPressed: _callCaregiver,
                            colors: const [
                              AppTheme.emergencyRed,
                              AppTheme.emergencyOrange
                            ],
                            icon: Icons.phone,
                          ),

                          const SizedBox(height: 12),


                          OutlinedButton(
                            onPressed: _dismissAlert,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: AppTheme.glassBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            ),
                            child: const Center(
                              child: Text('Mark as Resolved',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
