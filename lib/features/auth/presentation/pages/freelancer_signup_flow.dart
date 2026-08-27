import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../utils/signup_progress_store.dart';
import '../widgets/signup_account_step.dart';
import '../widgets/signup_multi_select_sheet.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_success_view.dart';
import '../widgets/signup_top_message.dart';

class FreelancerSignupFlow extends StatefulWidget {
  final VoidCallback? onBackToRoleSelection;
  final int initialStep;
  final String? verifiedEmail;
  const FreelancerSignupFlow({
    super.key,
    this.onBackToRoleSelection,
    this.initialStep = 1,
    this.verifiedEmail,
  });

  @override
  State<FreelancerSignupFlow> createState() => _FreelancerSignupFlowState();
}

class _FreelancerSignupFlowState extends State<FreelancerSignupFlow> {
  int _currentStep = 1;
  bool _isLoading = false;

  // Step 1 Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedMobileCountryCode = '+91';
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  double? _detectedLatitude;
  double? _detectedLongitude;
  bool _termsAccepted = false;
  bool _emailVerified = false;
  String? _registeredEmail;

  // Step 2 Controllers
  final _headlineController = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  // Step 3 Skills
  List<String> _selectedIndustries = [];
  final _otherIndustryController = TextEditingController();
  List<String> _selectedSkills = [];
  final _otherSkillController = TextEditingController();

  // Step 4 Experience
  String? _experienceLevel;
  String? _educationLevel;
  final _otherEducationController = TextEditingController();
  final List<String> _educationLevels = [
    'High School',
    'Diploma',
    'Bachelors',
    'Masters',
    'Doctorate (Ph.D.)',
    'Other',
  ];

  String? get _effectiveEducationLevel {
    if (_educationLevel == 'Other' ||
        (_educationLevel != null &&
            !_educationLevels.contains(_educationLevel))) {
      final text = _otherEducationController.text.trim();
      return text.isNotEmpty ? text : 'Other';
    }
    return _educationLevel;
  }

  List<String> _selectedWorkModes = [];
  final _portfolioController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();

