import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../utils/signup_progress_store.dart';
import '../widgets/signup_account_step.dart';
import '../widgets/signup_multi_select_sheet.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_success_view.dart';
import '../widgets/signup_top_message.dart';

class InvestorSignupFlow extends StatefulWidget {
  final VoidCallback? onBackToRoleSelection;
  final int initialStep;
  final String? verifiedEmail;
  const InvestorSignupFlow({
    super.key,
    this.onBackToRoleSelection,
    this.initialStep = 1,
    this.verifiedEmail,
  });

  @override
  State<InvestorSignupFlow> createState() => _InvestorSignupFlowState();
}

class _InvestorSignupFlowState extends State<InvestorSignupFlow> {
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
  bool _termsAccepted = false;
  bool _emailVerified = false;
  String? _registeredEmail;

  // Step 2 Profile
  String? _selectedInvestorType;
  String? _selectedCountry;
  String? _selectedState;
  final _firmNameController = TextEditingController();
  String? _selectedAccreditedStatus;

  // Step 3 Preferences
  List<String> _preferredIndustries = [];
  String? _selectedStage;
  final _minCheckSizeController = TextEditingController();
  final _maxCheckSizeController = TextEditingController();

  // Dynamic API Master lists (100% Sourced from Backend APIs)
  List<String> _investorTypes = [];
  List<String> _accreditedStatuses = [];
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _industries = [];
  List<String> _stages = [];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(1, 3).toInt();
    if (widget.verifiedEmail != null && widget.verifiedEmail!.isNotEmpty) {
      _emailController.text = widget.verifiedEmail!;
      _emailVerified = true;
    }
    final progress = SignupProgressStore.read();
    if (progress?.role == UserRole.investor) {
      _registeredEmail = progress!.registeredEmail;
      _restoreFields(progress.fields);
      if (progress.step >= 1) {
        _currentStep = progress.step.clamp(1, 3).toInt();
      }
    }
    _populateFromAuthState();
    for (final controller in [
      _fullNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _cityController,
      _firmNameController,
      _minCheckSizeController,
      _maxCheckSizeController,
    ]) {
      controller.addListener(_persistCurrentProgress);
    }
    _loadMasterData();
  }

  Future<void> _saveProgress(int step) {
    return SignupProgressStore.save(
      role: UserRole.investor,
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
    _selectedInvestorType = fields['investorType']?.toString();
    _firmNameController.text = fields['firm']?.toString() ?? '';
    _selectedAccreditedStatus = fields['isAccredited']?.toString();
    _minCheckSizeController.text = fields['ticketMin']?.toString() ?? '';
    _maxCheckSizeController.text = fields['ticketMax']?.toString() ?? '';
    final rawPreferredStage = fields['preferredStage'];
    final restoredStages = _stringList(
      rawPreferredStage,
    ).map((stage) => stage.trim()).where((stage) => stage.isNotEmpty).toList();
    if (restoredStages.isNotEmpty) {
      _selectedStage = restoredStages.first;
    } else if (rawPreferredStage is String) {
      final stage = rawPreferredStage.trim();
      _selectedStage = stage.isEmpty || stage == '[]' || stage == 'null'
          ? null
          : stage;
    } else {
      _selectedStage = null;
    }
    _preferredIndustries = _stringList(fields['preferredSectors']);
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
      'termsAccepted': _termsAccepted,
      'investorType': _selectedInvestorType,
      'firm': _firmNameController.text.trim(),
      'isAccredited': _selectedAccreditedStatus,
      'ticketMin': num.tryParse(_minCheckSizeController.text.trim()),
      'ticketMax': num.tryParse(_maxCheckSizeController.text.trim()),
      'preferredStage': _selectedStage == null ? [] : [_selectedStage],
      'focusAreas': _preferredIndustries,
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
    final pwd = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : 'Pass@123456';
    final result = await sl<AuthRepository>().signup(
      fullName: _fullNameController.text.trim(),
      email: email,
      password: pwd,
      role: UserRole.investor,
      isSocialLogin: isSocial,
      signupData: {
        'isSocialLogin': isSocial,
        'isSocial': isSocial,
        'country': _selectedCountry,
        // 'state': _selectedState,
        'city': _cityController.text.trim(),
      },
    );
    if (result.isFailure) {
      final code = result.failureOrNull?.code;
      final msg = result.failureOrNull?.message.toLowerCase() ?? '';
      if (code == 'EMAIL_ALREADY_EXISTS' ||
          msg.contains('already registered') ||
          msg.contains('already exists')) {
        _registeredEmail = email;
        return true;
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
    final typeRes = await repo.getInvestorTypes();
    final accRes = await repo.getAccreditedStatuses();
    final cRes = await repo.getCountries();
    final stRes = await repo.getInvestorStages();

    if (!mounted) return;
    setState(() {
      if (indRes.isSuccess && indRes.valueOrNull!.isNotEmpty) {
        _industries = indRes.valueOrNull!.map((e) => e.name).toList();
      }
      if (typeRes.isSuccess && typeRes.valueOrNull!.isNotEmpty) {
        _investorTypes = typeRes.valueOrNull!;
      }
      if (accRes.isSuccess && accRes.valueOrNull!.isNotEmpty) {
        _accreditedStatuses = accRes.valueOrNull!;
      }
      if (cRes.isSuccess && cRes.valueOrNull!.isNotEmpty) {
        _countries = cRes.valueOrNull!;
      }
      if (stRes.isSuccess && stRes.valueOrNull!.isNotEmpty) {
        _stages = stRes.valueOrNull!;
        if (_selectedStage != null && !_stages.contains(_selectedStage)) {
          _selectedStage = null;
        }
      }
      if (_investorTypes.isEmpty) {
        _investorTypes = ['Angel Investor', 'VC', 'Family Office', 'Syndicate'];
      }
      if (_accreditedStatuses.isEmpty) {
        _accreditedStatuses = [
          'Yes, I am accredited',
          'No, I am not accredited',
        ];
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
      if (!await _submitDraft(step: 2)) return;
      await _saveProgress(3);
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_preferredIndustries.isEmpty) {
        showSignupTopMessage(
          context,
          'Please select a preferred industry',
          isSuccess: false,
        );
        return;
      }
      if (!await _submitDraft(step: 4, completed: true)) return;
      await SignupProgressStore.clear();
      setState(() => _currentStep = 4);
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
    if (_currentStep == 4) {
      SignupProgressStore.clear();
      return SignupSuccessView(
        roleTitle: 'Investor',
        dashboardRoute: Routes.investorDashboard,
        completedSteps: const [
          'Investor Account Registered',
          'Investor Profile Configured',
          'Investment Preferences & Ticket Ranges Set',
        ],
        onGoToDashboard: () async {
          await SignupProgressStore.clear();
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthCheckRequested());
            context.go(Routes.investorDashboard);
          }
        },
      );
    }

    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 1:
        title = 'Create Investor Account';
        subtitle =
            'Discover high-potential startups and promising investment deals.';
        break;
      case 2:
        title = 'Investor Profile';
        subtitle = 'Specify your designation and organization details.';
        break;
      case 3:
        title = 'Investment Preferences';
        subtitle = 'Select your target industries, stage, and ticket size.';
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
        totalSteps: 4,
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
          initialVerifiedEmail: widget.verifiedEmail,
          isSocialLogin:
              context.read<AuthBloc>().state.user?.isSocialLogin ?? false,
        );
      case 2:
        return Column(
          children: [
            AppDropdown<String>(
              label: 'Investor Type *',
              hint: 'Select Investor Type',
              value: _selectedInvestorType,
              items: _investorTypes,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedInvestorType = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _firmNameController,
              label: 'Firm / Entity Name (Optional)',
              hint: 'Enter Firm / Entity Name',
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Accredited Investor Status *',
              hint: 'Select Accredited Investor Status',
              value: _selectedAccreditedStatus,
              items: _accreditedStatuses,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedAccreditedStatus = val);
                _persistCurrentProgress();
              },
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            SignupMultiSelectSheet(
              label: 'Focus Industry / Sector *',
              selectedItems: _preferredIndustries,
              availableOptions: _industries,
              minSelection: 1,
              onChanged: (val) {
                setState(() => _preferredIndustries = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _minCheckSizeController,
              keyboardType: TextInputType.number,
              label: 'Min Check Size (₹)',
              hint: 'Enter Min Check Size',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _maxCheckSizeController,
              keyboardType: TextInputType.number,
              label: 'Max Check Size (₹)',
              hint: 'Enter Max Check Size',
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Preferred Investment Stage *',
              hint: 'Select Preferred Investment Stage',
              value: _selectedStage,
              items: _stages,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedStage = val);
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
