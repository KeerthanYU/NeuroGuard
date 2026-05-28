// lib/features/analytics/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/models/alert_model.dart';
import 'package:neuroguard/providers/patient_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(patientProvider);
    final alerts = patient.alerts;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: const Row(children: [
          Icon(Icons.history_rounded, color: AppTheme.primaryCyan, size: 22),
          SizedBox(width: 8),
          Text('Seizure History'),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: alerts.isEmpty
            ? _emptyState()
            : CustomScrollView(
                slivers: [
                  // ─── Summary Header ───────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                borderColor: AppTheme.emergencyRed
                                    .withValues(alpha: 0.3),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Icon(Icons.emergency_rounded,
                                      color: AppTheme.emergencyRed,
                                      size: 20),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${alerts.where((a) => a.isCritical).length}',
                                    style: const TextStyle(
                                        fontFamily: AppTheme.fontPoppins,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.emergencyRed),
                                  ),
                                  Text('Critical Events',
                                      style: AppTheme.label),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                borderColor: AppTheme.warningYellow
                                    .withValues(alpha: 0.3),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Icon(Icons.warning_rounded,
                                      color: AppTheme.warningYellow,
                                      size: 20),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${alerts.where((a) => a.isWarning).length}',
                                    style: const TextStyle(
                                        fontFamily: AppTheme.fontPoppins,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.warningYellow),
                                  ),
                                  Text('Warning Events',
                                      style: AppTheme.label),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      color: AppTheme.primaryCyan,
                                      size: 20),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${alerts.length}',
                                    style: const TextStyle(
                                        fontFamily: AppTheme.fontPoppins,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryCyan),
                                  ),
                                  Text('Total Events',
                                      style: AppTheme.label),
                                ]),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          const SectionHeader(title: 'Event Timeline'),
                        ],
                      ),
                    ),
                  ),

                  // ─── Timeline List ────────────────────────────────
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _TimelineCard(alert: alerts[index]),
                        childCount: alerts.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.safeGreen, size: 64),
          SizedBox(height: 16),
          Text('No Events Recorded',
              style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('Seizure events will appear here',
              style: TextStyle(
                  fontFamily: AppTheme.fontInter,
                  fontSize: 14,
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final AlertModel alert;
  const _TimelineCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.isCritical;
    final color =
        isCritical ? AppTheme.emergencyRed : AppTheme.warningYellow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Timeline indicator ────────────────────────────
            Column(children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 1.5,
                  color: AppTheme.divider,
                ),
              ),
            ]),
            const SizedBox(width: 14),

            // ─── Card ─────────────────────────────────────────
            Expanded(
              child: GlassCard(
                margin: const EdgeInsets.only(bottom: 0),
                borderColor: color.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            alert.severity,
                            style: TextStyle(
                                fontFamily: AppTheme.fontInter,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.5),
                          ),
                        ),
                      ]),
                      Text(alert.formattedTimeOnly,
                          style: AppTheme.bodyMD.copyWith(fontSize: 12)),
                    ]),
                    const SizedBox(height: 10),
                    Text(alert.formattedDate,
                        style: const TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _metricChip(Icons.favorite_rounded,
                          '${alert.heartRate} bpm', AppTheme.emergencyRed),
                      const SizedBox(width: 8),
                      _metricChip(Icons.vibration_rounded,
                          '${alert.motionLevel.toStringAsFixed(1)}g',
                          AppTheme.warningYellow),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppTheme.primaryCyan, size: 13),
                      const SizedBox(width: 4),
                      Text(alert.coordinates,
                          style: AppTheme.bodySM.copyWith(fontSize: 11)),
                    ]),
                    if (alert.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(alert.notes,
                          style: AppTheme.bodyMD.copyWith(
                              fontSize: 12,
                              color: AppTheme.textMuted)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(IconData icon, String value, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontFamily: AppTheme.fontInter,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ]),
    );
  }
}
