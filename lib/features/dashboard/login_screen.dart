import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuroguard/providers/auth_provider.dart';
import 'package:neuroguard/core/utils/app_theme.dart';
import 'package:neuroguard/core/utils/constants.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isRegister = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider.notifier);

    bool success;

    if (_isRegister) {
      success = await auth.registerWithEmail(
        _emailCtrl.text,
        _passCtrl.text,
      );
    } else {
      success = await auth.signInWithEmail(
        _emailCtrl.text,
        _passCtrl.text,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/mode-selection',
      );
    }
  }

  Future<void> _googleSignIn() async {
    final auth = ref.read(authProvider.notifier);
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/mode-selection',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ─── Logo ─────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryBlue, AppTheme.primaryCyan],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.monitor_heart_rounded,
                                size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.primaryCyan, AppTheme.primaryBlue],
                            ).createShader(bounds),
                            child: Text(
                              AppConstants.appName,
                              style: AppTheme.headingLG
                                  .copyWith(color: Colors.white, letterSpacing: 2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppConstants.appTagline,
                            style: AppTheme.bodySM.copyWith(
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ─── Card ─────────────────────────────────────────────
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isRegister ? 'Create Account' : 'Welcome Back',
                              style: AppTheme.headingMD,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isRegister
                                  ? 'Sign up to monitor your patient'
                                  : 'Sign in to continue monitoring',
                              style: AppTheme.bodyMD,
                            ),
                            const SizedBox(height: 28),

                            // Email field
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontInter),
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: AppTheme.textMuted),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontInter),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppTheme.textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            // Error message
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.emergencyRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.emergencyRed.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppTheme.emergencyRed, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: const TextStyle(
                                          color: AppTheme.emergencyRed,
                                          fontSize: 13,
                                          fontFamily: AppTheme.fontInter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Submit button
                            GradientButton(
                              text: _isRegister ? 'Create Account' : 'Sign In',
                              onPressed: _submit,
                              isLoading: auth.isLoading,
                              icon: _isRegister
                                  ? Icons.person_add_outlined
                                  : Icons.login_rounded,
                            ),

                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(color: AppTheme.divider)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text('OR',
                                      style: AppTheme.label
                                          .copyWith(fontSize: 10)),
                                ),
                                const Expanded(
                                    child: Divider(color: AppTheme.divider)),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Google Sign-In button
                            GestureDetector(
                              onTap: auth.isLoading ? null : _googleSignIn,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppTheme.glassBorder),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google G logo
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [
                                          Color(0xFF4285F4),
                                          Color(0xFFEA4335),
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(11),
                                      ),
                                      child: const Center(
                                        child: Text('G',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontFamily: AppTheme.fontInter,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
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

                    const SizedBox(height: 24),

                    // Toggle login/register
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() => _isRegister = !_isRegister);
                          ref.read(authProvider.notifier).clearError();
                        },
                        child: RichText(
                          text: TextSpan(
                            style: AppTheme.bodyMD,
                            children: [
                              TextSpan(
                                text: _isRegister
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                              ),
                              TextSpan(
                                text: _isRegister ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  color: AppTheme.primaryCyan,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontInter,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
