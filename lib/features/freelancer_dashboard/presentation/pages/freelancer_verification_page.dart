import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerVerificationPage extends StatefulWidget {
  const FreelancerVerificationPage({super.key});

  @override
  State<FreelancerVerificationPage> createState() =>
      _FreelancerVerificationPageState();
}

class _FreelancerVerificationPageState
    extends State<FreelancerVerificationPage> {
  final _emailOtp = TextEditingController();
  final _phoneOtp = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _emailOtpSent = false;
  bool _phoneOtpSent = false;
  bool _sendingEmailOtp = false;
  bool _sendingPhoneOtp = false;
  bool _verifyingEmail = false;
  bool _verifyingPhone = false;
  bool _emailVerifiedOverride = false;
  bool _phoneVerifiedOverride = false;

  int _emailSeconds = 0;
  int _phoneSeconds = 0;
  Timer? _emailTimer;
  Timer? _phoneTimer;

  final _documents = {
    _KycDocumentType.pan: _KycDocumentState(),
    _KycDocumentType.aadhaar: _KycDocumentState(),
  };

  @override
  void dispose() {
    _emailOtp.dispose();
    _phoneOtp.dispose();
    _emailTimer?.cancel();
    _phoneTimer?.cancel();
    super.dispose();
  }

  void _startEmailTimer() {
    _emailTimer?.cancel();
    setState(() => _emailSeconds = 60);
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_emailSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _emailSeconds = 0);
        return;
      }
      if (mounted) setState(() => _emailSeconds--);
    });
  }

  void _startPhoneTimer() {
    _phoneTimer?.cancel();
    setState(() => _phoneSeconds = 60);
    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phoneSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _phoneSeconds = 0);
        return;
      }
      if (mounted) setState(() => _phoneSeconds--);
    });
  }

  Future<void> _sendEmailOtp(String email) async {
    if (email.isEmpty) {
      context.showSnack('Email is not available', isError: true);
      return;
    }

    setState(() => _sendingEmailOtp = true);
    final res = await sl<ApiClientHelper>().postAction(
      ApiEndpoints.sendEmailVerification,
      body: {'email': email},
    );
    if (!mounted) return;
    setState(() {
      _sendingEmailOtp = false;
      if (res.isSuccess) _emailOtpSent = true;
    });
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      _startEmailTimer();
      context.showSnack('OTP sent to your email');
    });
  }

  Future<void> _verifyEmailOtp(String email) async {
    final otp = _emailOtp.text.trim();
    if (otp.isEmpty) {
      context.showSnack('Enter email OTP', isError: true);
      return;
    }

    setState(() => _verifyingEmail = true);
    final res = await sl<ApiClientHelper>().postAction(
      ApiEndpoints.verifyEmailVerification,
      body: {'email': email, 'otp': otp},
    );
    if (!mounted) return;
    setState(() {
      _verifyingEmail = false;
      if (res.isSuccess) _emailVerifiedOverride = true;
    });
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Email verified successfully');
    });
  }

  Future<void> _sendPhoneOtp(String phone, String countryCode) async {
    if (phone.isEmpty) {
      context.showSnack('Mobile number is not available', isError: true);
      return;
    }

    setState(() => _sendingPhoneOtp = true);
    final res = await sl<AuthRepository>().sendOtp(
      phone: phone,
      countryCode: countryCode,
    );
    if (!mounted) return;
    setState(() {
      _sendingPhoneOtp = false;
      if (res.isSuccess) _phoneOtpSent = true;
    });
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      _startPhoneTimer();
      context.showSnack('OTP sent to your mobile number');
    });
  }

  Future<void> _verifyPhoneOtp(String phone, String countryCode) async {
    final otp = _phoneOtp.text.trim();
    if (otp.isEmpty) {
      context.showSnack('Enter mobile OTP', isError: true);
      return;
    }

    setState(() => _verifyingPhone = true);
    final res = await sl<AuthRepository>().verifyOtp(
      code: otp,
      phone: phone,
      countryCode: countryCode,
    );
    if (!mounted) return;
    setState(() {
      _verifyingPhone = false;
      if (res.isSuccess) _phoneVerifiedOverride = true;
    });
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Mobile number verified successfully');
    });
  }

  Future<void> _chooseKycSource(_KycDocumentType type) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickKycImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickKycImage(type, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload document'),
                subtitle: const Text('JPG, PNG, PDF, DOC, DOCX'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickKycFile(type);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickKycImage(_KycDocumentType type, ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _documents[type]!
        ..path = picked.path
        ..name = picked.name
        ..previewBytes = bytes
        ..uploaded = false;
    });
  }

  Future<void> _pickKycFile(_KycDocumentType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;

    final lowerName = file.name.toLowerCase();
    final canPreview =
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png');
    setState(() {
      _documents[type]!
        ..path = file.path
        ..name = file.name
        ..previewBytes = canPreview ? file.bytes : null
        ..uploaded = false;
    });
  }

  Future<void> _submitKycDocument(_KycDocumentType type) async {
    final state = _documents[type]!;
    if (state.path == null || state.path!.isEmpty) {
      context.showSnack('Choose a file first', isError: true);
      return;
    }

    setState(() => state.uploading = true);
    final res = await sl<FreelancerProfileRepository>().uploadKycDocument(
      filePath: state.path!,
      documentType: type.apiValue,
    );
    if (!mounted) return;

    setState(() {
      state.uploading = false;
      if (res.isSuccess) state.uploaded = true;
    });
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) => context.showSnack('${type.label} submitted for verification'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final countryCode = user?.countryCode ?? '+91';
    final accountVerified = user?.isVerified ?? false;
    final emailVerified = accountVerified || _emailVerifiedOverride;
    final phoneVerified =
        _phoneVerifiedOverride || (accountVerified && phone.isNotEmpty);
    final panVerified = _documents[_KycDocumentType.pan]!.uploaded;
    final aadhaarVerified = _documents[_KycDocumentType.aadhaar]!.uploaded;
    final verifiedCount = [
      emailVerified,
      phoneVerified,
      panVerified,
      aadhaarVerified,
    ].where((verified) => verified).length;

    return AppScaffold(
      constrainWidth: false,
      appBar: AppBar(title: const Text('Verification Center')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VerificationSummary(
                    name: user?.fullName ?? 'Freelancer',
                    avatarUrl: user?.avatarUrl,
                    verifiedCount: verifiedCount,
                    totalCount: 4,
                  ),
                  AppSizes.vGapXl,
                  Text(
                    verifiedCount == 4 ? 'Verified details' : 'Action Required',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AppSizes.vGapMd,
                  _OtpVerificationCard(
                    title: 'Email Verification',
                    subtitle: email.isEmpty ? 'Not provided' : email,
                    icon: Icons.mail_outline_rounded,
                    verified: emailVerified,
                    otpSent: _emailOtpSent,
                    seconds: _emailSeconds,
                    controller: _emailOtp,
                    sending: _sendingEmailOtp,
                    verifying: _verifyingEmail,
                    onSendOtp: () => _sendEmailOtp(email),
                    onVerify: () => _verifyEmailOtp(email),
                  ),
                  AppSizes.vGapMd,
                  _OtpVerificationCard(
                    title: 'Mobile Number',
                    subtitle: phone.isEmpty
                        ? 'Not provided'
                        : '$countryCode $phone',
                    icon: Icons.phone_outlined,
                    verified: phoneVerified,
                    otpSent: _phoneOtpSent,
                    seconds: _phoneSeconds,
                    controller: _phoneOtp,
                    sending: _sendingPhoneOtp,
                    verifying: _verifyingPhone,
                    onSendOtp: () => _sendPhoneOtp(phone, countryCode),
                    onVerify: () => _verifyPhoneOtp(phone, countryCode),
                  ),
                  AppSizes.vGapMd,
                  _KycVerificationCard(
                    type: _KycDocumentType.pan,
                    state: _documents[_KycDocumentType.pan]!,
                    onChoose: () => _chooseKycSource(_KycDocumentType.pan),
                    onSubmit: () => _submitKycDocument(_KycDocumentType.pan),
                  ),
                  AppSizes.vGapMd,
                  _KycVerificationCard(
                    type: _KycDocumentType.aadhaar,
                    state: _documents[_KycDocumentType.aadhaar]!,
                    onChoose: () => _chooseKycSource(_KycDocumentType.aadhaar),
                    onSubmit: () =>
                        _submitKycDocument(_KycDocumentType.aadhaar),
                  ),
                  AppSizes.vGapXl,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationSummary extends StatelessWidget {
  const _VerificationSummary({
    required this.name,
    required this.avatarUrl,
    required this.verifiedCount,
    required this.totalCount,
  });

  final String name;
  final String? avatarUrl;
  final int verifiedCount;
  final int totalCount;

  bool get _complete => verifiedCount == totalCount;

  @override
  Widget build(BuildContext context) {
    final color = _complete ? AppColors.success : AppColors.danger;
    return AppCard(
      radius: AppSizes.radiusMd,
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          AppAvatar(
            name: name,
            imageUrl: avatarUrl,
            size: 52,
            badge: CircleAvatar(
              radius: 12,
              backgroundColor: color,
              child: Icon(
                _complete ? Icons.verified_user : Icons.error_outline,
                color: AppColors.white,
                size: 15,
              ),
            ),
          ),
          AppSizes.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _complete
                      ? 'Your account is verified'
                      : 'Verification is incomplete',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _complete
                      ? 'You have full access to all platform features.'
                      : '$verifiedCount of $totalCount checks are complete. Finish the remaining steps to unlock full account trust.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpVerificationCard extends StatelessWidget {
  const _OtpVerificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.verified,
    required this.otpSent,
    required this.seconds,
    required this.controller,
    required this.sending,
    required this.verifying,
    required this.onSendOtp,
    required this.onVerify,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool verified;
  final bool otpSent;
  final int seconds;
  final TextEditingController controller;
  final bool sending;
  final bool verifying;
  final VoidCallback onSendOtp;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : AppColors.danger;
    return AppCard(
      radius: AppSizes.radiusMd,
      child: Column(
        children: [
          _VerificationHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
            statusLabel: verified ? 'Verified' : 'Not verified',
            statusIcon: verified
                ? Icons.check_circle_outline
                : Icons.error_outline_rounded,
          ),
          if (!verified) ...[
            const Divider(height: AppSizes.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 680;
                final otpField = AppTextField(
                  controller: controller,
                  label: 'OTP',
                  hint: otpSent ? 'Enter OTP' : 'Send OTP first',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  enabled: otpSent,
                );
                final actions = Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: otpSent
                            ? (seconds > 0
                                  ? 'Resend in ${seconds}s'
                                  : 'Resend OTP')
                            : 'Send OTP',
                        icon: Icons.send_outlined,
                        isLoading: sending,
                        onPressed: sending || seconds > 0 ? null : onSendOtp,
                      ),
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Submit',
                        icon: Icons.verified_outlined,
                        isLoading: verifying,
                        onPressed: otpSent && !verifying ? onVerify : null,
                        gradient: false,
                        backgroundColor: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                );
                if (!wide) {
                  return Column(children: [otpField, AppSizes.vGapMd, actions]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 3, child: otpField),
                    AppSizes.hGapMd,
                    Expanded(flex: 4, child: actions),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _KycVerificationCard extends StatelessWidget {
  const _KycVerificationCard({
    required this.type,
    required this.state,
    required this.onChoose,
    required this.onSubmit,
  });

  final _KycDocumentType type;
  final _KycDocumentState state;
  final VoidCallback onChoose;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final verified = state.uploaded;
    final color = verified ? AppColors.success : AppColors.danger;
    return AppCard(
      radius: AppSizes.radiusMd,
      child: Column(
        children: [
          _VerificationHeader(
            title: '${type.label} Verification',
            subtitle: verified
                ? '${type.label} document submitted.'
                : 'Please upload your ${type.label} card.',
            icon: Icons.description_outlined,
            color: color,
            statusLabel: verified ? 'Done' : 'Not verified',
            statusIcon: verified
                ? Icons.check_circle_outline
                : Icons.error_outline_rounded,
          ),
          if (!verified || state.name != null) ...[
            const Divider(height: AppSizes.xl),
            if (state.name != null) ...[
              _DocumentPreview(state: state),
              AppSizes.vGapMd,
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 560;
                final chooseButton = OutlinedButton.icon(
                  onPressed: state.uploading ? null : onChoose,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(state.name == null ? 'Choose file' : 'Change'),
                );
                final submitButton = AppPrimaryButton(
                  label: verified ? 'Submitted' : 'Submit',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: state.uploading,
                  onPressed: state.path == null || state.uploading || verified
                      ? null
                      : onSubmit,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [chooseButton, AppSizes.vGapMd, submitButton],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: chooseButton),
                    AppSizes.hGapMd,
                    Expanded(child: submitButton),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.statusLabel,
    required this.statusIcon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String statusLabel;
  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        AppSizes.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSizes.hGapMd,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: color, size: 18),
            AppSizes.hGapXs,
            Text(
              statusLabel,
              style: context.text.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.state});

  final _KycDocumentState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(color: context.theme.dividerColor),
            ),
            child: state.previewBytes == null
                ? const Icon(Icons.insert_drive_file_outlined)
                : Image.memory(state.previewBytes!, fit: BoxFit.cover),
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.name ?? 'Selected document',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  state.previewBytes == null
                      ? 'Document ready to submit'
                      : 'Image preview ready',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _KycDocumentType {
  pan('PAN Card', 'pan'),
  aadhaar('Aadhaar Card', 'aadhaar');

  const _KycDocumentType(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

class _KycDocumentState {
  String? path;
  String? name;
  Uint8List? previewBytes;
  bool uploading = false;
  bool uploaded = false;
}
