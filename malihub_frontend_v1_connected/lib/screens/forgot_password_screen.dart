import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/malihub_logo.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';

/// Completes the "Forgot Password?" link from the login screen.
///
/// Two steps in one screen:
/// 1. Enter email -> POST /api/auth/forgot-password with { email }.
///    Backend emails a 6-digit code (not a link), expires in 15 minutes.
/// 2. Enter code + new password -> POST /api/auth/reset-password with
///    { email, code, new_password }.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _sent = false; // email step done, showing code+password step
  bool _resetComplete = false; // password successfully changed

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Couldn't reach the server. Check your connection and try again.")));
    }
  }

  Future<void> _handleReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resetComplete = true;
      });
    } on ApiException catch (e) {
      // Backend returns "Invalid or expired code" (400) here if the code is
      // wrong, already used, or past its 15-minute window.
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Couldn't reach the server. Check your connection and try again.")));
    }
  }

  void _handleBack() {
    if (_resetComplete) {
      Navigator.of(context).pop();
    } else if (_sent) {
      // Go back to the email step rather than leaving the flow entirely.
      setState(() => _sent = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  String get _title {
    if (_resetComplete) return 'Password updated';
    if (_sent) return 'Enter your code';
    return 'Reset your password';
  }

  String get _subtitle {
    if (_resetComplete) {
      return 'Your password has been changed. You can now log in with your new password.';
    }
    if (_sent) {
      return 'Enter the 6-digit code we emailed you, along with a new password. The code expires in 15 minutes.';
    }
    return "Enter the email tied to your account and we'll send you a code to reset your password.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _handleBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 24),
              const MalihubLogo(size: 44),
              const SizedBox(height: 20),
              Text(
                _title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 28),

              if (_resetComplete) ...[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to log in'),
                ),
              ] else if (!_sent) ...[
                Form(
                  key: _emailFormKey,
                  child: AppTextField(
                    label: 'Email Address',
                    hint: 'amara@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSend,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send reset code'),
                ),
              ] else ...[
                Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Reset Code',
                        hint: '6-digit code',
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Code is required';
                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                            return 'Enter the 6-digit code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'New Password',
                        hint: 'Min. 8 characters',
                        controller: _newPasswordController,
                        obscureText: true,
                        toggleObscure: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 8) return 'Must be at least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Confirm New Password',
                        hint: 'Repeat password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        toggleObscure: true,
                        validator: (value) => (value != _newPasswordController.text)
                            ? 'Passwords do not match'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Reset Password'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          // Resend: fires forgot-password again for a fresh
                          // code, without leaving this step.
                          await _handleSend();
                          if (mounted && _sent) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('A new code has been sent.')),
                            );
                          }
                        },
                  child: const Text(
                    "Didn't get a code? Resend",
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
