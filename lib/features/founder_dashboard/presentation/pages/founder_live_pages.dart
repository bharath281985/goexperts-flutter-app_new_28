import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class FounderPitchDeckLivePage extends StatefulWidget {
  const FounderPitchDeckLivePage({super.key});

  @override
  State<FounderPitchDeckLivePage> createState() =>
      _FounderPitchDeckLivePageState();
}

class FounderProfileLivePage extends StatefulWidget {
  const FounderProfileLivePage({super.key});

  @override
  State<FounderProfileLivePage> createState() => _FounderProfileLivePageState();
}

class _FounderProfileLivePageState extends State<FounderProfileLivePage> {
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _phoneCode = TextEditingController(text: '+91');
  final _countryCode = TextEditingController(text: 'IN');
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _linkedin = TextEditingController();
  final _website = TextEditingController();

  final _startupName = TextEditingController();
  final _category = TextEditingController();
  final _teamSize = TextEditingController();

  final _shortPitch = TextEditingController();
  final _bio = TextEditingController();

  final _education = TextEditingController();
  final _experience = TextEditingController();

  final _fundingRequired = TextEditingController();
  final _equityOffered = TextEditingController();
  final _businessType = TextEditingController();
  final _expansionGoals = TextEditingController();
  final _problemStatement = TextEditingController();
  final _solution = TextEditingController();
  final _businessModel = TextEditingController();
  final _revenueModel = TextEditingController();
  final _targetCustomers = TextEditingController();
  final _competitiveAdvantage = TextEditingController();
  final _technologyStack = TextEditingController();
  final _raised = TextEditingController();
  final _valuation = TextEditingController();
  final _runway = TextEditingController();
  final _burnRate = TextEditingController();

  String? _founderTypeId;
  String? _stageId;
  String? _industryId;
  String? _categoryId;
  String? _countryId;

