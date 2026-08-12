import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await sl<AuthRepository>().forgotPassword(
      _email.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack('Verification code sent to ${_email.text.trim()}');
      setState(() => _codeSent = true);
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await sl<AuthRepository>().resetPassword(
      email: _email.text.trim(),
      otp: _otp.text.trim(),
      newPassword: _newPassword.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack('Password reset successfully! Please log in.');
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        leading: IconTapWidget(
          onTap: () {
            if (_codeSent) {
              setState(() => _codeSent = false);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppSizes.vGapXs,
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Image.asset(
                  AppAssets.logo,
                  width: 120,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              AppSizes.vGapLg,
              Text(
                _codeSent ? "Reset Password" : "Forgot Password",
                style: context.text.displaySmall,
              ),
              AppSizes.vGapXl,
              Text(
                _codeSent
                    ? "Enter the verification code sent to your email and your new password."
                    : "Enter your email and we will send you a verification code.",
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              AppSizes.vGapXxxl,
              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                readOnly: _codeSent,
              ),
              if (_codeSent) ...[
                AppSizes.vGapLg,
                AppTextField(
                  controller: _otp,
                  label: 'Verification Code (OTP)',
                  hint: 'Enter 6-digit code',
                  prefixIcon: Icons.lock_clock_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.required(v, field: 'OTP'),
                ),
                AppSizes.vGapLg,
                AppTextField(
                  controller: _newPassword,
                  label: 'New Password',
                  hint: 'Enter your new password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: Validators.password,
                ),
                AppSizes.vGapLg,
                AppTextField(
                  controller: _confirmPassword,
                  label: 'Confirm Password',
                  hint: 'Re-enter your new password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (v) =>
                      Validators.confirmPassword(v, _newPassword.text),
                ),
              ],
              AppSizes.vGapXxxl,
              AppPrimaryButton(
                label: _codeSent ? 'Reset Password' : 'Send Code',
                isLoading: _loading,
                onPressed: _codeSent ? _resetPassword : _sendCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
