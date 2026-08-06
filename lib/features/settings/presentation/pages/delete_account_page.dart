import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _sending = false;
  bool _submitting = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = context.read<AuthBloc>().state.user?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      context.showSnack('Enter a valid email', isError: true);
      return;
    }

    setState(() => _sending = true);
    try {
      final response = await Dio().post<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}/public/delete-account/send-otp',
        data: {'email': email},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = response.data ?? const <String, dynamic>{};
      if (!mounted) return;
      if (body['success'] == false) {
        context.showSnack(
          body['message']?.toString() ?? 'Failed to send OTP',
          isError: true,
        );
      } else {
        setState(() => _otpSent = true);
        context.showSnack('OTP sent to your email');
      }
    } catch (_) {
      if (mounted) context.showSnack('Failed to send OTP', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      context.showSnack('Enter a valid email', isError: true);
      return;
    }
    if (otp.length < 4) {
      context.showSnack('Enter OTP', isError: true);
      return;
    }

    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete account?',
      message:
          'This will submit your account deletion request. This action cannot be undone from the app.',
      confirmLabel: 'Yes, Delete',
      isDestructive: true,
      icon: Icons.delete_forever_outlined,
    );
    if (!confirm || !mounted) return;

    setState(() => _submitting = true);
    try {
      final response = await Dio().post<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}/public/delete-account/verify',
        data: {'email': email, 'otp': otp},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final body = response.data ?? const <String, dynamic>{};
      if (!mounted) return;
      if (body['success'] == false) {
        context.showSnack(
          body['message']?.toString() ?? 'Failed to submit request',
          isError: true,
        );
      } else {
        context.showSnack(
          body['message']?.toString() ?? 'Delete account request submitted',
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        context.showSnack('Failed to submit request', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email Verification', style: context.text.titleMedium),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_otpSent,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _otpController,
                  label: 'OTP',
                  hint: 'Enter OTP',
                  keyboardType: TextInputType.number,
                  enabled: _otpSent,
                ),
                AppSizes.vGapLg,
                Wrap(
                  spacing: AppSizes.md,
                  runSpacing: AppSizes.md,
                  children: [
                    SizedBox(
                      width: context.isMobile ? double.infinity : 180,
                      child: AppSecondaryButton(
                        label: _otpSent ? 'Resend OTP' : 'Get OTP',
                        icon: Icons.mail_outline_rounded,
                        isLoading: _sending,
                        onPressed: _sending ? null : _sendOtp,
                      ),
                    ),
                    SizedBox(
                      width: context.isMobile ? double.infinity : 220,
                      child: AppPrimaryButton(
                        label: 'Submit Request',
                        icon: Icons.delete_outline_rounded,
                        isLoading: _submitting,
                        backgroundColor: AppColors.danger,
                        gradient: false,
                        onPressed: _otpSent && !_submitting ? _submit : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