  String? _avatarUrl;
  String? _localAvatarPath;
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _founderTypesList = [];
  List<Map<String, dynamic>> _stagesList = [];
  List<Map<String, dynamic>> _industriesList = [];
  List<Map<String, dynamic>> _categoriesList = [];
  List<Map<String, dynamic>> _countriesList = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _phone.dispose();
    _phoneCode.dispose();
    _countryCode.dispose();
    _country.dispose();
    _city.dispose();
    _linkedin.dispose();
    _website.dispose();
    _startupName.dispose();
    _category.dispose();
    _teamSize.dispose();
    _shortPitch.dispose();
    _bio.dispose();
    _education.dispose();
    _experience.dispose();
    _fundingRequired.dispose();
    _equityOffered.dispose();
    _businessType.dispose();
    _expansionGoals.dispose();
    _problemStatement.dispose();
    _solution.dispose();
    _businessModel.dispose();
    _revenueModel.dispose();
    _targetCustomers.dispose();
    _competitiveAdvantage.dispose();
    _technologyStack.dispose();
    _raised.dispose();
    _valuation.dispose();
    _runway.dispose();
    _burnRate.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    final futures = await Future.wait([
      sl<ApiClientHelper>().get<Map<String, dynamic>>(
        ApiEndpoints.founderProfile,
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        ApiEndpoints.publicFounderTypes,
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        ApiEndpoints.publicStartupStages,
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        ApiEndpoints.publicIndustries,
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        ApiEndpoints.publicCountries,
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        ApiEndpoints.publicMobileCategories,
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
    ]);

    if (!mounted) return;

    final profileRes = futures[0] as Result<Map<String, dynamic>>;
    final typesRes = futures[1] as Result<List<Map<String, dynamic>>>;
    final stagesRes = futures[2] as Result<List<Map<String, dynamic>>>;
    final industriesRes = futures[3] as Result<List<Map<String, dynamic>>>;
    final countriesRes = futures[4] as Result<List<Map<String, dynamic>>>;
    final categoriesRes = futures[5] as Result<List<Map<String, dynamic>>>;

    if (typesRes.isSuccess) {
      _founderTypesList = typesRes.valueOrNull ?? [];
    }

    if (stagesRes.isSuccess) {
      _stagesList = stagesRes.valueOrNull ?? [];
    }

    if (industriesRes.isSuccess) {
      _industriesList = industriesRes.valueOrNull ?? [];
    }

    if (countriesRes.isSuccess) {
      _countriesList = countriesRes.valueOrNull ?? [];
    }

    if (categoriesRes.isSuccess) {
      _categoriesList = categoriesRes.valueOrNull ?? [];
    }

    profileRes.fold((f) => context.showSnack(f.message, isError: true), (m) {
      final data = m['data'] is Map ? m['data'] : m;
      final user = data['user'] is Map ? data['user'] as Map : data;

      _email.text =
          user['email']?.toString() ?? data['email']?.toString() ?? '';
      _fullName.text =
          user['fullName']?.toString() ??
          data['fullName']?.toString() ??
          data['name']?.toString() ??
          '';
      _phone.text =
          user['phone']?.toString() ?? data['phone']?.toString() ?? '';
      _phoneCode.text =
          data['phoneCode']?.toString() ??
          user['phoneCode']?.toString() ??
          '+91';
      _countryCode.text =
          data['countryCode']?.toString() ??
          user['countryCode']?.toString() ??
          'IN';

      _city.text = user['city']?.toString() ?? data['city']?.toString() ?? '';

      _linkedin.text = data['linkedin']?.toString() ?? '';
      _website.text = data['website']?.toString() ?? '';

      _education.text = data['education']?.toString() ?? '';
      _experience.text = data['experience']?.toString() ?? '';

      _startupName.text =
          data['startupName']?.toString() ?? data['startup']?.toString() ?? '';

      _category.text =
          data['categoryId']?.toString() ?? data['category']?.toString() ?? '';
      _teamSize.text = data['teamSize']?.toString() ?? '1';

      _shortPitch.text =
          data['oneLinePitch']?.toString() ??
          data['shortPitch']?.toString() ??
          data['pitch']?.toString() ??
          '';
      _bio.text =
          data['bio']?.toString() ??
          data['description']?.toString() ??
          user['bio']?.toString() ??
          '';

      _fundingRequired.text =
          data['raised']?.toString() ??
          data['fundingRequired']?.toString() ??
          '';
      _equityOffered.text =
          data['equity']?.toString() ?? data['equityOffered']?.toString() ?? '';
      _businessType.text = data['businessType']?.toString() ?? '';
      _expansionGoals.text = data['businessExpansionGoals']?.toString() ?? '';
      _problemStatement.text = data['problemStatement']?.toString() ?? '';
      _solution.text = data['solution']?.toString() ?? '';
      _businessModel.text = data['businessModel']?.toString() ?? '';
      _revenueModel.text = data['revenueModel']?.toString() ?? '';
      _targetCustomers.text = data['targetCustomers']?.toString() ?? '';
      _competitiveAdvantage.text =
          data['competitiveAdvantage']?.toString() ?? '';
      _technologyStack.text = data['technologyStack']?.toString() ?? '';
      _raised.text = data['raised']?.toString() ?? '';
      _valuation.text = data['valuation']?.toString() ?? '';
      _runway.text = data['runway']?.toString() ?? '';
      _burnRate.text = data['burnRate']?.toString() ?? '';

      final fType =
          data['founderTypeId']?.toString() ??
          data['founderType']?.toString() ??
          '';
      _founderTypeId =
          _founderTypesList.any((e) => e['id'] == fType || e['value'] == fType)
          ? _founderTypesList
                .firstWhere(
                  (e) => e['id'] == fType || e['value'] == fType,
                )['id']
                ?.toString()
          : null;

      final stageStr =
          data['stageId']?.toString() ?? data['stage']?.toString() ?? '';
      _stageId =
          _stagesList.any(
            (e) =>
                e['id'] == stageStr ||
                e['value'] == stageStr ||
                e['name'] == stageStr ||
                e['label'] == stageStr,
          )
          ? _stagesList
                .firstWhere(
                  (e) =>
                      e['id'] == stageStr ||
                      e['value'] == stageStr ||
                      e['name'] == stageStr ||
                      e['label'] == stageStr,
                )['id']
                ?.toString()
          : null;

      final indStr =
          data['industryId']?.toString() ?? data['industry']?.toString() ?? '';
      // Match by id first, then by name/label (API may return name instead of id)
      _industryId = _resolveDropdownId(_industriesList, indStr);

      final catStr =
          data['categoryId']?.toString() ?? data['category']?.toString() ?? '';
      _categoryId = _resolveDropdownId(_categoriesList, catStr);

      final countryStr =
          data['countryId']?.toString() ??
          data['country']?.toString() ??
          user['countryId']?.toString() ??
          user['country']?.toString() ??
          '';
      _country.text = countryStr;
      _countryId =
          _countriesList.any(
            (e) =>
                e['id'] == countryStr ||
                e['value'] == countryStr ||
                e['name'] == countryStr ||
                e['label'] == countryStr,
          )
          ? _countriesList
                .firstWhere(
                  (e) =>
                      e['id'] == countryStr ||
                      e['value'] == countryStr ||
                      e['name'] == countryStr ||
                      e['label'] == countryStr,
                )['id']
                ?.toString()
          : null;

      _avatarUrl =
          data['logo']?.toString() ??
          data['avatarUrl']?.toString() ??
          user['avatarUrl']?.toString();
    });
    setState(() => _loading = false);
  }

