// lib/features/dashboard/home_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/patient_provider.dart';
import 'package:neuroguard/providers/auth_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/utils/constants.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';
import 'package:neuroguard/core/widgets/charts.dart';
import 'package:neuroguard/services/health_insights_service.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> with TickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  int _currentNav = 0;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade =
        CurvedAnimation(parent: _headerAnim, curve: Curves.easeIn);
    _headerAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(patientProvider.notifier)
          .initialize(AppConstants.defaultPatientId);
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final patient = patientState.patient;
    print('[HomeDashboard] Rebuilding. Connected=${patientState.patient.connected}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (patientState.hasSeizureAlert) {
        Navigator.pushNamed(context, AppRoutes.emergency);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      bottomNavigationBar: _buildBottomNav(context),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.read(patientProvider.notifier).refresh(),
            color: AppTheme.primaryCyan,
            backgroundColor: AppTheme.bgCard,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: FadeTransition(
                        opacity: _headerFade,
                        child: _buildHeader(context, patientState))),
                SliverToBoxAdapter(
                    child: _buildStatusBanner(patient)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      StatCard(
                        label: 'HEART RATE',
                        value: patient.heartRate.toString(),
                        unit: 'bpm',
                        icon: Icons.favorite_rounded,
                        accentColor: AppTheme.emergencyRed,
                        status: patient.heartRateStatus,
                        isAlert: patient.heartRate > 120,
                      ),
                      StatCard(
                        label: 'MOTION',
                        value: patient.motionLevel.toStringAsFixed(1),
                        unit: 'g',
                        icon: Icons.vibration_rounded,
                        accentColor: patient.seizureDetected
                            ? AppTheme.emergencyRed
                            : AppTheme.safeGreen,
                        status: patient.seizureDetected
                            ? 'Seizure Activity'
                            : 'Normal Activity',
                        isAlert: patient.seizureDetected,
                      ),
                      StatCard(
                        label: 'SPO₂',
                        value: patient.spo2.toString(),
                        unit: '%',
                        icon: Icons.bloodtype_rounded,
                        accentColor: patient.spo2 >= 95
                            ? AppTheme.safeGreen
                            : (patient.spo2 >= 90
                                ? AppTheme.warningYellow
                                : AppTheme.emergencyRed),
                        status: patient.spo2 >= 95
                            ? 'Normal'
                            : (patient.spo2 >= 90 ? 'Mild Hypoxia' : 'Critical'),
                        isAlert: patient.spo2 < 90,
                      ),
                      StatCard(
                        label: 'BATTERY',
                        value: patient.battery.toString(),
                        unit: '%',
                        icon: Icons.battery_charging_full_rounded,
                        accentColor: patient.battery > 20
                            ? AppTheme.safeGreen
                            : AppTheme.emergencyRed,
                        status: patient.battery > 20 ? 'Good' : 'Low',
                      ),
                      StatCard(
                        label: 'DEVICE',
                        value: patient.connectionState == 'LIVE' ? 'LIVE' : 'OFFLINE',
                        unit: '',
                        icon: Icons.bluetooth_connected_rounded,
                        accentColor: patient.connectionState == 'LIVE'
                            ? AppTheme.safeGreen
                            : AppTheme.emergencyRed,
                        status: patient.connectionState == 'LIVE'
                            ? 'Connected'
                            : 'Offline',
                      ),
                      StatCard(
                        label: 'SEIZURE RISK',
                        value: _riskScore(patient),
                        unit: '%',
                        icon: Icons.warning_amber_rounded,
                        accentColor: _riskColor(patient),
                        status: _riskLabel(patient),
                        isAlert: patient.seizureDetected,
                      ),
                    ]),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _buildClinicalAdvisor(patientState),
                  ),
                ),
                SliverToBoxAdapter(
                    child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Heart Rate'),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding:
                            const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        child: Column(
                          children: [
                            Row(children: [
                              const Icon(Icons.favorite_rounded,
                                  color: AppTheme.emergencyRed,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${patient.heartRate} bpm',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.emergencyRed,
                                ),
                              ),
                              const Spacer(),
                              const PulseIndicator(
                                  color: AppTheme.emergencyRed),
                              const SizedBox(width: 6),
                              Text('Live',
                                  style: AppTheme.label
                                      .copyWith(fontSize: 10)),
                            ]),
                            const SizedBox(height: 12),
                            SizedBox(
                                height: 120,
                                child: HeartRateChart(
                                    data: patientState.heartRateHistory)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                SliverToBoxAdapter(
                    child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Motion Activity',
                        action: 'Monitor',
                        onAction: () => Navigator.pushNamed(
                            context, AppRoutes.liveMonitoring),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding:
                            const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        child: Column(
                          children: [
                            Row(children: [
                              const Icon(Icons.vibration_rounded,
                                  color: AppTheme.warningYellow,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${patient.motionLevel.toStringAsFixed(1)} g',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontPoppins,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.warningYellow,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            SizedBox(
                                height: 120,
                                child: MotionChart(
                                    data: patientState.motionHistory,
                                    seizureDetected: patient.seizureDetected)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                SliverToBoxAdapter(
                    child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _quickAction(
                                icon: Icons.map_rounded,
                                label: 'GPS Track',
                                color: AppTheme.primaryCyan,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.gpsTracking))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _quickAction(
                                icon: Icons.history_rounded,
                                label: 'History',
                                color: AppTheme.primaryBlue,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.history))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _quickAction(
                                icon: Icons.people_rounded,
                                label: 'Caregiver',
                                color: AppTheme.safeGreen,
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.caregiver))),
                      ]),
                    ],
                  ),
                )),
                SliverToBoxAdapter(
                    child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: GlassCard(
                    borderColor:
                        AppTheme.emergencyRed.withValues(alpha: 0.3),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppTheme.emergencyRed
                                .withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(12)),
                        child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.emergencyRed,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text('Demo Mode',
                                style: TextStyle(
                                    fontFamily: AppTheme.fontPoppins,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text('Simulate seizure detection',
                                style: TextStyle(
                                    fontFamily: AppTheme.fontInter,
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                          ])),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(patientProvider.notifier).simulateSeizure(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emergencyRed,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        child: const Text('Test SOS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PatientState patientState) {
    final auth = ref.watch(authProvider);
    final patient = patientState.patient;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Good ${_greeting()}, 👋', style: AppTheme.bodyMD),
              const SizedBox(height: 2),
              Text(auth.displayName, style: AppTheme.headingMD),
            ])),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderColor: patient.connectionState == 'LIVE'
              ? AppTheme.safeGreen.withValues(alpha: 0.4)
              : AppTheme.emergencyRed.withValues(alpha: 0.3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            PulseIndicator(
                color: patient.connectionState == 'LIVE'
                    ? AppTheme.safeGreen
                    : AppTheme.emergencyRed),
            const SizedBox(width: 8),
            Text(
                patient.connectionState == 'LIVE'
                    ? 'LIVE'
                    : 'OFFLINE',
                style: TextStyle(
                    fontFamily: AppTheme.fontInter,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: patient.connectionState == 'LIVE'
                        ? AppTheme.safeGreen
                        : AppTheme.emergencyRed)),
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.settings),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppTheme.bgCard,
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppTheme.glassBorder)),
            child: const Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatusBanner(patient) {
    final isSafe =
        !patient.seizureDetected && patient.heartRate < 120;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: patient.seizureDetected
                ? [
                    AppTheme.emergencyRed.withValues(alpha: 0.2),
                    AppTheme.emergencyOrange.withValues(alpha: 0.1)
                  ]
                : isSafe
                    ? [
                        AppTheme.safeGreen.withValues(alpha: 0.12),
                        AppTheme.primaryCyan.withValues(alpha: 0.05)
                      ]
                    : [
                        AppTheme.warningYellow.withValues(alpha: 0.15),
                        AppTheme.warningYellow.withValues(alpha: 0.05)
                      ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: patient.seizureDetected
                ? AppTheme.emergencyRed.withValues(alpha: 0.5)
                : isSafe
                    ? AppTheme.safeGreen.withValues(alpha: 0.3)
                    : AppTheme.warningYellow.withValues(alpha: 0.4),
          ),
        ),
        child: Row(children: [
          Icon(
            patient.seizureDetected
                ? Icons.emergency_rounded
                : isSafe
                    ? Icons.shield_rounded
                    : Icons.warning_rounded,
            color: patient.seizureDetected
                ? AppTheme.emergencyRed
                : isSafe
                    ? AppTheme.safeGreen
                    : AppTheme.warningYellow,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  patient.seizureDetected
                      ? 'SEIZURE DETECTED!'
                      : isSafe
                          ? 'Patient is Safe'
                          : 'Elevated Activity',
                  style: TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: patient.seizureDetected
                          ? AppTheme.emergencyRed
                          : isSafe
                              ? AppTheme.safeGreen
                              : AppTheme.warningYellow),
                ),
                Text(patient.formattedTimestamp,
                    style: AppTheme.bodySM),
              ])),
          if (patient.seizureDetected)
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.emergency),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emergencyRed,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('View',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontFamily: AppTheme.fontInter,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
      ]),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(top: BorderSide(color: AppTheme.divider))),
      child: BottomNavigationBar(
        currentIndex: _currentNav,
        onTap: (i) {
          setState(() => _currentNav = i);
          switch (i) {
            case 1:
              Navigator.pushNamed(
                  context, AppRoutes.liveMonitoring);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.gpsTracking);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.history);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.settings);
              break;
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryCyan,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.fontInter,
            fontSize: 10,
            fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.fontInter, fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_rounded),
              label: 'Monitor'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded), label: 'GPS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildClinicalAdvisor(PatientState patientState) {
    final insight = HealthInsightsService.generateInsight(patientState);
    
    Color accentColor;
    IconData icon;
    String badgeText;
    
    switch (insight.severity) {
      case 'critical':
        accentColor = AppTheme.emergencyRed;
        icon = Icons.emergency_rounded;
        badgeText = 'CRITICAL SEIZURE ANOMALY';
        break;
      case 'warning':
        accentColor = AppTheme.warningYellow;
        icon = Icons.warning_amber_rounded;
        badgeText = 'AUTONOMIC DRIFT WARNING';
        break;
      case 'safe':
      default:
        accentColor = AppTheme.safeGreen;
        icon = Icons.check_circle_outline_rounded;
        badgeText = 'STABLE TELEMETRY PROFILE';
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'AI Clinical Advisor'),
        const SizedBox(height: 12),
        GlassCard(
          borderColor: accentColor.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(icon, color: accentColor, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontFamily: AppTheme.fontInter,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: ${insight.confidenceScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontPoppins,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight.summary,
                style: const TextStyle(
                  fontFamily: AppTheme.fontInter,
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.glassBorder.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.healing_rounded,
                      color: AppTheme.primaryCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CLINICAL RECOMMENDATION',
                            style: TextStyle(
                              fontFamily: AppTheme.fontInter,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryCyan,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight.recommendation,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontInter,
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  String _riskScore(patient) {
    if (patient.seizureDetected) return '95';
    if (patient.heartRate > 140 || patient.motionLevel > 8) return '80';
    if (patient.heartRate > 120 || patient.motionLevel > 6) return '45';
    return '10';
  }

  Color _riskColor(patient) {
    final score = int.parse(_riskScore(patient));
    if (score > 70) return AppTheme.emergencyRed;
    if (score > 30) return AppTheme.warningYellow;
    return AppTheme.safeGreen;
  }

  String _riskLabel(patient) {
    final score = int.parse(_riskScore(patient));
    if (score > 70) return 'HIGH';
    if (score > 30) return 'MODERATE';
    return 'LOW';
  }
}
