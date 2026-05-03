import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _errorMessage = null);
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      setState(() => _errorMessage = auth.errorMessage);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _errorMessage = null);
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else if (auth.errorMessage != null) {
      setState(() => _errorMessage = auth.errorMessage);
    }
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Password',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your email and we'll send you a reset link.",
              style: GoogleFonts.dmSans(
                  color: AppColors.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 20),
            AppInput(
              label: 'Email',
              controller: _resetEmailController,
              keyboardType: TextInputType.emailAddress,
              hint: 'you@example.com',
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Send Reset Link',
              onPressed: () async {
                Navigator.pop(ctx);
                final auth = context.read<AuthProvider>();
                try {
                  await auth.sendPasswordResetEmail(
                    _resetEmailController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Reset link sent to your email'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _errorMessage = e.toString());
                  }
                }
              },
            ),
          ],
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 28),
              GoogleSignInButton(
                onPressed: _signInWithGoogle,
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderColor)),
                ],
              ),
              const SizedBox(height: 20),
              AppInput(
                label: 'EMAIL ADDRESS',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hint: 'Enter your email...',
                prefix: const Icon(Icons.mail_outline, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'PASSWORD',
                controller: _passwordController,
                obscureText: _obscurePassword,
                hint: '••••••••',
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.dmSans(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Sign In',
                onPressed: _signIn,
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.dmSans(
                      color: AppColors.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: Text(
                      'Sign up',
                      style: GoogleFonts.dmSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
