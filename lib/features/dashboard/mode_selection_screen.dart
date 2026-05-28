// lib/features/dashboard/mode_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';
import 'package:neuroguard/providers/app_mode_provider.dart';
import 'package:neuroguard/models/app_mode.dart';
import 'package:neuroguard/providers/sensor_data_provider.dart';
import 'package:neuroguard/services/caretaker_service.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectMode(bool isDemo) async {
    final mode = isDemo ? AppMode.demo : AppMode.live;
    ref.read(appModeProvider.notifier).setMode(mode);

    if (mode == AppMode.live) {
      final patientId = ref.read(activePatientIdProvider);
      final service = CaretakerService(patientId);
      final caretaker = await service.loadCaretaker();

      if (caretaker.isEmpty || !caretaker.isValid) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/caretaker-setup',
            arguments: {'fromModeSelection': true},
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Logo & Glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryCyan,
                                AppTheme.primaryBlue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monitor_heart_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Title
                    Text(
                      "Choose Your Mode",
                      style: AppTheme.headingXL.copyWith(
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Select how you want to run the monitoring engine",
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMD.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Demo Mode Card
                    _ModeSelectionCard(
                      title: "Demo Simulation",
                      subtitle: "Explore NeuroGuard features using realistic simulated seizures and ECG streams.",
                      icon: Icons.play_circle_filled_rounded,
                      color: AppTheme.primaryCyan,
                      gradient: AppTheme.primaryGradient,
                      onTap: () => _selectMode(true),
                    ),

                    const SizedBox(height: 20),

                    // Live Mode Card
                    _ModeSelectionCard(
                      title: "Live Monitoring",
                      subtitle: "Securely pair and connect live ESP32 wearable hardware sensors via Firebase RTDB.",
                      icon: Icons.sensors_rounded,
                      color: AppTheme.safeGreen,
                      gradient: AppTheme.safeGradient,
                      onTap: () => _selectMode(false),
                    ),

                    const Spacer(),

                    // Footer branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "NEUROGUARD SYSTEM v2.0 • LEVEL 2 COMPLIANT",
                          style: AppTheme.label.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSelectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ModeSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ModeSelectionCard> createState() => _ModeSelectionCardState();
}

class _ModeSelectionCardState extends State<_ModeSelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animController.forward(),
      onTapUp: (_) {
        _animController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _animController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          borderColor: widget.color.withValues(alpha: 0.25),
          backgroundColor: AppTheme.bgCard.withValues(alpha: 0.6),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.headingMD.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: AppTheme.bodyMD.copyWith(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
