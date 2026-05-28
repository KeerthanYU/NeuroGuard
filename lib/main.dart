import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroguard/core/services/app_initializer.dart';
import 'package:neuroguard/providers/theme_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/utils/constants.dart';
import 'package:neuroguard/features/dashboard/splash_screen.dart';
import 'package:neuroguard/features/dashboard/login_screen.dart';
import 'package:neuroguard/features/dashboard/home_dashboard.dart';
import 'package:neuroguard/features/notifications/emergency_alert_screen.dart';
import 'package:neuroguard/features/analytics/live_monitoring_screen.dart';
import 'package:neuroguard/features/notifications/gps_tracking_screen.dart';
import 'package:neuroguard/features/analytics/history_screen.dart';
import 'package:neuroguard/features/dashboard/caregiver_dashboard.dart';
import 'package:neuroguard/features/dashboard/settings_screen.dart';
import 'package:neuroguard/features/dashboard/mode_selection_screen.dart';
import 'package:neuroguard/screens/caretaker_setup_screen.dart';

Future<void> main() async {
  // Initialize bootstrapping cleanly via AppInitializer
  await AppInitializer.initialize();

  // Enforce portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: NeuroGuardApp()));
}

class NeuroGuardApp extends ConsumerWidget {
  const NeuroGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const HomeDashboard(),
        AppRoutes.emergency: (_) => const EmergencyAlertScreen(),
        AppRoutes.liveMonitoring: (_) => const LiveMonitoringScreen(),
        AppRoutes.gpsTracking: (_) => const GpsTrackingScreen(),
        AppRoutes.history: (_) => const HistoryScreen(),
        AppRoutes.caregiver: (_) => const CaregiverDashboard(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        '/mode-selection': (_) => const ModeSelectionScreen(),
        AppRoutes.caretakerSetup: (_) => const CaretakerSetupScreen(),
      },

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context)
                  .textScaler
                  .scale(1.0)
                  .clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}