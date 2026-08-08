import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/payments/payment_checkout_service.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/phone_validation.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_file_upload.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/services/google_places_service.dart';
import '../bloc/auth_bloc.dart';

enum _PortfolioMediaType { cover, video, caseStudy, screenshot }

enum _SignupDocumentType {
  education,
  certificate,
  startup,
  verification,
  projectReference,
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _country = TextEditingController();
  final _stateLocation = TextEditingController();
  final _city = TextEditingController();
  final _skills = TextEditingController();
  final _experience = TextEditingController();
  final _bio = TextEditingController();
  final _linkedin = TextEditingController();
  final _github = TextEditingController();
  final _portfolioUrl = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _education = TextEditingController();
  final _portfolioTitle = TextEditingController();
  final _portfolioClient = TextEditingController();
  final _portfolioIndustry = TextEditingController();
  final _portfolioTechStack = TextEditingController();
  final _portfolioDuration = TextEditingController();
  final _portfolioRole = TextEditingController();
  final _portfolioGithub = TextEditingController();
  final _portfolioLiveUrl = TextEditingController();
  final _portfolioOverview = TextEditingController();
  final _educationInstitution = TextEditingController();
  final _educationQualification = TextEditingController();
  final _educationSpecialization = TextEditingController();
  final _educationYear = TextEditingController();
  final _certificateName = TextEditingController();
  final _certificateIssuer = TextEditingController();
  final _certificateIssueDate = TextEditingController();
  final _certificateUrl = TextEditingController();
  final _businessName = TextEditingController();
  final _businessDescription = TextEditingController();
  final _website = TextEditingController();
  final _industry = TextEditingController();
  final _gstNumber = TextEditingController();
  final _annualRequirement = TextEditingController();
  final _serviceLocation = TextEditingController();
  final _companyName = TextEditingController();
  final _projectTitle = TextEditingController();
  final _projectBudget = TextEditingController();
  final _projectTimeline = TextEditingController();
  final _projectDescription = TextEditingController();
  final _projectPreferredSkills = TextEditingController();
  final _projectLocationPreference = TextEditingController();
  final _investorCompanyFund = TextEditingController();
  final _minTicket = TextEditingController();
  final _maxTicket = TextEditingController();
  final _founderTypeOther = TextEditingController();
  final _startupName = TextEditingController();
  final _shortPitch = TextEditingController();
  final _longDescription = TextEditingController();
  final _problemStatement = TextEditingController();
  final _solution = TextEditingController();
  final _targetCustomers = TextEditingController();
  final _marketSize = TextEditingController();
  final _businessModel = TextEditingController();
  final _revenueModel = TextEditingController();
  final _currentProgress = TextEditingController();
  final _fundingRequired = TextEditingController();
  final _equityOffered = TextEditingController();
  final _demoLink = TextEditingController();
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();
  final _emailOtp = TextEditingController();
  final _imagePicker = ImagePicker();

  UserRole? _role;
  int _step = 0;
  String _countryCode = '+91';
  String _countryIsoCode = 'IN';
  String _countryName = 'India';
  _PublicOption? _selectedIndustry;
  _PublicOption? _categoryOption;
  _PublicOption? _founderProfileCategory;
  _PublicOption? _founderTaxonomyCategory;
  _PublicOption? _portfolioIndustryOption;
  _PublicOption? _portfolioCategoryOption;
  String _plan = '';
  String _paymentType = '';
  String _paymentStatus = '';
  String _transactionId = '';
  String _paidPlanId = '';
  bool _isProcessingPayment = false;
  String? _businessType;
  String? _teamSize;
  String? _portfolioStatus;
  String? _portfolioTeamSize;
  _PublicOption? _clientProjectCategory;
  String? _remoteType;
  String? _urgency;
  final List<String> _lookingForGoals = [];
  final List<String> _expansionGoals = [];
  String? _investorType;
  String? _ticketSize;
  final List<String> _stagePreferencesSelected = [];
  final List<String> _investmentModesSelected = [];
  final List<String> _targetIndustriesSelected = [];
  final List<String> _investorGoals = [];
  String? _founderType;
  String? _startupStage;
  String? _founderSubCategory;
  final List<String> _founderGoalsSelected = [];
  String? _profilePhotoName;
  ImageProvider? _profilePhotoPreview;
  String? _portfolioCoverName;
  String? _portfolioVideoName;
  String? _portfolioCaseStudyName;
  String? _portfolioScreenshotName;
  String? _projectReferenceName;
  String? _portfolioCoverSource;
  String? _portfolioVideoSource;
  String? _portfolioCaseStudySource;
  String? _portfolioScreenshotSource;
  String? _projectReferenceSource;
  String? _startupDocumentName;
  String? _educationDocumentName;
  String? _certificateDocumentName;
  String? _verificationDocName;
  String? _startupDocumentSource;
  String? _educationDocumentSource;
  String? _certificateDocumentSource;
  String? _verificationDocSource;
  bool _agree = false;
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isLoadingCategories = false;
  bool _isLoadingSkills = false;
  List<_PublicOption> _industryPublicOptions = const [];
  List<_PublicOption> _categoryPublicOptions = const [];
  List<_PublicOption> _founderCategoryOptions = const [];
  List<_PublicOption> _skillPublicOptions = const [];
  List<String> _businessTypeOptions = const [];
  List<_CountryOption> _countryOptions = const [];
  List<_StateOption> _stateOptions = const [];
  List<String> _founderTypeOptions = const [];
  List<String> _startupStageOptions = const [];
  List<String> _investorTypeOptions = const [];
  List<String> _investmentModeOptions = const [];
  List<_TicketOption> _ticketSizeOptions = const [];
  List<String> _teamSizeOptions = const [];
  List<String> _clientGoalOptions = const [];
  List<String> _expansionGoalOptions = const [];
  List<String> _investorGoalOptions = const [];
  List<String> _stagePreferenceOptions = const [];
  List<String> _targetIndustryOptions = const [];
  List<_PlanOption> _pricingPlanOptions = const [];
  final Map<String, String> _optionIdsByLabel = {};

  static const _remoteTypes = ['Remote', 'On-site', 'Hybrid'];
  static const _urgencies = [
    'High (Immediate)',
    'Medium (Within a month)',
    'Low (Flexible)',
  ];
  static const List<String> _founderGoals = [];

  List<String> get _steps {
    if (_role == null) return const ['Role'];
    if (_role == UserRole.freelancer) {
      return const [
        'Role',
        'Account',
        'Category',
        'Skills & Experience',
        'Profile',
        'Budget',
        'Portfolios',
        'Badges',
        'Verification',
        'Billing',
      ];
    }
    if (_role == UserRole.client) {
      return const [
        'Account',
        'Business type',
        'Profile',
        'Services & Requirements',
        'Looking For',
        'Projects',
        'Expansion',
        'Verification',
        'Billing',
      ];
    }
    if (_role == UserRole.investor) {
      return const [
        'Account',
        'Investor type',
        'Profile',
        'Goals',
        'Verification',
        'Billing',
      ];
    }
    if (_role == UserRole.founder) {
      return const [
        'Account',
        'Founder type',
        'Profile',
        'Startup Details',
        'Taxonomy',
        'Goals',
        'Verification',
        'Billing',
      ];
    }
    return const ['Role', 'Account', 'Profile', 'Verification', 'Billing'];
  }

  String get _signupLabel {
    final short = _role?.shortLabel ?? 'User';
    return '${short.toUpperCase()} SIGNUP';
  }

  int get _progressPercent => (((_step + 1) / _steps.length) * 100).round();

  @override
  void initState() {
    super.initState();
    _loadPublicSignupOptions();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _country.dispose();
    _stateLocation.dispose();
    _city.dispose();
    _skills.dispose();
    _experience.dispose();
    _bio.dispose();
    _linkedin.dispose();
    _github.dispose();
    _portfolioUrl.dispose();
    _hourlyRate.dispose();
    _education.dispose();
    _portfolioTitle.dispose();
    _portfolioClient.dispose();
    _portfolioIndustry.dispose();
    _portfolioTechStack.dispose();
    _portfolioDuration.dispose();
    _portfolioRole.dispose();
    _portfolioGithub.dispose();
    _portfolioLiveUrl.dispose();
    _portfolioOverview.dispose();
    _educationInstitution.dispose();
    _educationQualification.dispose();
    _educationSpecialization.dispose();
    _educationYear.dispose();
    _certificateName.dispose();
    _certificateIssuer.dispose();
    _certificateIssueDate.dispose();
    _certificateUrl.dispose();
    _businessName.dispose();
    _businessDescription.dispose();
    _website.dispose();
    _industry.dispose();
    _gstNumber.dispose();
    _annualRequirement.dispose();
    _serviceLocation.dispose();
    _companyName.dispose();
    _projectTitle.dispose();
    _projectBudget.dispose();
    _projectTimeline.dispose();
    _projectDescription.dispose();
    _projectPreferredSkills.dispose();
    _projectLocationPreference.dispose();
    _investorCompanyFund.dispose();
    _minTicket.dispose();
    _maxTicket.dispose();
    _founderTypeOther.dispose();
    _startupName.dispose();
    _shortPitch.dispose();
    _longDescription.dispose();
    _problemStatement.dispose();
    _solution.dispose();
    _targetCustomers.dispose();
    _marketSize.dispose();
    _businessModel.dispose();
    _revenueModel.dispose();
    _currentProgress.dispose();
    _fundingRequired.dispose();
    _equityOffered.dispose();
    _demoLink.dispose();
    _aadhaar.dispose();
    _pan.dispose();
    _emailOtp.dispose();
    super.dispose();
  }

  void _setCountryCode(CountryCode countryCode) {
    setState(() {
      _countryCode = countryCode.dialCode ?? '+91';
      _countryIsoCode = countryCode.code ?? 'IN';
      _countryName = countryCode.name ?? 'India';
      _stateLocation.clear();
      _stateOptions = const [];
      _phone.text = PhoneValidation.trimToRequiredLength(
        _phone.text,
        _countryIsoCode,
      );
    });
    _formKey.currentState?.validate();
    _loadStates(_countryIsoCode);
  }

  void _setCountryOption(_CountryOption country) {
    setState(() {
      _country.text = country.name;
      _countryName = country.name;
      if (country.code.isNotEmpty) _countryIsoCode = country.code;
      if (country.phoneCode.isNotEmpty) _countryCode = country.phoneCode;
      _stateLocation.clear();
      _stateOptions = const [];
      _phone.text = PhoneValidation.trimToRequiredLength(
        _phone.text,
        _countryIsoCode,
      );
    });
    _formKey.currentState?.validate();
    _loadStates(_countryIsoCode);
  }

