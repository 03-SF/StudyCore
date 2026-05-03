import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/app_chip.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _confirmError;
  String? _generalError;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus && _confirmController.text.isNotEmpty) {
        setState(() {
          _confirmError = _confirmController.text != _passwordController.text
              ? 'Passwords do not match.'
              : null;
        });
      }
    });
  }

  void _updateStrength() {
    final p = _passwordController.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(p)) score++;
    setState(() => _passwordStrength = score);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Color _strengthColor(int index) {
    if (_passwordStrength <= index) return AppColors.borderColor;
    switch (_passwordStrength) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.amber;
      case 3:
        return AppColors.teal;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _signUp() async {
    setState(() => _generalError = null);

    if (_passwordController.text != _confirmController.text) {
      setState(() => _confirmError = 'Passwords do not match.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      _showProfileSetup();
    } else {
      setState(() => _generalError = auth.errorMessage);
    }
  }

  void _showProfileSetup() {
    final selectedSubjects = <String>[];
    final bioController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Almost there! 🎉',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us a bit about yourself.',
                  style: GoogleFonts.dmSans(color: AppColors.mutedText),
                ),
                const SizedBox(height: 20),
                AppInput(
                  label: 'Bio (optional)',
                  controller: bioController,
                  maxLines: 2,
                  hint: 'e.g. 2nd year Biology student...',
                ),
                const SizedBox(height: 20),
                Text(
                  'SUBJECTS',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.subjects.map((s) {
                    final selected = selectedSubjects.contains(s);
                    return AppChip(
                      label: s,
                      selected: selected,
                      onTap: () => setModal(() {
                        if (selected) {
                          selectedSubjects.remove(s);
                        } else {
                          selectedSubjects.add(s);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Done',
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    await auth.updateProfile(
                      bio: bioController.text.isNotEmpty
                          ? bioController.text
                          : null,
                      subjects: selectedSubjects,
                    );
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                'StudyCore',
                style: GoogleFonts.dmSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue learning',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 24),
              AppInput(
                label: 'FULL NAME',
                controller: _nameController,
                hint: 'Jane Smith',
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'EMAIL ADDRESS',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hint: 'you@university.edu',
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.mail_outline, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'PASSWORD',
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                hint: '••••••••',
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.mutedText,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: _strengthColor(i),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'CONFIRM PASSWORD',
                controller: _confirmController,
                focusNode: _confirmFocus,
                obscureText: _obscureConfirm,
                hint: '••••••••',
                error: _confirmError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signUp(),
                prefix: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.mutedText,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              if (_generalError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _generalError!,
                    style: GoogleFonts.dmSans(
                        color: AppColors.danger, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Create Account',
                onPressed: _signUp,
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: GoogleFonts.dmSans(
                        color: AppColors.mutedText, fontSize: 14),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.dmSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
