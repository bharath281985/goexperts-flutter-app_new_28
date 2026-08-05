import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/payments/payment_checkout_service.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

class ClientCompanyProfilePage extends StatefulWidget {
  const ClientCompanyProfilePage({super.key});

  @override
  State<ClientCompanyProfilePage> createState() =>
      _ClientCompanyProfilePageState();
}

class _ClientCompanyProfilePageState extends State<ClientCompanyProfilePage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _phoneCode = TextEditingController(text: '+91');
  final _countryCode = TextEditingController(text: 'IN');
  final _companyNameController = TextEditingController();
  final _industry = TextEditingController();
  final _teamSize = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _website = TextEditingController();
  final _linkedin = TextEditingController();
  final _pan = TextEditingController();
  final _aadhaar = TextEditingController();
  final _gst = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Company? _companyData;
  String? _localLogoPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _phoneCode.dispose();
    _countryCode.dispose();
    _companyNameController.dispose();
    _industry.dispose();
    _teamSize.dispose();
    _bio.dispose();
    _city.dispose();
    _country.dispose();
    _website.dispose();
    _linkedin.dispose();
    _pan.dispose();
    _aadhaar.dispose();
    _gst.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await sl<CompanyRepository>().getClientProfile();
    if (!mounted) return;
    res.fold((f) => context.showSnack(f.message), (c) {
      _companyData = c;
      _name.text = c.ownerName.isNotEmpty ? c.ownerName : c.name;
      _email.text = c.email;
      _phone.text = c.phone;
      _phoneCode.text = c.phoneCode.isEmpty ? '+91' : c.phoneCode;
      _countryCode.text = c.countryCode.isEmpty ? 'IN' : c.countryCode;
      _companyNameController.text = c.name;
      _industry.text = c.industry;
      _teamSize.text = c.teamSize;
      _bio.text = c.bio;
      _city.text = c.city;
      _country.text = c.country;
      _website.text = c.website ?? '';
      _linkedin.text = c.linkedin;
      _pan.text = (c.pan.isNotEmpty ? c.pan : c.panNumber);
      _aadhaar.text = c.aadhaarNumber;
      _gst.text = c.gst;
    });
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      context.showSnack('Full name is required', isError: true);
      return;
    }
    setState(() => _saving = true);
    final res = await sl<CompanyRepository>().updateClientProfile({
      'fullName': _name.text.trim(),
      'phone': _phone.text.trim(),
      'phoneCode': _phoneCode.text.trim(),
      'countryCode': _countryCode.text.trim(),
      'companyName': _companyNameController.text.trim(),
      'industry': _industry.text.trim(),
      'companySize': _teamSize.text.trim(),
      'bio': _bio.text.trim(),
      'city': _city.text.trim(),
      'countryId': _country.text.trim(),
      'website': _website.text.trim(),
      'linkedin': _linkedin.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (res.isSuccess) {
        _localLogoPath = null;
      }
    });
    res.fold((f) => context.showSnack(f.message), (_) {
      context.showSnack('Company profile updated');
      final currentUser = context.read<AuthBloc>().state.user;
      if (currentUser != null) {
        context.read<AuthBloc>().add(
          AuthUserUpdated(currentUser.copyWith(fullName: _name.text.trim())),
        );
      }
      Navigator.of(context).pop();
    });
  }

  Future<void> _uploadDoc() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (picked == null || picked.files.single.path == null) return;
    final res = await sl<CompanyRepository>().uploadClientDocument(
      picked.files.single.path!,
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Document uploaded'),
    );
  }

  Future<void> _uploadLogo(String path) async {
    setState(() => _localLogoPath = path);
    final result = await sl<CompanyRepository>().uploadClientLogo(path);
    if (!mounted) return;
    result.fold(
      (failure) => context.showSnack(failure.message, isError: true),
      (url) {
        setState(() {
          _localLogoPath = null;
        });
        context.read<AuthBloc>().add(const AuthRefreshUser());
        context.showSnack('Company logo updated');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companyData?.isVerified == true
                            ? 'Verified business'
                            : 'Verification pending',
                      ),
                      const SizedBox(height: 6),
                      Text('Profile completion: ${_completionPercent()}%'),
                    ],
                  ),
                ),
                AppSizes.vGapMd,
                ProfileAvatarEditor(
                  localPath: _localLogoPath,
                  networkUrl: _companyData?.logoUrl,
                  onPathPicked: _uploadLogo,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _name,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                ),
                AppSizes.vGapMd,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: AppTextField(
                        controller: _phoneCode,
                        label: 'Code',
                        hint: '+91',
                      ),
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: AppTextField(
                        controller: _phone,
                        label: 'Phone Number',
                        hint: 'Enter contact phone',
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                    ),
                  ],
                ),
                AppSizes.vGapLg,
                Text('Company Info', style: context.text.titleMedium),
                AppSizes.vGapSm,
                AppTextField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  hint: 'Enter company name',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _bio,
                  label: 'Biography / Overview',
                  hint: 'Brief description about the company',
                  maxLines: 3,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _industry,
                  label: 'Industry',
                  hint: 'Enter industry (e.g. Technology)',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _teamSize,
                  label: 'Company Size',
                  hint: 'e.g. 50-200',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _city,
                  label: 'City',
                  hint: 'Your city',
                ),
                AppSizes.vGapMd,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: AppTextField(
                        controller: _countryCode,
                        label: 'Country Code',
                        hint: 'IN',
                      ),
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: AppTextField(
                        controller: _country,
                        label: 'Country',
                        hint: 'India',
                      ),
                    ),
                  ],
                ),
                AppSizes.vGapLg,
                Text('Links', style: context.text.titleMedium),
                AppSizes.vGapSm,
                AppTextField(
                  controller: _website,
                  label: 'Website',
                  hint: 'Enter website URL',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _linkedin,
                  label: 'LinkedIn URL',
                  hint: 'Enter LinkedIn URL',
                ),
                AppSizes.vGapLg,
                AppPrimaryButton(
                  label: 'Upload Document',
                  onPressed: _uploadDoc,
                  icon: Icons.upload_file_outlined,
                ),
                AppSizes.vGapMd,
                AppPrimaryButton(
                  label: 'Save Profile',
                  isLoading: _saving,
                  onPressed: _save,
                ),
                SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
              ],
            ),
    );
  }

  int _completionPercent() {
    final vals = [
      _name.text.trim(),
      _email.text.trim(),
      _phone.text.trim(),
      _companyNameController.text.trim(),
      _industry.text.trim(),
      _bio.text.trim(),
      _city.text.trim(),
      _country.text.trim(),
      _pan.text.trim(),
      _aadhaar.text.trim(),
      if ((_companyData?.logoUrl ?? '').isNotEmpty || _localLogoPath != null)
        'logo',
    ];
    final filled = vals.where((e) => e.isNotEmpty).length;
    return ((filled / 11) * 100).round();
  }
}

