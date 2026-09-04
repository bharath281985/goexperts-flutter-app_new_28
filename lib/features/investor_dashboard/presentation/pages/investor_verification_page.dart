import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/app_config.dart';
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
import '../../domain/repositories/investor_repository.dart';

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
          json['documentUrl']?.toString() ??
          json['document_url']?.toString() ??
          json['publicUrl']?.toString() ??
          json['url']?.toString() ??
          json['file']?.toString(),
      required: json['required'] == true,
    );
  }
}

class InvestorVerificationPage extends StatefulWidget {
  const InvestorVerificationPage({super.key});

  @override
  State<InvestorVerificationPage> createState() =>
      _InvestorVerificationPageState();
}

class _InvestorVerificationPageState extends State<InvestorVerificationPage> {
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

  String _selectedBusinessProofKey = 'gst';
  String _selectedIdentityKey = 'pan';
  static const Map<String, String> _businessProofOptions = {
    'gst': 'GST Certificate',
    'udyam': 'Udyam Aadhaar',
    'incorporation': 'Incorporation Proof',
    'business_pan': 'Business PAN',
    'company': 'Company Registration',
  };

  static const Map<String, String> _identityOptions = {
    'pan': 'PAN Card',
    'aadhaar': 'Aadhaar Card',
    'driving_licence': 'Driving Licence',
  };

  InvestorRepository get _repo => sl<InvestorRepository>();

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

    res.fold((f) {}, (data) {
      if (data.isNotEmpty) {
        final payload = (data['data'] is Map)
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;

        final rawItems = payload['items'] as List?;
        if (rawItems != null && rawItems.isNotEmpty) {
          _items = rawItems
              .map((e) {
                final map = Map<String, dynamic>.from(e as Map);
                final key = map['key']?.toString().toLowerCase() ?? '';
                // Ensure proper labels if not provided by backend
                if (_businessProofOptions.containsKey(key) &&
                    map['label'] == null) {
                  map['label'] = _businessProofOptions[key];
                }
                if (_identityOptions.containsKey(key) && map['label'] == null) {
                  map['label'] = _identityOptions[key];
                }
                return VerificationItem.fromJson(map);
              })
              .where((item) => item.key != 'selfie' && item.key != 'address')
              .toList();

          setState(() {
            final presentBusinessKeys = _items
                .map((e) => e.key)
                .where((k) => _businessProofOptions.containsKey(k))
                .toList();
            if (presentBusinessKeys.isNotEmpty) {
              _selectedBusinessProofKey = presentBusinessKeys.first;
            }

            final presentIdentityKeys = _items
                .map((e) => e.key)
                .where((k) => _identityOptions.containsKey(k))
                .toList();
            if (presentIdentityKeys.isNotEmpty) {
              _selectedIdentityKey = presentIdentityKeys.first;
            }
          });

          for (final item in _items) {
            if (item.value.isNotEmpty && item.value != 'Not submitted') {
              final ctrl = _itemValueControllers[item.key];
              if (ctrl != null) {
                ctrl.text = item.value;
              }
            }
          }
        }

        _trustScore = _parseInt(
          payload['trustScore'] ?? payload['trust_score'],
        );
        _verifiedCount = _parseInt(
          payload['verifiedCount'] ?? payload['verified_count'],
        );
        _pendingCount = _parseInt(
          payload['pendingCount'] ?? payload['pending_count'],
        );
        _missingCount = _parseInt(
          payload['missingCount'] ?? payload['missing_count'],
        );
        _accountVerified = payload['accountVerified'] == true;
        _headerName =
            payload['fullName']?.toString() ?? user?.fullName ?? 'User';
        _headerEmail = payload['email']?.toString() ?? user?.email ?? '';
      }
    });

    final keysPresent = _items.map((i) => i.key).toSet();

    final presentIdentityKeys = keysPresent.intersection(
      _identityOptions.keys.toSet(),
    );
    if (presentIdentityKeys.length < 2 && !keysPresent.contains('identity')) {
      _items.add(
        VerificationItem(
          key: 'identity',
          label: 'Identity Document',
          value: 'Not submitted',
          status: 'missing',
          required: true,
        ),
      );
    }