  /// Resolve a dropdown id from a list of options.
  /// Matches by [id], [value], [name], or [label] — case-insensitive.
  String? _resolveDropdownId(List<Map<String, dynamic>> list, String raw) {
    final val = raw.trim();
    if (val.isEmpty) return null;
    final lower = val.toLowerCase();
    for (final e in list) {
      final id = e['id']?.toString() ?? '';
      final value = e['value']?.toString() ?? '';
      final name = e['name']?.toString().toLowerCase() ?? '';
      final label = e['label']?.toString().toLowerCase() ?? '';
      if (id == val || value == val || name == lower || label == lower) {
        return id.isNotEmpty ? id : null;
      }
    }
    return null;
  }

  Future<void> _save() async {
    final fullName = _fullName.text.trim();

    if (fullName.isEmpty) {
      context.showSnack('Name is required', isError: true);
      return;
    }

    setState(() => _saving = true);
    final int teamSizeInt = int.tryParse(_teamSize.text.trim()) ?? 1;
    final Map<String, dynamic> body = {
      // ── Personal ────────────────────────────────────────────────────────────
      'fullName': fullName,
      'phone': _phone.text.trim(),
      'phoneCode': _phoneCode.text.trim(),
      'countryCode': _countryCode.text.trim(),
      'bio': _bio.text.trim(),
      // ── Location ────────────────────────────────────────────────────────────
      'city': _city.text.trim(),
      'state': '',
      'country': _countryId ?? _country.text.trim(),
      // ── Social & Links ──────────────────────────────────────────────────────
      'linkedin': _linkedin.text.trim(),
      'website': _website.text.trim(),
      // ── Startup Details ─────────────────────────────────────────────────────
      'founderType': _founderTypeId ?? '',
      'startupName': _startupName.text.trim(),
      'industry': _industryId ?? '',
      'category': _categoryId ?? '',
      'fundingStage': _stageId ?? '',
      'teamSize': teamSizeInt,
      // ── Financials ──────────────────────────────────────────────────────────
      'raised': double.tryParse(_raised.text.trim()) ?? 0,
      'equityOffered': double.tryParse(_equityOffered.text.trim()) ?? 0,
      'valuation': double.tryParse(_valuation.text.trim()) ?? 0,
      'runway': _runway.text.trim(),
      'burnRate': double.tryParse(_burnRate.text.trim()) ?? 0,
      // ── Narrative ───────────────────────────────────────────────────────────
      'problemStatement': _problemStatement.text.trim(),
      'solution': _solution.text.trim(),
      'businessModel': _businessModel.text.trim(),
      'revenueModel': _revenueModel.text.trim(),
      'marketSize': '',
      'targetCustomers': _targetCustomers.text.trim(),
      'competitiveAdvantage': _competitiveAdvantage.text.trim(),
      'technologyStack': _technologyStack.text.trim(),
      // ── Background ──────────────────────────────────────────────────────────
      'education': _education.text.trim(),
      'experience': _experience.text.trim(),
    };

    final Result<String> res;
    if (_localAvatarPath != null) {
      final uploadRes = await sl<FileUploadHelper>().upload(
        path: _localAvatarPath!,
        endpoint: ApiEndpoints.founderProfile,
        fileField: 'file',
        method: 'put',
        fields: body,
      );
      res = uploadRes.fold((f) => Err(f), (json) {
        final url =
            json['avatarUrl']?.toString() ??
            json['logo']?.toString() ??
            json['url']?.toString() ??
            _avatarUrl;
        if (url != null) _avatarUrl = url;
        return const Success('Founder profile updated successfully');
      });
    } else {
      res = await sl<ApiClientHelper>().putEnvelope<String>(
        ApiEndpoints.founderProfile,
        body: body,
        parser: (envelope) => envelope.message?.trim().isNotEmpty == true
            ? envelope.message!
            : 'Founder profile updated successfully',
      );
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (res.isSuccess) {
        _localAvatarPath = null;
      }
    });

