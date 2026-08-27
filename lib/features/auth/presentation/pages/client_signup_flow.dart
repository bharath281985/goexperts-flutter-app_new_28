import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../utils/signup_progress_store.dart';
import '../widgets/signup_account_step.dart';
import '../widgets/signup_multi_select_sheet.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_success_view.dart';
import '../widgets/signup_top_message.dart';

class ClientSignupFlow extends StatefulWidget {
  final VoidCallback? onBackToRoleSelection;
  final int initialStep;
  final String? verifiedEmail;
  const ClientSignupFlow({
    super.key,
    this.onBackToRoleSelection,
    this.initialStep = 1,
    this.verifiedEmail,
  });

  @override
  State<ClientSignupFlow> createState() => _ClientSignupFlowState();
}

class _ClientSignupFlowState extends State<ClientSignupFlow> {
  int _currentStep = 1;
  bool _isLoading = false;

  // Step 1 Account
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

  // Step 2 Business
  final _businessNameController = TextEditingController();
  final _companySiteController = TextEditingController();
  List<String> _selectedIndustries = [];
  String? _selectedCompanySize;
  String? _selectedCountry;
  String? _selectedState;

  // Step 3 Profile
  String? _selectedJobRole;
  List<String> _selectedHiringGoals = [];

  // Step 4 Team (Optional)
  String? _selectedTeamSize;
  MasterOption? _selectedBudgetRange;

