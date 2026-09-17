import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
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
  bool _emailVerified = false;

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
    final result = await sl<ApiClientHelper>().postEnvelope<String>(
      '${AppConfig.authBaseUrl}/public/delete-account/send-otp',
      body: {'email': email},
      parser: (envelope) =>
          envelope.message ?? 'Verification OTP sent to your email.',
    );
    if (!mounted) return;
    result.fold(
      (failure) => context.showSnack(failure.message, isError: true),
      (message) {
        setState(() => _otpSent = true);
        context.showSnack(message);
      },
    );
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _verifyOtp() async {
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

    setState(() => _submitting = true);
    
    final verifyResult = await sl<ApiClientHelper>().postEnvelope<String>(
      '${AppConfig.authBaseUrl}/public/delete-account/verify',
      body: {'email': email, 'otp': otp},
      parser: (envelope) =>
          envelope.message ?? 'OTP Verified successfully',
    );
    

    if (!mounted) return;
    
    verifyResult.fold(
      (failure) {
        context.showSnack(failure.message, isError: true);
        setState(() => _submitting = false);
      },
      (message) {
        context.showSnack(
          'Your account deletion request has been submitted. You will be logged out.',
        );
        if(mounted){
           context.read<AuthBloc>().add(const AuthLoggedOut());
        }
      },
    );
  }

  // Future<void> _deleteAccount() async {
  //   final email = _emailController.text.trim();
    
  //   final confirm = await AppConfirmDialog.show(
  //     context,
  //     title: 'Confirm Account Deletion',
  //     message:
  //         'Are you sure you want to permanently delete $email? This action cannot be undone.',
  //     confirmLabel: 'Delete Account',
  //     isDestructive: true,
  //     icon: Icons.delete_forever_outlined,
  //   );
  //   if (!confirm || !mounted) return;

  //   context.showSnack(
  //     'Your account deletion request has been submitted. You will be logged out.',
  //   );
    
  //   // The verify endpoint already submitted the deletion request to admin.
  //   // Just log the user out.
    
  // }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Delete Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_emailVerified) ...[
                  Text('Email Verification', style: context.text.titleMedium),
                  AppSizes.vGapMd,
                  Text(
                    'Verify your email to proceed with account deletion.',
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  AppSizes.vGapLg,
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'user@example.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_otpSent,
                  ),
                  AppSizes.vGapMd,
                  if (_otpSent) ...[
                    AppTextField(
                      controller: _otpController,
                      label: 'OTP',
                      hint: 'Enter OTP',
                      keyboardType: TextInputType.number,
                    ),
                    AppSizes.vGapLg,
                  ],
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
                      if (_otpSent)
                      SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: 'Delete My Account',
                      icon: Icons.delete_outline_rounded,
                      isLoading: _submitting,
                      backgroundColor: AppColors.danger,
                      gradient: false,
                      onPressed: _submitting ? null : _verifyOtp,
                    ),
                  ),
                       
                    ],
                  ),
                ] 
              ],
            ),
          ),
        ],
      ),
    );
  }
}