    if (res.isFailure) {
      context.showSnack(res.failureOrNull!.message, isError: true);
      return;
    }

    final message = res.valueOrNull ?? 'Founder profile updated successfully';
    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser != null) {
      context.read<AuthBloc>().add(
        AuthUserUpdated(
          currentUser.copyWith(
            fullName: fullName,
            location: _city.text.trim(),
            avatarUrl: _avatarUrl,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.showSnack(message);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Founder Profile')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      color: context.colors.primary,
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Startup story',
                            style: context.text.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help investors understand your founder profile, market, and funding position.',
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              Center(
                child: ProfileAvatarEditor(
                  localPath: _localAvatarPath,
                  networkUrl: _avatarUrl,
                  onPathPicked: (path) =>
                      setState(() => _localAvatarPath = path),
                ),
              ),
              AppSizes.vGapXl,
              _buildSectionTitle('Personal Details'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      hint: 'Email Address',
                      readOnly: true,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _fullName,
                      label: 'Name',
                      hint: 'Enter your name',
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
                            hint: 'Enter your phone number',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                          ),
                        ),
                      ],
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
                          child: AppDropdown<String>(
                            label: 'Country',
                            hint: 'Select country',
                            value: _countryId,
                            items: _countriesList
                                .map((e) => e['id']?.toString() ?? '')
                                .toList(),
                            itemLabel: (v) {
                              final item = _countriesList.firstWhere(
                                (e) => e['id'] == v,
                                orElse: () => {},
                              );
                              return (item['name'] ?? item['label'] ?? v)
                                  .toString();
                            },
                            onChanged: (v) => setState(() => _countryId = v),
                          ),
                        ),
                      ],
                    ),
                    AppSizes.vGapMd,
                    AppLocationField(
                      controller: _city,
                      label: 'City',
                      hint: 'Select city',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _linkedin,
                      label: 'LinkedIn Profile',
                      hint: 'https://linkedin.com/in/...',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _website,
                      label: 'Website',
                      hint: 'https://...',
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              _buildSectionTitle('Startup Details'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _startupName,
                      label: 'Startup Name',
                      hint: 'Enter startup name',
                    ),
                    AppSizes.vGapMd,
                    AppDropdown<String>(
                      label: 'Founder Type',
                      hint: 'Select founder type',
                      value: _founderTypeId,
                      items: _founderTypesList
                          .map((e) => e['id']?.toString() ?? '')
                          .toList(),
                      itemLabel: (v) {
                        final item = _founderTypesList.firstWhere(
                          (e) => e['id'] == v,
                          orElse: () => {},
                        );
                        return item['label']?.toString() ?? v;
                      },
                      onChanged: (v) => setState(() => _founderTypeId = v),
                    ),
                    AppSizes.vGapMd,
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            label: 'Industry',
                            hint: 'Select industry',
                            value: _industryId,
                            items: _industriesList
                                .map((e) => e['id']?.toString() ?? '')
                                .where((id) => id.isNotEmpty)
                                .toList(),
                            itemLabel: (v) {
                              final item = _industriesList.firstWhere(
                                (e) => e['id'] == v,
                                orElse: () => {},
                              );
                              return (item['name'] ?? item['label'] ?? v)
                                  .toString();
                            },
                            onChanged: (v) => setState(() => _industryId = v),
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: AppDropdown<String>(
                            label: 'Category',
                            hint: 'Select category',
                            value: _categoryId,
                            items: _categoriesList
                                .map((e) => e['id']?.toString() ?? '')
                                .where((id) => id.isNotEmpty)
                                .toList(),
                            itemLabel: (v) {
                              final item = _categoriesList.firstWhere(
                                (e) => e['id'] == v,
                                orElse: () => {},
                              );
                              return (item['name'] ?? item['label'] ?? v)
                                  .toString();
                            },
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                        ),
                      ],
                    ),
                    AppSizes.vGapMd,
                    Row(
                      children: [
                        Expanded(
                          child: AppDropdown<String>(
                            label: 'Stage',
                            hint: 'Select stage',
                            value: _stageId,
                            items: _stagesList
                                .map((e) => e['id']?.toString() ?? '')
                                .toList(),
                            itemLabel: (v) {
                              final item = _stagesList.firstWhere(
                                (e) => e['id'] == v,
                                orElse: () => {},
                              );
                              return item['label']?.toString() ?? v;
                            },
                            onChanged: (v) => setState(() => _stageId = v),
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: AppTextField(
                            controller: _teamSize,
                            label: 'Team Size',
                            hint: 'e.g. 5',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              _buildSectionTitle('Product & Market'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _shortPitch,
                      label: 'Short Pitch',
                      hint: 'A one-line pitch of your startup',
                      maxLines: 2,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _problemStatement,
                      label: 'Problem Statement',
                      hint: 'What important problem are you solving?',
                      maxLines: 4,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _solution,
                      label: 'Solution',
                      hint: 'Explain how your product solves it',
                      maxLines: 4,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _targetCustomers,
                      label: 'Target Customers',
                      hint: 'Who buys or uses your solution?',
                      maxLines: 3,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _competitiveAdvantage,
                      label: 'Competitive Advantage',
                      hint: 'What makes your company hard to copy?',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              _buildSectionTitle('Business Model'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _businessType,
                      label: 'Business Type',
                      hint: 'e.g. B2B',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _businessModel,
                      label: 'Business Model',
                      hint: 'e.g. Enterprise SaaS',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _revenueModel,
                      label: 'Revenue Model',
                      hint: 'How does the business make money?',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _technologyStack,
                      label: 'Technology Stack',
                      hint: 'TypeScript, Python, PostgreSQL',
                      maxLines: 2,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _expansionGoals,
                      label: 'Expansion Goals',
                      hint: 'Describe your next growth milestone',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              _buildSectionTitle('Funding'),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _raised,
                            label: 'Raised',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: AppTextField(
                            controller: _equityOffered,
                            label: 'Equity (%)',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _valuation,
                      label: 'Valuation',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                    AppSizes.vGapMd,
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _runway,
                            label: 'Runway',
                            hint: 'e.g. 18 Months',
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: AppTextField(
                            controller: _burnRate,
                            label: 'Monthly Burn Rate',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              _buildSectionTitle('Founder Bio'),
              AppCard(
                child: AppTextField(
                  controller: _bio,
                  label: 'Bio',
                  hint: 'Tell people about your background and vision',
                  maxLines: 4,
                ),
              ),

              AppSizes.vGapXl,
              AppPrimaryButton(
                label: 'Save Profile',
                isLoading: _saving,
                onPressed: _save,
              ),
              AppSizes.vGapXl,
            ],
          ),
  );

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class FounderFundingLivePage extends StatefulWidget {
  const FounderFundingLivePage({super.key});
  @override
  State<FounderFundingLivePage> createState() => _FounderFundingLivePageState();
}

class _FounderFundingLivePageState extends State<FounderFundingLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rounds = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.founderFunding,
          parser: (e) {
            final list = e.data as List?;
            if (list == null) return const [];
            return list
                .whereType<Map>()
                .map((x) => Map<String, dynamic>.from(x))
                .toList();
          },
        );
    if (!mounted) return;
    _rounds = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _createRound() async {
    final res = await sl<ApiClientHelper>().post<Map<String, dynamic>>(
      ApiEndpoints.founderFunding,
      body: {'title': 'New Round', 'targetAmount': 0},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
      allowNullData: false,
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Funding round created'),
    );
    await _load();
  }

  Future<void> _updateStatus(String id, String status) async {
    final res = await sl<ApiClientHelper>().patchAction(
      ApiEndpoints.founderFundingStatus(id),
      body: {'status': status},
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Status updated'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Funding'),
      actions: [TextButton(onPressed: _createRound, child: const Text('New'))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (_rounds.isEmpty)
                  const AppCard(child: Text('No funding rounds yet')),
                for (final r in _rounds)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: ListTile(
                      title: Text(r['title']?.toString() ?? 'Funding round'),
                      subtitle: Text('Status: ${r['status'] ?? 'draft'}'),
                      trailing: IconButton(
                        onPressed: () =>
                            _updateStatus(r['id']?.toString() ?? '', 'active'),
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class _FounderPitchDeckLivePageState extends State<FounderPitchDeckLivePage> {
  final _summary = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().get<Map<String, dynamic>>(
      ApiEndpoints.founderPitchDeck,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (!mounted) return;
    _summary.text = res.valueOrNull?['summary']?.toString() ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final api = sl<ApiClientHelper>();
    var res = await api.put<Map<String, dynamic>>(
      ApiEndpoints.founderPitchDeck,
      body: {'summary': _summary.text.trim()},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (res.isFailure) {
      res = await api.post<Map<String, dynamic>>(
        ApiEndpoints.founderPitchDeck,
        body: {'summary': _summary.text.trim()},
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
        allowNullData: false,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Pitch deck saved'),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Pitch Deck')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              AppTextField(
                controller: _summary,
                label: 'Deck Summary',
                hint: 'Enter deck summary',
                maxLines: 8,
              ),
              AppSizes.vGapMd,
              AppPrimaryButton(
                label: 'Save',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
  );
}

class FounderBusinessPlanLivePage extends StatefulWidget {
  const FounderBusinessPlanLivePage({super.key});
  @override
  State<FounderBusinessPlanLivePage> createState() =>
      _FounderBusinessPlanLivePageState();
}

class _FounderBusinessPlanLivePageState
    extends State<FounderBusinessPlanLivePage> {
  final _summary = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().get<Map<String, dynamic>>(
      ApiEndpoints.founderBusinessPlan,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (!mounted) return;
    _summary.text = res.valueOrNull?['summary']?.toString() ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final api = sl<ApiClientHelper>();
    var res = await api.put<Map<String, dynamic>>(
      ApiEndpoints.founderBusinessPlan,
      body: {'summary': _summary.text.trim()},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (res.isFailure) {
      res = await api.post<Map<String, dynamic>>(
        ApiEndpoints.founderBusinessPlan,
        body: {'summary': _summary.text.trim()},
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
        allowNullData: false,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Business plan saved'),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Business Plan')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              AppTextField(
                controller: _summary,
                label: 'Plan Summary',
                hint: 'Enter plan summary',
                maxLines: 10,
              ),
              AppSizes.vGapMd,
              AppPrimaryButton(
                label: 'Save',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
  );
}

class FounderTeamLivePage extends StatefulWidget {
  const FounderTeamLivePage({super.key});

  @override
  State<FounderTeamLivePage> createState() => _FounderTeamLivePageState();
}

class _FounderTeamLivePageState extends State<FounderTeamLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _team = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.founderTeam,
          parser: (e) {
            final list = e.data as List?;
            if (list == null) return const [];
            return list
                .whereType<Map>()
                .map((x) => Map<String, dynamic>.from(x))
                .toList();
          },
        );
    if (!mounted) return;
    _team = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final role = TextEditingController();
    await showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Add team member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: name, hint: 'Name'),
            AppTextField(controller: role, hint: 'Role'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final res = await sl<ApiClientHelper>().postAction(
                ApiEndpoints.founderTeam,
                body: {'name': name.text.trim(), 'role': role.text.trim()},
              );
              if (!mounted) return;
              res.fold(
                (f) => context.showSnack(f.message),
                (_) => context.showSnack('Member added'),
              );
              if (dCtx.mounted) Navigator.pop(dCtx);
              await _load();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Team'),
      actions: [TextButton(onPressed: _add, child: const Text('Add'))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (_team.isEmpty)
                  const AppCard(child: Text('No team members yet')),
                for (final m in _team)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: ListTile(
                      title: Text(m['name']?.toString() ?? 'Member'),
                      subtitle: Text(m['role']?.toString() ?? ''),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class FounderMediaLivePage extends StatefulWidget {
  const FounderMediaLivePage({super.key});
  @override
  State<FounderMediaLivePage> createState() => _FounderMediaLivePageState();
}

class _FounderMediaLivePageState extends State<FounderMediaLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _docs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.founderDocuments,
          parser: (e) {
            final list = e.data as List?;
            if (list == null) return const [];
            return list
                .whereType<Map>()
                .map((x) => Map<String, dynamic>.from(x))
                .toList();
          },
        );
    if (!mounted) return;
    _docs = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _upload() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = picked?.files.single.path;
    if (path == null) return;
    final direct = await sl<FileUploadHelper>().uploadUrl(
      path: path,
      endpoint: ApiEndpoints.founderDocumentsUpload,
    );
    if (!mounted) return;
    if (direct.isSuccess) {
      context.showSnack('Uploaded');
      await _load();
      return;
    }
    final fallback = await sl<FileUploadHelper>().uploadUrl(
      path: path,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'founder_document'},
    );
    if (!mounted) return;
    fallback.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Uploaded via files API'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Media & Documents'),
      actions: [TextButton(onPressed: _upload, child: const Text('Upload'))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (_docs.isEmpty)
                  const AppCard(child: Text('No documents uploaded')),
                for (final d in _docs)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Text(
                      d['name']?.toString() ??
                          d['title']?.toString() ??
                          'Document',
                    ),
                  ),
              ],
            ),
          ),
  );
}

class FounderAnalyticsLivePage extends StatefulWidget {
  const FounderAnalyticsLivePage({super.key});
  @override
  State<FounderAnalyticsLivePage> createState() =>
      _FounderAnalyticsLivePageState();
}

class _FounderAnalyticsLivePageState extends State<FounderAnalyticsLivePage> {
  bool _loading = true;
  Map<String, dynamic> _analytics = const {};
  List<Map<String, dynamic>> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final a = await api.get<Map<String, dynamic>>(
      ApiEndpoints.founderAnalytics,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final r = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.founderReports,
      parser: (e) {
        final list = e.data as List?;
        if (list == null) return const [];
        return list
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
      },
    );
    if (!mounted) return;
    _analytics = a.valueOrNull ?? const {};
    _reports = r.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Founder Analytics')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                _metric('Funding Raised', _analytics['fundingRaised']),
                _metric('Investor Interests', _analytics['investorInterests']),
                _metric('Meetings', _analytics['meetings']),
                _metric('Pitch Deck Views', _analytics['pitchDeckViews']),
                _metric('Wallet', _analytics['walletBalance']),
                _metric('Subscription', _analytics['subscriptionPlan']),
                for (final rep in _reports)
                  AppCard(
                    margin: const EdgeInsets.only(top: AppSizes.sm),
                    child: Text(rep['title']?.toString() ?? 'Report'),
                  ),
              ],
            ),
          ),
  );

  Widget _metric(String label, dynamic value) => AppCard(
    child: Row(
      children: [Text(label), const Spacer(), Text(value?.toString() ?? '—')],
    ),
  );
}