  // Dynamic API Master lists (100% Sourced from Backend APIs)
  List<String> _industries = [];
  List<String> _companySizes = [];
  List<String> _hiringGoals = [];
  List<MasterOption> _budgetRanges = [];
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _designations = [];
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
    if (progress?.role == UserRole.client) {
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
      _businessNameController,
      _companySiteController,
    ]) {
      controller.addListener(_persistCurrentProgress);
    }
    _loadMasterData();
  }

  Future<void> _saveProgress(int step) {
    return SignupProgressStore.save(
      role: UserRole.client,
      step: step,
      verifiedEmail: _emailController.text.trim(),
      registeredEmail: _registeredEmail,
      fields: _fields(),
    );
  }

  void _persistCurrentProgress() {
    _saveProgress(_currentStep);
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
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
    _businessNameController.text = fields['companyName']?.toString() ?? '';
    _companySiteController.text = fields['companySite']?.toString() ?? '';
    _selectedIndustries = _stringList(fields['industry']);
    _selectedCompanySize = fields['companySize']?.toString();
    final restoredJobRole = fields['jobRole']?.toString();
    _selectedJobRole = restoredJobRole != null && restoredJobRole.isNotEmpty
        ? restoredJobRole
        : null;
    _selectedHiringGoals = _stringList(fields['hiringGoal']).take(1).toList();
    _selectedTeamSize = fields['currentTeam']?.toString();
    final budgetId = fields['projectHireBudgetId']?.toString();
    final budgetName = fields['projectHireBudget']?.toString();
    if (budgetId != null && budgetId.isNotEmpty) {
      _selectedBudgetRange = MasterOption(
        id: budgetId,
        name: budgetName?.isNotEmpty == true ? budgetName! : budgetId,
      );
    }
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
      'state': _selectedState,
      'city': _cityController.text.trim(),
      if (_detectedLatitude != null) 'latitude': _detectedLatitude,
      if (_detectedLongitude != null) 'longitude': _detectedLongitude,
      'termsAccepted': _termsAccepted,
      'companyName': _businessNameController.text.trim(),
      'companySite': _companySiteController.text.trim(),
      'companySize': _selectedCompanySize,
      'companySizeId': _selectedCompanySize,
      'currentTeam': _selectedTeamSize,
      'currentTeamId': _selectedTeamSize,
      'projectHireBudget': _selectedBudgetRange?.name,
      'projectHireBudgetId': _selectedBudgetRange?.id,
      'industry': _selectedIndustries,
      'jobRole': _selectedJobRole ?? '',
      'hiringGoal': _selectedHiringGoals,
      'hiringGoalIds': _selectedHiringGoals,
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
      role: UserRole.client,
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
    final indRes = await repo.getIndustries();
    final csRes = await repo.getCompanySizes();
    final hgRes = await repo.getHiringGoals();
    final budgetRes = await repo.getHiringBudgetOptions();
    final cRes = await repo.getCountries();
    final desigRes = await repo.getDesignations();

    if (!mounted) return;
    setState(() {
      if (indRes.isSuccess && indRes.valueOrNull!.isNotEmpty) {
        _industries = indRes.valueOrNull!.map((e) => e.name).toList();
      }
      if (csRes.isSuccess && csRes.valueOrNull!.isNotEmpty) {
        _companySizes = csRes.valueOrNull!;
      }
      if (desigRes.isSuccess && desigRes.valueOrNull!.isNotEmpty) {
        _designations = desigRes.valueOrNull!.toSet().toList();
      }
      if (hgRes.isSuccess && hgRes.valueOrNull!.isNotEmpty) {
        _hiringGoals = hgRes.valueOrNull!.toSet().toList();
      }
      if (budgetRes.isSuccess && budgetRes.valueOrNull!.isNotEmpty) {
        _budgetRanges = budgetRes.valueOrNull!;
        final selected = _selectedBudgetRange;
        if (selected != null) {
          for (final option in _budgetRanges) {
            if (option.id == selected.id || option.name == selected.name) {
              _selectedBudgetRange = option;
              break;
            }
          }
        }
      }
      if (cRes.isSuccess && cRes.valueOrNull!.isNotEmpty) {
        _countries = cRes.valueOrNull!;
      }
    });
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

  String? _businessValidationMessage() {
    final companyName = _businessNameController.text.trim();
    if (companyName.isEmpty) return 'Please enter Business / Company Name';
    if (companyName.length < 2) {
      return 'Company name must be at least 2 characters';
    }
    if (_selectedIndustries.isEmpty) return 'Please select an Industry';
    final website = _companySiteController.text.trim();
    if (website.isNotEmpty) {
      final normalized = website.contains('://') ? website : 'https://$website';
      final uri = Uri.tryParse(normalized);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty ||
          !uri.host.contains('.')) {
        return 'Please enter a valid company website';
      }
    }
    return null;
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
      final validationMessage = _businessValidationMessage();
      if (validationMessage != null) {
        showSignupTopMessage(context, validationMessage, isSuccess: false);
        return;
      }
      if (!await _submitDraft(step: 2)) return;
      await _saveProgress(3);
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (!await _submitDraft(step: 3)) return;
      await _saveProgress(4);
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      if (_selectedTeamSize == null || _selectedTeamSize!.isEmpty) {
        showSignupTopMessage(
          context,
          'Please select Current Team Size',
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
        roleTitle: 'Client / Business Owner',
        dashboardRoute: Routes.clientDashboard,
        completedSteps: const [
          'Client Account Created',
          'Business Profile Configured',
          'Designation Set',
          'Team Workspace Ready',
        ],
        onGoToDashboard: () async {
          await SignupProgressStore.clear();
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthCheckRequested());
            context.go(Routes.clientDashboard);
          }
        },
      );
    }

    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 1:
        title = 'Create Client Account';
        subtitle = 'Hire vetted experts and execute projects with confidence.';
        break;
      case 2:
        title = 'Business Details';
        subtitle = 'Tell us about your company or organization.';
        break;
      case 3:
        title = 'Profile & Role';
        subtitle = 'Specify your job role and hiring goals.';
        break;
      case 4:
        title = 'Team & Budget';
        subtitle = 'Set your current team size and estimated project budget.';
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
        continueLabel:  'Continue',
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
              controller: _businessNameController,
              label: 'Company Name *',
              hint: 'Enter your company name',
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              label: 'Industry / Sector *',
              hint: "Choose the industry your business operates in",
              selectedItems: _selectedIndustries,
              availableOptions: _industries,
              minSelection: 1,

              onChanged: (val) {
                setState(() => _selectedIndustries = val);
                _persistCurrentProgress();
              },
            ),
          
            const SizedBox(height: 16),
            AppTextField(
              controller: _companySiteController,
              label: 'Company Website Link',
              hint: 'Enter your company website (optional)',
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            AppDropdown<String>(
              label: 'Designation *',
              hint: 'What is your role in the company?',
              value: _selectedJobRole,
              items: _designations,
              itemLabel: (value) => value,
              onTap: () {
                if (_designations.isEmpty) {
                  _loadMasterData();
                }
              },
              onChanged: (val) {
                setState(() => _selectedJobRole = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              hint: "Select your primary goals on the platform",
              label: 'Primary Hiring Goal *',
              selectedItems: _selectedHiringGoals,
              availableOptions: _hiringGoals,
              minSelection: 1,

              onTap: () {
                if (_hiringGoals.isEmpty) {
                  _loadMasterData();
                }
              },
              onChanged: (items) {
                setState(() => _selectedHiringGoals = items);
                _persistCurrentProgress();
              },
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppDropdown<String>(
              label: 'Current Team Size *',
              hint: 'Select Current Team Size',
              value: _selectedTeamSize,
              items: _companySizes,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedTeamSize = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
             
            AppDropdown<MasterOption>(
              label: 'Estimated Project / Hiring Budget Range',
              hint: 'What is your budget for this project?',
              value: _selectedBudgetRange,
              items: _budgetRanges,
              itemLabel: (value) => value.name,
              onChanged: (val) {
                setState(() => _selectedBudgetRange = val);
                _persistCurrentProgress();
              },
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