  Future<void> _loadPublicSignupOptions() async {
    await Future.wait([
      _loadIndustries(),
      _loadPublicStringOptions(
        ApiEndpoints.publicBusinessTypes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _businessTypeOptions = items,
      ),
      _loadCountries(),
      _loadStates(_countryIsoCode),
      _loadPublicStringOptions(
        ApiEndpoints.publicFounderTypes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _founderTypeOptions = items,
      ),
      _loadPublicMobileStringOptions(
        ApiEndpoints.publicMobileStartupStages,
        (item) => item['label']?.toString() ?? item['value']?.toString(),
        (items) {
          _startupStageOptions = items;
          _stagePreferenceOptions = items;
        },
      ),
      _loadPublicStringOptions(
        ApiEndpoints.publicInvestorTypes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _investorTypeOptions = items,
      ),
      _loadPublicRootStringOptions(
        ApiEndpoints.publicInvestmentModes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _investmentModeOptions = items,
      ),
      _loadPublicRootStringOptions(
        ApiEndpoints.publicInvestorGoals,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _investorGoalOptions = items,
      ),
      _loadPublicMobileTicketSizes(),
      _loadPublicMobileStringOptions(
        ApiEndpoints.publicMobileCategories,
        (item) =>
            item['label']?.toString() ??
            item['name']?.toString() ??
            item['value']?.toString(),
        (items) => _targetIndustryOptions = items,
      ),
      _loadPublicMobileCategories(),
      _loadPublicMobileStringOptions(
        ApiEndpoints.publicMobileTeamSizes,
        (item) => item['label']?.toString() ?? item['value']?.toString(),
        (items) => _teamSizeOptions = items,
      ),
      _loadPublicRootStringOptions(
        ApiEndpoints.publicClientGoals,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _clientGoalOptions = items,
      ),
      _loadPublicRootStringOptions(
        ApiEndpoints.publicExpansionGoals,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _expansionGoalOptions = items,
      ),
      _loadPricingPlans(),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _loadPricingPlans() async {
    try {
      final res = await Dio().get(
        '${AppConfig.publicBaseUrl}${ApiEndpoints.publicPricingPlans}',
      );
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = raw
          .whereType<Map>()
          .where((item) => item['status'] == null || item['status'] == 'active')
          .map((item) => _PlanOption.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
      _pricingPlanOptions = items;
      _ensureSelectedPlanForRole();
    } catch (_) {
      // Keep subscription plans empty when API is unavailable.
    }
  }

  Future<void> _loadIndustries() async {
    try {
      final res = await Dio().get(
        '${AppConfig.baseUrl}${ApiEndpoints.publicIndustries}',
      );
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = raw
          .whereType<Map>()
          .where((item) => item['status'] == null || item['status'] == 'active')
          .map(
            (item) => _PublicOption.fromJson(
              Map<String, dynamic>.from(item),
              labelKeys: const ['name', 'label', 'value'],
            ),
          )
          .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
          .toList();
      if (items.isEmpty) return;
      for (final item in items) {
        _rememberOptionId(id: item.id, label: item.label);
      }
      _industryPublicOptions = items;
    } catch (_) {
      // Keep local fallback options.
    }
  }

  void _rememberOptionId({required String id, required String label}) {
    final cleanId = id.trim();
    final cleanLabel = label.trim();
    if (cleanId.isEmpty || cleanLabel.isEmpty) return;
    _optionIdsByLabel[cleanLabel] = cleanId;
  }

  String _idForOption(String value) => _optionIdsByLabel[value] ?? value;

  List<_PlanOption> _plansForRole(UserRole? role) {
    if (role == null) return const [];
    final roleValue = role.apiValue.toLowerCase();
    return _pricingPlanOptions
        .where((plan) => plan.role.toLowerCase() == roleValue)
        .toList();
  }

  _PlanOption? _selectedPlanOption() {
    final plans = _plansForRole(_role);
    for (final plan in plans) {
      if (plan.id == _plan) return plan;
    }
    return null;
  }

  void _ensureSelectedPlanForRole() {
    final plans = _plansForRole(_role);
    if (plans.isEmpty) {
      _plan = '';
      return;
    }
    if (!plans.any((plan) => plan.id == _plan)) {
      _plan = plans.first.id;
    }
  }

  void _setSelectedPlan(String planId) {
    setState(() {
      _plan = planId;
      _paymentType = '';
      _paymentStatus = '';
      _transactionId = '';
      _paidPlanId = '';
    });
  }

  Future<void> _loadPublicStringOptions(
    String endpoint,
    String? Function(Map<String, dynamic>) labelOf,
    ValueChanged<List<String>> apply,
  ) async {
    try {
      final res = await Dio().get('${AppConfig.baseUrl}$endpoint');
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = <String>[];
      for (final rawItem in raw.whereType<Map>()) {
        if (rawItem['status'] != null && rawItem['status'] != 'active') {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final label = labelOf(item)?.trim();
        if (label == null || label.isEmpty) continue;
        _rememberOptionId(id: item['id']?.toString() ?? label, label: label);
        if (!items.contains(label)) items.add(label);
      }
      if (items.isNotEmpty) apply(items);
    } catch (_) {
      // Keep local fallback options.
    }
  }

  Future<void> _loadPublicMobileStringOptions(
    String endpoint,
    String? Function(Map<String, dynamic>) labelOf,
    ValueChanged<List<String>> apply,
  ) async {
    try {
      final res = await Dio().get('${AppConfig.mobilePublicBaseUrl}$endpoint');
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = <String>[];
      for (final rawItem in raw.whereType<Map>()) {
        if (rawItem['status'] != null && rawItem['status'] != 'active') {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final label = labelOf(item)?.trim();
        if (label == null || label.isEmpty) continue;
        _rememberOptionId(id: item['id']?.toString() ?? label, label: label);
        if (!items.contains(label)) items.add(label);
      }
      if (items.isNotEmpty) apply(items);
    } catch (_) {
      // Keep local fallback options.
    }
  }

  Future<void> _loadPublicRootStringOptions(
    String endpoint,
    String? Function(Map<String, dynamic>) labelOf,
    ValueChanged<List<String>> apply,
  ) async {
    try {
      final res = await Dio().get('${AppConfig.publicBaseUrl}$endpoint');
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = <String>[];
      for (final rawItem in raw.whereType<Map>()) {
        if (rawItem['status'] != null && rawItem['status'] != 'active') {
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final label = labelOf(item)?.trim();
        if (label == null || label.isEmpty) continue;
        _rememberOptionId(id: item['id']?.toString() ?? label, label: label);
        if (!items.contains(label)) items.add(label);
      }
      if (items.isNotEmpty) apply(items);
    } catch (_) {
      // Keep local fallback options.
    }
  }

  Future<void> _loadPublicMobileTicketSizes() async {
    try {
      final res = await Dio().get(
        '${AppConfig.mobilePublicBaseUrl}${ApiEndpoints.publicMobileTicketSizes}',
      );
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = raw
          .whereType<Map>()
          .where((item) => item['status'] == null || item['status'] == 'active')
          .map(
            (item) => _TicketOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.label.isNotEmpty)
          .toList();
      for (final item in items) {
        _rememberOptionId(id: item.id, label: item.label);
      }
      if (items.isNotEmpty) _ticketSizeOptions = items;
    } catch (_) {
      // Keep manual ticket fields if API is unavailable.
    }
  }

  Future<void> _loadPublicMobileCategories() async {
    try {
      final res = await Dio().get(
        '${AppConfig.mobilePublicBaseUrl}${ApiEndpoints.publicMobileCategories}',
      );
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final items = raw
          .whereType<Map>()
          .where((item) => item['status'] == null || item['status'] == 'active')
          .map(
            (item) => _PublicOption.fromJson(
              Map<String, dynamic>.from(item),
              labelKeys: const ['label', 'name', 'value'],
            ),
          )
          .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
          .toList();
      for (final item in items) {
        _rememberOptionId(id: item.id, label: item.label);
      }
      if (items.isNotEmpty) _founderCategoryOptions = items;
    } catch (_) {
      // Keep local fallback options.
    }
  }

  Future<void> _loadCountries() async {
    try {
      final res = await Dio().get(
        '${AppConfig.baseUrl}${ApiEndpoints.publicCountries}',
      );
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final countries = raw
          .whereType<Map>()
          .map(
            (item) => _CountryOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.allowRegistration && item.name.isNotEmpty)
          .toList();
      if (countries.isNotEmpty) _countryOptions = countries;
    } catch (_) {
      // Keep Google location fallback for country selection.
    }
  }

  Future<void> _loadStates(String countryCode) async {
    try {
      final res = await Dio().get(
        '${AppConfig.publicBaseUrl}${ApiEndpoints.publicStates}',
        queryParameters: {'countryCode': countryCode},
      );
      final raw = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)['data']
          : null;
      if (raw is! List) return;
      final states = raw
          .whereType<Map>()
          .map((item) => _StateOption.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.name.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() => _stateOptions = states);
    } catch (_) {
      // Keep Google location fallback for state selection.
    }
  }

  void _setStateOption(_StateOption state) {
    setState(() => _stateLocation.text = state.name);
    _formKey.currentState?.validate();
  }

  Future<List<_PublicOption>> _loadPublicOptions(
    String endpoint, {
    Map<String, dynamic>? query,
  }) async {
    final res = await Dio().get(
      '${AppConfig.baseUrl}$endpoint',
      queryParameters: query,
    );
    final raw = res.data is Map<String, dynamic>
        ? (res.data as Map<String, dynamic>)['data']
        : null;
    if (raw is! List) return const [];
    final items = raw
        .whereType<Map>()
        .where((item) => item['status'] == null || item['status'] == 'active')
        .map(
          (item) => _PublicOption.fromJson(
            Map<String, dynamic>.from(item),
            labelKeys: const ['name', 'label', 'value'],
          ),
        )
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList();
    for (final item in items) {
      _rememberOptionId(id: item.id, label: item.label);
    }
    return items;
  }

  Future<void> _loadCategoriesForIndustry(_PublicOption industry) async {
    setState(() => _isLoadingCategories = true);
    try {
      final items = await _loadPublicOptions(
        ApiEndpoints.publicCategories,
        query: {
          'industryId': industry.id,
          'page': 1,
          'limit': 50,
          'pageSize': 50,
        },
      );
      if (!mounted) return;
      setState(() {
        _categoryPublicOptions = items;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadSkillsForCategory(_PublicOption category) async {
    setState(() => _isLoadingSkills = true);
    try {
      final items = await _loadPublicOptions(
        ApiEndpoints.publicSkills,
        query: {
          'categoryId': category.id,
          'page': 1,
          'limit': 50,
          'pageSize': 50,
        },
      );
      if (!mounted) return;
      setState(() {
        _skillPublicOptions = items;
        _isLoadingSkills = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSkills = false);
    }
  }

  void _onIndustryChanged(_PublicOption? value) {
    setState(() {
      _selectedIndustry = value;
      _categoryOption = null;
      _clientProjectCategory = null;
      _categoryPublicOptions = const [];
      _skillPublicOptions = const [];
      _skills.clear();
      _projectPreferredSkills.clear();
      _industry.text = value?.label ?? '';
    });
    if (value != null) _loadCategoriesForIndustry(value);
  }

  void _onCategoryChanged(_PublicOption? value) {
    setState(() {
      _categoryOption = value;
      _skillPublicOptions = const [];
      _skills.clear();
      if (_clientProjectCategory?.id == value?.id) {
        _clientProjectCategory = null;
        _projectPreferredSkills.clear();
      }
    });
    if (value != null) _loadSkillsForCategory(value);
  }

  void _onClientProjectCategoryChanged(_PublicOption? value) {
    setState(() {
      _clientProjectCategory = value;
      _skillPublicOptions = const [];
      _projectPreferredSkills.clear();
    });
    if (value != null) _loadSkillsForCategory(value);
  }

  void _onFounderProfileCategoryChanged(_PublicOption? value) {
    setState(() {
      _founderProfileCategory = value;
      _skillPublicOptions = const [];
      _skills.clear();
    });
    if (value != null) _loadSkillsForCategory(value);
  }

  void _onFounderTaxonomyCategoryChanged(_PublicOption? value) {
    setState(() {
      _founderTaxonomyCategory = value;
      _founderSubCategory = null;
      _skillPublicOptions = const [];
    });
    if (value != null) _loadSkillsForCategory(value);
  }

  void _onPortfolioIndustryChanged(_PublicOption? value) {
    setState(() {
      _portfolioIndustryOption = value;
      _portfolioCategoryOption = null;
      _categoryPublicOptions = const [];
      _skillPublicOptions = const [];
      _portfolioIndustry.text = value?.label ?? '';
      _portfolioTechStack.clear();
    });
    if (value != null) _loadCategoriesForIndustry(value);
  }

  void _onPortfolioCategoryChanged(_PublicOption? value) {
    setState(() {
      _portfolioCategoryOption = value;
      _skillPublicOptions = const [];
      _portfolioTechStack.clear();
    });
    if (value != null) _loadSkillsForCategory(value);
  }

  String? _validatePhone(String? value) => PhoneValidation.validateMobile(
    value: value,
    countryIsoCode: _countryIsoCode,
    countryName: _countryName,
  );

  Future<void> _sendEmailOtp() async {
    final email = _email.text.trim();
    if (email.isEmpty || Validators.email(email) != null) {
      context.showSnack('Please enter a valid email first', isError: true);
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      final res = await Dio().post(
        '${AppConfig.authBaseUrl}${ApiEndpoints.sendOtp}',
        data: {'email': email},
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        context.showSnack('OTP sent to your email');
      } else {
        context.showSnack(
          'Failed to send OTP (${res.statusCode})',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        context.showSnack(
          'Error sending OTP. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final email = _email.text.trim();
    final otp = _emailOtp.text.trim();
    if (email.isEmpty || Validators.email(email) != null) {
      context.showSnack('Please enter a valid email first', isError: true);
      return;
    }
    if (otp.isEmpty) {
      context.showSnack('Please enter email OTP', isError: true);
      return;
    }
    setState(() => _isVerifyingOtp = true);
    try {
      final res = await Dio().post(
        '${AppConfig.authBaseUrl}${ApiEndpoints.verifyOtp}',
        data: {'email': email, 'otp': otp},
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _isEmailVerified = true);
        context.showSnack('Email verified successfully!');
      } else {
        context.showSnack('Invalid OTP', isError: true);
      }
    } catch (_) {
      if (mounted) {
        context.showSnack('Error verifying OTP', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _onContinue(AuthState state) {
    FocusScope.of(context).unfocus();
    if (_step == 0 && _role == null) {
      context.showSnack('Please choose a role', isError: true);
      return;
    }
    if (!_validateCurrentStep()) return;
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }
    _submit(state);
  }

  bool _validateCurrentStep() {
    final stepName = _steps[_step];
    switch (stepName) {
      case 'Account':
        return _formKey.currentState?.validate() ?? false;
      case 'Category':
        if (_selectedIndustry == null && _effectiveIndustryOptions.isNotEmpty) {
          context.showSnack('Please choose an industry', isError: true);
          return false;
        }
        if (_categoryPublicOptions.isNotEmpty && _categoryOption == null) {
          context.showSnack('Please choose a category', isError: true);
          return false;
        }
        return true;
      case 'Skills & Experience':
        if (_experience.text.trim().isEmpty) {
          context.showSnack('Please enter years of experience', isError: true);
          return false;
        }
        return true;
      case 'Budget':
        if (_hourlyRate.text.trim().isEmpty) {
          context.showSnack('Please enter amount', isError: true);
          return false;
        }
        return true;
      case 'Profile':
        if (_role == UserRole.client) {
          if (_businessName.text.trim().isEmpty) {
            context.showSnack('Please enter company name', isError: true);
            return false;
          }
          if (_businessDescription.text.trim().isEmpty) {
            context.showSnack(
              'Please enter company description',
              isError: true,
            );
            return false;
          }
          if (_selectedIndustry == null) {
            context.showSnack('Please choose industry', isError: true);
            return false;
          }
          if (_teamSize == null || _teamSize!.trim().isEmpty) {
            context.showSnack('Please choose team size', isError: true);
            return false;
          }
        }
        if (_role == UserRole.investor) {
          if (_investorCompanyFund.text.trim().isEmpty) {
            context.showSnack('Please enter company name', isError: true);
            return false;
          }
          if (_ticketSize == null) {
            context.showSnack('Please choose ticket size', isError: true);
            return false;
          }
          if (_stagePreferencesSelected.isEmpty) {
            context.showSnack('Please choose stage preference', isError: true);
            return false;
          }
          if (_investmentModesSelected.isEmpty) {
            context.showSnack('Please choose investment mode', isError: true);
            return false;
          }
          if (_targetIndustriesSelected.isEmpty) {
            context.showSnack('Please choose categories', isError: true);
            return false;
          }
        }
        if (_role == UserRole.founder) {
          if (_bio.text.trim().isEmpty) {
            context.showSnack('Please enter bio', isError: true);
            return false;
          }
          if (_founderProfileCategory == null) {
            context.showSnack('Please choose category', isError: true);
            return false;
          }
          if (_experience.text.trim().isEmpty) {
            context.showSnack('Please enter experience', isError: true);
            return false;
          }
          if (_teamSize == null || _teamSize!.trim().isEmpty) {
            context.showSnack('Please choose team size', isError: true);
            return false;
          }
        }
        return true;
      case 'Business type':
        if (_businessType == null || _businessType!.trim().isEmpty) {
          context.showSnack('Please choose business type', isError: true);
          return false;
        }
        return true;
      case 'Investor type':
        if (_investorType == null || _investorType!.trim().isEmpty) {
          context.showSnack('Please choose investor type', isError: true);
          return false;
        }
        return true;
      case 'Founder type':
        if (_founderType == null || _founderType!.trim().isEmpty) {
          context.showSnack('Please choose founder type', isError: true);
          return false;
        }
        return true;
      case 'Startup Details':
        if (_startupName.text.trim().isEmpty) {
          context.showSnack('Please enter startup name', isError: true);
          return false;
        }
        if (_startupStage == null || _startupStage!.trim().isEmpty) {
          context.showSnack('Please choose startup stage', isError: true);
          return false;
        }
        if (_shortPitch.text.trim().isEmpty) {
          context.showSnack('Please enter pitch', isError: true);
          return false;
        }
        if (_longDescription.text.trim().isEmpty) {
          context.showSnack('Please enter description', isError: true);
          return false;
        }
        if (_problemStatement.text.trim().isEmpty) {
          context.showSnack('Please enter problem statement', isError: true);
          return false;
        }
        if (_solution.text.trim().isEmpty) {
          context.showSnack('Please enter solution', isError: true);
          return false;
        }
        if (_targetCustomers.text.trim().isEmpty) {
          context.showSnack('Please enter target customers', isError: true);
          return false;
        }
        if (_startupDocumentName == null) {
          context.showSnack('Please upload startup file', isError: true);
          return false;
        }
        return true;
      case 'Badges':
        if (_educationInstitution.text.trim().isEmpty ||
            _educationQualification.text.trim().isEmpty ||
            _educationSpecialization.text.trim().isEmpty ||
            _educationYear.text.trim().isEmpty) {
          context.showSnack(
            'Please complete all education fields',
            isError: true,
          );
          return false;
        }
        if (_educationDocumentName == null) {
          context.showSnack('Please upload education file', isError: true);
          return false;
        }
        return true;
      case 'Taxonomy':
        if (_role == UserRole.founder && _founderTaxonomyCategory == null) {
          context.showSnack('Please choose primary category', isError: true);
          return false;
        }
        return true;
      case 'Services & Requirements':
        if (_selectedIndustry == null && _effectiveIndustryOptions.isNotEmpty) {
          context.showSnack(
            'Please choose an industry in Profile',
            isError: true,
          );
          return false;
        }
        if (_categoryPublicOptions.isNotEmpty && _categoryOption == null) {
          context.showSnack('Please choose category', isError: true);
          return false;
        }
        return true;
      case 'Looking For':
        if (_lookingForGoals.isEmpty) {
          context.showSnack('Please choose at least one goal', isError: true);
          return false;
        }
        return true;
      case 'Expansion':
        if (_expansionGoals.isEmpty) {
          context.showSnack(
            'Please choose at least one expansion goal',
            isError: true,
          );
          return false;
        }
        return true;
      case 'Goals':
        if (_role == UserRole.investor && _investorGoals.isEmpty) {
          context.showSnack('Please choose at least one goal', isError: true);
          return false;
        }
        if (_role == UserRole.founder && _founderGoalsSelected.isEmpty) {
          context.showSnack('Please choose at least one goal', isError: true);
          return false;
        }
        return true;
      case 'Projects':
        final hasTitle = _projectTitle.text.trim().isNotEmpty;
        if (!hasTitle) return true;
        if (_projectDescription.text.trim().isEmpty) {
          context.showSnack('Please enter project description', isError: true);
          return false;
        }
        if (_clientProjectCategory == null) {
          context.showSnack('Please choose project category', isError: true);
          return false;
        }
        if (_projectSelectedSkills.isEmpty) {
          context.showSnack('Please choose project skills', isError: true);
          return false;
        }
        if (_projectBudget.text.trim().isEmpty) {
          context.showSnack('Please enter project budget', isError: true);
          return false;
        }
        if (_projectTimeline.text.trim().isEmpty) {
          context.showSnack('Please enter project timeline', isError: true);
          return false;
        }
        return true;
      case 'Verification':
        final phoneError = _validatePhone(_phone.text);
        if (phoneError != null) {
          context.showSnack(phoneError, isError: true);
          return false;
        }
        final passwordError = Validators.password(_password.text);
        if (passwordError != null) {
          context.showSnack(passwordError, isError: true);
          return false;
        }
        final confirmError = Validators.confirmPassword(
          _confirm.text,
          _password.text,
        );
        if (confirmError != null) {
          context.showSnack(confirmError, isError: true);
          return false;
        }
        if (!_isEmailVerified) {
          context.showSnack('Please verify your email address', isError: true);
          return false;
        }
        if (_aadhaar.text.trim().length != 12) {
          context.showSnack(
            'Please enter a valid 12-digit Aadhaar number',
            isError: true,
          );
          return false;
        }
        final panPattern = RegExp(r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$');
        if (!panPattern.hasMatch(_pan.text.trim())) {
          context.showSnack(
            'Please enter a valid PAN card number',
            isError: true,
          );
          return false;
        }
        if (_verificationDocName == null) {
          context.showSnack('Please upload ID document', isError: true);
          return false;
        }
        if (!_agree) {
          context.showSnack(
            'Please accept the Terms & Privacy Policy',
            isError: true,
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  String? _selectedCountryId() {
    for (final country in _countryOptions) {
      if (country.name == _country.text.trim()) return country.id;
    }
    return null;
  }

  String? _selectedStateId() {
    for (final state in _stateOptions) {
      if (state.name == _stateLocation.text.trim()) return state.id;
    }
    return null;
  }

  List<String> _idsForOptions(List<String> values) =>
      values.map(_idForOption).where((item) => item.isNotEmpty).toList();

  void _putIfNotEmpty(Map<String, dynamic> data, String key, Object? value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    if (value is Iterable && value.isEmpty) return;
    data[key] = value;
  }

  Map<String, dynamic> _baseSignupPayload() {
    final data = <String, dynamic>{};
    _putIfNotEmpty(data, 'countryId', _selectedCountryId());
    _putIfNotEmpty(data, 'stateId', _selectedStateId());
    _putIfNotEmpty(data, 'city', _city.text.trim());
    data['verification'] = {
      'emailVerified': _isEmailVerified,
      'aadhaar': _aadhaar.text.trim(),
      'pan': _pan.text.trim().toUpperCase(),
      'document': _verificationDocName,
      'acceptedTerms': _agree,
    };
    final plan = _selectedPlanOption();
    if (plan != null) {
      data['subscription'] = {
        'isFreePlan': plan.isFree,
        'planId': plan.id,
        'paymentType': _paymentType,
        'paymentStatus': _paymentStatus,
        'transactionId': _transactionId,
      };
    }
    return data;
  }

  Map<String, dynamic> _roleSignupPayload() {
    final data = _baseSignupPayload();
    switch (_role) {
      case UserRole.freelancer:
        _putIfNotEmpty(data, 'industryId', _selectedIndustry?.id);
        _putIfNotEmpty(data, 'categoryId', _categoryOption?.id);
        _putIfNotEmpty(data, 'skills', _idsForOptions(_selectedSkills));
        _putIfNotEmpty(data, 'experienceYears', _experience.text.trim());
        _putIfNotEmpty(data, 'bio', _bio.text.trim());
        _putIfNotEmpty(data, 'linkedinUrl', _linkedin.text.trim());
        _putIfNotEmpty(data, 'githubUrl', _github.text.trim());
        _putIfNotEmpty(data, 'portfolioUrl', _portfolioUrl.text.trim());
        _putIfNotEmpty(data, 'hourlyRate', _hourlyRate.text.trim());
        data['portfolio'] = {
          'title': _portfolioTitle.text.trim(),
          'industryId': _portfolioIndustryOption?.id,
          'categoryId': _portfolioCategoryOption?.id,
          'skills': _idsForOptions(_portfolioSelectedSkills),
          'status': _portfolioStatus,
          'client': _portfolioClient.text.trim(),
          'duration': _portfolioDuration.text.trim(),
          'teamSizeId': _portfolioTeamSize == null
              ? null
              : _idForOption(_portfolioTeamSize!),
          'role': _portfolioRole.text.trim(),
          'githubUrl': _portfolioGithub.text.trim(),
          'liveUrl': _portfolioLiveUrl.text.trim(),
          'overview': _portfolioOverview.text.trim(),
          'coverImage': _portfolioCoverName,
          'videoDemo': _portfolioVideoName,
          'caseStudy': _portfolioCaseStudyName,
          'screenshot': _portfolioScreenshotName,
        };
        data['education'] = {
          'institution': _educationInstitution.text.trim(),
          'qualification': _educationQualification.text.trim(),
          'specialization': _educationSpecialization.text.trim(),
          'year': _educationYear.text.trim(),
          'document': _educationDocumentName,
        };
        data['certificate'] = {
          'name': _certificateName.text.trim(),
          'issuer': _certificateIssuer.text.trim(),
          'issueDate': _certificateIssueDate.text.trim(),
          'url': _certificateUrl.text.trim(),
          'document': _certificateDocumentName,
        };
        break;
      case UserRole.client:
        _putIfNotEmpty(
          data,
          'businessTypeId',
          _businessType == null ? null : _idForOption(_businessType!),
        );
        _putIfNotEmpty(data, 'businessName', _businessName.text.trim());
        _putIfNotEmpty(
          data,
          'businessDescription',
          _businessDescription.text.trim(),
        );
        _putIfNotEmpty(data, 'website', _website.text.trim());
        _putIfNotEmpty(data, 'industryId', _selectedIndustry?.id);
        _putIfNotEmpty(
          data,
          'teamSizeId',
          _teamSize == null ? null : _idForOption(_teamSize!),
        );
        _putIfNotEmpty(data, 'gstNumber', _gstNumber.text.trim());
        _putIfNotEmpty(
          data,
          'annualRequirement',
          _annualRequirement.text.trim(),
        );
        _putIfNotEmpty(data, 'serviceLocation', _serviceLocation.text.trim());
        _putIfNotEmpty(data, 'categoryId', _categoryOption?.id);
        _putIfNotEmpty(data, 'skills', _idsForOptions(_selectedSkills));
        _putIfNotEmpty(data, 'clientGoals', _idsForOptions(_lookingForGoals));
        data['project'] = {
          'title': _projectTitle.text.trim(),
          'description': _projectDescription.text.trim(),
          'categoryId': _clientProjectCategory?.id,
          'skills': _idsForOptions(_projectSelectedSkills),
          'budget': _projectBudget.text.trim(),
          'timeline': _projectTimeline.text.trim(),
          'locationPreference': _projectLocationPreference.text.trim(),
          'remoteType': _remoteType,
          'urgency': _urgency,
        };
        _putIfNotEmpty(data, 'expansionGoals', _idsForOptions(_expansionGoals));
        break;
      case UserRole.investor:
        _putIfNotEmpty(
          data,
          'investorTypeId',
          _investorType == null ? null : _idForOption(_investorType!),
        );
        _putIfNotEmpty(
          data,
          'companyFundName',
          _investorCompanyFund.text.trim(),
        );
        _putIfNotEmpty(data, 'linkedinUrl', _linkedin.text.trim());
        _putIfNotEmpty(data, 'website', _website.text.trim());
        _putIfNotEmpty(data, 'bio', _bio.text.trim());
        _putIfNotEmpty(data, 'ticketSizeId', _ticketSize);
        _putIfNotEmpty(data, 'minTicket', _minTicket.text.trim());
        _putIfNotEmpty(data, 'maxTicket', _maxTicket.text.trim());
        _putIfNotEmpty(
          data,
          'stagePreferences',
          _idsForOptions(_stagePreferencesSelected),
        );
        _putIfNotEmpty(
          data,
          'investmentModes',
          _idsForOptions(_investmentModesSelected),
        );
        _putIfNotEmpty(
          data,
          'categories',
          _idsForOptions(_targetIndustriesSelected),
        );
        _putIfNotEmpty(data, 'goals', _idsForOptions(_investorGoals));
        break;
      case UserRole.founder:
        _putIfNotEmpty(
          data,
          'founderTypeId',
          _founderType == null ? null : _idForOption(_founderType!),
        );
        _putIfNotEmpty(data, 'bio', _bio.text.trim());
        _putIfNotEmpty(data, 'profileCategoryId', _founderProfileCategory?.id);
        _putIfNotEmpty(data, 'skills', _idsForOptions(_selectedSkills));
        _putIfNotEmpty(data, 'experienceYears', _experience.text.trim());
        _putIfNotEmpty(data, 'education', _education.text.trim());
        _putIfNotEmpty(data, 'linkedinUrl', _linkedin.text.trim());
        _putIfNotEmpty(data, 'portfolioUrl', _portfolioUrl.text.trim());
        _putIfNotEmpty(
          data,
          'teamSizeId',
          _teamSize == null ? null : _idForOption(_teamSize!),
        );
        data['startup'] = {
          'name': _startupName.text.trim(),
          'stageId': _startupStage == null
              ? null
              : _idForOption(_startupStage!),
          'shortPitch': _shortPitch.text.trim(),
          'longDescription': _longDescription.text.trim(),
          'problemStatement': _problemStatement.text.trim(),
          'solution': _solution.text.trim(),
          'targetCustomers': _targetCustomers.text.trim(),
          'marketSize': _marketSize.text.trim(),
          'businessModel': _businessModel.text.trim(),
          'revenueModel': _revenueModel.text.trim(),
          'currentProgress': _currentProgress.text.trim(),
          'fundingRequired': _fundingRequired.text.trim(),
          'equityOffered': _equityOffered.text.trim(),
          'pitchDeck': _startupDocumentName,
          'demoLink': _demoLink.text.trim(),
        };
        data['taxonomy'] = {
          'primaryCategoryId': _founderTaxonomyCategory?.id,
          'skills': _founderSubCategory == null
              ? const <String>[]
              : [_idForOption(_founderSubCategory!)],
        };
        _putIfNotEmpty(data, 'goals', _idsForOptions(_founderGoalsSelected));
        break;
      case null:
        break;
    }
    return data;
  }

  String _transactionIdFromCheckout(
    PaymentInitiateResult payment,
    EasebuzzCheckoutResult checkout,
  ) {
    final raw = checkout.raw;
    final nested = raw['payment_response'] is Map
        ? Map<String, dynamic>.from(raw['payment_response'] as Map)
        : const <String, dynamic>{};
    return nested['txnid']?.toString() ??
        nested['easepayid']?.toString() ??
        nested['transaction_id']?.toString() ??
        raw['txnid']?.toString() ??
        raw['easepayid']?.toString() ??
        raw['transaction_id']?.toString() ??
        payment.orderId;
  }

  Future<bool> _ensureSubscriptionPayment() async {
    final plan = _selectedPlanOption();
    if (plan == null) {
      context.showSnack('Please choose a subscription plan', isError: true);
      return false;
    }

    if (plan.isFree) {
      _paymentType = '';
      _paymentStatus = 'paid';
      _transactionId = '';
      _paidPlanId = plan.id;
      return true;
    }

    if (_paidPlanId == plan.id &&
        _paymentStatus == 'paid' &&
        _transactionId.isNotEmpty) {
      return true;
    }

    setState(() => _isProcessingPayment = true);
    final checkout = sl<PaymentCheckoutService>();
    final result = await checkout.checkoutPublicWithEasebuzz(
      purpose: 'Subscription ${plan.name}',
      amount: plan.amount,
      planId: plan.id,
      email: _email.text.trim(),
      firstname: _name.text.trim(),
      phone: _phone.text.trim(),
      currency: plan.currency,
    );
    if (!mounted) return false;

    final paid = result.valueOrNull;
    if (paid == null) {
      setState(() => _isProcessingPayment = false);
      context.showSnack(
        result.failureOrNull?.message ?? 'Payment failed. Please try again.',
        isError: true,
      );
      return false;
    }

    setState(() => _isProcessingPayment = false);

    _paymentType = 'Easebuzz';
    _paymentStatus = 'paid';
    _transactionId = _transactionIdFromCheckout(paid.payment, paid.checkout);
    _paidPlanId = plan.id;
    return true;
  }

  Future<void> _submit(AuthState state) async {
    if (state.isSubmitting || _role == null) return;
    if (!await _ensureSubscriptionPayment()) return;
    if (!mounted) return;
    context.read<AuthBloc>().add(
      AuthSignupDraftSaved(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        countryCode: _countryCode,
        password: _password.text,
        signupData: _roleSignupPayload(),
      ),
    );
    context.read<AuthBloc>().add(AuthRoleSelected(_role!));
  }

  Future<void> _openProfilePhotoPicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickProfilePhoto(source);
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
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
      _profilePhotoName = picked.name;
      _profilePhotoPreview = MemoryImage(bytes);
    });
  }

  Future<void> _pickPortfolioMedia(_PortfolioMediaType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: switch (type) {
        _PortfolioMediaType.cover => const ['jpg', 'jpeg', 'png', 'webp'],
        _PortfolioMediaType.video => const ['mp4', 'mov'],
        _PortfolioMediaType.caseStudy => const ['pdf'],
        _PortfolioMediaType.screenshot => const ['jpg', 'jpeg', 'png', 'webp'],
      },
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    final source = file.path?.trim().isNotEmpty == true
        ? file.path!
        : file.name;
    setState(() {
      switch (type) {
        case _PortfolioMediaType.cover:
          _portfolioCoverName = file.name;
          _portfolioCoverSource = source;
        case _PortfolioMediaType.video:
          _portfolioVideoName = file.name;
          _portfolioVideoSource = source;
        case _PortfolioMediaType.caseStudy:
          _portfolioCaseStudyName = file.name;
          _portfolioCaseStudySource = source;
        case _PortfolioMediaType.screenshot:
          _portfolioScreenshotName = file.name;
          _portfolioScreenshotSource = source;
      }
    });
  }

  void _clearPortfolioMedia(_PortfolioMediaType type) {
    setState(() {
      switch (type) {
        case _PortfolioMediaType.cover:
          _portfolioCoverName = null;
          _portfolioCoverSource = null;
        case _PortfolioMediaType.video:
          _portfolioVideoName = null;
          _portfolioVideoSource = null;
        case _PortfolioMediaType.caseStudy:
          _portfolioCaseStudyName = null;
          _portfolioCaseStudySource = null;
        case _PortfolioMediaType.screenshot:
          _portfolioScreenshotName = null;
          _portfolioScreenshotSource = null;
      }
    });
  }

  Future<void> _pickEducationDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() {
      _educationDocumentName = file.name;
      _educationDocumentSource = _pickedFileSource(file);
    });
  }

  Future<void> _pickCertificateDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() {
      _certificateDocumentName = file.name;
      _certificateDocumentSource = _pickedFileSource(file);
    });
  }

  Future<void> _pickStartupDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() {
      _startupDocumentName = file.name;
      _startupDocumentSource = _pickedFileSource(file);
    });
  }

  Future<void> _pickCertificateIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    setState(() {
      _certificateIssueDate.text = '${picked.year}-$month-$day';
    });
  }

  Future<void> _pickVerificationDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() {
      _verificationDocName = file.name;
      _verificationDocSource = _pickedFileSource(file);
    });
  }

  Future<void> _pickProjectReferenceFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'mp4',
        'mov',
        'doc',
        'docx',
      ],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() {
      _projectReferenceName = file.name;
      _projectReferenceSource = _pickedFileSource(file);
    });
  }

  String _pickedFileSource(PlatformFile file) =>
      file.path?.trim().isNotEmpty == true ? file.path! : file.name;

  void _clearSignupDocument(_SignupDocumentType type) {
    setState(() {
      switch (type) {
        case _SignupDocumentType.education:
          _educationDocumentName = null;
          _educationDocumentSource = null;
        case _SignupDocumentType.certificate:
          _certificateDocumentName = null;
          _certificateDocumentSource = null;
        case _SignupDocumentType.startup:
          _startupDocumentName = null;
          _startupDocumentSource = null;
        case _SignupDocumentType.verification:
          _verificationDocName = null;
          _verificationDocSource = null;
        case _SignupDocumentType.projectReference:
          _projectReferenceName = null;
          _projectReferenceSource = null;
      }
    });
  }

  void _onBack() {
    if (_step == 0) {
      if (context.canPop()) {
        context.pop();
      }
      return;
    }
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage && c.errorMessage != null,
      listener: (context, state) =>
          context.showSnack(state.errorMessage!, isError: true),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 64 : AppSizes.lg,
                    vertical: isWide ? 44 : AppSizes.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _SignupWizard(
                              step: _step,
                              steps: _steps,
                              progressPercent: _progressPercent,
                              label: _signupLabel,
                              content: _buildStepContent(),
                              onBack: _onBack,
                              onContinue: () => _onContinue(state),
                              isSubmitting:
                                  state.isSubmitting || _isProcessingPayment,
                              isLastStep: _step == _steps.length - 1,
                            ),
                          ),
                          if (isWide) ...[
                            const SizedBox(width: 40),
                            SizedBox(
                              width: 410,
                              child: _SignupSidePanel(
                                role: _role,
                                progressPercent: _progressPercent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent() {
    switch (_steps[_step]) {
      case 'Role':
        return _RoleStep(
          selected: _role,
          onSelected: (role) => setState(() {
            _role = role;
            _ensureSelectedPlanForRole();
          }),
        );
      case 'Account':
        if (_role == UserRole.investor) {
          return _BasicRoleAccountStep(
            formKey: _formKey,
            name: _name,
            email: _email,
            country: _country,
            countryOptions: _countryOptions,
            stateLocation: _stateLocation,
            stateOptions: _stateOptions,
            city: _city,
            onCountrySelected: _setCountryOption,
            onCountryPlaceSelected: (place) =>
                _keepPlaceNameOnly(_country, place),
            onStateSelected: _setStateOption,
            onStatePlaceSelected: (place) =>
                _keepPlaceNameOnly(_stateLocation, place),
            onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
            onEmailChanged: (_) {
              if (_isEmailVerified) setState(() => _isEmailVerified = false);
            },
          );
        }
        if (_role == UserRole.founder) {
          return _FounderAccountStep(
            formKey: _formKey,
            name: _name,
            email: _email,
            country: _country,
            countryOptions: _countryOptions,
            stateLocation: _stateLocation,
            stateOptions: _stateOptions,
            city: _city,
            onCountrySelected: _setCountryOption,
            onCountryPlaceSelected: (place) =>
                _keepPlaceNameOnly(_country, place),
            onStateSelected: _setStateOption,
            onStatePlaceSelected: (place) =>
                _keepPlaceNameOnly(_stateLocation, place),
            onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
            onEmailChanged: (_) {
              if (_isEmailVerified) setState(() => _isEmailVerified = false);
            },
          );
        }
        if (_role == UserRole.client) {
          return _ClientAccountStep(
            formKey: _formKey,
            name: _name,
            email: _email,
            country: _country,
            countryOptions: _countryOptions,
            stateLocation: _stateLocation,
            stateOptions: _stateOptions,
            city: _city,
            onCountrySelected: _setCountryOption,
            onCountryPlaceSelected: (place) =>
                _keepPlaceNameOnly(_country, place),
            onStateSelected: _setStateOption,
            onStatePlaceSelected: (place) =>
                _keepPlaceNameOnly(_stateLocation, place),
            onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
            onEmailChanged: (_) {
              if (_isEmailVerified) setState(() => _isEmailVerified = false);
            },
          );
        }
        return _AccountStep(
          formKey: _formKey,
          name: _name,
          email: _email,
          country: _country,
          countryOptions: _countryOptions,
          stateLocation: _stateLocation,
          stateOptions: _stateOptions,
          city: _city,
          onCountrySelected: _setCountryOption,
          onCountryPlaceSelected: (place) =>
              _keepPlaceNameOnly(_country, place),
          onStateSelected: _setStateOption,
          onStatePlaceSelected: (place) =>
              _keepPlaceNameOnly(_stateLocation, place),
          onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
          onEmailChanged: (_) {
            if (_isEmailVerified) setState(() => _isEmailVerified = false);
          },
        );
      case 'Category':
        return _CategoryStep(
          industry: _selectedIndustry,
          category: _categoryOption,
          industries: _effectiveIndustryOptions,
          categories: _categoryPublicOptions,
          isLoadingCategories: _isLoadingCategories,
          onIndustryChanged: _onIndustryChanged,
          onCategoryChanged: _onCategoryChanged,
        );
      case 'Skills & Experience':
        return _SkillsStep(
          skills: _skills,
          experience: _experience,
          bio: _bio,
          selectedSkills: _selectedSkills,
          skillOptions: _effectiveSkillOptions,
          isLoadingSkills: _isLoadingSkills,
          onSkillSelected: _addSkill,
          onSkillRemoved: _removeSkill,
          onManualSkillsChanged: (_) => setState(() {}),
        );
      case 'Profile':
        if (_role == UserRole.investor) {
          return _InvestorProfileStep(
            profilePhotoName: _profilePhotoName,
            profilePhotoPreview: _profilePhotoPreview,
            companyFund: _investorCompanyFund,
            linkedin: _linkedin,
            website: _website,
            bio: _bio,
            ticketSize: _ticketSize,
            ticketOptions: _ticketSizeOptions,
            stagePreferences: _stagePreferencesSelected,
            investmentModes: _investmentModesSelected,
            targetIndustries: _targetIndustriesSelected,
            stageOptions: _stagePreferenceOptions,
            investmentModeOptions: _investmentModeOptions,
            industryOptions: _targetIndustryOptions,
            onPickProfilePhoto: _openProfilePhotoPicker,
            onTicketChanged: (value) {
              _TicketOption? ticket;
              for (final option in _ticketSizeOptions) {
                if (option.id == value) {
                  ticket = option;
                  break;
                }
              }
              setState(() {
                _ticketSize = value;
                if (ticket != null) {
                  _minTicket.text = ticket.min?.toString() ?? '';
                  _maxTicket.text = ticket.max?.toString() ?? '';
                }
              });
            },
            onStageChanged: (value) =>
                _toggleSelection(_stagePreferencesSelected, value),
            onModeChanged: (value) =>
                _toggleSelection(_investmentModesSelected, value),
            onIndustryChanged: (value) =>
                _toggleSelection(_targetIndustriesSelected, value),
          );
        }
        if (_role == UserRole.founder) {
          return _FounderProfileStep(
            profilePhotoName: _profilePhotoName,
            profilePhotoPreview: _profilePhotoPreview,
            bio: _bio,
            skills: _skills,
            experience: _experience,
            education: _education,
            linkedin: _linkedin,
            portfolioUrl: _portfolioUrl,
            teamSize: _teamSize,
            teamSizeOptions: _teamSizeOptions,
            category: _founderProfileCategory,
            categoryOptions: _founderCategoryOptions,
            selectedSkills: _selectedSkills,
            skillOptions: _founderProfileCategory == null
                ? const []
                : _effectiveSkillOptions,
            isLoadingSkills: _isLoadingSkills,
            onCategoryChanged: _onFounderProfileCategoryChanged,
            onSkillSelected: _addSkill,
            onSkillRemoved: _removeSkill,
            onManualSkillsChanged: (_) => setState(() {}),
            onPickProfilePhoto: _openProfilePhotoPicker,
            onTeamSizeChanged: (value) => setState(() => _teamSize = value),
          );
        }
        if (_role == UserRole.client) {
          return _ClientProfileStep(
            logoName: _profilePhotoName,
            logoPreview: _profilePhotoPreview,
            businessName: _businessName,
            businessDescription: _businessDescription,
            website: _website,
            industry: _selectedIndustry,
            industryOptions: _effectiveIndustryOptions,
            gstNumber: _gstNumber,
            teamSize: _teamSize,
            teamSizeOptions: _teamSizeOptions,
            annualRequirement: _annualRequirement,
            serviceLocation: _serviceLocation,
            onPickLogo: _openProfilePhotoPicker,
            onIndustryChanged: _onIndustryChanged,
            onTeamSizeChanged: (value) => setState(() => _teamSize = value),
          );
        }
        return _ProfileStep(
          linkedin: _linkedin,
          github: _github,
          portfolioUrl: _portfolioUrl,
          profilePhotoName: _profilePhotoName,
          profilePhotoPreview: _profilePhotoPreview,
          onPickProfilePhoto: _openProfilePhotoPicker,
        );
      case 'Budget':
        return _BudgetStep(hourlyRate: _hourlyRate);
      case 'Portfolios':
        return _PortfolioUploadsStep(
          title: _portfolioTitle,
          selectedIndustry: _portfolioIndustryOption,
          industryOptions: _effectiveIndustryOptions,
          category: _portfolioCategoryOption,
          categoryOptions: _categoryPublicOptions,
          selectedSkills: _portfolioSelectedSkills,
          skillOptions: _portfolioCategoryOption == null
              ? const []
              : _effectiveSkillOptions,
          isLoadingCategories: _isLoadingCategories,
          isLoadingSkills: _isLoadingSkills,
          status: _portfolioStatus,
          client: _portfolioClient,
          techStack: _portfolioTechStack,
          duration: _portfolioDuration,
          teamSize: _portfolioTeamSize,
          teamSizeOptions: _teamSizeOptions,
          role: _portfolioRole,
          githubUrl: _portfolioGithub,
          liveUrl: _portfolioLiveUrl,
          overview: _portfolioOverview,
          coverName: _portfolioCoverName,
          videoName: _portfolioVideoName,
          caseStudyName: _portfolioCaseStudyName,
          screenshotName: _portfolioScreenshotName,
          coverSource: _portfolioCoverSource,
          videoSource: _portfolioVideoSource,
          caseStudySource: _portfolioCaseStudySource,
          screenshotSource: _portfolioScreenshotSource,
          onIndustryChanged: _onPortfolioIndustryChanged,
          onCategoryChanged: _onPortfolioCategoryChanged,
          onSkillSelected: _addPortfolioSkill,
          onSkillRemoved: _removePortfolioSkill,
          onManualSkillsChanged: (_) => setState(() {}),
          onStatusChanged: (value) => setState(() => _portfolioStatus = value),
          onTeamSizeChanged: (value) =>
              setState(() => _portfolioTeamSize = value),
          onPickCover: () => _pickPortfolioMedia(_PortfolioMediaType.cover),
          onPickVideo: () => _pickPortfolioMedia(_PortfolioMediaType.video),
          onPickCaseStudy: () =>
              _pickPortfolioMedia(_PortfolioMediaType.caseStudy),
          onPickScreenshot: () =>
              _pickPortfolioMedia(_PortfolioMediaType.screenshot),
          onClearCover: () => _clearPortfolioMedia(_PortfolioMediaType.cover),
          onClearVideo: () => _clearPortfolioMedia(_PortfolioMediaType.video),
          onClearCaseStudy: () =>
              _clearPortfolioMedia(_PortfolioMediaType.caseStudy),
          onClearScreenshot: () =>
              _clearPortfolioMedia(_PortfolioMediaType.screenshot),
        );
      case 'Badges':
        return _BadgesStep(
          institution: _educationInstitution,
          qualification: _educationQualification,
          specialization: _educationSpecialization,
          year: _educationYear,
          educationDocumentName: _educationDocumentName,
          educationDocumentSource: _educationDocumentSource,
          certificateName: _certificateName,
          certificateIssuer: _certificateIssuer,
          certificateIssueDate: _certificateIssueDate,
          certificateDocumentName: _certificateDocumentName,
          certificateDocumentSource: _certificateDocumentSource,
          certificateUrl: _certificateUrl,
          onPickEducationDocument: _pickEducationDocument,
          onPickCertificateDocument: _pickCertificateDocument,
          onClearEducationDocument: () =>
              _clearSignupDocument(_SignupDocumentType.education),
          onClearCertificateDocument: () =>
              _clearSignupDocument(_SignupDocumentType.certificate),
          onPickCertificateIssueDate: _pickCertificateIssueDate,
        );
      case 'Billing':
        return _BillingStep(
          plans: _plansForRole(_role),
          selectedPlan: _plan,
          onSelected: _setSelectedPlan,
        );
      case 'Business type':
        return _ClientBusinessTypeStep(
          value: _businessType,
          items: _businessTypeOptions,
          label: 'Business Type *',
          onChanged: (value) => setState(() => _businessType = value),
        );
      case 'Founder type':
        return _ClientBusinessTypeStep(
          value: _founderType,
          items: _founderTypeOptions,
          label: 'Founder Type *',
          onChanged: (value) => setState(() => _founderType = value),
        );
      case 'Services & Requirements':
        return _ClientServiceStep(
          industry: _selectedIndustry,
          category: _categoryOption,
          categories: _categoryPublicOptions,
          selectedSkills: _selectedSkills,
          skillOptions: _categoryOption == null
              ? const []
              : _effectiveSkillOptions,
          isLoadingCategories: _isLoadingCategories,
          isLoadingSkills: _isLoadingSkills,
          onCategoryChanged: _onCategoryChanged,
          onSkillSelected: _addSkill,
          onSkillRemoved: _removeSkill,
        );
      case 'Looking For':
        return _MultiChoiceListStep(
          title: 'What are your goals? *',
          options: _clientGoalOptions,
          values: _lookingForGoals,
          onChanged: (value) => _toggleSelection(_lookingForGoals, value),
        );
      case 'Projects':
        return _ClientProjectsStep(
          title: _projectTitle,
          category: _clientProjectCategory,
          budget: _projectBudget,
          timeline: _projectTimeline,
          description: _projectDescription,
          preferredSkills: _projectPreferredSkills,
          locationPreference: _projectLocationPreference,
          remoteType: _remoteType,
          urgency: _urgency,
          referenceFileName: _projectReferenceName,
          referenceFileSource: _projectReferenceSource,
          industry: _selectedIndustry,
          categories: _categoryPublicOptions,
          skillOptions: _clientProjectCategory == null
              ? const []
              : _effectiveSkillOptions,
          selectedSkills: _projectSelectedSkills,
          isLoadingCategories: _isLoadingCategories,
          isLoadingSkills: _isLoadingSkills,
          onCategoryChanged: _onClientProjectCategoryChanged,
          onSkillSelected: _addProjectSkill,
          onSkillRemoved: _removeProjectSkill,
          onManualSkillsChanged: (_) => setState(() {}),
          onPickReferenceFile: _pickProjectReferenceFile,
          onClearReferenceFile: () =>
              _clearSignupDocument(_SignupDocumentType.projectReference),
          onRemoteTypeChanged: (value) => setState(() => _remoteType = value),
          onUrgencyChanged: (value) => setState(() => _urgency = value),
        );
      case 'Expansion':
        return _MultiChoiceListStep(
          title: 'Business Expansion Goals *',
          options: _expansionGoalOptions,
          values: _expansionGoals,
          onChanged: (value) => _toggleSelection(_expansionGoals, value),
        );
      case 'Subscription':
        return _BillingStep(
          plans: _plansForRole(_role),
          selectedPlan: _plan,
          onSelected: _setSelectedPlan,
        );
      case 'Investor type':
        return _ClientBusinessTypeStep(
          value: _investorType,
          items: _investorTypeOptions,
          label: 'Investor Type *',
          onChanged: (value) => setState(() => _investorType = value),
        );
      case 'Startup Details':
        return _FounderStartupDetailsStep(
          startupName: _startupName,
          startupStage: _startupStage,
          startupStageOptions: _startupStageOptions,
          shortPitch: _shortPitch,
          longDescription: _longDescription,
          problemStatement: _problemStatement,
          solution: _solution,
          targetCustomers: _targetCustomers,
          marketSize: _marketSize,
          businessModel: _businessModel,
          revenueModel: _revenueModel,
          currentProgress: _currentProgress,
          fundingRequired: _fundingRequired,
          equityOffered: _equityOffered,
          demoLink: _demoLink,
          documentName: _startupDocumentName,
          documentSource: _startupDocumentSource,
          onStageChanged: (value) => setState(() => _startupStage = value),
          onPickDocument: _pickStartupDocument,
          onClearDocument: () =>
              _clearSignupDocument(_SignupDocumentType.startup),
        );
      case 'Taxonomy':
        return _FounderTaxonomyStep(
          category: _founderTaxonomyCategory,
          skill: _founderSubCategory,
          categories: _founderCategoryOptions,
          skills: _founderTaxonomyCategory == null
              ? const []
              : _effectiveSkillOptions,
          isLoadingSkills: _isLoadingSkills,
          onCategoryChanged: _onFounderTaxonomyCategoryChanged,
          onSkillChanged: (value) =>
              setState(() => _founderSubCategory = value),
        );
      case 'Goals':
        if (_role == UserRole.investor) {
          return _MultiChoiceListStep(
            title: 'Looking For (Intent) *',
            options: _investorGoalOptions,
            values: _investorGoals,
            onChanged: (value) => _toggleSelection(_investorGoals, value),
          );
        }
        if (_role == UserRole.founder) {
          return _MultiChoiceListStep(
            title: 'What are you looking for? *',
            options: _founderGoals,
            values: _founderGoalsSelected,
            onChanged: (value) =>
                _toggleSelection(_founderGoalsSelected, value),
          );
        }
        break;
      case 'Verification':
        if (_role == UserRole.investor) {
          return _SimpleVerificationStep(
            email: _email,
            emailOtp: _emailOtp,
            accountPhone: _phone,
            countryIsoCode: _countryIsoCode,
            password: _password,
            confirm: _confirm,
            aadhaar: _aadhaar,
            pan: _pan,
            documentName: _verificationDocName,
            documentSource: _verificationDocSource,
            isEmailVerified: _isEmailVerified,
            isSendingOtp: _isSendingOtp,
            isVerifyingOtp: _isVerifyingOtp,
            agree: _agree,
            documentLabel: 'Upload Aadhaar / PAN Document *',
            documentHint: 'Upload JPG, PNG, PDF, DOC, or DOCX file.',
            onSendOtp: _sendEmailOtp,
            onVerifyOtp: _verifyEmailOtp,
            onCountryChanged: _setCountryCode,
            validatePhone: _validatePhone,
            onPickDocument: _pickVerificationDocument,
            onClearDocument: () =>
                _clearSignupDocument(_SignupDocumentType.verification),
            onAgreeChanged: (value) => setState(() => _agree = value ?? false),
          );
        }
        if (_role == UserRole.founder) {
          return _SimpleVerificationStep(
            email: _email,
            emailOtp: _emailOtp,
            accountPhone: _phone,
            countryIsoCode: _countryIsoCode,
            password: _password,
            confirm: _confirm,
            aadhaar: _aadhaar,
            pan: _pan,
            documentName: _verificationDocName,
            documentSource: _verificationDocSource,
            isEmailVerified: _isEmailVerified,
            isSendingOtp: _isSendingOtp,
            isVerifyingOtp: _isVerifyingOtp,
            agree: _agree,
            documentLabel: 'Upload Aadhaar / PAN Document *',
            documentHint: 'Upload JPG, PNG, PDF, DOC, or DOCX file.',
            onSendOtp: _sendEmailOtp,
            onVerifyOtp: _verifyEmailOtp,
            onCountryChanged: _setCountryCode,
            validatePhone: _validatePhone,
            onPickDocument: _pickVerificationDocument,
            onClearDocument: () =>
                _clearSignupDocument(_SignupDocumentType.verification),
            onAgreeChanged: (value) => setState(() => _agree = value ?? false),
          );
        }
        return _VerificationStep(
          email: _email,
          emailOtp: _emailOtp,
          accountPhone: _phone,
          countryIsoCode: _countryIsoCode,
          password: _password,
          confirm: _confirm,
          aadhaar: _aadhaar,
          pan: _pan,
          documentName: _verificationDocName,
          documentSource: _verificationDocSource,
          isEmailVerified: _isEmailVerified,
          isSendingOtp: _isSendingOtp,
          isVerifyingOtp: _isVerifyingOtp,
          agree: _agree,
          onSendOtp: _sendEmailOtp,
          onVerifyOtp: _verifyEmailOtp,
          onCountryChanged: _setCountryCode,
          onEmailChanged: (_) {
            if (_isEmailVerified) setState(() => _isEmailVerified = false);
          },
          onPickDocument: _pickVerificationDocument,
          onClearDocument: () =>
              _clearSignupDocument(_SignupDocumentType.verification),
          validatePhone: _validatePhone,
          onAgreeChanged: (value) => setState(() => _agree = value ?? false),
        );
    }
    return const SizedBox.shrink();
  }

  List<String> get _selectedSkills => _skills.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> get _projectSelectedSkills => _projectPreferredSkills.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> get _portfolioSelectedSkills => _portfolioTechStack.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<_PublicOption> get _effectiveIndustryOptions => _industryPublicOptions;

  List<String> get _effectiveSkillOptions => _skillPublicOptions.isNotEmpty
      ? _skillPublicOptions.map((item) => item.label).toList()
      : const [];

  void _addSkill(String skill) {
    final existing = _skills.text.trim();
    final parts = existing.isEmpty
        ? <String>[]
        : existing
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    if (parts.contains(skill)) return;
    setState(() => _skills.text = [...parts, skill].join(', '));
  }

  void _removeSkill(String skill) {
    final parts = _selectedSkills.where((item) => item != skill).toList();
    setState(() => _skills.text = parts.join(', '));
  }

  void _addProjectSkill(String skill) {
    final parts = _projectSelectedSkills;
    if (parts.contains(skill)) return;
    setState(() => _projectPreferredSkills.text = [...parts, skill].join(', '));
  }

  void _removeProjectSkill(String skill) {
    final parts = _projectSelectedSkills
        .where((item) => item != skill)
        .toList();
    setState(() => _projectPreferredSkills.text = parts.join(', '));
  }

  void _addPortfolioSkill(String skill) {
    final parts = _portfolioSelectedSkills;
    if (parts.contains(skill)) return;
    setState(() => _portfolioTechStack.text = [...parts, skill].join(', '));
  }

  void _removePortfolioSkill(String skill) {
    final parts = _portfolioSelectedSkills
        .where((item) => item != skill)
        .toList();
    setState(() => _portfolioTechStack.text = parts.join(', '));
  }

  void _toggleSelection(List<String> values, String value) {
    setState(() {
      if (values.contains(value)) {
        values.remove(value);
      } else {
        values.add(value);
      }
    });
  }

  void _keepPlaceNameOnly(
    TextEditingController controller,
    SelectedPlace place,
  ) {
    final name = place.formattedAddress
        .split(',')
        .map((part) => part.trim())
        .firstWhere(
          (part) => part.isNotEmpty,
          orElse: () => place.formattedAddress,
        );
    controller.text = name;
  }
}

class _SignupWizard extends StatelessWidget {
  const _SignupWizard({
    required this.step,
    required this.steps,
    required this.progressPercent,
    required this.label,
    required this.content,
    required this.onBack,
    required this.onContinue,
    required this.isSubmitting,
    required this.isLastStep,
  });

  final int step;
  final List<String> steps;
  final int progressPercent;
  final String label;
  final Widget content;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isSubmitting;
  final bool isLastStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text('Set up your account', style: context.text.displaySmall),
        AppSizes.vGapXl,
        Row(
          children: [
            Expanded(
              child: Text(
                'Step ${step + 1} of ${steps.length} - ${steps[step]}',
                style: context.text.titleMedium,
              ),
            ),
            Text('$progressPercent%', style: context.text.titleMedium),
          ],
        ),
        AppSizes.vGapMd,
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: (step + 1) / steps.length,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        AppSizes.vGapLg,
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (var i = 0; i < steps.length; i++)
              _StepPill(index: i, title: steps[i], currentStep: step),
          ],
        ),
        const SizedBox(height: 44),
        content,
        const SizedBox(height: 36),
        Row(
          children: [
            TextButton.icon(
              onPressed: isSubmitting ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlack,
                textStyle: context.text.titleSmall,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 190,
              child: AppPrimaryButton(
                label: isLastStep ? 'Create Account' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                isLoading: isSubmitting,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.title,
    required this.currentStep,
  });

  final int index;
  final String title;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final active = index == currentStep;
    final done = index < currentStep;
    final color = done ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withValues(alpha: 0.1)
            : active
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border.all(
          color: done || active
              ? color.withValues(alpha: 0.45)
              : context.theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.success)
          else
            Text(
              '${index + 1}',
              style: context.text.labelLarge?.copyWith(
                color: active ? AppColors.primary : AppColors.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(width: 7),
          Text(
            title,
            style: context.text.labelLarge?.copyWith(
              color: done
                  ? AppColors.success
                  : active
                  ? AppColors.primary
                  : AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border.all(color: context.theme.dividerColor),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({required this.selected, required this.onSelected});

  final UserRole? selected;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = AppSizes.lg;
          final twoColumns = constraints.maxWidth >= 620;
          final cardWidth = twoColumns
              ? (constraints.maxWidth - spacing) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: [
              for (final role in UserRole.values)
                SizedBox(
                  width: cardWidth,
                  child: _RoleCard(
                    role: role,
                    selected: selected == role,
                    onTap: () => onSelected(role),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.06)
                : context.theme.scaffoldBackgroundColor,
            border: Border.all(
              color: selected ? AppColors.primary : context.theme.dividerColor,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(role.icon, color: AppColors.primary),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                ],
              ),
              AppSizes.vGapMd,
              Text(role.label, style: context.text.titleMedium),
              AppSizes.vGapXs,
              Text(role.description, style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.formKey,
    required this.name,
    required this.email,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.stateOptions,
    required this.city,
    required this.onCountrySelected,
    required this.onStateSelected,
    required this.onCountryPlaceSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final List<_StateOption> stateOptions;
  final TextEditingController city;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<_StateOption> onStateSelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            AppTextField(
              controller: name,
              label: 'Full name',
              hint: 'Enter full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Email',
              hint: 'Enter email',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            _CountrySelectionField(
              controller: country,
              countries: countryOptions,
              label: 'Country',
              hint: 'Search and select country',
              validator: (v) => Validators.required(v, field: 'Country'),
              onCountrySelected: onCountrySelected,
              onPlaceSelected: onCountryPlaceSelected,
            ),
            AppSizes.vGapLg,
            _StateSelectionField(
              controller: stateLocation,
              states: stateOptions,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
              onStateSelected: onStateSelected,
              onPlaceSelected: onStatePlaceSelected,
            ),
            AppSizes.vGapLg,
            AppLocationField(
              controller: city,
              label: 'City',
              hint: 'Search and select city',
              validator: (v) => Validators.required(v, field: 'City'),
              onPlaceSelected: onCityPlaceSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicRoleAccountStep extends StatelessWidget {
  const _BasicRoleAccountStep({
    required this.formKey,
    required this.name,
    required this.email,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.stateOptions,
    required this.city,
    required this.onCountrySelected,
    required this.onStateSelected,
    required this.onCountryPlaceSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final List<_StateOption> stateOptions;
  final TextEditingController city;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<_StateOption> onStateSelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            AppTextField(
              controller: name,
              label: 'Full name',
              hint: 'Enter full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Email',
              hint: 'Enter email',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            _CountrySelectionField(
              controller: country,
              countries: countryOptions,
              label: 'Country',
              hint: 'Search and select country',
              validator: (v) => Validators.required(v, field: 'Country'),
              onCountrySelected: onCountrySelected,
              onPlaceSelected: onCountryPlaceSelected,
            ),
            AppSizes.vGapLg,
            _StateSelectionField(
              controller: stateLocation,
              states: stateOptions,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
              onStateSelected: onStateSelected,
              onPlaceSelected: onStatePlaceSelected,
            ),
            AppSizes.vGapLg,
            AppLocationField(
              controller: city,
              label: 'City',
              hint: 'Search and select city',
              validator: (v) => Validators.required(v, field: 'City'),
              onPlaceSelected: onCityPlaceSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _FounderAccountStep extends StatelessWidget {
  const _FounderAccountStep({
    required this.formKey,
    required this.name,
    required this.email,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.stateOptions,
    required this.city,
    required this.onCountrySelected,
    required this.onCountryPlaceSelected,
    required this.onStateSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final List<_StateOption> stateOptions;
  final TextEditingController city;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<_StateOption> onStateSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            AppTextField(
              controller: name,
              label: 'Full name',
              hint: 'Enter full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Email',
              hint: 'Enter email',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            _CountrySelectionField(
              controller: country,
              countries: countryOptions,
              label: 'Country',
              hint: 'Search and select country',
              validator: (v) => Validators.required(v, field: 'Country'),
              onCountrySelected: onCountrySelected,
              onPlaceSelected: onCountryPlaceSelected,
            ),
            AppSizes.vGapLg,
            _StateSelectionField(
              controller: stateLocation,
              states: stateOptions,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
              onStateSelected: onStateSelected,
              onPlaceSelected: onStatePlaceSelected,
            ),
            AppSizes.vGapLg,
            AppLocationField(
              controller: city,
              label: 'City',
              hint: 'Search and select city',
              validator: (v) => Validators.required(v, field: 'City'),
              onPlaceSelected: onCityPlaceSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneWithCountryCodeRow extends StatelessWidget {
  const _PhoneWithCountryCodeRow({
    required this.phone,
    required this.countryIsoCode,
    required this.onCountryChanged,
    required this.validatePhone,
  });

  final TextEditingController phone;
  final String countryIsoCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final String? Function(String?) validatePhone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Country', style: context.text.titleSmall),
              AppSizes.vGapSm,
              InputDecorator(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.sm,
                  ),
                ),
                child: CountryCodePicker(
                  initialSelection: countryIsoCode,
                  onChanged: onCountryChanged,
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: true,
                  alignLeft: true,
                  padding: EdgeInsets.zero,
                  flagWidth: 24,
                  builder: (countryCode) =>
                      _CountryCodeButton(countryCode: countryCode),
                ),
              ),
            ],
          ),
        ),
        AppSizes.hGapSm,
        Expanded(
          child: _PhoneFieldWithCounter(
            controller: phone,
            label: 'Mobile number *',
            countryIsoCode: countryIsoCode,
            validator: validatePhone,
          ),
        ),
      ],
    );
  }
}

class _PhoneFieldWithCounter extends StatelessWidget {
  const _PhoneFieldWithCounter({
    required this.controller,
    required this.countryIsoCode,
    required this.validator,
    this.label = 'Mobile number *',
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String countryIsoCode;
  final String? Function(String?) validator;
  final String label;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final maxLength = PhoneValidation.requiredLength(countryIsoCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: controller,
          label: label,
          hint: 'Enter mobile number',
          prefixIcon: prefixIcon,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxLength),
          ],
          validator: validator,
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return Text(
              '${value.text.length}/$maxLength',
              textAlign: TextAlign.right,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ClientAccountStep extends StatelessWidget {
  const _ClientAccountStep({
    required this.formKey,
    required this.name,
    required this.email,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.stateOptions,
    required this.city,
    required this.onCountrySelected,
    required this.onCountryPlaceSelected,
    required this.onStateSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final List<_StateOption> stateOptions;
  final TextEditingController city;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<_StateOption> onStateSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            AppTextField(
              controller: name,
              label: 'Full name',
              hint: 'Enter full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Work email',
              hint: 'Enter work email',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            _CountrySelectionField(
              controller: country,
              countries: countryOptions,
              label: 'Country',
              hint: 'Search and select country',
              validator: (v) => Validators.required(v, field: 'Country'),
              onCountrySelected: onCountrySelected,
              onPlaceSelected: onCountryPlaceSelected,
            ),
            AppSizes.vGapLg,
            _StateSelectionField(
              controller: stateLocation,
              states: stateOptions,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
              onStateSelected: onStateSelected,
              onPlaceSelected: onStatePlaceSelected,
            ),
            AppSizes.vGapLg,
            AppLocationField(
              controller: city,
              label: 'City',
              hint: 'Search and select city',
              validator: (v) => Validators.required(v, field: 'City'),
              onPlaceSelected: onCityPlaceSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientBusinessTypeStep extends StatelessWidget {
  const _ClientBusinessTypeStep({
    required this.value,
    required this.items,
    required this.onChanged,
    this.label = 'Business Type',
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: AppDropdown<String>(
        label: label,
        hint: 'Choose type',
        value: value,
        items: items,
        itemLabel: (item) => item,
        onChanged: onChanged,
      ),
    );
  }
}

class _ClientProfileStep extends StatelessWidget {
  const _ClientProfileStep({
    required this.logoName,
    required this.logoPreview,
    required this.businessName,
    required this.businessDescription,
    required this.website,
    required this.industry,
    required this.industryOptions,
    required this.gstNumber,
    required this.teamSize,
    required this.teamSizeOptions,
    required this.annualRequirement,
    required this.serviceLocation,
    required this.onPickLogo,
    required this.onIndustryChanged,
    required this.onTeamSizeChanged,
  });

  final String? logoName;
  final ImageProvider? logoPreview;
  final TextEditingController businessName;
  final TextEditingController businessDescription;
  final TextEditingController website;
  final _PublicOption? industry;
  final List<_PublicOption> industryOptions;
  final TextEditingController gstNumber;
  final String? teamSize;
  final List<String> teamSizeOptions;
  final TextEditingController annualRequirement;
  final TextEditingController serviceLocation;
  final VoidCallback onPickLogo;
  final ValueChanged<_PublicOption?> onIndustryChanged;
  final ValueChanged<String?> onTeamSizeChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        children: [
          _ProfilePhotoPicker(
            fileName: logoName,
            preview: logoPreview,
            onTap: onPickLogo,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: businessName,
            label: 'Company Name / Business Name *',
            hint: 'Enter company name',
            validator: (v) => Validators.required(v, field: 'Business name'),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: businessDescription,
            label: 'Business Description *',
            hint: 'Tell us about your business...',
            maxLines: 4,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: website,
            label: 'Website',
            hint: 'Enter website url',
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapLg,
          AppDropdown<_PublicOption>(
            label: 'Industry *',
            hint: 'Select industry',
            value: industryOptions.contains(industry) ? industry : null,
            items: industryOptions,
            itemLabel: (item) => item.label,
            onChanged: onIndustryChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: gstNumber,
            label: 'GST Number (Optional)',
            hint: 'Enter GST number',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Team Size *',
            hint: 'Select size',
            value: teamSizeOptions.contains(teamSize) ? teamSize : null,
            items: teamSizeOptions,
            itemLabel: (item) => item,
            onChanged: onTeamSizeChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: annualRequirement,
            label: 'Annual Requirement',
            hint: 'Enter annual requirement',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: serviceLocation,
            label: 'Service Location',
            hint: 'Enter service location (e.g. Global, India, Regional)',
          ),
        ],
      ),
    );
  }
}

class _ClientServiceStep extends StatelessWidget {
  const _ClientServiceStep({
    required this.industry,
    required this.category,
    required this.categories,
    required this.selectedSkills,
    required this.skillOptions,
    required this.isLoadingCategories,
    required this.isLoadingSkills,
    required this.onCategoryChanged,
    required this.onSkillSelected,
    required this.onSkillRemoved,
  });

  final _PublicOption? industry;
  final _PublicOption? category;
  final List<_PublicOption> categories;
  final List<String> selectedSkills;
  final List<String> skillOptions;
  final bool isLoadingCategories;
  final bool isLoadingSkills;
  final ValueChanged<_PublicOption?> onCategoryChanged;
  final ValueChanged<String> onSkillSelected;
  final ValueChanged<String> onSkillRemoved;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (industry == null)
            Text(
              'Select an industry in Profile to load categories and skills.',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
            )
          else if (isLoadingCategories)
            const LinearProgressIndicator(minHeight: 2)
          else
            AppDropdown<_PublicOption>(
              label: 'Category / Primary Service *',
              hint: 'Select category',
              value: categories.contains(category) ? category : null,
              items: categories,
              itemLabel: (item) => item.label,
              onChanged: categories.isEmpty ? null : onCategoryChanged,
            ),
          AppSizes.vGapLg,
          _SkillChoiceSection(
            label: 'Skills',
            selectedSkills: selectedSkills,
            skillOptions: skillOptions,
            isLoading: isLoadingSkills,
            onSkillSelected: onSkillSelected,
            onSkillRemoved: onSkillRemoved,
          ),
        ],
      ),
    );
  }
}

class _MultiChoiceListStep extends StatelessWidget {
  const _MultiChoiceListStep({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppSizes.vGapMd,
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                onTap: () => onChanged(option),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  // Stable local read keeps selection style consistent during
                  // rebuilds while parent state owns the actual selected list.
                  decoration: BoxDecoration(
                    color: values.contains(option)
                        ? AppColors.primary.withValues(alpha: 0.04)
                        : context.theme.cardColor,
                    border: Border.all(
                      color: values.contains(option)
                          ? AppColors.primary
                          : context.theme.dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        values.contains(option)
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: AppColors.primary,
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: Text(option, style: context.text.titleSmall),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientProjectsStep extends StatelessWidget {
  const _ClientProjectsStep({
    required this.title,
    required this.category,
    required this.budget,
    required this.timeline,
    required this.description,
    required this.preferredSkills,
    required this.locationPreference,
    required this.remoteType,
    required this.urgency,
    required this.referenceFileName,
    required this.referenceFileSource,
    required this.industry,
    required this.categories,
    required this.skillOptions,
    required this.selectedSkills,
    required this.isLoadingCategories,
    required this.isLoadingSkills,
    required this.onCategoryChanged,
    required this.onSkillSelected,
    required this.onSkillRemoved,
    required this.onManualSkillsChanged,
    required this.onPickReferenceFile,
    required this.onClearReferenceFile,
    required this.onRemoteTypeChanged,
    required this.onUrgencyChanged,
  });

  final TextEditingController title;
  final _PublicOption? category;
  final TextEditingController budget;
  final TextEditingController timeline;
  final TextEditingController description;
  final TextEditingController preferredSkills;
  final TextEditingController locationPreference;
  final String? remoteType;
  final String? urgency;
  final String? referenceFileName;
  final String? referenceFileSource;
  final _PublicOption? industry;
  final List<_PublicOption> categories;
  final List<String> skillOptions;
  final List<String> selectedSkills;
  final bool isLoadingCategories;
  final bool isLoadingSkills;
  final ValueChanged<_PublicOption?> onCategoryChanged;
  final ValueChanged<String> onSkillSelected;
  final ValueChanged<String> onSkillRemoved;
  final ValueChanged<String> onManualSkillsChanged;
  final VoidCallback onPickReferenceFile;
  final VoidCallback onClearReferenceFile;
  final ValueChanged<String?> onRemoteTypeChanged;
  final ValueChanged<String?> onUrgencyChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: title,
            label: 'Project Title',
            hint: 'Enter project title',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: description,
            label: 'Description',
            hint: 'Enter project description',
            maxLines: 4,
          ),
          AppSizes.vGapLg,
          if (industry == null)
            Text(
              'Select an industry in Profile to load project categories.',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
            )
          else if (isLoadingCategories)
            const LinearProgressIndicator(minHeight: 2)
          else
            AppDropdown<_PublicOption>(
              label: 'Project Category',
              hint: 'Select category',
              value: categories.contains(category) ? category : null,
              items: categories,
              itemLabel: (item) => item.label,
              onChanged: categories.isEmpty ? null : onCategoryChanged,
            ),
          AppSizes.vGapLg,
          AppTextField(
            controller: preferredSkills,
            label: 'Project Skills',
            hint: 'Select skills',
            onChanged: onManualSkillsChanged,
          ),
          AppSizes.vGapSm,
          _SkillChoiceSection(
            label: 'Select from category skills',
            selectedSkills: selectedSkills,
            skillOptions: skillOptions,
            isLoading: isLoadingSkills,
            onSkillSelected: onSkillSelected,
            onSkillRemoved: onSkillRemoved,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: budget,
            label: 'Budget',
            hint: 'Enter budget',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: timeline,
            label: 'Timeline',
            hint: 'Enter timeline',
          ),
          AppSizes.vGapLg,
          _TitledFileUpload(
            label: 'Project reference files',
            hint: 'Upload project reference files.',
            fileName: referenceFileName,
            source: referenceFileSource,
            icon: Icons.attach_file_rounded,
            onTap: onPickReferenceFile,
            onClear: onClearReferenceFile,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: locationPreference,
            label: 'Location Preference',
            hint: 'Enter location preference',
          ),
          AppSizes.vGapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'Remote / On-site',
                  hint: 'Select type',
                  value: remoteType,
                  items: _SignupPageState._remoteTypes,
                  itemLabel: (item) => item,
                  onChanged: onRemoteTypeChanged,
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: AppDropdown<String>(
                  label: 'Urgency',
                  hint: 'Select urgency',
                  value: urgency,
                  items: _SignupPageState._urgencies,
                  itemLabel: (item) => item,
                  onChanged: onUrgencyChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.industry,
    required this.category,
    required this.industries,
    required this.categories,
    required this.isLoadingCategories,
    required this.onIndustryChanged,
    required this.onCategoryChanged,
  });

  final _PublicOption? industry;
  final _PublicOption? category;
  final List<_PublicOption> industries;
  final List<_PublicOption> categories;
  final bool isLoadingCategories;
  final ValueChanged<_PublicOption?> onIndustryChanged;
  final ValueChanged<_PublicOption?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<_PublicOption>(
            label: 'Industry *',
            hint: 'Select industry',
            value: industries.contains(industry) ? industry : null,
            items: industries,
            itemLabel: (item) => item.label,
            onChanged: onIndustryChanged,
            validator: (value) => value == null ? 'Select industry' : null,
          ),
          AppSizes.vGapLg,
          if (isLoadingCategories)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                AppSizes.hGapSm,
                Text('Loading categories...', style: context.text.bodyMedium),
              ],
            )
          else if (categories.isNotEmpty)
            AppDropdown<_PublicOption>(
              label: 'Category *',
              hint: 'Select category',
              value: categories.contains(category) ? category : null,
              items: categories,
              itemLabel: (item) => item.label,
              onChanged: onCategoryChanged,
              validator: (value) => value == null ? 'Select category' : null,
            )
          else
            Text(
              'No categories available for the selected industry.',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillsStep extends StatelessWidget {
  const _SkillsStep({
    required this.skills,
    required this.experience,
    required this.bio,
    required this.selectedSkills,
    required this.skillOptions,
    required this.isLoadingSkills,
    required this.onSkillSelected,
    required this.onSkillRemoved,
    required this.onManualSkillsChanged,
  });

  final TextEditingController skills;
  final TextEditingController experience;
  final TextEditingController bio;
  final List<String> selectedSkills;
  final List<String> skillOptions;
  final bool isLoadingSkills;
  final ValueChanged<String> onSkillSelected;
  final ValueChanged<String> onSkillRemoved;
  final ValueChanged<String> onManualSkillsChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: skills,
            label: 'Top skills',
            hint: 'Enter skills',
            prefixIcon: Icons.auto_awesome_rounded,
            onChanged: onManualSkillsChanged,
          ),
          AppSizes.vGapMd,
          Text(
            'Select from admin-curated skills:',
            style: context.text.titleSmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          AppSizes.vGapSm,
          _SkillChoiceSection(
            label: '',
            selectedSkills: selectedSkills,
            skillOptions: skillOptions,
            isLoading: isLoadingSkills,
            onSkillSelected: onSkillSelected,
            onSkillRemoved: onSkillRemoved,
          ),
          AppSizes.vGapXl,
          AppTextField(
            controller: experience,
            label: 'Years of experience *',
            hint: 'Enter years of experience',
            prefixIcon: Icons.timeline_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: bio,
            label: 'Short bio',
            hint: 'Enter short bio',
            prefixIcon: Icons.notes_rounded,
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

class _SkillChoiceSection extends StatelessWidget {
  const _SkillChoiceSection({
    required this.label,
    required this.selectedSkills,
    required this.skillOptions,
    required this.isLoading,
    required this.onSkillSelected,
    required this.onSkillRemoved,
  });

  final String label;
  final List<String> selectedSkills;
  final List<String> skillOptions;
  final bool isLoading;
  final ValueChanged<String> onSkillSelected;
  final ValueChanged<String> onSkillRemoved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: context.text.titleSmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          AppSizes.vGapSm,
        ],
        if (isLoading)
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              AppSizes.hGapSm,
              Text('Loading skills...', style: context.text.bodyMedium),
            ],
          )
        else if (skillOptions.isEmpty)
          Text(
            'No skills available for the selected category.',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          )
        else
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              for (final skill in skillOptions)
                _SkillChoiceChip(
                  skill: skill,
                  selected: selectedSkills.contains(skill),
                  onTap: () => selectedSkills.contains(skill)
                      ? onSkillRemoved(skill)
                      : onSkillSelected(skill),
                ),
            ],
          ),
      ],
    );
  }
}

class _SkillChoiceChip extends StatelessWidget {
  const _SkillChoiceChip({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  final String skill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        selected ? Icons.check_rounded : Icons.add_rounded,
        size: 18,
        color: selected ? AppColors.white : AppColors.mutedText,
      ),
      label: Text(skill),
      labelStyle: context.text.titleSmall?.copyWith(
        color: selected ? AppColors.white : AppColors.primaryBlack,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: selected ? AppColors.primary : context.theme.cardColor,
      side: BorderSide(
        color: selected ? AppColors.primary : context.theme.dividerColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onPressed: onTap,
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.linkedin,
    required this.github,
    required this.portfolioUrl,
    required this.profilePhotoName,
    required this.profilePhotoPreview,
    required this.onPickProfilePhoto,
  });

  final TextEditingController linkedin;
  final TextEditingController github;
  final TextEditingController portfolioUrl;
  final String? profilePhotoName;
  final ImageProvider? profilePhotoPreview;
  final VoidCallback onPickProfilePhoto;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        children: [
          _ProfilePhotoPicker(
            fileName: profilePhotoName,
            preview: profilePhotoPreview,
            onTap: onPickProfilePhoto,
          ),
          AppSizes.vGapXl,
          AppTextField(
            controller: linkedin,
            label: 'LinkedIn URL',
            hint: 'Enter linkedIn url',
            prefixIcon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: github,
            label: 'GitHub URL',
            hint: 'Enter gitHub url',
            prefixIcon: Icons.code_rounded,
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: portfolioUrl,
            label: 'Portfolio URL',
            hint: 'Enter portfolio url',
            prefixIcon: Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.fileName,
    required this.preview,
    required this.onTap,
  });

  final String? fileName;
  final ImageProvider? preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: preview,
                    child: preview == null
                        ? const Icon(
                            Icons.person_outline_rounded,
                            size: 64,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 10,
                  child: Material(
                    color: context.theme.cardColor,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      tooltip: 'Edit profile photo',
                      onPressed: onTap,
                      icon: const Icon(Icons.edit_rounded),
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // AppSizes.vGapSm,
          // TextButton.icon(
          //   onPressed: onTap,
          //   icon: const Icon(Icons.add_a_photo_outlined),
          //   label: Text(fileName == null ? 'Select profile photo' : fileName!),
          // ),
        ],
      ),
    );
  }
}

class _BudgetStep extends StatelessWidget {
  const _BudgetStep({required this.hourlyRate});

  final TextEditingController hourlyRate;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: AppTextField(
        controller: hourlyRate,
        label: 'Hourly rate (USD) *',
        hint: 'Enter amount',
        prefixIcon: Icons.attach_money_rounded,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
    );
  }
}

class _TitledFileUpload extends StatelessWidget {
  const _TitledFileUpload({
    required this.label,
    required this.hint,
    required this.fileName,
    this.source,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String hint;
  final String? fileName;
  final String? source;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final previewSource = source?.trim().isNotEmpty == true
        ? source!.trim()
        : fileName?.trim() ?? '';
    final selected = fileName?.trim().isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (selected && onClear != null)
              IconButton(
                tooltip: 'Clear file',
                onPressed: onClear,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
          ],
        ),
        AppSizes.vGapSm,
        if (_signupIsImageSource(previewSource))
          _SignupImageUploadPreview(
            title: label,
            source: previewSource,
            fileName: fileName,
            onTap: onTap,
            onClear: onClear,
            showTitle: false,
          )
        else if (_signupIsVideoSource(previewSource))
          _SignupVideoUploadPreview(
            title: label,
            source: previewSource,
            fileName: fileName,
            onTap: onTap,
            onClear: onClear,
            showTitle: false,
          )
        else
          Center(
            child: AppFileUpload(
              label: 'Choose file',
              hint: hint,
              fileName: fileName,
              icon: icon,
              onTap: onTap,
            ),
          ),
      ],
    );
  }
}

class _ResponsiveFieldGrid extends StatelessWidget {
  const _ResponsiveFieldGrid({required this.children, this.minItemWidth = 320});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSizes.lg;
        final width = constraints.maxWidth;
        final columns = width >= (minItemWidth * 2 + spacing) ? 2 : 1;
        final itemWidth = columns == 1 ? width : (width - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _CompactUploadTile extends StatelessWidget {
  const _CompactUploadTile({
    required this.title,
    required this.hint,
    required this.fileName,
    this.source,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final String hint;
  final String? fileName;
  final String? source;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final selected = fileName != null && fileName!.isNotEmpty;
    final previewSource = source?.trim().isNotEmpty == true
        ? source!.trim()
        : fileName?.trim() ?? '';
    if (_signupIsImageSource(previewSource)) {
      return _SignupImageUploadPreview(
        title: title,
        source: previewSource,
        fileName: fileName,
        onTap: onTap,
        onClear: onClear,
      );
    }
    if (_signupIsVideoSource(previewSource)) {
      return _SignupVideoUploadPreview(
        title: title,
        source: previewSource,
        fileName: fileName,
        onTap: onTap,
        onClear: onClear,
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      onTap: onTap,
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.description_outlined
                    : Icons.file_upload_outlined,
                color: AppColors.primary,
              ),
              AppSizes.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected ? fileName! : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected ? 'Tap to replace' : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected && onClear != null)
                IconButton(
                  tooltip: 'Clear file',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupImageUploadPreview extends StatelessWidget {
  const _SignupImageUploadPreview({
    required this.title,
    required this.source,
    required this.fileName,
    required this.onTap,
    this.onClear,
    this.showTitle = true,
  });

  final String title;
  final String source;
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final image = _signupIsNetworkSource(source)
        ? CustomCachedImage(
            imageUrl: source,
            fit: BoxFit.cover,
            errorWidget: _fallback(context),
          )
        : Image.file(
            File(source),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(context),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.titleSmall)),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear file',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
          AppSizes.vGapSm,
        ],
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          onTap: onTap,
          child: DottedBorderBox(
            child: SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    Positioned(
                      left: AppSizes.sm,
                      right: AppSizes.sm,
                      bottom: AppSizes.sm,
                      child: _SignupPreviewCaption(
                        icon: Icons.image_outlined,
                        title: fileName ?? title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(BuildContext context) {
    return Center(
      child: Text(
        'Unable to preview image',
        style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
      ),
    );
  }
}

class _SignupVideoUploadPreview extends StatelessWidget {
  const _SignupVideoUploadPreview({
    required this.title,
    required this.source,
    required this.fileName,
    required this.onTap,
    this.onClear,
    this.showTitle = true,
  });

  final String title;
  final String source;
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.titleSmall)),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear file',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
          AppSizes.vGapSm,
        ],
        DottedBorderBox(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: _SignupVideoPlayer(source: source),
              ),
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: _SignupPreviewCaption(
                    icon: Icons.video_library_outlined,
                    title: fileName ?? title,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignupPreviewCaption extends StatelessWidget {
  const _SignupPreviewCaption({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EducationSignupRow extends StatelessWidget {
  const _EducationSignupRow({
    required this.institution,
    required this.qualification,
    required this.specialization,
    required this.year,
    required this.documentName,
    required this.documentSource,
    required this.onPickDocument,
    required this.onClearDocument,
  });

  final TextEditingController institution;
  final TextEditingController qualification;
  final TextEditingController specialization;
  final TextEditingController year;
  final String? documentName;
  final String? documentSource;
  final VoidCallback onPickDocument;
  final VoidCallback onClearDocument;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        if (compact) {
          return Column(
            children: [
              AppTextField(
                controller: institution,
                label: 'Institution *',
                hint: 'Enter institution',
                prefixIcon: Icons.school_outlined,
              ),
              AppSizes.vGapLg,
              AppTextField(
                controller: qualification,
                label: 'Qualification *',
                hint: 'Enter qualification',
              ),
              AppSizes.vGapLg,
              AppTextField(
                controller: specialization,
                label: 'Specialization *',
                hint: 'Enter specialization',
              ),
              AppSizes.vGapLg,
              AppTextField(
                controller: year,
                label: 'Year *',
                hint: 'Enter passing year',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
              AppSizes.vGapLg,
              Align(
                alignment: Alignment.centerLeft,
                child: _TitledFileUpload(
                  label: 'Upload Education Document *',
                  hint: 'Upload JPG, PNG, or PDF education file.',
                  fileName: documentName,
                  source: documentSource,
                  icon: Icons.upload_file_rounded,
                  onTap: onPickDocument,
                  onClear: onClearDocument,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: _EducationColumnHeader('Institution *'),
                ),
                SizedBox(width: AppSizes.md),
                Expanded(
                  flex: 2,
                  child: _EducationColumnHeader('Qualification *'),
                ),
                SizedBox(width: AppSizes.md),
                Expanded(
                  flex: 2,
                  child: _EducationColumnHeader('Specialization *'),
                ),
                SizedBox(width: AppSizes.md),
                Expanded(child: _EducationColumnHeader('Year *')),
                SizedBox(width: AppSizes.md),
                Expanded(flex: 2, child: _EducationColumnHeader('Document *')),
              ],
            ),
            AppSizes.vGapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: institution,
                    hint: 'Enter institution',
                    prefixIcon: Icons.school_outlined,
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: qualification,
                    hint: 'Enter qualification',
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: specialization,
                    hint: 'Enter specialization',
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: AppTextField(
                    controller: year,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _TitledFileUpload(
                      label: 'Upload',
                      hint: 'Choose file',
                      fileName: documentName,
                      source: documentSource,
                      icon: Icons.upload_file_rounded,
                      onTap: onPickDocument,
                      onClear: onClearDocument,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _EducationColumnHeader extends StatelessWidget {
  const _EducationColumnHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.labelLarge?.copyWith(
        color: AppColors.mutedText,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _SignupVideoPlayer extends StatefulWidget {
  const _SignupVideoPlayer({required this.source, this.fullscreen = false});

  final String source;
  final bool fullscreen;

  @override
  State<_SignupVideoPlayer> createState() => _SignupVideoPlayerState();
}

class _SignupVideoPlayerState extends State<_SignupVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _SignupVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _controller?.dispose();
      _controller = null;
      _ready = false;
      _error = null;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final controller = _signupIsNetworkSource(widget.source)
          ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
          : VideoPlayerController.file(File(widget.source));
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to preview this video.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return SizedBox(
        height: 150,
        child: Center(child: Text(_error!, style: context.text.bodySmall)),
      );
    }
    if (!_ready || controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final videoSize = controller.value.size;
    final aspectRatio = widget.fullscreen
        ? (controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio)
        : 16 / 9;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: videoSize.width == 0 ? 16 : videoSize.width,
                  height: videoSize.height == 0 ? 9 : videoSize.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePlay,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: controller.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSizes.sm,
            right: AppSizes.sm,
            bottom: AppSizes.sm,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _togglePlay,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                  ),
                ),
                if (!widget.fullscreen)
                  IconButton.filledTonal(
                    onPressed: _openFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  Future<void> _openFullscreen() async {
    await _controller?.pause();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Video Demo'),
          ),
          body: Center(
            child: _SignupVideoPlayer(source: widget.source, fullscreen: true),
          ),
        ),
      ),
    );
  }
}

bool _signupIsNetworkSource(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.hasScheme;
}

String _signupFileLabel(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
  return trimmed.split(Platform.pathSeparator).last;
}

bool _signupIsImageSource(String value) {
  final label = _signupFileLabel(value).toLowerCase();
  return label.endsWith('.jpg') ||
      label.endsWith('.jpeg') ||
      label.endsWith('.png') ||
      label.endsWith('.webp') ||
      label.endsWith('.gif') ||
      label.endsWith('.bmp') ||
      label.endsWith('.heic') ||
      label.endsWith('.heif');
}

bool _signupIsVideoSource(String value) {
  final label = _signupFileLabel(value).toLowerCase();
  return label.endsWith('.mp4') ||
      label.endsWith('.mov') ||
      label.endsWith('.m4v') ||
      label.endsWith('.webm') ||
      label.endsWith('.avi') ||
      label.endsWith('.mkv');
}

class _PortfolioUploadsStep extends StatelessWidget {
  const _PortfolioUploadsStep({
    required this.title,
    required this.selectedIndustry,
    required this.industryOptions,
    required this.category,
    required this.categoryOptions,
    required this.selectedSkills,
    required this.skillOptions,
    required this.isLoadingCategories,
    required this.isLoadingSkills,
    required this.status,
    required this.client,
    required this.techStack,
    required this.duration,
    required this.teamSize,
    required this.teamSizeOptions,
    required this.role,
    required this.githubUrl,
    required this.liveUrl,
    required this.overview,
    required this.coverName,
    required this.videoName,
    required this.caseStudyName,
    required this.screenshotName,
    required this.coverSource,
    required this.videoSource,
    required this.caseStudySource,
    required this.screenshotSource,
    required this.onIndustryChanged,
    required this.onCategoryChanged,
    required this.onSkillSelected,
    required this.onSkillRemoved,
    required this.onManualSkillsChanged,
    required this.onStatusChanged,
    required this.onTeamSizeChanged,
    required this.onPickCover,
    required this.onPickVideo,
    required this.onPickCaseStudy,
    required this.onPickScreenshot,
    required this.onClearCover,
    required this.onClearVideo,
    required this.onClearCaseStudy,
    required this.onClearScreenshot,
  });

  final TextEditingController title;
  final _PublicOption? selectedIndustry;
  final List<_PublicOption> industryOptions;
  final _PublicOption? category;
  final List<_PublicOption> categoryOptions;
  final List<String> selectedSkills;
  final List<String> skillOptions;
  final bool isLoadingCategories;
  final bool isLoadingSkills;
  final String? status;
  final TextEditingController client;
  final TextEditingController techStack;
  final TextEditingController duration;
  final String? teamSize;
  final List<String> teamSizeOptions;
  final TextEditingController role;
  final TextEditingController githubUrl;
  final TextEditingController liveUrl;
  final TextEditingController overview;
  final String? coverName;
  final String? videoName;
  final String? caseStudyName;
  final String? screenshotName;
  final String? coverSource;
  final String? videoSource;
  final String? caseStudySource;
  final String? screenshotSource;
  final ValueChanged<_PublicOption?> onIndustryChanged;
  final ValueChanged<_PublicOption?> onCategoryChanged;
  final ValueChanged<String> onSkillSelected;
  final ValueChanged<String> onSkillRemoved;
  final ValueChanged<String> onManualSkillsChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTeamSizeChanged;
  final VoidCallback onPickCover;
  final VoidCallback onPickVideo;
  final VoidCallback onPickCaseStudy;
  final VoidCallback onPickScreenshot;
  final VoidCallback onClearCover;
  final VoidCallback onClearVideo;
  final VoidCallback onClearCaseStudy;
  final VoidCallback onClearScreenshot;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add portfolio item', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Upload cover media and publish when ready',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          AppSizes.vGapLg,
          AppTextField(controller: title, label: 'Title', hint: 'Enter title'),
          AppSizes.vGapLg,
          AppDropdown<_PublicOption>(
            label: 'Industry',
            hint: 'Select industry',
            value: industryOptions.contains(selectedIndustry)
                ? selectedIndustry
                : null,
            items: industryOptions,
            itemLabel: (item) => item.label,
            onChanged: onIndustryChanged,
          ),
          AppSizes.vGapLg,
          if (isLoadingCategories)
            const LinearProgressIndicator(minHeight: 2)
          else
            AppDropdown<_PublicOption>(
              label: 'Category',
              hint: 'Select category',
              value: categoryOptions.contains(category) ? category : null,
              items: categoryOptions,
              itemLabel: (item) => item.label,
              onChanged: categoryOptions.isEmpty ? null : onCategoryChanged,
            ),
          AppSizes.vGapLg,
          AppTextField(
            controller: techStack,
            label: 'Skills',
            hint: 'Select skills',
            onChanged: onManualSkillsChanged,
          ),
          AppSizes.vGapSm,
          _SkillChoiceSection(
            label: 'Select from category skills',
            selectedSkills: selectedSkills,
            skillOptions: skillOptions,
            isLoading: isLoadingSkills,
            onSkillSelected: onSkillSelected,
            onSkillRemoved: onSkillRemoved,
          ),
          AppSizes.vGapLg,
          _ResponsiveFieldGrid(
            children: [
              AppDropdown<String>(
                label: 'Status',
                hint: 'Select status',
                value: status,
                items: const [
                  'Published',
                  'Featured',
                  'Case Study',
                  'Draft',
                  'Archived',
                ],
                itemLabel: (item) => item,
                onChanged: onStatusChanged,
              ),
              AppTextField(
                controller: client,
                label: 'Client',
                hint: 'Enter client',
              ),
            ],
          ),
          AppSizes.vGapLg,
          _ResponsiveFieldGrid(
            children: [
              AppTextField(
                controller: duration,
                label: 'Duration',
                hint: 'Enter duration',
              ),
              AppDropdown<String>(
                label: 'Team size',
                hint: 'Select team size',
                value: teamSizeOptions.contains(teamSize) ? teamSize : null,
                items: teamSizeOptions,
                itemLabel: (item) => item,
                onChanged: onTeamSizeChanged,
              ),
              AppTextField(
                controller: role,
                label: 'Your role',
                hint: 'Enter role/desgination',
              ),
              AppTextField(
                controller: githubUrl,
                label: 'Github URL',
                hint: 'Enter github url',
                keyboardType: TextInputType.url,
              ),
              AppTextField(
                controller: liveUrl,
                label: 'Live URL',
                hint: 'Enter live url',
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: overview,
            label: 'Overview',
            maxLines: 4,
            hint: 'Enter overview',
          ),
          AppSizes.vGapLg,
          _ResponsiveFieldGrid(
            minItemWidth: 210,
            children: [
              _CompactUploadTile(
                title: 'Cover image',
                hint: 'Select JPG · PNG · WebP',
                fileName: coverName,
                source: coverSource,
                onTap: onPickCover,
                onClear: onClearCover,
              ),
              _CompactUploadTile(
                title: 'Video demo',
                hint: 'Select MP4 · MOV',
                fileName: videoName,
                source: videoSource,
                onTap: onPickVideo,
                onClear: onClearVideo,
              ),
              _CompactUploadTile(
                title: 'PDF case study',
                hint: 'Select PDF',
                fileName: caseStudyName,
                source: caseStudySource,
                onTap: onPickCaseStudy,
                onClear: onClearCaseStudy,
              ),
              _CompactUploadTile(
                title: 'Extra screenshot',
                hint: 'Adds as cover if empty',
                fileName: screenshotName,
                source: screenshotSource,
                onTap: onPickScreenshot,
                onClear: onClearScreenshot,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgesStep extends StatelessWidget {
  const _BadgesStep({
    required this.institution,
    required this.qualification,
    required this.specialization,
    required this.year,
    required this.educationDocumentName,
    required this.educationDocumentSource,
    required this.certificateName,
    required this.certificateIssuer,
    required this.certificateIssueDate,
    required this.certificateDocumentName,
    required this.certificateDocumentSource,
    required this.certificateUrl,
    required this.onPickEducationDocument,
    required this.onPickCertificateDocument,
    required this.onClearEducationDocument,
    required this.onClearCertificateDocument,
    required this.onPickCertificateIssueDate,
  });

  final TextEditingController institution;
  final TextEditingController qualification;
  final TextEditingController specialization;
  final TextEditingController year;
  final String? educationDocumentName;
  final String? educationDocumentSource;
  final TextEditingController certificateName;
  final TextEditingController certificateIssuer;
  final TextEditingController certificateIssueDate;
  final String? certificateDocumentName;
  final String? certificateDocumentSource;
  final TextEditingController certificateUrl;
  final VoidCallback onPickEducationDocument;
  final VoidCallback onPickCertificateDocument;
  final VoidCallback onClearEducationDocument;
  final VoidCallback onClearCertificateDocument;
  final VoidCallback onPickCertificateIssueDate;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Education records', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Synced to your freelancer profile',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          AppSizes.vGapLg,
          _EducationSignupRow(
            institution: institution,
            qualification: qualification,
            specialization: specialization,
            year: year,
            documentName: educationDocumentName,
            documentSource: educationDocumentSource,
            onPickDocument: onPickEducationDocument,
            onClearDocument: onClearEducationDocument,
          ),
          AppSizes.vGapXl,
          Text('Certificate', style: context.text.titleLarge),
          AppSizes.vGapLg,
          _ResponsiveFieldGrid(
            children: [
              AppTextField(
                controller: certificateName,
                label: 'Name',
                hint: 'Enter certificate name',
              ),
              AppTextField(
                controller: certificateIssuer,
                label: 'Issuer',
                hint: 'Enter issuer name',
              ),
              AppTextField(
                controller: certificateIssueDate,
                label: 'Issue date',
                hint: 'Select date',
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                onTap: onPickCertificateIssueDate,
              ),
              AppTextField(
                controller: certificateUrl,
                label: 'Certificate Url',
                hint: 'Enter certificate url',
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          AppSizes.vGapLg,
          _TitledFileUpload(
            label: 'Upload Certificate Document (Image / PDF)',
            hint: 'Upload JPG, PNG, or PDF certificate file.',
            fileName: certificateDocumentName,
            source: certificateDocumentSource,
            icon: Icons.upload_file_rounded,
            onTap: onPickCertificateDocument,
            onClear: onClearCertificateDocument,
          ),
        ],
      ),
    );
  }
}

class _BillingStep extends StatelessWidget {
  const _BillingStep({
    required this.plans,
    required this.selectedPlan,
    required this.onSelected,
  });

  final List<_PlanOption> plans;
  final String selectedPlan;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a plan that fits your needs. You can upgrade later.',
            style: context.text.titleSmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          AppSizes.vGapXl,
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth >= 620;
              return Wrap(
                spacing: AppSizes.lg,
                runSpacing: AppSizes.lg,
                children: [
                  for (final plan in plans)
                    SizedBox(
                      width: twoCols
                          ? (constraints.maxWidth - AppSizes.lg) / 2
                          : constraints.maxWidth,
                      child: _PlanCard(
                        plan: plan,
                        selected: selectedPlan == plan.id,
                        onTap: () => onSelected(plan.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _PlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.04)
              : context.theme.cardColor,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : context.theme.dividerColor.withValues(alpha: 0.8),
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(plan.name, style: context.text.titleMedium),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
            AppSizes.vGapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (plan.originalPrice != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      right: AppSizes.sm,
                      bottom: 3,
                    ),
                    child: Text(
                      plan.originalPrice!,
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: Text(plan.price, style: context.text.headlineSmall),
                ),
              ],
            ),
            AppSizes.vGapMd,
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                _PlanBadge(
                  label: plan.popular ? 'Popular' : 'Not popular',
                  color: plan.popular ? AppColors.success : AppColors.mutedText,
                  filled: plan.popular,
                ),
                _PlanBadge(
                  label: plan.recommended ? 'Recommended' : 'Standard',
                  color: plan.recommended
                      ? AppColors.primary
                      : AppColors.mutedText,
                  filled: plan.recommended,
                ),
                if (plan.savedBadge != null && plan.savedBadge!.isNotEmpty)
                  _PlanBadge(
                    label: plan.savedBadge!,
                    color: AppColors.warning,
                    filled: true,
                  ),
              ],
            ),
            if (plan.features.isNotEmpty) ...[
              AppSizes.vGapLg,
              _PlanSectionTitle(icon: Icons.auto_awesome, label: 'Features'),
              AppSizes.vGapSm,
              for (final feature in plan.features)
                _PlanDetailRow(icon: Icons.check, label: feature),
            ],
            if (plan.limits.isNotEmpty) ...[
              AppSizes.vGapLg,
              _PlanSectionTitle(icon: Icons.speed_rounded, label: 'Limits'),
              AppSizes.vGapSm,
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  for (final entry in plan.limits.entries)
                    _PlanLimitChip(
                      label:
                          '${_formatPlanLimitKey(entry.key)}: ${_formatPlanLimitValue(entry.value)}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPlanLimitKey(String key) {
    final spaced = key
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatPlanLimitValue(Object? value) {
    if (value is bool) return value ? 'Yes' : 'No';
    return value?.toString() ?? '';
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    required this.color,
    this.filled = true,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.12 : 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: filled ? 0.32 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  const _PlanSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlack),
        const SizedBox(width: AppSizes.sm),
        Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PlanDetailRow extends StatelessWidget {
  const _PlanDetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              label,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLimitChip extends StatelessWidget {
  const _PlanLimitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primaryBlack,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.email,
    required this.emailOtp,
    required this.accountPhone,
    required this.countryIsoCode,
    required this.password,
    required this.confirm,
    required this.aadhaar,
    required this.pan,
    required this.documentName,
    required this.documentSource,
    required this.isEmailVerified,
    required this.isSendingOtp,
    required this.isVerifyingOtp,
    required this.agree,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onCountryChanged,
    required this.onEmailChanged,
    required this.onPickDocument,
    required this.onClearDocument,
    required this.validatePhone,
    required this.onAgreeChanged,
  });

  final TextEditingController email;
  final TextEditingController emailOtp;
  final TextEditingController accountPhone;
  final String countryIsoCode;
  final TextEditingController password;
  final TextEditingController confirm;
  final TextEditingController aadhaar;
  final TextEditingController pan;
  final String? documentName;
  final String? documentSource;
  final bool isEmailVerified;
  final bool isSendingOtp;
  final bool isVerifyingOtp;
  final bool agree;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onPickDocument;
  final VoidCallback onClearDocument;
  final String? Function(String?) validatePhone;
  final ValueChanged<bool?> onAgreeChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Verification (OTP sent to Mail) *',
            style: context.text.titleMedium,
          ),
          AppSizes.vGapSm,
          AppTextField(
            controller: email,
            hint: 'Enter email address',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            onChanged: onEmailChanged,
            suffixIcon: isEmailVerified
                ? const Icon(Icons.verified_rounded, color: AppColors.success)
                : null,
          ),
          AppSizes.vGapMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final otpField = AppTextField(
                controller: emailOtp,
                hint: 'Enter email OTP',
                prefixIcon: Icons.password_rounded,
                keyboardType: TextInputType.number,
                enabled: !isEmailVerified,
              );
              final verifyButton = AppPrimaryButton(
                label: isEmailVerified ? 'Verified' : 'Verify OTP',
                isLoading: isVerifyingOtp,
                onPressed: isEmailVerified ? null : onVerifyOtp,
                gradient: false,
                backgroundColor: isEmailVerified
                    ? AppColors.success
                    : AppColors.primary,
              );
              final otpButton = AppPrimaryButton(
                label: 'Get Email OTP',
                isLoading: isSendingOtp,
                onPressed: isEmailVerified ? null : onSendOtp,
                gradient: false,
                backgroundColor: AppColors.primaryBlack,
              );

              if (stacked) {
                return Column(
                  children: [
                    otpField,
                    AppSizes.vGapMd,
                    Row(
                      children: [
                        Expanded(child: verifyButton),
                        AppSizes.hGapSm,
                        Expanded(child: otpButton),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: otpField),
                  AppSizes.hGapMd,
                  SizedBox(width: 150, child: verifyButton),
                  AppSizes.hGapSm,
                  SizedBox(width: 170, child: otpButton),
                ],
              );
            },
          ),
          AppSizes.vGapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Country', style: context.text.titleSmall),
                    AppSizes.vGapSm,
                    InputDecorator(
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.sm,
                        ),
                      ),
                      child: CountryCodePicker(
                        initialSelection: countryIsoCode,
                        onChanged: onCountryChanged,
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: true,
                        alignLeft: true,
                        padding: EdgeInsets.zero,
                        flagWidth: 24,
                        builder: (countryCode) =>
                            _CountryCodeButton(countryCode: countryCode),
                      ),
                    ),
                  ],
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: _PhoneFieldWithCounter(
                  controller: accountPhone,
                  label: 'Mobile Number *',
                  prefixIcon: Icons.phone_outlined,
                  countryIsoCode: countryIsoCode,
                  validator: validatePhone,
                ),
              ),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: password,
            label: 'Password *',
            hint: 'Enter password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: true,
            validator: Validators.password,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: confirm,
            label: 'Confirm Password *',
            hint: 'Re-enter password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: true,
            validator: (v) => Validators.confirmPassword(v, password.text),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: aadhaar,
            label: 'Aadhaar Card Number *',
            hint: 'Enter Aadhaar number',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: pan,
            label: 'PAN Card Number *',
            hint: 'Enter PAN number',
            prefixIcon: Icons.credit_card_rounded,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            ],
          ),
          AppSizes.vGapLg,
          _TitledFileUpload(
            label: 'Upload ID Document (Aadhaar / PAN Card Photo) *',
            hint: 'Upload a clear photo, PDF, DOC, Excel, or PPT file.',
            icon: Icons.file_present_outlined,
            fileName: documentName,
            source: documentSource,
            onTap: onPickDocument,
            onClear: onClearDocument,
          ),
          AppSizes.vGapLg,
          Row(
            children: [
              Checkbox(value: agree, onChanged: onAgreeChanged),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: context.text.bodySmall,
                    children: const [
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
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
}

class _InvestorProfileStep extends StatelessWidget {
  const _InvestorProfileStep({
    required this.profilePhotoName,
    required this.profilePhotoPreview,
    required this.companyFund,
    required this.linkedin,
    required this.website,
    required this.bio,
    required this.ticketSize,
    required this.ticketOptions,
    required this.stagePreferences,
    required this.investmentModes,
    required this.targetIndustries,
    required this.stageOptions,
    required this.investmentModeOptions,
    required this.industryOptions,
    required this.onPickProfilePhoto,
    required this.onTicketChanged,
    required this.onStageChanged,
    required this.onModeChanged,
    required this.onIndustryChanged,
  });

  final String? profilePhotoName;
  final ImageProvider? profilePhotoPreview;
  final TextEditingController companyFund;
  final TextEditingController linkedin;
  final TextEditingController website;
  final TextEditingController bio;
  final String? ticketSize;
  final List<_TicketOption> ticketOptions;
  final List<String> stagePreferences;
  final List<String> investmentModes;
  final List<String> targetIndustries;
  final List<String> stageOptions;
  final List<String> investmentModeOptions;
  final List<String> industryOptions;
  final VoidCallback onPickProfilePhoto;
  final ValueChanged<String?> onTicketChanged;
  final ValueChanged<String> onStageChanged;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onIndustryChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfilePhotoPicker(
            fileName: profilePhotoName,
            preview: profilePhotoPreview,
            onTap: onPickProfilePhoto,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: companyFund,
            label: 'Company/Fund Name *',
            hint: 'Enter company name',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: linkedin,
            label: 'LinkedIn Profile',
            hint: 'Enter linkedIn url',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: website,
            label: 'Website URL',
            hint: 'Enter website url',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: bio,
            label: 'Bio',
            hint: 'Enter bio',
            maxLines: 5,
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Ticket Size *',
            hint: 'Select ticket size',
            value: ticketOptions.any((item) => item.id == ticketSize)
                ? ticketSize
                : null,
            items: ticketOptions.map((item) => item.id).toList(),
            itemLabel: (value) {
              for (final option in ticketOptions) {
                if (option.id == value) return option.label;
              }
              return value;
            },
            onChanged: ticketOptions.isEmpty ? null : onTicketChanged,
          ),
          AppSizes.vGapLg,
          _CompactMultiChoiceGroup(
            title: 'Stage Preference *',
            options: stageOptions,
            values: stagePreferences,
            onChanged: onStageChanged,
          ),
          AppSizes.vGapLg,
          _CompactMultiChoiceGroup(
            title: 'Investment Mode *',
            options: investmentModeOptions,
            values: investmentModes,
            onChanged: onModeChanged,
          ),
          AppSizes.vGapLg,
          _CompactMultiChoiceGroup(
            title: 'Target Industries / Categories *',
            options: industryOptions,
            values: targetIndustries,
            onChanged: onIndustryChanged,
          ),
        ],
      ),
    );
  }
}

class _FounderProfileStep extends StatelessWidget {
  const _FounderProfileStep({
    required this.profilePhotoName,
    required this.profilePhotoPreview,
    required this.bio,
    required this.skills,
    required this.experience,
    required this.education,
    required this.linkedin,
    required this.portfolioUrl,
    required this.teamSize,
    required this.teamSizeOptions,
    required this.category,
    required this.categoryOptions,
    required this.selectedSkills,
    required this.skillOptions,
    required this.isLoadingSkills,
    required this.onCategoryChanged,
    required this.onSkillSelected,
    required this.onSkillRemoved,
    required this.onManualSkillsChanged,
    required this.onPickProfilePhoto,
    required this.onTeamSizeChanged,
  });

  final String? profilePhotoName;
  final ImageProvider? profilePhotoPreview;
  final TextEditingController bio;
  final TextEditingController skills;
  final TextEditingController experience;
  final TextEditingController education;
  final TextEditingController linkedin;
  final TextEditingController portfolioUrl;
  final String? teamSize;
  final List<String> teamSizeOptions;
  final _PublicOption? category;
  final List<_PublicOption> categoryOptions;
  final List<String> selectedSkills;
  final List<String> skillOptions;
  final bool isLoadingSkills;
  final ValueChanged<_PublicOption?> onCategoryChanged;
  final ValueChanged<String> onSkillSelected;
  final ValueChanged<String> onSkillRemoved;
  final ValueChanged<String> onManualSkillsChanged;
  final VoidCallback onPickProfilePhoto;
  final ValueChanged<String?> onTeamSizeChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        children: [
          _ProfilePhotoPicker(
            fileName: profilePhotoName,
            preview: profilePhotoPreview,
            onTap: onPickProfilePhoto,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: bio,
            label: 'Bio *',
            hint: 'Tell us about yourself...',
            maxLines: 5,
          ),
          AppSizes.vGapLg,
          AppDropdown<_PublicOption>(
            label: 'Category *',
            hint: 'Select category',
            value: categoryOptions.contains(category) ? category : null,
            items: categoryOptions,
            itemLabel: (item) => item.label,
            onChanged: categoryOptions.isEmpty ? null : onCategoryChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: skills,
            label: 'Skills',
            hint: 'Select skills',
            onChanged: onManualSkillsChanged,
          ),
          AppSizes.vGapSm,
          _SkillChoiceSection(
            label: 'Select from category skills',
            selectedSkills: selectedSkills,
            skillOptions: skillOptions,
            isLoading: isLoadingSkills,
            onSkillSelected: onSkillSelected,
            onSkillRemoved: onSkillRemoved,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: experience,
            label: 'Experience *',
            hint: 'Enter years of experience',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: education,
            label: 'Education',
            hint: 'Enter your education',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: linkedin,
            label: 'LinkedIn',
            hint: 'Enter linkedIn url',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: portfolioUrl,
            label: 'Website / Portfolio',
            hint: 'Enter portfolio url',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Team Size *',
            hint: 'Select team size',
            value: teamSizeOptions.contains(teamSize) ? teamSize : null,
            items: teamSizeOptions,
            itemLabel: (item) => item,
            onChanged: onTeamSizeChanged,
          ),
        ],
      ),
    );
  }
}

class _FounderStartupDetailsStep extends StatelessWidget {
  const _FounderStartupDetailsStep({
    required this.startupName,
    required this.startupStage,
    required this.startupStageOptions,
    required this.shortPitch,
    required this.longDescription,
    required this.problemStatement,
    required this.solution,
    required this.targetCustomers,
    required this.marketSize,
    required this.businessModel,
    required this.revenueModel,
    required this.currentProgress,
    required this.fundingRequired,
    required this.equityOffered,
    required this.demoLink,
    required this.documentName,
    required this.documentSource,
    required this.onStageChanged,
    required this.onPickDocument,
    required this.onClearDocument,
  });

  final TextEditingController startupName;
  final String? startupStage;
  final List<String> startupStageOptions;
  final TextEditingController shortPitch;
  final TextEditingController longDescription;
  final TextEditingController problemStatement;
  final TextEditingController solution;
  final TextEditingController targetCustomers;
  final TextEditingController marketSize;
  final TextEditingController businessModel;
  final TextEditingController revenueModel;
  final TextEditingController currentProgress;
  final TextEditingController fundingRequired;
  final TextEditingController equityOffered;
  final TextEditingController demoLink;
  final String? documentName;
  final String? documentSource;
  final ValueChanged<String?> onStageChanged;
  final VoidCallback onPickDocument;
  final VoidCallback onClearDocument;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: startupName,
            label: 'Startup Name *',
            hint: 'Enter startup name',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Startup Stage *',
            hint: 'Select stage',
            value: startupStage,
            items: startupStageOptions,
            itemLabel: (item) => item,
            onChanged: onStageChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: shortPitch,
            label: 'Short Pitch (One-liner) *',
            hint: 'Enter short pitch',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: longDescription,
            label: 'Long Description *',
            hint: 'Describe your startup idea in detail...',
            maxLines: 4,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: problemStatement,
            label: 'Problem Statement *',
            hint: 'Enter problem statement',
            maxLines: 3,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: solution,
            label: 'Solution *',
            hint: 'Enter solution',
            maxLines: 3,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: targetCustomers,
            label: 'Target Customers *',
            hint: 'Enter target customers',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: marketSize,
            label: 'Market Size',
            hint: 'Enter market size',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: businessModel,
            label: 'Business Model',
            hint: 'Enter model like B2B, B2C, Marketplace...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: revenueModel,
            label: 'Revenue Model',
            hint: 'Enter model like SaaS, Transactional, Ads...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: currentProgress,
            label: 'Current Progress',
            hint: 'What have you achieved so far?',
            maxLines: 3,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: fundingRequired,
            label: 'Funding Required',
            hint: 'Enter fund amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: equityOffered,
            label: 'Equity Offered',
            hint: 'Enter equity offered',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          AppSizes.vGapLg,
          _TitledFileUpload(
            label: 'Pitch Deck Upload *',
            hint: 'Upload pitch deck file.',
            fileName: documentName,
            source: documentSource,
            icon: Icons.upload_file_rounded,
            onTap: onPickDocument,
            onClear: onClearDocument,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: demoLink,
            label: 'Demo Video / App / Website Link',
            hint: 'Enter demo link',
          ),
        ],
      ),
    );
  }
}

class _FounderTaxonomyStep extends StatelessWidget {
  const _FounderTaxonomyStep({
    required this.category,
    required this.skill,
    required this.categories,
    required this.skills,
    required this.isLoadingSkills,
    required this.onCategoryChanged,
    required this.onSkillChanged,
  });

  final _PublicOption? category;
  final String? skill;
  final List<_PublicOption> categories;
  final List<String> skills;
  final bool isLoadingSkills;
  final ValueChanged<_PublicOption?> onCategoryChanged;
  final ValueChanged<String?> onSkillChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        children: [
          AppDropdown<_PublicOption>(
            label: 'Primary Category *',
            hint: 'Select category',
            value: categories.contains(category) ? category : null,
            items: categories,
            itemLabel: (item) => item.label,
            onChanged: onCategoryChanged,
          ),
          AppSizes.vGapLg,
          if (isLoadingSkills)
            const LinearProgressIndicator(minHeight: 2)
          else
            AppDropdown<String>(
              label: 'Skills',
              hint: 'Select skill',
              value: skills.contains(skill) ? skill : null,
              items: skills,
              itemLabel: (item) => item,
              onChanged: skills.isEmpty ? null : onSkillChanged,
            ),
        ],
      ),
    );
  }
}

class _CompactMultiChoiceGroup extends StatelessWidget {
  const _CompactMultiChoiceGroup({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        AppSizes.vGapSm,
        Wrap(
          spacing: AppSizes.xl,
          runSpacing: AppSizes.sm,
          children: [
            for (final option in options)
              SizedBox(
                width: 260,
                child: InkWell(
                  onTap: () => onChanged(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          values.contains(option)
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        AppSizes.hGapSm,
                        Expanded(
                          child: Text(option, style: context.text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SimpleVerificationStep extends StatelessWidget {
  const _SimpleVerificationStep({
    required this.email,
    required this.emailOtp,
    required this.accountPhone,
    required this.countryIsoCode,
    required this.password,
    required this.confirm,
    required this.aadhaar,
    required this.pan,
    required this.documentName,
    required this.documentSource,
    required this.isEmailVerified,
    required this.isSendingOtp,
    required this.isVerifyingOtp,
    required this.agree,
    required this.documentLabel,
    required this.documentHint,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onCountryChanged,
    required this.validatePhone,
    required this.onPickDocument,
    required this.onClearDocument,
    required this.onAgreeChanged,
  });

  final TextEditingController email;
  final TextEditingController emailOtp;
  final TextEditingController accountPhone;
  final String countryIsoCode;
  final TextEditingController password;
  final TextEditingController confirm;
  final TextEditingController aadhaar;
  final TextEditingController pan;
  final String? documentName;
  final String? documentSource;
  final bool isEmailVerified;
  final bool isSendingOtp;
  final bool isVerifyingOtp;
  final bool agree;
  final String documentLabel;
  final String documentHint;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final ValueChanged<CountryCode> onCountryChanged;
  final String? Function(String?) validatePhone;
  final VoidCallback onPickDocument;
  final VoidCallback onClearDocument;
  final ValueChanged<bool?> onAgreeChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Verification (OTP sent to Mail)',
            style: context.text.titleMedium,
          ),
          AppSizes.vGapSm,
          AppTextField(
            controller: email,
            hint: 'Enter email',
            prefixIcon: Icons.alternate_email_rounded,
            suffixIcon: isEmailVerified
                ? const Icon(Icons.verified_rounded, color: AppColors.success)
                : null,
          ),
          AppSizes.vGapMd,
          AppTextField(controller: emailOtp, hint: 'Enter email OTP'),
          AppSizes.vGapMd,
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: isEmailVerified ? 'Verified' : 'Verify OTP',
                  isLoading: isVerifyingOtp,
                  onPressed: isEmailVerified ? null : onVerifyOtp,
                  gradient: false,
                ),
              ),
              AppSizes.hGapSm,
              Expanded(
                child: AppPrimaryButton(
                  label: 'Get Email OTP',
                  isLoading: isSendingOtp,
                  onPressed: isEmailVerified ? null : onSendOtp,
                  gradient: false,
                  backgroundColor: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          AppSizes.vGapLg,
          _PhoneWithCountryCodeRow(
            phone: accountPhone,
            countryIsoCode: countryIsoCode,
            onCountryChanged: onCountryChanged,
            validatePhone: validatePhone,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: password,
            label: 'Password *',
            hint: 'Enter password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: true,
            validator: Validators.password,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: confirm,
            label: 'Confirm Password *',
            hint: 'Re-enter password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: true,
            validator: (v) => Validators.confirmPassword(v, password.text),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: aadhaar,
            label: 'Aadhaar Card Number *',
            hint: 'Enter Aadhaar number',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: pan,
            label: 'PAN Card Number *',
            hint: 'Enter PAN number',
            prefixIcon: Icons.credit_card_rounded,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            ],
          ),
          AppSizes.vGapLg,
          _TitledFileUpload(
            label: documentLabel,
            hint: documentHint,
            fileName: documentName,
            source: documentSource,
            icon: Icons.file_present_outlined,
            onTap: onPickDocument,
            onClear: onClearDocument,
          ),
          AppSizes.vGapLg,
          Row(
            children: [
              Checkbox(value: agree, onChanged: onAgreeChanged),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: context.text.bodySmall,
                    children: const [
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
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
}

class _SignupSidePanel extends StatelessWidget {
  const _SignupSidePanel({required this.role, required this.progressPercent});

  final UserRole? role;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final benefits =
        role?.benefits ??
        const [
          'Bank-grade escrow protection',
          'End-to-end encrypted messaging',
          'ID + KYC verified network',
          'AI matching in seconds',
        ];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.asset(
                AppAssets.bannerImage,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSizes.lg,
                right: AppSizes.lg,
                bottom: AppSizes.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${role?.shortLabel ?? 'Freelancer'} signup',
                      style: context.text.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Land career-defining projects',
                      style: context.text.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSizes.vGapLg,
        _SideCard(
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progressPercent / 100,
                  strokeWidth: 7,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
              AppSizes.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$progressPercent%', style: context.text.titleMedium),
                    Text('Profile completion', style: context.text.titleMedium),
                    Text(
                      'Complete all steps to unlock matches.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSizes.vGapLg,
        _SideCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why Go Experts', style: context.text.titleMedium),
              AppSizes.vGapMd,
              for (final item in benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      AppSizes.hGapSm,
                      Expanded(
                        child: Text(item, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AppSizes.vGapMd,
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Already have an account? Sign in'),
        ),
      ],
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border.all(color: context.theme.dividerColor),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CountryCodeButton extends StatelessWidget {
  const _CountryCodeButton({required this.countryCode});

  final CountryCode? countryCode;

  @override
  Widget build(BuildContext context) {
    final code = countryCode;
    return SizedBox(
      height: 32,
      child: Row(
        children: [
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
    );
  }
}

class _CountrySelectionField extends StatelessWidget {
  const _CountrySelectionField({
    required this.controller,
    required this.countries,
    required this.label,
    required this.hint,
    required this.validator,
    required this.onCountrySelected,
    required this.onPlaceSelected,
  });

  final TextEditingController controller;
  final List<_CountryOption> countries;
  final String label;
  final String hint;
  final String? Function(String?) validator;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<SelectedPlace> onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return AppLocationField(
        controller: controller,
        label: label,
        hint: hint,
        validator: validator,
        onPlaceSelected: onPlaceSelected,
      );
    }

    _CountryOption? selected;
    for (final country in countries) {
      if (country.name == controller.text) {
        selected = country;
        break;
      }
    }

    return AppDropdown<_CountryOption>(
      label: label,
      hint: hint,
      value: selected,
      items: countries,
      itemLabel: (item) => item.displayNameWithoutPhoneCode,
      validator: (value) => validator(value?.name),
      onChanged: (value) {
        if (value == null) return;
        onCountrySelected(value);
      },
    );
  }
}

class _StateSelectionField extends StatelessWidget {
  const _StateSelectionField({
    required this.controller,
    required this.states,
    required this.label,
    required this.hint,
    required this.validator,
    required this.onStateSelected,
    required this.onPlaceSelected,
  });

  final TextEditingController controller;
  final List<_StateOption> states;
  final String label;
  final String hint;
  final String? Function(String?) validator;
  final ValueChanged<_StateOption> onStateSelected;
  final ValueChanged<SelectedPlace> onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    if (states.isEmpty) {
      return AppLocationField(
        controller: controller,
        label: label,
        hint: hint,
        validator: validator,
        onPlaceSelected: onPlaceSelected,
      );
    }

    _StateOption? selected;
    for (final state in states) {
      if (state.name == controller.text) {
        selected = state;
        break;
      }
    }

    return AppDropdown<_StateOption>(
      label: label,
      hint: hint,
      value: selected,
      items: states,
      itemLabel: (item) => item.name,
      validator: (value) => validator(value?.name),
      onChanged: (value) {
        if (value == null) return;
        onStateSelected(value);
      },
    );
  }
}

class _CountryOption {
  const _CountryOption({
    required this.id,
    required this.name,
    required this.code,
    required this.phoneCode,
    required this.flag,
    required this.allowRegistration,
  });

  final String id;
  final String name;
  final String code;
  final String phoneCode;
  final String flag;
  final bool allowRegistration;

  String get displayName {
    final parts = [
      if (flag.isNotEmpty) flag,
      name,
      if (phoneCode.isNotEmpty) phoneCode,
    ];
    return parts.join(' ');
  }

  String get displayNameWithoutPhoneCode {
    final parts = [if (flag.isNotEmpty) flag, name];
    return parts.join(' ');
  }

  factory _CountryOption.fromJson(Map<String, dynamic> json) {
    return _CountryOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      phoneCode: json['phoneCode']?.toString() ?? '',
      flag: json['flag']?.toString() ?? '',
      allowRegistration: json['allowRegistration'] != false,
    );
  }
}

class _TicketOption {
  const _TicketOption({
    required this.id,
    required this.label,
    required this.value,
    this.min,
    this.max,
  });

  final String id;
  final String label;
  final String value;
  final int? min;
  final int? max;

  factory _TicketOption.fromJson(Map<String, dynamic> json) {
    final label =
        json['label']?.toString().trim() ??
        json['value']?.toString().trim() ??
        '';
    final value =
        json['value']?.toString().trim() ??
        json['label']?.toString().trim() ??
        '';
    return _TicketOption(
      id: json['id']?.toString().trim() ?? value,
      label: label,
      value: value,
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );
  }
}

class _StateOption {
  const _StateOption({
    required this.id,
    required this.code,
    required this.name,
    required this.countryCode,
  });

  final String id;
  final String code;
  final String name;
  final String countryCode;

  factory _StateOption.fromJson(Map<String, dynamic> json) {
    return _StateOption(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
    );
  }
}

class _PublicOption {
  const _PublicOption({required this.id, required this.label});

  final String id;
  final String label;

  factory _PublicOption.fromJson(
    Map<String, dynamic> json, {
    required List<String> labelKeys,
  }) {
    String label = '';
    for (final key in labelKeys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        label = value;
        break;
      }
    }
    return _PublicOption(id: json['id']?.toString() ?? '', label: label);
  }
}

class _PlanOption {
  const _PlanOption({
    required this.id,
    required this.name,
    required this.role,
    required this.amount,
    required this.currency,
    required this.duration,
    required this.popular,
    required this.recommended,
    this.features = const [],
    this.limits = const {},
    this.originalAmount,
    this.savedBadge,
  });

  final String id;
  final String name;
  final String role;
  final double amount;
  final String currency;
  final String duration;
  final bool popular;
  final bool recommended;
  final List<String> features;
  final Map<String, dynamic> limits;
  final double? originalAmount;
  final String? savedBadge;

  bool get isFree => amount <= 0 || name.toLowerCase().contains('free');

  List<String> get badges => [
    if (popular) 'Popular',
    if (recommended) 'Recommended',
    if (savedBadge != null && savedBadge!.isNotEmpty) savedBadge!,
  ];

  String get price {
    return _money(amount);
  }

  String? get originalPrice {
    final original = originalAmount;
    if (original == null || original <= amount) return null;
    return _money(original);
  }

  String _money(double value) {
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    final amountText = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    final period = duration.isEmpty ? '' : '/$duration';
    return '$symbol$amountText$period';
  }

  factory _PlanOption.fromJson(Map<String, dynamic> json) {
    return _PlanOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      duration: json['duration']?.toString() ?? '',
      popular: json['popular'] == true,
      recommended: json['recommended'] == true,
      features: _parseFeatures(json['features']),
      limits: _parseLimits(json['limits']),
      originalAmount: _doubleOrNull(json['originalAmount']),
      savedBadge: json['savedBadge']?.toString().trim(),
    );
  }

  static List<String> _parseFeatures(dynamic raw) {
    final value = _decodeJsonString(raw);
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic> _parseLimits(dynamic raw) {
    final value = _decodeJsonString(raw);
    if (value is Map) {
      return Map<String, dynamic>.from(value)
        ..removeWhere((key, value) => key.toString().trim().isEmpty);
    }
    return const {};
  }

  static dynamic _decodeJsonString(dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return raw;
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  static double? _doubleOrNull(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }
}
