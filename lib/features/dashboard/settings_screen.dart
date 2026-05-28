// lib/features/dashboard/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/auth_provider.dart';
import 'package:neuroguard/providers/theme_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/utils/constants.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';
import 'package:neuroguard/providers/caretaker_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emergencyVibration = true;
  bool _autoCallCaregiver = false;
  double _heartRateThreshold = 130;
  double _motionThreshold = 7.0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = ref.read(themeProvider.notifier);
    final caretakerState = ref.watch(caretakerProvider);
    final caretaker = caretakerState.caretaker;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: const Row(children: [
          Icon(Icons.settings_rounded, color: AppTheme.primaryCyan, size: 22),
          SizedBox(width: 8),
          Text('Settings'),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Profile Card ─────────────────────────────────────────
              GlassCard(
                child: Row(children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.displayName.isNotEmpty
                            ? auth.displayName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.displayName, style: AppTheme.headingSM),
                        const SizedBox(height: 4),
                        Text(auth.email, style: AppTheme.bodyMD),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Caregiver Account',
                              style: TextStyle(
                                  fontFamily: AppTheme.fontInter,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryCyan)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ─── Emergency Contact ──────────────────────────────────────
              _sectionTitle('Emergency Contact'),
              _settingsTile(
                icon: Icons.contact_emergency_rounded,
                label: 'Caretaker Details',
                subtitle: caretaker.isEmpty
                    ? 'Configure caretaker details for alerts'
                    : '${caretaker.name} — ${caretaker.phone}',
                color: AppTheme.emergencyRed,
                onTap: () {
                  Navigator.pushNamed(context, '/caretaker-setup');
                },
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ),

              // ─── Appearance ───────────────────────────────────────────
              _sectionTitle('Appearance'),
              _settingsTile(
                icon: Icons.dark_mode_rounded,
                label: 'Dark Mode',
                subtitle: 'Use dark healthcare theme',
                color: AppTheme.primaryBlue,
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => theme.toggleTheme(),
                  activeThumbColor: AppTheme.primaryCyan,
                ),
              ),

              // ─── Notifications ────────────────────────────────────────
              _sectionTitle('Notifications'),
              _settingsTile(
                icon: Icons.notifications_rounded,
                label: 'Push Notifications',
                subtitle: 'Receive seizure alerts',
                color: AppTheme.primaryCyan,
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (v) =>
                      setState(() => _notificationsEnabled = v),
                  activeThumbColor: AppTheme.primaryCyan,
                ),
              ),
              _settingsTile(
                icon: Icons.vibration_rounded,
                label: 'Emergency Vibration',
                subtitle: 'Vibrate on critical alert',
                color: AppTheme.warningYellow,
                trailing: Switch(
                  value: _emergencyVibration,
                  onChanged: (v) =>
                      setState(() => _emergencyVibration = v),
                  activeThumbColor: AppTheme.primaryCyan,
                ),
              ),
              _settingsTile(
                icon: Icons.phone_in_talk_rounded,
                label: 'Auto-Call Caregiver',
                subtitle: 'Automatically call on seizure',
                color: AppTheme.emergencyRed,
                trailing: Switch(
                  value: _autoCallCaregiver,
                  onChanged: (v) =>
                      setState(() => _autoCallCaregiver = v),
                  activeThumbColor: AppTheme.primaryCyan,
                ),
              ),

              // ─── Alert Thresholds ─────────────────────────────────────
              _sectionTitle('Alert Thresholds'),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      const Row(children: [
                        Icon(Icons.favorite_rounded,
                            color: AppTheme.emergencyRed, size: 16),
                        SizedBox(width: 8),
                        Text('Heart Rate Alert',
                            style: TextStyle(
                                fontFamily: AppTheme.fontInter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary)),
                      ]),
                      Text('${_heartRateThreshold.toInt()} bpm',
                          style: const TextStyle(
                              fontFamily: AppTheme.fontPoppins,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.emergencyRed)),
                    ]),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.emergencyRed,
                        inactiveTrackColor:
                            AppTheme.emergencyRed.withValues(alpha: 0.2),
                        thumbColor: AppTheme.emergencyRed,
                        overlayColor:
                            AppTheme.emergencyRed.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: _heartRateThreshold,
                        min: 80,
                        max: 180,
                        divisions: 20,
                        onChanged: (v) =>
                            setState(() => _heartRateThreshold = v),
                      ),
                    ),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      const Row(children: [
                        Icon(Icons.vibration_rounded,
                            color: AppTheme.warningYellow, size: 16),
                        SizedBox(width: 8),
                        Text('Motion Alert',
                            style: TextStyle(
                                fontFamily: AppTheme.fontInter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary)),
                      ]),
                      Text('${_motionThreshold.toStringAsFixed(1)} g',
                          style: const TextStyle(
                              fontFamily: AppTheme.fontPoppins,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningYellow)),
                    ]),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.warningYellow,
                        inactiveTrackColor:
                            AppTheme.warningYellow.withValues(alpha: 0.2),
                        thumbColor: AppTheme.warningYellow,
                        overlayColor:
                            AppTheme.warningYellow.withValues(alpha: 0.15),
                      ),
                      child: Slider(
                        value: _motionThreshold,
                        min: 3.0,
                        max: 10.0,
                        divisions: 14,
                        onChanged: (v) =>
                            setState(() => _motionThreshold = v),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Device ───────────────────────────────────────────────
              _sectionTitle('Device'),
              _settingsTile(
                icon: Icons.bluetooth_rounded,
                label: 'Reconnect Device',
                subtitle: 'ESP32-NG-001',
                color: AppTheme.primaryCyan,
                onTap: () {},
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ),
              _settingsTile(
                icon: Icons.info_outline_rounded,
                label: 'About NeuroGuard',
                subtitle: 'v${AppConstants.appVersion} — 24/7 Guardian',
                color: AppTheme.primaryBlue,
                onTap: () {},
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ),

              // ─── Sign Out ─────────────────────────────────────────────
              const SizedBox(height: 8),
              GradientButton(
                text: 'Sign Out',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await ref.read(authProvider.notifier).signOut();
                  navigator.pushReplacementNamed(AppRoutes.login);
                },
                colors: [
                  AppTheme.emergencyRed.withValues(alpha: 0.8),
                  AppTheme.emergencyOrange.withValues(alpha: 0.7),
                ],
                icon: Icons.logout_rounded,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.label.copyWith(letterSpacing: 1.5),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: AppTheme.fontInter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
                Text(subtitle, style: AppTheme.bodySM),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }
}