  // Dynamic API Master lists (100% Sourced from Backend APIs)
  List<String> _countries = [];
  List<String> _states = [];
  List<SkillCategory> _availableIndustries = [];
  List<String> _industries = [];
  final Map<String, SkillOption> _skillsMap = {};
  List<String> _availableSkillNames = [];
  List<String> _expLevels = [];
  List<String> _workModes = [];
  final _locationService = const LocationService();

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(1, 4).toInt();
    if (widget.verifiedEmail != null && widget.verifiedEmail!.isNotEmpty) {
      _emailController.text = widget.verifiedEmail!;
      _emailVerified = true;
    }
    final progress = SignupProgressStore.read();
    if (progress?.role == UserRole.freelancer) {
      _registeredEmail = progress!.registeredEmail;
      _restoreFields(progress.fields);
      if (progress.step >= 1) {
        _currentStep = progress.step.clamp(1, 4).toInt();
      }
    }
    _populateFromAuthState();
    for (final controller in [
      _fullNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _cityController,
      _headlineController,
      _bioController,
      _hourlyRateController,
      _portfolioController,
      _githubController,
      _linkedinController,
      _otherIndustryController,
      _otherSkillController,
    ]) {
      controller.addListener(_persistCurrentProgress);
    }
    _loadMasterData();
  }

  Future<void> _saveProgress(int step) {
    return SignupProgressStore.save(
      role: UserRole.freelancer,
      step: step,
      verifiedEmail: _emailController.text.trim(),
      registeredEmail: _registeredEmail,
      fields: _fields(),
    );
  }

  void _persistCurrentProgress() {
    _saveProgress(_currentStep);
  }

  void _restoreFields(Map<String, dynamic> fields) {
    _fullNameController.text = fields['fullName']?.toString() ?? '';
    _passwordController.text = fields['password']?.toString() ?? '';
    _confirmPasswordController.text =
        fields['confirmPassword']?.toString() ?? '';
    _cityController.text = fields['city']?.toString() ?? '';
    _selectedCountry = fields['country']?.toString();
    _selectedState = fields['state']?.toString();
    _termsAccepted = fields['termsAccepted'] == true;
    _headlineController.text = fields['titleHeadline']?.toString() ?? '';
    _bioController.text = fields['bio']?.toString() ?? '';
    _hourlyRateController.text = fields['hourlyRate']?.toString() ?? '';
    _portfolioController.text = fields['portfolioUrl']?.toString() ?? '';
    _githubController.text = fields['githubUrl']?.toString() ?? '';
    _linkedinController.text = fields['linkedInUrl']?.toString() ?? '';
    _experienceLevel = fields['experienceLevel']?.toString();
    final restoredEdu = fields['education']?.toString();
    if (restoredEdu != null && restoredEdu.isNotEmpty) {
      if (_educationLevels.contains(restoredEdu)) {
        _educationLevel = restoredEdu;
        _otherEducationController.clear();
      } else {
        _educationLevel = 'Other';
        _otherEducationController.text = restoredEdu;
      }
    } else {
      _educationLevel = null;
      _otherEducationController.clear();
    }
    _selectedIndustries = _stringList(fields['industry']);
    _selectedSkills = _stringList(fields['skills']);
    _selectedWorkModes = _stringList(fields['workMode']);
    _otherIndustryController.text =
        fields['otherIndustry']?.toString() ?? '';
    _otherSkillController.text = fields['otherSkill']?.toString() ?? '';
    _detectedLatitude = double.tryParse(fields['latitude']?.toString() ?? '');
    _detectedLongitude =
        double.tryParse(fields['longitude']?.toString() ?? '');
  }

  void _populateFromAuthState() {
    final authState = context.read<AuthBloc>().state;
    final draft = authState.pendingSignup;
    final user = authState.user;

    if (draft != null) {
      if (_fullNameController.text.isEmpty && draft.fullName.isNotEmpty) {
        _fullNameController.text = draft.fullName;
      }
      if (_emailController.text.isEmpty && draft.email.isNotEmpty) {
        _emailController.text = draft.email;
      }
      if (_mobileController.text.isEmpty && draft.phone.isNotEmpty) {
        _mobileController.text = draft.phone;
      }
      if (draft.countryCode.isNotEmpty) {
        _selectedMobileCountryCode = draft.countryCode;
      }
      final city = draft.signupData['city'] ?? draft.signupData['location'];
      if (_cityController.text.isEmpty && city != null) {
        _cityController.text = city.toString();
      }
      final country = draft.signupData['country'];
      if (_selectedCountry == null && country != null) {
        _selectedCountry = country.toString();
      }
    }

    if (user != null) {
      if ((user.isSocialLogin || _fullNameController.text.isEmpty) &&
          user.fullName.isNotEmpty) {
        _fullNameController.text = user.fullName;
      }
      if ((user.isSocialLogin || _emailController.text.isEmpty) &&
          user.email.isNotEmpty) {
        _emailController.text = user.email;
      }
      if (_mobileController.text.isEmpty && user.phone != null) {
        _mobileController.text = user.phone!;
      }
      if (user.countryCode != null && user.countryCode!.isNotEmpty) {
        _selectedMobileCountryCode = user.countryCode!;
      }
      if (_headlineController.text.isEmpty && user.headline != null) {
        _headlineController.text = user.headline!;
      }
      if (_cityController.text.isEmpty && user.location != null) {
        _cityController.text = user.location!;
      }
    }

    if (user?.isSocialLogin == true ||
        _emailController.text.trim().isNotEmpty) {
      _emailVerified = true;
    }
  }

  void _syncFromAuthState(BuildContext context, AuthState state) {
    _populateFromAuthState();
    if (mounted) setState(() {});
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) {
            if (e is Map) {
              final name =
                  e['value']?.toString() ??
                  e['name']?.toString() ??
                  e['id']?.toString() ??
                  '';
              final id = e['id']?.toString() ?? '';
              if (name.isNotEmpty) {
                _skillsMap[name] = SkillOption(id: id, name: name);
              }
              return name;
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _fields({bool completed = false}) {
    final isSocial =
        context.read<AuthBloc>().state.user?.isSocialLogin ?? false;
    return {
      'step': _currentStep,
      'completed': completed,
      'isSocialLogin': isSocial,
      'isSocial': isSocial,
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'country': _selectedCountry,
      // 'state': _selectedState,
      'city': _cityController.text.trim(),
      if (_detectedLatitude != null) 'latitude': _detectedLatitude,
      if (_detectedLongitude != null) 'longitude': _detectedLongitude,
      'termsAccepted': _termsAccepted,
      'titleHeadline': _headlineController.text.trim(),
      'bio': _bioController.text.trim(),
      'experienceLevel': _experienceLevel,
      'education': _effectiveEducationLevel,
      'hourlyRate': double.tryParse(_hourlyRateController.text.trim()),
      'portfolioUrl': _portfolioController.text.trim(),
      'linkedInUrl': _linkedinController.text.trim(),
      'githubUrl': _githubController.text.trim(),
      'industry': _selectedIndustries,
      'otherIndustry': _otherIndustryController.text.trim(),
      'skills': _selectedSkills.map((name) {
        final option = _skillsMap[name];
        final skillId =
            option?.id ??
            'static_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
        return {'id': skillId, 'value': name, 'name': name};
      }).toList(),
      'otherSkill': _otherSkillController.text.trim(),
      'workMode': _selectedWorkModes,
    };
  }

  Future<bool> _registerIfNeeded() async {
    final email = _emailController.text.trim();
    if (_registeredEmail == email) return true;
    if (widget.verifiedEmail != null && widget.verifiedEmail!.isNotEmpty) {
      _registeredEmail = email;
      return true;
    }
    final isSocial =
        context.read<AuthBloc>().state.user?.isSocialLogin ?? false;
    if (isSocial) {
      _registeredEmail = email;
      return true;
    }

    final pwd = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : 'Pass@123456';
    final result = await sl<AuthRepository>().signup(
      fullName: _fullNameController.text.trim(),
      email: email,
      password: pwd,
      role: UserRole.freelancer,
      isSocialLogin: isSocial,
      signupData: {
        'isSocialLogin': isSocial,
        'isSocial': isSocial,
        'country': _selectedCountry,
        // 'state': _selectedState,
        'city': _cityController.text.trim(),
        if (_detectedLatitude != null) 'latitude': _detectedLatitude,
        if (_detectedLongitude != null) 'longitude': _detectedLongitude,
      },
    );
    if (result.isFailure) {
      final code = result.failureOrNull?.code;
      final msg = result.failureOrNull?.message.toLowerCase() ?? '';
      if (code == 'EMAIL_ALREADY_EXISTS' ||
          msg.contains('already registered') ||
          msg.contains('already exists')) {
        if (!mounted) return false;
        showSignupTopMessage(
          context,
          'Email is already registered. Please login.',
          isSuccess: false,
        );
        return false;
      }
      if (!mounted) return false;
      showSignupTopMessage(
        context,
        result.failureOrNull!.message,
        isSuccess: false,
      );
      return false;
    }
    if (mounted && result.valueOrNull != null) {
      context.read<AuthBloc>().add(AuthUserUpdated(result.valueOrNull!));
    }
    _registeredEmail = email;
    return true;
  }

  Future<bool> _submitDraft({required int step, bool completed = false}) async {
    final data = {..._fields(completed: completed), 'step': step};
    final result = await sl<AuthRepository>().saveOnboardingDraft(data);
    if (result.isFailure) {
      if (!mounted) return false;
      showSignupTopMessage(
        context,
        result.failureOrNull!.message,
        isSuccess: false,
      );
      return false;
    }
    return true;
  }

  Future<void> _loadMasterData() async {
    final repo = sl<MasterDataRepository>();
    final cRes = await repo.getCountries();
    final indRes = await repo.getIndustries();
    final expRes = await repo.getExperienceLevels();
    final workModeRes = await repo.getWorkModes();

    if (!mounted) return;
    setState(() {
      if (cRes.isSuccess && cRes.valueOrNull!.isNotEmpty) {
        _countries = cRes.valueOrNull!;
      }
      if (indRes.isSuccess && indRes.valueOrNull!.isNotEmpty) {
        _availableIndustries = indRes.valueOrNull!;
        _industries = _availableIndustries.map((e) => e.name).toList();
      }
      if (expRes.isSuccess && expRes.valueOrNull!.isNotEmpty) {
        _expLevels = expRes.valueOrNull!;
      }
      if (workModeRes.isSuccess && workModeRes.valueOrNull!.isNotEmpty) {
        _workModes = workModeRes.valueOrNull!;
      }
    });

    if (_selectedIndustries.isNotEmpty) {
      _fetchSkillsApi().then((skills) {
        if (!mounted) return;
        setState(() {
          for (final s in skills) {
            _skillsMap[s.name] = s;
          }
          _availableSkillNames = skills.map((s) => s.name).toList();
        });
      });
    }
  }

  Future<void> _loadStatesForCountry(String country) async {
    final res = await sl<MasterDataRepository>().getStates(country);
    if (!mounted || res.isFailure) return;
    setState(() {
      _states = res.valueOrNull ?? [];
      _selectedState = null;
    });
  }

  String? _matchCountry(String candidate) {
    final normalized = candidate.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final country in _countries) {
      final current = country.trim().toLowerCase();
      if (current == normalized ||
          current.contains(normalized) ||
          normalized.contains(current)) {
        return country;
      }
    }
    return candidate.trim();
  }

  Future<void> _autoDetectLocation() async {
    try {
      final detected = await _locationService.detectCurrentLocation();
      if (!mounted) return;
      setState(() {
        if (detected.city.isNotEmpty) {
          _cityController.text = detected.city;
        } else if (detected.address.isNotEmpty) {
          _cityController.text = detected.address;
        }
        _detectedLatitude = detected.latitude;
        _detectedLongitude = detected.longitude;
        final matchedCountry = detected.country.isNotEmpty
            ? _matchCountry(detected.country)
            : null;
        if (matchedCountry != null && matchedCountry.isNotEmpty) {
          _selectedCountry = matchedCountry;
        }
      });
      _persistCurrentProgress();
      if (_selectedCountry != null) {
        await _loadStatesForCountry(_selectedCountry!);
      }
      if (mounted) {
        showSignupTopMessage(
          context,
          'Location detected successfully',
          isSuccess: true,
        );
      }
    } on LocationServiceDisabledException {
      if (!mounted) return;
      showSignupTopMessage(
        context,
        'Please enable location services and try again',
        isSuccess: false,
      );
    } on LocationPermissionDeniedException {
      if (!mounted) return;
      showSignupTopMessage(
        context,
        'Location permission is required to detect your city',
        isSuccess: false,
      );
    } on LocationPermissionPermanentlyDeniedException {
      if (!mounted) return;
      showSignupTopMessage(
        context,
        'Location permission is permanently denied. Enable it from settings.',
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) return;
      showSignupTopMessage(
        context,
        'Could not detect location right now. Please search manually.',
        isSuccess: false,
      );
    }
  }

  String? _accountValidationMessage() {
    final email = _emailController.text.trim();
    if (_fullNameController.text.trim().isEmpty) {
      return 'Please enter full name';
    }
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    if (!_emailVerified) return 'Please verify email OTP';
    final isSocial =
        context.read<AuthBloc>().state.user?.isSocialLogin ?? false;
    if (!isSocial) {
      if (_passwordController.text.isEmpty) {
        return 'Please enter password';
      }
      if (_passwordController.text.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        return 'Password and confirm password must match';
      }
    }
    if (_selectedCountry == null) return 'Please select country';
    // if (_selectedState == null) return 'Please select state';
    if (_cityController.text.trim().isEmpty) return 'Please select city';
    if (!_termsAccepted) return 'Please accept terms and privacy policy';
    return null;
  }

  Future<List<SkillOption>> _fetchSkillsApi({String? query}) async {
    if (_selectedIndustries.isEmpty) {
      return <SkillOption>[];
    }
    List<String> industryIds = [];
    if (_availableIndustries.isNotEmpty) {
      industryIds = _availableIndustries
          .where((ind) => _selectedIndustries.contains(ind.name))
          .map((ind) => ind.id)
          .where((id) => id.isNotEmpty)
          .toList();
    }

    if (industryIds.isEmpty) {
      return <SkillOption>[];
    }

    final futures = industryIds.map((id) => _fetchSkillsForIndustry(id, query));
    final results = await Future.wait(futures);
    final allSkills = <SkillOption>[];
    final seenIds = <String>{};
    for (final list in results) {
      for (final s in list) {
        if (!seenIds.contains(s.id)) {
          seenIds.add(s.id);
          allSkills.add(s);
        }
      }
    }

    return allSkills;
  }

  Future<List<SkillOption>> _fetchSkillsForIndustry(
    String? industryId,
    String? query,
  ) async {
    try {
      final res = await sl<ApiClientHelper>().getEnvelope<List<SkillOption>>(
        ApiEndpoints.publicSkills,
        query: {
          if (industryId != null && industryId.isNotEmpty)
            'industryId': industryId,
          'page': 1,
          'limit': 100,
          if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        },
        parser: (env) {
          dynamic list = env.data;
          if (list is Map) {
            final map = Map<String, dynamic>.from(list);
            list = map['data'] ?? map['items'] ?? map['skills'] ?? const [];
          }
          if (list is! List) return <SkillOption>[];
          return list
              .map(
                (e) =>
                    SkillOption.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        },
      );
      if (res.isSuccess && res.valueOrNull != null) {
        return res.valueOrNull!;
      }
    } catch (_) {}

    return <SkillOption>[];
  }

  Future<List<String>> _searchSkillsApi(String query) async {
    if (_selectedIndustries.isEmpty) {
      return <String>[];
    }
    final skills = await _fetchSkillsApi(query: query);
    for (final s in skills) {
      _skillsMap[s.name] = s;
    }
    return skills.map((s) => s.name).toList();
  }

  void _onContinue() async {
    if (_currentStep == 1) {
      final validationMessage = _accountValidationMessage();
      if (validationMessage != null) {
        showSignupTopMessage(context, validationMessage, isSuccess: false);
        return;
      }

      setState(() => _isLoading = true);
      final registered = await _registerIfNeeded();
      if (!mounted) return;
      if (!registered) {
        setState(() => _isLoading = false);
        return;
      }
      await _saveProgress(2);
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      if (_headlineController.text.isEmpty) {
        showSignupTopMessage(
          context,
          'Please enter your professional headline',
          isSuccess: false,
        );
        return;
      }
      if (_experienceLevel == null) {
        showSignupTopMessage(
          context,
          'Please select total experience',
          isSuccess: false,
        );
        return;
      }
      if (_educationLevel == null) {
        showSignupTopMessage(
          context,
          'Please select education level',
          isSuccess: false,
        );
        return;
      }
      if ((_educationLevel == 'Other' ||
              (_educationLevel != null &&
                  !_educationLevels.contains(_educationLevel))) &&
          _otherEducationController.text.trim().isEmpty) {
        showSignupTopMessage(
          context,
          'Please specify your education level',
          isSuccess: false,
        );
        return;
      }
      if (!await _submitDraft(step: 2)) return;
      await _saveProgress(3);
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_selectedIndustries.isEmpty) {
        showSignupTopMessage(
          context,
          'Please select an Industry',
          isSuccess: false,
        );
        return;
      }
      if (_selectedIndustries.contains('Other') &&
          _otherIndustryController.text.trim().isEmpty) {
        showSignupTopMessage(
          context,
          'Please specify your industry',
          isSuccess: false,
        );
        return;
      }
      if (_selectedSkills.contains('Other') &&
          _otherSkillController.text.trim().isEmpty) {
        showSignupTopMessage(
          context,
          'Please specify your skill',
          isSuccess: false,
        );
        return;
      }
      if (!await _submitDraft(step: 3)) return;
      await _saveProgress(4);
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      // final hourlyRate = _hourlyRateController.text.trim();
      // if (hourlyRate.isEmpty) {
      //   showSignupTopMessage(
      //     context,
      //     'Please enter hourly rate amount',
      //     isSuccess: false,
      //   );
      //   return;
      // }
      // if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(hourlyRate)) {
      //   showSignupTopMessage(
      //     context,
      //     'Hourly rate can contain up to 2 decimals',
      //     isSuccess: false,
      //   );
      //   return;
      // }

      final portfolioUrl = _portfolioController.text.trim();
      if (portfolioUrl.isEmpty) {
        showSignupTopMessage(
          context,
          'Please enter Portfolio Website Link',
          isSuccess: false,
        );
        return;
      }

      final urlRegExp = RegExp(
        r'^(https?:\/\/)?([\w\d\-]+\.)+\w{2,}(\/.*)?$',
        caseSensitive: false,
      );
      if (!urlRegExp.hasMatch(portfolioUrl)) {
        showSignupTopMessage(
          context,
          'Please enter a valid website link (e.g. yourwebsite.com)',
          isSuccess: false,
        );
        return;
      }
      if (!await _submitDraft(step: 4, completed: true)) return;
      await SignupProgressStore.clear();
      setState(() => _currentStep = 5);
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      final prevStep = _currentStep - 1;
      _saveProgress(prevStep);
      setState(() => _currentStep = prevStep);
    } else if (widget.onBackToRoleSelection != null) {
      _saveProgress(1);
      widget.onBackToRoleSelection!();
    } else if (context.canPop()) {
      _saveProgress(1);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 5) {
      SignupProgressStore.clear();
      return SignupSuccessView(
        roleTitle: 'Freelancer',
        dashboardRoute: Routes.freelancerDashboard,
        completedSteps: const [
          'Account Registered',
          'Professional Profile Created',
          'Skills & Technologies Added',
          'Social Media Configured',
        ],
        onGoToDashboard: () async {
          await SignupProgressStore.clear();
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthCheckRequested());
            context.go(Routes.freelancerDashboard);
          }
        },
      );
    }

    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 1:
        title = 'Create Freelancer Account';
        subtitle = 'Join top clients and work on high-paying global projects.';
        break;
      case 2:
        title = ' Profile';
        subtitle = 'Tell clients about your expertise and background.';
        break;
      case 3:
        title = 'Skills & Technologies';
        subtitle = 'Select your core technical and professional skills.';
        break;
      case 4:
        title = 'Social Media Links';
        subtitle = 'Provide links to your portfolio and professional profiles.';
        break;
    }

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user != current.user ||
          previous.pendingSignup != current.pendingSignup,
      listener: _syncFromAuthState,
      child: SignupScaffold(
        title: title,
        subtitle: subtitle,
        currentStep: _currentStep,
        totalSteps: 5,
        onBack: _onBack,
        onContinue: _onContinue,
        isLoading: _isLoading,
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return SignupAccountStep(
          fullNameController: _fullNameController,
          emailController: _emailController,
          mobileController: _mobileController,
          selectedMobileCountryCode: _selectedMobileCountryCode,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          cityController: _cityController,
          countries: _countries,
          // states: _states,
          selectedCountry: _selectedCountry,
          // selectedState: _selectedState,
          onCountryChanged: (val) {
            setState(() {
              _selectedCountry = val;
              _selectedState = null;
              _states = [];
            });
            _persistCurrentProgress();
            _loadStatesForCountry(val);
          },
          onMobileCountryCodeChanged: (val) =>
              setState(() => _selectedMobileCountryCode = val),
          onAutoDetectLocation: _autoDetectLocation,
          // onStateChanged: (val) {
          //   setState(() => _selectedState = val);
          //   _persistCurrentProgress();
          // },
          termsAccepted: _termsAccepted,
          onTermsChanged: (val) {
            setState(() => _termsAccepted = val);
            _persistCurrentProgress();
          },
          onEmailVerificationChanged: (val) =>
              setState(() => _emailVerified = val),
          initialVerifiedEmail: widget.verifiedEmail ??
              (context.read<AuthBloc>().state.user?.isVerified == true
                  ? context.read<AuthBloc>().state.user?.email
                  : ''),
          isSocialLogin:
              context.read<AuthBloc>().state.user?.isSocialLogin ?? false,
        );
      case 2:
        return Column(
          children: [
            AppTextField(
              controller: _headlineController,
              label: 'Professional Title / Headline *',
              hint: 'e.g., Full-Stack Developer | UI/UX Designer',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _bioController,
              maxLines: 3,
              label: 'Brief Bio / Summary',
              hint: 'Turn your experience into your next opportunity...',
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Total Experience  *',
              hint: 'Highlight your professional journey...',
              value: _experienceLevel,
              items: _expLevels,
              itemLabel: (item) => item,
              onChanged: (val) {
                setState(() => _experienceLevel = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Education Level *',
              hint: 'Select Education Level',
              value: _educationLevels.contains(_educationLevel)
                  ? _educationLevel
                  : (_educationLevel != null && _educationLevel!.isNotEmpty
                        ? 'Other'
                        : null),
              items: _educationLevels,
              itemLabel: (item) => item,
              onChanged: (val) {
                setState(() {
                  _educationLevel = val;
                  if (val != 'Other') {
                    _otherEducationController.clear();
                  }
                });
                _persistCurrentProgress();
              },
            ),
            if (_educationLevel == 'Other' ||
                (_educationLevel != null &&
                    !_educationLevels.contains(_educationLevel))) ...[
              const SizedBox(height: 16),
              AppTextField(
                controller: _otherEducationController,
                label: 'Specify Education Level *',
                hint: 'Enter Education Level',
                onChanged: (_) => _persistCurrentProgress(),
              ),
            ],
          ],
        );
      case 3:
        return Column(
          children: [
            SignupMultiSelectSheet(
              label: 'Primary Industry / Domain*',
              hint: "Choose the industry that matches your skills",
              selectedItems: _selectedIndustries,
              availableOptions: [..._industries, 'Other'],
              minSelection: 1,

              onChanged: (val) {
                setState(() {
                  _selectedIndustries = val;
                  if (val.isEmpty) {
                    _selectedSkills = [];
                    _availableSkillNames = [];
                  }
                });
                _persistCurrentProgress();
                if (val.isNotEmpty) {
                  _fetchSkillsApi().then((skills) {
                    if (!mounted) return;
                    setState(() {
                      for (final s in skills) {
                        _skillsMap[s.name] = s;
                      }
                      _availableSkillNames = skills.map((s) => s.name).toList();
                    });
                  });
                }
              },
            ),
            if (_selectedIndustries.contains('Other')) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _otherIndustryController,
                label: 'Specify Industry *',
                hint: 'Enter your industry',
              ),
            ],
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              hint: "Select skills e.g., Flutter, UI/UX.....",
              label: 'Skills *',
              selectedItems: _selectedSkills,
              availableOptions: [..._availableSkillNames, 'Other'],
              minSelection: 0,
              onSearchApi: _searchSkillsApi,
              onChanged: (items) {
                setState(() => _selectedSkills = items);
                _persistCurrentProgress();
              },
            ),
            if (_selectedSkills.contains('Other')) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _otherSkillController,
                label: 'Specify Skill *',
                hint: 'Enter your skill',
              ),
            ],
          ],
        );
      case 4:
        return Column(
          children: [
            // SignupMultiSelectSheet(
            //   label: 'Preferred Work Mode',
            //   selectedItems: _selectedWorkModes,
            //   availableOptions: _workModes,
            //   minSelection: 1,
            //   onChanged: (items) {
            //     setState(() => _selectedWorkModes = items);
            //     _persistCurrentProgress();
            //   },
            // ),
            // const SizedBox(height: 16),
            // AppTextField(
            //   controller: _hourlyRateController,
            //   keyboardType: const TextInputType.numberWithOptions(
            //     decimal: true,
            //   ),
            //   inputFormatters: [
            //     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            //   ],
            //   label: 'Hourly Rate Amount *',
            //   hint: 'Enter Hourly Rate Amount',
            // ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _portfolioController,
              label: 'Portfolio Website Link *',
              hint: 'Add projects that showcase your skills...',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _githubController,
              label: 'Github Profile Link',
              hint: 'Share your code and contributions...',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _linkedinController,
              label: 'LinkedIn Profile Link',
              hint: 'Share your professional journey...',
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
