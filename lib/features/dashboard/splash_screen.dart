import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/auth_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/utils/constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _pulseScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    _navigate();
  }

  void _navigate() async {
    await _fadeController.forward();
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _screenFade,
      builder: (_, child) => Opacity(
        opacity: _screenFade.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Pulse Rings ─────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (_, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Transform.scale(
                          scale: _pulseScale.value * 1.4,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Middle ring
                        Transform.scale(
                          scale: _pulseScale.value * 1.2,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _logoController,
                      builder: (_, __) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0066FF),
                                  Color(0xFF00D4FF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.monitor_heart_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ─── App Name ─────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                AppTheme.primaryCyan,
                                AppTheme.primaryBlue,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              AppConstants.appName,
                              style: AppTheme.headingXL.copyWith(
                                fontSize: 42,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.appTagline,
                            style: AppTheme.bodyMD.copyWith(
                              letterSpacing: 1,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // ─── ECG Line Animation ────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Opacity(
                      opacity: _pulseController.value,
                      child: _ECGWidget(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Version
                  Text(
                    'v${AppConstants.appVersion}',
                    style: AppTheme.label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple ECG-style custom paint wave
class _ECGWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 40,
      child: CustomPaint(
        painter: _ECGPainter(),
      ),
    );
  }
}

class _ECGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryCyan.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.2, mid);
    path.lineTo(w * 0.25, mid - h * 0.3);
    path.lineTo(w * 0.3, mid + h * 0.4);
    path.lineTo(w * 0.35, mid - h * 0.9);
    path.lineTo(w * 0.4, mid + h * 0.2);
    path.lineTo(w * 0.45, mid - h * 0.1);
    path.lineTo(w * 0.5, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