    final presentBusinessKeys = keysPresent.intersection(
      _businessProofOptions.keys.toSet(),
    );
    if (presentBusinessKeys.length < 2 &&
        !keysPresent.contains('business_proof')) {
      _items.add(
        VerificationItem(
          key: 'business_proof',
          label: 'Business Document',
          value: 'Not submitted',
          status: 'missing',
          required: true,
        ),
      );
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
      final updateRes = await _repo.updateVerificationDetail(
        key: 'email',
        value: email,
        status: 'verified',
      );
      if (!mounted) return;
      final apiMsg = updateRes.valueOrNull;
      final displayMsg = (apiMsg != null && apiMsg.trim().isNotEmpty)
          ? apiMsg.trim()
          : 'Email verified successfully';
      context.showSnack(displayMsg);
      await _load();
    });
  }

  Future<bool> _submitPhone(VerificationItem item) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      context.showSnack('Please enter a mobile number', isError: true);
      return false;
    }

    final fullPhone = '$_countryCode $phone';

    setState(() => _submittingPhone = true);
    final updateRes = await _repo.updateVerificationDetail(
      key: item.key,
      value: fullPhone,
      status: 'pending',
    );

    if (!mounted) return false;
    setState(() {
      _submittingPhone = false;
      _editingPhone = false;
    });

    if (updateRes.isFailure) {
      context.showSnack(
        updateRes.failureOrNull?.message ?? 'Failed to submit phone number',
        isError: true,
      );
      return false;
    }

    final msg = updateRes.valueOrNull;
    final displayMsg = (msg != null && msg.trim().isNotEmpty)
        ? msg.trim()
        : 'Phone number submitted for verification';
    context.showSnack(displayMsg);
    _load();
    return true;
  }

  String? _validateDocument(String key, String value) {
    final normalized = value.trim().toUpperCase().replaceAll(' ', '');
    final Map<String, Map<String, dynamic>> validators = {
      'pan': {
        'regex': RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$'),
        'message': 'Invalid PAN format (e.g. ABCDE1234F)',
      },
      'pancard': {
        'regex': RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$'),
        'message': 'Invalid PAN format (e.g. ABCDE1234F)',
      },
      'business_pan': {
        'regex': RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$'),
        'message': 'Invalid PAN format (e.g. ABCDE1234F)',
      },
      'aadhaar': {
        'regex': RegExp(r'^\d{4}\s?\d{4}\s?\d{4}$'),
        'message': 'Invalid Aadhaar format (12 digits)',
      },
      'gst': {
        'regex': RegExp(
          r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
        ),
        'message': 'Invalid GSTIN format (e.g. 27ABCDE1234F1Z5)',
      },
      'udyam': {
        'regex': RegExp(r'^UDYAM-[A-Z]{2}-[0-9]{2}-[0-9]{7}$'),
        'message': 'Invalid Udyam number (e.g. UDYAM-MH-18-0123456)',
      },
      'driving': {
        'regex': RegExp(r'^[A-Z0-9-/\s]{10,20}$', caseSensitive: false),
        'message': 'Invalid Driving Licence format',
      },
      'driving_licence': {
        'regex': RegExp(r'^[A-Z0-9-/\s]{10,20}$', caseSensitive: false),
        'message': 'Invalid Driving Licence format',
      },
      'incorporation': {
        'regex': RegExp(r'^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$'),
        'message': 'Invalid CIN format (e.g. U12345MH2020PTC123456)',
      },
      'company': {
        'regex': RegExp(r'^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$'),
        'message': 'Invalid CIN format (e.g. U12345MH2020PTC123456)',
      },
    };
    if (validators.containsKey(key)) {
      final RegExp regex = validators[key]!['regex'];
      if (!regex.hasMatch(normalized)) {
        return validators[key]!['message'];
      }
    }
    return null;
  }

  Future<bool> _submitDocument(
    VerificationItem item, {
    String? explicitValue,
  }) async {
    final controller = _getController(item.key, item.value);
    final valueText = (explicitValue ?? controller.text).trim().toUpperCase();

    final isBusinessCard =
        item.key == 'business_proof' ||
        item.key == 'company' ||
        _businessProofOptions.containsKey(item.key);
    final isIdentityCard =
        item.key == 'identity' || _identityOptions.containsKey(item.key);
    final actualKey = isBusinessCard
        ? _selectedBusinessProofKey
        : (isIdentityCard ? _selectedIdentityKey : item.key);
    final actualLabel = isBusinessCard
        ? (_businessProofOptions[actualKey] ?? item.label)
        : (isIdentityCard
              ? (_identityOptions[actualKey] ?? item.label)
              : item.label);

    if (valueText.isEmpty) {
      context.showSnack('Please enter $actualLabel Number', isError: true);
      return false;
    }

    final validationError = _validateDocument(actualKey, valueText);
    if (validationError != null) {
      context.showSnack(validationError, isError: true);
      return false;
    }

    final path = _selectedFilePaths[item.key];
    final hasExistingDoc =
        item.documentUrl != null && item.documentUrl!.isNotEmpty;

    if ((path == null || path.isEmpty) && !hasExistingDoc) {
      context.showSnack('Please select a document to upload', isError: true);
      return false;
    }
    String? documentUrl = item.documentUrl;

    setState(() {
      _submittingItem = true;
      _submittingKey = item.key;
    });

    if (path != null && path.isNotEmpty) {
      final uploadRes = await sl<FileUploadHelper>().upload(
        path: path,
        endpoint: ApiEndpoints.filesUpload,
        method: 'post',
      );

      if (uploadRes.isFailure) {
        if (!mounted) return false;
        setState(() {
          _submittingItem = false;
          _submittingKey = null;
        });
        context.showSnack(
          'File upload failed: ${uploadRes.failureOrNull?.message}',
          isError: true,
        );
        return false;
      }

      final data = uploadRes.valueOrNull;
      if (data != null) {
        documentUrl = data['publicUrl']?.toString() ?? data['url']?.toString();
      }
    }

    final updateRes = await _repo.updateVerificationDetail(
      key: actualKey,
      value: valueText,
      status: 'pending',
      documentUrl: documentUrl,
    );

    if (updateRes.isFailure) {
      if (!mounted) return false;
      setState(() {
        _submittingItem = false;
        _submittingKey = null;
      });
      context.showSnack(
        updateRes.failureOrNull?.message ?? 'Failed to submit verification',
        isError: true,
      );
      return false;
    }
    bool isSuccess = true;
    final displayMsg = updateRes.valueOrNull;

    if (!mounted) return false;

    setState(() {
      _submittingItem = false;
      _submittingKey = null;
      _editingKeys.remove(item.key);
    });

    if (isSuccess) {
      final msg = (displayMsg != null && displayMsg.trim().isNotEmpty)
          ? displayMsg.trim()
          : '${item.label} submitted for verification';
      context.showSnack(msg);
      _selectedFilePaths.remove(item.key);
      _selectedFileNames.remove(item.key);
      _load();
    }
    return true;
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

    res.fold((f) => context.showSnack(f.message, isError: true), (msg) {
      final displayMsg = (msg != null && msg.trim().isNotEmpty)
          ? msg.trim()
          : '${item.label} submission deleted';
      context.showSnack(displayMsg);
      _selectedFilePaths.remove(item.key);
      _selectedFileNames.remove(item.key);
      _load();
    });
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

  Widget _compactCardHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget status,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            AppSizes.hGapSm,
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: status),
            ),
          ],
        ),
        AppSizes.vGapSm,
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle.isNotEmpty) ...[
          AppSizes.vGapXs,
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String sectionTitle,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<VerificationItem> items,
    required int requiredCount,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final submittedItems = items.where((i) => !i.isMissing).toList();
    final submittedCount = submittedItems.length;
    final isMet = submittedCount >= requiredCount;
    final displayItems = isMet ? submittedItems : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSizes.vGapXl,
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Text(
                sectionTitle.toUpperCase(),
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        AppSizes.vGapLg,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.danger, size: 24),
            ),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSizes.vGapXs,
                  Text(
                    subtitle,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isMet
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMet ? AppColors.success : AppColors.warning,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: isMet ? AppColors.success : AppColors.warning,
                  ),
                  AppSizes.hGapXs,
                  Text(
                    '$submittedCount/$requiredCount submitted',
                    style: context.text.labelSmall?.copyWith(
                      color: isMet ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSizes.vGapLg,
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSizes.sm;
            final columns = constraints.maxWidth >= 600 ? 2 : 1;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: AppSizes.md,
              children: displayItems.map((item) {
                return SizedBox(width: cardWidth, child: _buildItemCard(item));
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final email = _headerEmail.isNotEmpty ? _headerEmail : (user?.email ?? '');
    final name = _headerName.isNotEmpty
        ? _headerName
        : (user?.fullName ?? 'User');

    final basicKeys = ['email', 'phone', 'mobile'];
    final identityKeys = ['identity', ..._identityOptions.keys];
    final businessKeys = ['business_proof', ..._businessProofOptions.keys];

    final basicItems = _items.where((i) => basicKeys.contains(i.key)).toList();
    final identityItems =
        _items
            .where((i) => identityKeys.contains(i.key) || i.key == 'pancard')
            .toList()
          ..sort(
            (a, b) => identityKeys
                .indexOf(a.key)
                .compareTo(identityKeys.indexOf(b.key)),
          );

    while (identityItems.length < 2) {
      identityItems.add(
        VerificationItem(
          key: 'identity',
          label: 'Additional Identity Document',
          value: '',
          status: 'missing',
          required: true,
        ),
      );
    }

    final businessItems =
        _items.where((i) => businessKeys.contains(i.key)).toList()..sort(
          (a, b) => businessKeys
              .indexOf(a.key)
              .compareTo(businessKeys.indexOf(b.key)),
        );

    while (businessItems.length < 2) {
      businessItems.add(
        VerificationItem(
          key: 'business_proof',
          label: 'Additional Business Document',
          value: '',
          status: 'missing',
          required: true,
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Investor Verification'),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppSizes.sm;
                        final columns = constraints.maxWidth >= 600 ? 2 : 1;
                        final cardWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: AppSizes.md,
                          children: basicItems.map((item) {
                            final card = item.key == 'email'
                                ? _buildEmailCard(item, email)
                                : item.key == 'phone' || item.key == 'mobile'
                                ? _buildPhoneCard(item)
                                : _buildItemCard(item);
                            return SizedBox(width: cardWidth, child: card);
                          }).toList(),
                        );
                      },
                    ),
                    if (identityItems.isNotEmpty)
                      _buildSection(
                        context: context,
                        sectionTitle: 'Identity Documents',
                        title: 'Personal Documents',
                        subtitle:
                            'Upload any 2 of the following personal identity proofs',
                        icon: Icons.person_outline,
                        items: identityItems,
                        requiredCount: 2,
                      ),
                    if (businessItems.isNotEmpty)
                      _buildSection(
                        context: context,
                        sectionTitle: 'Business Documents',
                        title: 'Business Documents',
                        subtitle:
                            'Upload any 2 of the following business registration proofs',
                        icon: Icons.domain_outlined,
                        items: businessItems,
                        requiredCount: 2,
                      ),
                    AppSizes.vGapLg,
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
        padding: const EdgeInsets.all(AppSizes.sm),
        child: _compactCardHeader(
          icon: Icons.email_outlined,
          color: AppColors.success,
          title: 'Email Verification',
          subtitle: email.isNotEmpty ? email : item.value,
          status: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
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
        ),
      );
    }

    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _compactCardHeader(
            icon: Icons.email_outlined,
            color: AppColors.danger,
            title: 'Email Verification',
            subtitle: email,
            status: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                  size: 16,
                ),
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
          Column(
            children: [
              SizedBox(
                width: double.infinity,
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
              AppSizes.vGapSm,
              SizedBox(
                width: double.infinity,
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
    final isSubmitting = _submittingItem && _submittingKey == item.key;
    if (item.isMissing) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_outlined, color: AppColors.danger),
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
                    item.value.isNotEmpty ? item.value : 'Not verified',
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
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    AppSizes.hGapXs,
                    if (MediaQuery.sizeOf(context).width >= 600)
                      Text(
                        'Not verified',
                        style: context.text.labelSmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                AppSizes.vGapXs,
                InkWell(
                  onTap: () => _showPhoneBottomSheet(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        AppSizes.hGapXs,
                        Text(
                          'Add',
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

    if (item.isPending) {
      return AppCard(
        radius: AppSizes.radiusMd,
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
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
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.danger,
                        ),
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

    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
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
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 16,
                  ),
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
                onTap: () => _showPhoneBottomSheet(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.upload_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
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

  void _showPhoneBottomSheet(VerificationItem item) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom +
                    MediaQuery.paddingOf(context).bottom,
                left: AppSizes.md,
                right: AppSizes.md,
                top: AppSizes.md,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Update Phone Number',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    AppSizes.vGapMd,
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
                          setSheetState(() {
                            _countryCode = code.dialCode ?? '+91';
                            _countryIsoCode = code.code ?? 'IN';
                          });
                        },
                        favorite: const ['+91', 'IN'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: true,
                        padding: EdgeInsets.zero,
                        textStyle: context.text.bodyMedium,
                        searchStyle: context.text.bodyMedium,
                        dialogTextStyle: context.text.bodyMedium,
                      ),
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _phoneController,
                      label: 'Mobile Number',
                      hint: 'Enter Mobile Number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    AppSizes.vGapMd,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submittingPhone
                            ? null
                            : () async {
                                setSheetState(() => _submittingPhone = true);
                                final success = await _submitPhone(item);
                                if (mounted) {
                                  setSheetState(() => _submittingPhone = false);
                                  if (success) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                        icon: _submittingPhone
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
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
                    AppSizes.vGapLg,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isEmpty) {
      if (mounted) context.showSnack('Document URL is empty', isError: true);
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = AppConfig.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      url = '$base${url.startsWith('/') ? '' : '/'}$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) context.showSnack('Invalid document URL', isError: true);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        if (mounted)
          context.showSnack('Could not open document', isError: true);
      }
    }
  }

  Future<void> _viewDocument(VerificationItem item) async {
    final documentUrl = item.documentUrl?.trim();
    final value = item.value.trim();

    String? url = (documentUrl != null && documentUrl.isNotEmpty)
        ? documentUrl
        : null;
    if (url == null &&
        value.isNotEmpty &&
        value != 'Not submitted' &&
        value != 'Submitted for review') {
      url = value;
    }

    if (url == null) {
      if (mounted)
        context.showSnack('Document is not available to view', isError: true);
      return;
    }
    await _launchUrl(url);
  }

  void _showDocumentBottomSheet(VerificationItem item, [IconData? icon]) {
    final controller = TextEditingController();
    String? numberError;
    String? fileError;
    if (item.value != 'Not submitted') controller.text = item.value;
    final keysPresent = _items.map((i) => i.key).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isSubmitting = _submittingItem && _submittingKey == item.key;
            final chosenFileName = _selectedFileNames[item.key];
            final hasExistingDoc =
                item.documentUrl != null && item.documentUrl!.isNotEmpty;

            final submittedIdentityKeys = _items
                .where((i) => !i.isMissing)
                .expand((i) {
                  if (i.key == 'identity') return ['identity', 'aadhaar'];
                  if (i.key == 'pancard') return ['pancard', 'pan'];
                  return [i.key];
                })
                .toList();

            final currentItemKeys = [item.key];
            if (item.key == 'identity') currentItemKeys.add('aadhaar');
            if (item.key == 'pancard') currentItemKeys.add('pan');

            final availableIdentityOptions = Map.fromEntries(
              _identityOptions.entries.where(
                (e) =>
                    !submittedIdentityKeys.contains(e.key) ||
                    currentItemKeys.contains(e.key),
              ),
            );
            if (!availableIdentityOptions.containsKey(_selectedIdentityKey) &&
                availableIdentityOptions.isNotEmpty) {
              _selectedIdentityKey = availableIdentityOptions.keys.first;
            }

            final submittedBusinessKeys = _items
                .where((i) => !i.isMissing)
                .map((i) => i.key)
                .toList();
            final availableBusinessOptions = Map.fromEntries(
              _businessProofOptions.entries.where(
                (e) =>
                    !submittedBusinessKeys.contains(e.key) || item.key == e.key,
              ),
            );
            if (!availableBusinessOptions.containsKey(
                  _selectedBusinessProofKey,
                ) &&
                availableBusinessOptions.isNotEmpty) {
              _selectedBusinessProofKey = availableBusinessOptions.keys.first;
            }

            final isBusinessCard =
                item.key == 'business_proof' ||
                item.key == 'company' ||
                _businessProofOptions.containsKey(item.key);
            final isIdentityCard =
                item.key == 'identity' ||
                item.key == 'pancard' ||
                _identityOptions.containsKey(item.key);
            final actualKey = isBusinessCard
                ? _selectedBusinessProofKey
                : (isIdentityCard ? _selectedIdentityKey : item.key);
            final actualLabel = isBusinessCard
                ? (_businessProofOptions[actualKey] ?? item.label)
                : (isIdentityCard
                      ? (_identityOptions[actualKey] ?? item.label)
                      : item.label);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom +
                    MediaQuery.paddingOf(context).bottom,
                left: AppSizes.md,
                right: AppSizes.md,
                top: AppSizes.md,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upload $actualLabel',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    AppSizes.vGapMd,
                    if (item.key == 'business_proof' ||
                        item.key == 'company' ||
                        _businessProofOptions.containsKey(item.key) ||
                        item.key == 'identity' ||
                        item.key == 'pancard' ||
                        _identityOptions.containsKey(item.key)) ...[
                      if (isIdentityCard)
                        DropdownButtonFormField<String>(
                          value: _selectedIdentityKey,
                          decoration: const InputDecoration(
                            labelText: 'Document Type',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          items: availableIdentityOptions.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setSheetState(() => _selectedIdentityKey = val);
                          },
                        ),
                      if (isBusinessCard)
                        DropdownButtonFormField<String>(
                          value: _selectedBusinessProofKey,
                          decoration: const InputDecoration(
                            labelText: 'Document Type',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          items: availableBusinessOptions.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setSheetState(
                                () => _selectedBusinessProofKey = val,
                              );
                          },
                        ),
                      AppSizes.vGapMd,
                    ],
                    Builder(
                      builder: (context) {
                        int? maxLength;
                        TextInputType? keyboardType;
                        String hintText = 'Enter document number';

                        switch (actualKey) {
                          case 'pan':
                          case 'business_pan':
                          case 'pancard':
                            maxLength = 10;
                            hintText = 'e.g. ABCDE1234F';
                            break;
                          case 'aadhaar':
                            maxLength = 12;
                            keyboardType = TextInputType.number;
                            hintText = 'e.g. 1234 5678 9012';
                            break;
                          case 'gst':
                            maxLength = 15;
                            hintText = '15-character GSTIN';
                            break;
                          case 'udyam':
                            maxLength = 25;
                            hintText = 'e.g. UDYAM-MH-18-0123456';
                            break;
                          case 'driving':
                          case 'driving_licence':
                            maxLength = 20;
                            hintText = 'e.g. DL1420110012345';
                            break;
                          case 'passport':
                            maxLength = 12;
                            hintText = 'e.g. A1234567';
                            break;
                          case 'incorporation':
                          case 'company':
                            maxLength = 25;
                            hintText = 'e.g. U12345MH2020PTC123456';
                            break;
                        }

                        return AppTextField(
                          controller: controller,
                          label: '${actualLabel} Number',
                          hint: hintText,
                          prefixIcon: icon,
                          keyboardType: keyboardType,
                          maxLength: maxLength,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {
                            if (numberError != null) {
                              setSheetState(() => numberError = null);
                            }
                          },
                        );
                      },
                    ),
                    if (numberError != null) ...[
                      AppSizes.vGapSm,
                      Text(
                        numberError!,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    AppSizes.vGapMd,
                    OutlinedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'jpg',
                                      'jpeg',
                                      'png',
                                      'pdf',
                                    ],
                                  );
                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                final path = file.path;
                                if (path == null || path.isEmpty) {
                                  setSheetState(() {
                                    fileError =
                                        'Unable to access the selected file';
                                  });
                                  return;
                                }
                                if (file.size > 5 * 1024 * 1024) {
                                  setSheetState(() {
                                    fileError =
                                        'File size must be 5 MB or less';
                                  });
                                  return;
                                }
                                setSheetState(() {
                                  fileError = null;
                                  _selectedFilePaths[item.key] = path;
                                  _selectedFileNames[item.key] = file.name;
                                });
                                // Also update parent state
                                setState(() {
                                  _selectedFilePaths[item.key] = path;
                                  _selectedFileNames[item.key] = file.name;
                                });
                              }
                            },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        chosenFileName ??
                            (hasExistingDoc
                                ? 'Document previously uploaded (Click to change)'
                                : 'Choose image or pdf'),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    if (fileError != null) ...[
                      AppSizes.vGapSm,
                      Text(
                        fileError!,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    AppSizes.vGapLg,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final isBusinessCard =
                                    item.key == 'business_proof' ||
                                    item.key == 'company' ||
                                    _businessProofOptions.containsKey(item.key);
                                final isIdentityCard =
                                    item.key == 'identity' ||
                                    item.key == 'pancard' ||
                                    _identityOptions.containsKey(item.key);
                                final actualKey = isBusinessCard
                                    ? _selectedBusinessProofKey
                                    : (isIdentityCard
                                          ? _selectedIdentityKey
                                          : item.key);

                                final valueText = controller.text.trim();
                                if (valueText.isEmpty) {
                                  setSheetState(() {
                                    numberError =
                                        'Please enter $actualLabel Number';
                                  });
                                  return;
                                }

                                final validationError = _validateDocument(
                                  actualKey,
                                  valueText,
                                );
                                if (validationError != null) {
                                  setSheetState(() {
                                    numberError = validationError;
                                  });
                                  return;
                                }

                                final path = _selectedFilePaths[item.key];
                                if ((path == null || path.isEmpty) &&
                                    !hasExistingDoc) {
                                  setSheetState(() {
                                    fileError =
                                        'Please select a document to upload';
                                  });
                                  return;
                                }

                                setSheetState(() {
                                  _submittingItem = true;
                                  _submittingKey = item.key;
                                });
                                // Call parent method
                                final success = await _submitDocument(
                                  item,
                                  explicitValue: valueText,
                                );
                                if (mounted) {
                                  setSheetState(() {
                                    _submittingItem = false;
                                    _submittingKey = null;
                                  });
                                  if (success) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Submit Document'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                    AppSizes.vGapLg,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(VerificationItem item) {
    final isSubmitting = _submittingItem && _submittingKey == item.key;
    final icon = _iconForKey(item.key);

    // Determine colors
    Color color;
    if (item.isVerified) {
      color = AppColors.success;
    } else if (item.isPending) {
      color = AppColors.warning;
    } else {
      color = AppColors.danger;
    }

    // Determine status text/icon
    IconData statusIcon;
    String statusText;
    if (item.isVerified) {
      statusIcon = Icons.check_circle_outline;
      statusText = 'Verified';
    } else if (item.isPending) {
      statusIcon = Icons.hourglass_empty_rounded;
      statusText = 'Pending';
    } else {
      statusIcon = Icons.error_outline;
      statusText = 'Missing';
    }

    String subtitle = item.isPending
        ? 'Submitted for review'
        : (item.isVerified ? item.value : 'Please upload your ${item.label}.');

    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.sm),
      child: _compactCardHeader(
        icon: icon,
        color: color,
        title: item.label,
        subtitle: subtitle,
        status: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: color, size: 16),
                AppSizes.hGapXs,
                Text(
                  statusText,
                  style: context.text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            AppSizes.vGapXs,
            // Action Buttons Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!item.isVerified &&
                    item.documentUrl != null &&
                    item.documentUrl!.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _launchUrl(item.documentUrl!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          AppSizes.hGapXs,
                          Text(
                            'View',
                            style: context.text.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSizes.hGapSm,
                ],
                InkWell(
                  onTap: item.isVerified
                      ? () => _viewDocument(item)
                      : () => _showDocumentBottomSheet(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isVerified
                              ? Icons.visibility_outlined
                              : item.isPending
                              ? Icons.edit_outlined
                              : Icons.add_circle_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        AppSizes.hGapXs,
                        Text(
                          item.isVerified
                              ? 'View'
                              : (item.isPending ? 'Change' : 'Add'),
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
              Builder(
                builder: (context) {
                  final isFullyVerified = accountVerified && missingCount == 0;
                  final isPending = !isFullyVerified && pendingCount > 0 && missingCount == 0;
                  final badgeText = isFullyVerified
                      ? 'Verified Account'
                      : (isPending ? 'Pending' : 'Not Verified');
                  final badgeColor = isFullyVerified
                      ? AppColors.success
                      : (isPending ? AppColors.warning : AppColors.danger);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: context.text.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
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
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
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
          style: context.text.labelSmall?.copyWith(color: AppColors.mutedText),
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
