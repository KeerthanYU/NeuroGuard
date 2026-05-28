// lib/screens/caretaker_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_theme.dart';
import '../core/widgets/common_widgets.dart';
import '../providers/caretaker_provider.dart';

class CaretakerSetupScreen extends ConsumerStatefulWidget {
  const CaretakerSetupScreen({super.key});

  @override
  ConsumerState<CaretakerSetupScreen> createState() => _CaretakerSetupScreenState();
}

class _CaretakerSetupScreenState extends ConsumerState<CaretakerSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Pre-populate input fields with existing values if caretaker is already configured
      final caretakerState = ref.read(caretakerProvider);
      final caretaker = caretakerState.caretaker;
      if (!caretaker.isEmpty) {
        _nameCtrl.text = caretaker.name;
        _phoneCtrl.text = caretaker.phone;
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(caretakerProvider.notifier);
    final success = await notifier.updateCaretaker(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Emergency contact saved successfully!',
                style: AppTheme.bodyMD.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final fromModeSelection = args != null && (args['fromModeSelection'] ?? false);

      if (fromModeSelection) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      final errorMsg = ref.read(caretakerProvider).error ?? 'Failed to save caretaker';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: AppTheme.bodyMD.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caretakerProvider);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final fromModeSelection = args != null && (args['fromModeSelection'] ?? false);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Emergency Setup'),
        centerTitle: true,
        leading: fromModeSelection
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Medical Visual Anchor / Glowing Pulse Icon
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.emergencyRed.withValues(alpha: 0.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.emergencyRed.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.emergencyGradient,
                              ),
                              child: const Icon(
                                Icons.contact_emergency_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Explanatory Headers
                      Text(
                        'Configure Caretaker',
                        textAlign: TextAlign.center,
                        style: AppTheme.headingLG.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Caretaker details are required for automatic emergency calling and real-time alerts in the event of a seizure.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMD.copyWith(color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 36),

                      // Input Glass Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Caretaker Contact Info',
                                style: AppTheme.headingSM.copyWith(color: AppTheme.primaryCyan),
                              ),
                              const SizedBox(height: 20),

                              // Name TextFormField
                              TextFormField(
                                controller: _nameCtrl,
                                keyboardType: TextInputType.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontInter,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'e.g. John Doe',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Caretaker name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Phone TextFormField
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontFamily: AppTheme.fontInter,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g. +1 555 123 4567',
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Caretaker phone is required';
                                  }
                                  final clean = v.trim();
                                  final digitCount = clean.replaceAll(RegExp(r'\D'), '').length;
                                  if (digitCount < 10) {
                                    return 'Phone number must be at least 10 digits';
                                  }
                                  final phoneRegex = RegExp(r'^\+?[0-9\-\s\(\)]+$');
                                  if (!phoneRegex.hasMatch(clean)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // Save Button
                              GradientButton(
                                text: 'Save Configuration',
                                onPressed: _save,
                                isLoading: state.isLoading,
                                icon: Icons.save_rounded,
                                colors: const [
                                  AppTheme.primaryBlue,
                                  AppTheme.primaryCyan,
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Safety Notice
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.security_rounded,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Data is encrypted locally and synchronized with Firebase.',
                              style: AppTheme.label.copyWith(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