class ClientReportsHubPage extends StatefulWidget {
  const ClientReportsHubPage({super.key});

  @override
  State<ClientReportsHubPage> createState() => _ClientReportsHubPageState();
}

class _ClientReportsHubPageState extends State<ClientReportsHubPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = const [];
  List<Map<String, dynamic>> _milestones = const [];
  List<Map<String, dynamic>> _payments = const [];
  List<Map<String, dynamic>> _documents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final tasks = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientTasks,
      parser: (e) => _asMapList(e.data),
    );
    final milestones = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientMilestones,
      parser: (e) => _asMapList(e.data),
    );
    final payments = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientPayments,
      parser: (e) => _asMapList(e.data),
    );
    final docs = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientDocuments,
      parser: (e) => _asMapList(e.data),
    );
    if (!mounted) return;
    _tasks = tasks.valueOrNull ?? const [];
    _milestones = milestones.valueOrNull ?? const [];
    _payments = payments.valueOrNull ?? const [];
    _documents = docs.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _patchTaskStatus(String id, String status) async {
    final res = await sl<ApiClientHelper>().patchAction(
      ApiEndpoints.clientTaskStatus(id),
      body: {'status': status},
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Task updated'),
    );
    await _load();
  }

  Future<void> _milestoneAction(String id, bool approve) async {
    final res = await sl<ApiClientHelper>().patchAction(
      approve
          ? ApiEndpoints.clientMilestoneApprove(id)
          : ApiEndpoints.clientMilestoneReject(id),
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Milestone updated'),
    );
    await _load();
  }

  Future<void> _initiatePayment() async {
    final checkout = sl<PaymentCheckoutService>();
    final result = await checkout.checkoutWithEasebuzz(
      purpose: 'client_payment',
      amount: 1,
      metadata: const {'source': 'client_payments_page'},
    );
    if (!mounted) return;
    await result.fold((f) async => context.showSnack(f.message), (paid) async {
      final sdk = paid.checkout;
      final verify = await checkout.verify(
        paymentId: paid.payment.paymentId,
        gateway: paid.payment.gateway,
        purpose: 'client_payment',
        verification: {
          'status': 'success',
          'orderId': paid.payment.orderId,
          'txnid': paid.payment.orderId,
          ...sdk.raw,
          if (sdk.raw['payment_response'] is Map)
            ...Map<String, dynamic>.from(sdk.raw['payment_response'] as Map),
        },
      );
      if (!mounted) return;
      verify.fold(
        (f) => context.showSnack(f.message),
        (_) => context.showSnack('Payment completed and verified'),
      );
    });
  }

  Future<void> _verifyPayment() async {
    context.showSnack(
      'Verification runs automatically after Easebuzz checkout',
    );
  }

  Future<void> _uploadDocument() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = picked?.files.single.path;
    if (path == null) return;
    final uploader = sl<FileUploadHelper>();
    final direct = await uploader.uploadUrl(
      path: path,
      endpoint: '${ApiEndpoints.clientDocuments}/upload',
    );
    if (!mounted) return;
    if (direct.isSuccess) {
      context.showSnack('Document uploaded');
      await _load();
      return;
    }
    final fallback = await uploader.uploadUrl(
      path: path,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'client_document'},
    );
    if (!mounted) return;
    fallback.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Document uploaded via files API'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Client Operations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Initiate Payment',
                            onPressed: _initiatePayment,
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Verify Payment',
                            onPressed: _verifyPayment,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tasks'),
                        for (final t in _tasks.take(5))
                          ListTile(
                            dense: true,
                            title: Text(t['title']?.toString() ?? 'Task'),
                            subtitle: Text(
                              'Status: ${t['status'] ?? 'pending'}',
                            ),
                            trailing: IconButton(
                              onPressed: () => _patchTaskStatus(
                                t['id']?.toString() ?? '',
                                'completed',
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Milestones'),
                        for (final m in _milestones.take(5))
                          ListTile(
                            dense: true,
                            title: Text(m['title']?.toString() ?? 'Milestone'),
                            subtitle: Text(
                              'Status: ${m['status'] ?? 'pending'}',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () => _milestoneAction(
                                    m['id']?.toString() ?? '',
                                    true,
                                  ),
                                  icon: const Icon(Icons.check),
                                ),
                                IconButton(
                                  onPressed: () => _milestoneAction(
                                    m['id']?.toString() ?? '',
                                    false,
                                  ),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Documents'),
                            const Spacer(),
                            TextButton(
                              onPressed: _uploadDocument,
                              child: const Text('Upload'),
                            ),
                          ],
                        ),
                        for (final d in _documents.take(5))
                          ListTile(
                            dense: true,
                            title: Text(
                              d['name']?.toString() ??
                                  d['title']?.toString() ??
                                  'Document',
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payments'),
                        for (final p in _payments.take(5))
                          ListTile(
                            dense: true,
                            title: Text(p['title']?.toString() ?? 'Payment'),
                            subtitle: Text(
                              'Status: ${p['status'] ?? 'unknown'}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    final list = raw as List?;
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class ClientAnalyticsLivePage extends StatefulWidget {
  const ClientAnalyticsLivePage({super.key});

  @override
  State<ClientAnalyticsLivePage> createState() =>
      _ClientAnalyticsLivePageState();
}

class _ClientAnalyticsLivePageState extends State<ClientAnalyticsLivePage> {
  bool _loading = true;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.clientAnalytics,
      parser: (e) => Map<String, dynamic>.from(e.data as Map),
    );
    if (!mounted) return;
    _data = res.valueOrNull ?? const {};
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Client Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  _metric('Spend', _data['spend']),
                  _metric('Projects', _data['projects']),
                  _metric('Proposals', _data['proposals']),
                  _metric('Contracts', _data['contracts']),
                  _metric('Payments', _data['payments']),
                  _metric('Hiring Funnel', _data['hiringFunnel']),
                ],
              ),
            ),
    );
  }

  Widget _metric(String label, dynamic value) => AppCard(
    child: Row(
      children: [Text(label), const Spacer(), Text(value?.toString() ?? '—')],
    ),
  );
}
