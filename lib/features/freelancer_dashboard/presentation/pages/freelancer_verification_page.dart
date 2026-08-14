import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class VerificationItem {
  VerificationItem({
    required this.key,
    required this.label,
    required this.value,
    required this.status,
    this.documentUrl,
    required this.required,
  });

  final String key;
  final String label;
  final String value;
  final String status;
  final String? documentUrl;
  final bool required;

  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isMissing => !isVerified && !isPending;

  factory VerificationItem.fromJson(Map<String, dynamic> json) {
    return VerificationItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      status: json['status']?.toString() ?? 'missing',
      documentUrl:
          json['documentUrl']?.toString() ?? json['document_url']?.toString(),
      required: json['required'] == true,
    );
  }
}

class FreelancerVerificationPage extends StatefulWidget {
  const FreelancerVerificationPage({super.key});

  @override
  State<FreelancerVerificationPage> createState() =>
      _FreelancerVerificationPageState();
}

class _FreelancerVerificationPageState
    extends State<FreelancerVerificationPage> {
  final _emailOtp = TextEditingController();
  final _phoneController = TextEditingController();
  final Map<String, TextEditingController> _itemValueControllers = {};

  bool _loading = true;
  bool _submittingItem = false;
  String? _submittingKey;

  bool _emailOtpSent = false;
  bool _sendingEmailOtp = false;
  bool _verifyingEmail = false;
  bool _emailVerifiedOverride = false;

  String _countryCode = '+91';
  String _countryIsoCode = 'IN';
  bool _editingPhone = false;
  bool _submittingPhone = false;

  final Set<String> _editingKeys = {};

  int _emailSeconds = 0;
  Timer? _emailTimer;

  List<VerificationItem> _items = [];
  int _trustScore = 0;
  int _verifiedCount = 0;
  int _pendingCount = 0;
  int _missingCount = 0;
  bool _accountVerified = false;
  String _headerName = '';
  String _headerEmail = '';

  final Map<String, String> _selectedFilePaths = {};
  final Map<String, String> _selectedFileNames = {};

  FreelancerProfileRepository get _repo =>
      sl<FreelancerProfileRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailOtp.dispose();
    _phoneController.dispose();
    for (final controller in _itemValueControllers.values) {
      controller.dispose();
    }
    _emailTimer?.cancel();
    super.dispose();
  }

  TextEditingController _getController(String key, String defaultValue) {
    if (!_itemValueControllers.containsKey(key)) {
      final initialText = (defaultValue == 'Not submitted') ? '' : defaultValue;
      _itemValueControllers[key] = TextEditingController(text: initialText);
    }
    return _itemValueControllers[key]!;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      return (double.tryParse(value) ?? num.tryParse(value) ?? 0).toInt();
    }
    return 0;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthBloc>().state.user;
    final res = await _repo.getVerificationDetails();
    if (!mounted) return;

    res.fold(
      (f) {},
      (data) {
        if (data.isNotEmpty) {
          final payload = (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'] as Map)
              : data;

          final rawItems = payload['items'] as List?;
          if (rawItems != null && rawItems.isNotEmpty) {
            _items = rawItems
                .map((e) => VerificationItem.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList();

            for (final item in _items) {
              if (item.value.isNotEmpty && item.value != 'Not submitted') {
                final ctrl = _itemValueControllers[item.key];
                if (ctrl != null) {
                  ctrl.text = item.value;
                }
              }
            }
          }

          _trustScore =
              _parseInt(payload['trustScore'] ?? payload['trust_score']);
          _verifiedCount =
              _parseInt(payload['verifiedCount'] ?? payload['verified_count']);
          _pendingCount =
              _parseInt(payload['pendingCount'] ?? payload['pending_count']);
          _missingCount =
              _parseInt(payload['missingCount'] ?? payload['missing_count']);
          _accountVerified = payload['accountVerified'] == true;
          _headerName =
              payload['fullName']?.toString() ?? user?.fullName ?? 'User';
          _headerEmail = payload['email']?.toString() ?? user?.email ?? '';
        }
      },
    );

    if (_items.isEmpty) {
      _items = [
        VerificationItem(
          key: 'email',
          label: 'Email address',
          value: user?.email ?? '',
          status: user?.isVerified == true ? 'verified' : 'missing',
          required: true,
        ),
        VerificationItem(
          key: 'phone',
          label: 'Phone number',
          value: user?.phone ?? '',
          status: user?.isVerified == true ? 'verified' : 'missing',
          required: true,
        ),
        VerificationItem(
          key: 'identity',
          label: 'Aadhard Card/Identity (Government ID)',
          value: 'Not submitted',
          status: 'missing',
          required: true,
        ),
        VerificationItem(
          key: 'pancard',
          label: 'PAN Card',
          value: 'Not submitted',
          status: 'missing',
          required: false,
        ),
        VerificationItem(
          key: 'passport',
          label: 'Passport',
          value: 'Not submitted',
          status: 'missing',
          required: false,
        ),
        VerificationItem(
          key: 'driving',
          label: 'Driving License',
          value: 'Not submitted',
          status: 'missing',
          required: false,
        ),
        VerificationItem(
          key: 'gst',
          label: 'GST (Optional)',
          value: 'Not submitted',
          status: 'missing',
          required: false,
        ),
        VerificationItem(
          key: 'address',
          label: 'Address proof',
          value: 'Not submitted',
          status: 'missing',
          required: true,
        ),
        VerificationItem(
          key: 'selfie',
          label: 'Selfie verification',
          value: 'Not submitted',
          status: 'missing',
          required: true,
        ),
        VerificationItem(
          key: 'company',
          label: 'Company Incorporation',
          value: 'Not submitted',
          status: 'missing',
          required: false,
        ),
      ];
    }

    if (mounted) setState(() => _loading = false);
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
    res.fold((f) => context.showSnack(f.message, isError: true), (_) async {
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Email verified successfully');
      await _repo.updateVerificationDetail(
        key: 'email',
        value: email,
        status: 'verified',
      );
      await _load();
    });
  }

  Future<void> _submitPhone(VerificationItem item) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      context.showSnack('Please enter a mobile number', isError: true);
      return;
    }

    final fullPhone = '$_countryCode $phone';

    setState(() => _submittingPhone = true);
    final updateRes = await _repo.updateVerificationDetail(
      key: item.key,
      value: fullPhone,
      status: 'pending',
    );

    if (!mounted) return;
    setState(() {
      _submittingPhone = false;
      _editingPhone = false;
    });

    updateRes.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack('Phone number submitted for verification');
        _load();
      },
    );
  }

  Future<void> _pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path;
      if (path != null) {
        setState(() {
          _selectedFilePaths[key] = path;
          _selectedFileNames[key] = file.name;
        });
      }
    }
  }

  Future<void> _submitDocument(VerificationItem item) async {
    final controller = _getController(item.key, item.value);
    final valueText = controller.text.trim();

    if (valueText.isEmpty) {
      context.showSnack('Please enter ${item.label}', isError: true);
      return;
    }

    final path = _selectedFilePaths[item.key];
    if (path == null || path.isEmpty) {
      context.showSnack('Please choose an image or PDF file first', isError: true);
      return;
    }

    setState(() {
      _submittingItem = true;
      _submittingKey = item.key;
    });

    final uploadRes = await sl<FileUploadHelper>().uploadUrl(
      path: path,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'verification', 'key': item.key},
    );

    if (!mounted) return;

    final documentUrl = uploadRes.valueOrNull;
    if (documentUrl == null) {
      setState(() {
        _submittingItem = false;
        _submittingKey = null;
      });
      context.showSnack(
        uploadRes.failureOrNull?.message ?? 'Failed to upload file',
        isError: true,
      );
      return;
    }

    final updateRes = await _repo.updateVerificationDetail(
      key: item.key,
      value: valueText,
      status: 'pending',
      documentUrl: documentUrl,
    );

    if (!mounted) return;

    setState(() {
      _submittingItem = false;
      _submittingKey = null;
      _editingKeys.remove(item.key);
    });

    updateRes.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack('${item.label} submitted for verification');
        _selectedFilePaths.remove(item.key);
        _selectedFileNames.remove(item.key);
        _load();
      },
    );
  }

  Future<void> _deleteItem(VerificationItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${item.label}?'),
        content: Text(
          'Are you sure you want to delete this pending ${item.label} submission?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _submittingItem = true;
      _submittingKey = item.key;
    });

    final res = await _repo.deleteVerificationDetail(key: item.key);

    if (!mounted) return;

    setState(() {
      _submittingItem = false;
      _submittingKey = null;
      _editingKeys.remove(item.key);
    });

    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack('${item.label} submission deleted');
        _selectedFilePaths.remove(item.key);
        _selectedFileNames.remove(item.key);
        _load();
      },
    );
  }

  IconData _iconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'phone':
      case 'mobile':
        return Icons.phone_outlined;
      case 'identity':
      case 'pan':
      case 'pancard':
      case 'aadhaar':
        return Icons.description_outlined;
      case 'passport':
        return Icons.badge_outlined;
      case 'driving':
        return Icons.card_membership_outlined;
      case 'gst':
        return Icons.receipt_long_outlined;
      case 'address':
        return Icons.location_on_outlined;
      case 'selfie':
        return Icons.face_outlined;
      case 'company':
        return Icons.business_outlined;
      default:
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final email = _headerEmail.isNotEmpty ? _headerEmail : (user?.email ?? '');
    final name = _headerName.isNotEmpty ? _headerName : (user?.fullName ?? 'User');

    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Verification Center'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(
                      fullName: name,
                      email: email,
                      trustScore: _trustScore,
                      verifiedCount: _verifiedCount,
                      pendingCount: _pendingCount,
                      missingCount: _missingCount,
                      accountVerified: _accountVerified,
                    ),
                    AppSizes.vGapMd,
                    for (final item in _items) ...[
                      if (item.key == 'email')
                        _buildEmailCard(item, email)
                      else if (item.key == 'phone' || item.key == 'mobile')
                        _buildPhoneCard(item)
                      else
                        _buildItemCard(item),
                      AppSizes.vGapMd,
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmailCard(VerificationItem item, String email) {
    final isVerified = item.isVerified || _emailVerifiedOverride;

    if (isVerified) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_outlined, color: AppColors.success),
            ),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Verification',
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    email.isNotEmpty ? email : item.value,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSizes.hGapSm,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                AppSizes.hGapXs,
                Text(
                  'Verified',
                  style: context.text.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: AppColors.danger),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Verification',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      email,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSizes.hGapSm,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                  AppSizes.hGapXs,
                  Text(
                    'Not verified',
                    style: context.text.labelSmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _emailOtp,
            label: 'OTP',
            hint: _emailOtpSent ? 'Enter 6-digit OTP' : 'Send OTP first',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
          ),
          AppSizes.vGapMd,
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_sendingEmailOtp || _emailSeconds > 0)
                      ? null
                      : () => _sendEmailOtp(email),
                  icon: _sendingEmailOtp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _emailSeconds > 0
                        ? 'Resend (${_emailSeconds}s)'
                        : 'Send OTP',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_verifyingEmail || !_emailOtpSent)
                      ? null
                      : () => _verifyEmailOtp(email),
                  icon: _verifyingEmail
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard(VerificationItem item) {
    final isEditing = _editingPhone || item.isMissing;
    final isSubmitting = _submittingItem && _submittingKey == item.key;

    if (isEditing) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item.isVerified ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: item.isVerified ? AppColors.success : AppColors.danger,
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone number',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Enter your mobile number to submit.',
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSizes.hGapSm,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isVerified
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: item.isVerified ? AppColors.success : AppColors.danger,
                      size: 16,
                    ),
                    AppSizes.hGapXs,
                    Text(
                      item.isVerified ? 'Verified' : 'Not verified',
                      style: context.text.labelSmall?.copyWith(
                        color: item.isVerified ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSizes.vGapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code', style: context.text.titleSmall),
                      AppSizes.vGapSm,
                      InputDecorator(
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: AppSizes.md,
                          ),
                        ),
                        child: CountryCodePicker(
                          initialSelection: _countryIsoCode,
                          onInit: (code) {
                            if (code == null) return;
                            _countryCode = code.dialCode ?? '+91';
                            _countryIsoCode = code.code ?? 'IN';
                          },
                          onChanged: (code) {
                            setState(() {
                              _countryCode = code.dialCode ?? '+91';
                              _countryIsoCode = code.code ?? 'IN';
                            });
                          },
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          showDropDownButton: false,
                          alignLeft: true,
                          padding: EdgeInsets.zero,
                          flagWidth: 22,
                          textStyle: context.text.bodyMedium,
                          dialogTextStyle: context.text.bodyMedium,
                          searchDecoration: const InputDecoration(
                            hintText: 'Search country',
                          ),
                          builder: (code) => SizedBox(
                            height: 32,
                            child: Row(
                              children: [
                                if (code?.flagUri != null) ...[
                                  Image.asset(
                                    code!.flagUri!,
                                    package: 'country_code_picker',
                                    width: 20,
                                  ),
                                  AppSizes.hGapXs,
                                ],
                                Expanded(
                                  child: Text(
                                    code?.dialCode ?? '+91',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: AppSizes.iconSm),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSizes.hGapSm,
                Expanded(
                  child: AppTextField(
                    controller: _phoneController,
                    label: 'Mobile number',
                    hint: '9515362625',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ),
              ],
            ),
            AppSizes.vGapMd,
            Row(
              children: [
                if (item.isVerified) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _editingPhone = false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  AppSizes.hGapMd,
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submittingPhone ? null : () => _submitPhone(item),
                    icon: _submittingPhone
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (item.isPending) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_outlined, color: AppColors.warning),
            ),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.value.isNotEmpty ? item.value : 'Submitted for review',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSizes.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty_rounded,
                        color: AppColors.warning, size: 16),
                    AppSizes.hGapXs,
                    Text(
                      'Pending',
                      style: context.text.labelMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AppSizes.vGapXs,
                InkWell(
                  onTap: isSubmitting ? null : () => _deleteItem(item),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 14, color: AppColors.danger),
                        AppSizes.hGapXs,
                        Text(
                          'Delete',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Phone is Verified and not editing
    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_outlined, color: AppColors.success),
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone number',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.value,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSizes.hGapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 16),
                  AppSizes.hGapXs,
                  Text(
                    'Done',
                    style: context.text.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              AppSizes.vGapXs,
              InkWell(
                onTap: () {
                  String digits = item.value;
                  if (digits.startsWith('+91')) {
                    _countryCode = '+91';
                    _countryIsoCode = 'IN';
                    digits = digits.replaceAll('+91', '').trim();
                  } else if (digits.contains(' ')) {
                    final parts = digits.split(' ');
                    if (parts.length >= 2) {
                      _countryCode = parts[0];
                      digits = parts.sublist(1).join(' ').trim();
                    }
                  }
                  _phoneController.text = digits;
                  setState(() => _editingPhone = true);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upload_outlined,
                          size: 14, color: AppColors.primary),
                      AppSizes.hGapXs,
                      Text(
                        'Change',
                        style: context.text.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(VerificationItem item) {
    final icon = _iconForKey(item.key);
    final chosenFileName = _selectedFileNames[item.key];
    final isSubmitting = _submittingItem && _submittingKey == item.key;
    final isEditing = _editingKeys.contains(item.key) || item.isMissing;
    final controller = _getController(item.key, item.value);

    if (item.isVerified && !isEditing) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.success),
            ),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.value.isNotEmpty)
                    Text(
                      item.value,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            AppSizes.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 16),
                    AppSizes.hGapXs,
                    Text(
                      'Done',
                      style: context.text.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AppSizes.vGapXs,
                InkWell(
                  onTap: () {
                    controller.text =
                        item.value == 'Not submitted' ? '' : item.value;
                    setState(() => _editingKeys.add(item.key));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_outlined,
                            size: 14, color: AppColors.primary),
                        AppSizes.hGapXs,
                        Text(
                          'Change',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (item.isPending && !isEditing) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.warning),
            ),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.value.isNotEmpty ? item.value : 'Submitted for review',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSizes.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty_rounded,
                        color: AppColors.warning, size: 16),
                    AppSizes.hGapXs,
                    Text(
                      'Pending',
                      style: context.text.labelMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AppSizes.vGapXs,
                InkWell(
                  onTap: isSubmitting ? null : () => _deleteItem(item),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 14, color: AppColors.danger),
                        AppSizes.hGapXs,
                        Text(
                          'Delete',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Status: Missing or Editing
    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item.isVerified
                          ? AppColors.success
                          : (item.isPending
                              ? AppColors.warning
                              : AppColors.danger))
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: item.isVerified
                      ? AppColors.success
                      : (item.isPending
                          ? AppColors.warning
                          : AppColors.danger),
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Please enter details & upload your ${item.label}.',
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSizes.hGapSm,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isVerified
                        ? Icons.check_circle_outline
                        : (item.isPending
                            ? Icons.hourglass_empty_rounded
                            : Icons.error_outline),
                    color: item.isVerified
                        ? AppColors.success
                        : (item.isPending
                            ? AppColors.warning
                            : AppColors.danger),
                    size: 16,
                  ),
                  AppSizes.hGapXs,
                  Text(
                    item.isVerified
                        ? 'Verified'
                        : (item.isPending ? 'Pending' : 'Not verified'),
                    style: context.text.labelSmall?.copyWith(
                      color: item.isVerified
                          ? AppColors.success
                          : (item.isPending
                              ? AppColors.warning
                              : AppColors.danger),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: controller,
            label: item.label,
            hint: 'Enter ${item.label}',
            prefixIcon: icon,
            textInputAction: TextInputAction.next,
          ),
          AppSizes.vGapMd,
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : () => _pickFile(item.key),
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              chosenFileName ?? 'Choose file',
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          AppSizes.vGapMd,
          Row(
            children: [
              if (item.isVerified || item.isPending) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _editingKeys.remove(item.key)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                AppSizes.hGapMd,
              ],
              Expanded(
                child: AppPrimaryButton(
                  label: 'Submit',
                  icon: Icons.check_circle_outline,
                  isLoading: isSubmitting,
                  onPressed: (isSubmitting || chosenFileName == null)
                      ? null
                      : () => _submitDocument(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.fullName,
    required this.email,
    required this.trustScore,
    required this.verifiedCount,
    required this.pendingCount,
    required this.missingCount,
    required this.accountVerified,
  });

  final String fullName;
  final String email;
  final int trustScore;
  final int verifiedCount;
  final int pendingCount;
  final int missingCount;
  final bool accountVerified;

  @override
  Widget build(BuildContext context) {
    final progressValue = (trustScore / 100).clamp(0.0, 1.0);

    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(
                name: fullName.isNotEmpty ? fullName : 'User',
                size: 48,
                showOnline: true,
                isOnline: true,
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'User',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSizes.hGapSm,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accountVerified
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  accountVerified ? 'Verified Account' : 'Unverified',
                  style: context.text.labelSmall?.copyWith(
                    color: accountVerified
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          AppSizes.vGapMd,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trust Score: $trustScore%',
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSizes.vGapXs,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 8,
                        backgroundColor: context.theme.dividerColor,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSizes.vGapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBadge(
                label: 'Verified',
                count: verifiedCount,
                color: AppColors.success,
              ),
              _StatBadge(
                label: 'Pending',
                count: pendingCount,
                color: AppColors.warning,
              ),
              _StatBadge(
                label: 'Missing',
                count: missingCount,
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSizes.hGapXs,
        Text(
          '$label: ',
          style: context.text.labelSmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        Text(
          '$count',
          style: context.text.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
