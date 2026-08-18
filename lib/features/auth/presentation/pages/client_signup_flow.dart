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
  bool _termsAccepted = false;
  bool _emailVerified = false;
  String? _registeredEmail;

  // Step 2 Business
  final _businessNameController = TextEditingController();
  final _companySiteController = TextEditingController();
  String? _selectedIndustry;
  String? _selectedCompanySize;
  String? _selectedCountry;
  String? _selectedState;

  // Step 3 Profile
  final _jobRoleController = TextEditingController();
  List<String> _selectedHiringGoals = [];

  // Step 4 Team (Optional)
  String? _selectedTeamSize;
  String? _selectedBudgetRange;

  // Dynamic API Master lists (100% Sourced from Backend APIs)
  List<String> _industries = [];
  List<String> _companySizes = [];
  List<String> _hiringGoals = [];
  List<String> _budgetRanges = [];
  List<String> _countries = [];
  List<String> _states = [];

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
    }
    for (final controller in [
      _fullNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _cityController,
      _businessNameController,
      _companySiteController,
      _jobRoleController,
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
    if (_currentStep <= 1 && _registeredEmail == null) return;
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
    final restoredIndustries = _stringList(fields['industry']);
    _selectedIndustry = restoredIndustries.isNotEmpty
        ? restoredIndustries.first
        : fields['industry']?.toString();
    _selectedCompanySize = fields['companySize']?.toString();
    _jobRoleController.text = fields['jobRole']?.toString() ?? '';
    _selectedHiringGoals = _stringList(fields['hiringGoal']);
    _selectedTeamSize = fields['currentTeam']?.toString();
    _selectedBudgetRange = fields['projectHireBudget']?.toString();
  }

  Map<String, dynamic> _fields({bool completed = false}) => {
    'step': _currentStep,
    'completed': completed,
    'fullName': _fullNameController.text.trim(),
    'email': _emailController.text.trim(),
    'password': _passwordController.text,
    'confirmPassword': _confirmPasswordController.text,
    'country': _selectedCountry,
    'state': _selectedState,
    'city': _cityController.text.trim(),
    'termsAccepted': _termsAccepted,
    'companyName': _businessNameController.text.trim(),
    'companySite': _companySiteController.text.trim(),
    'companySize': _selectedCompanySize,
    'companySizeId': _selectedCompanySize,
    'currentTeam': _selectedTeamSize,
    'currentTeamId': _selectedTeamSize,
    'projectHireBudget': _selectedBudgetRange,
    'projectHireBudgetId': _selectedBudgetRange,
    'industry': _selectedIndustry == null ? [] : [_selectedIndustry],
    'jobRole': _jobRoleController.text.trim(),
    'hiringGoal': _selectedHiringGoals,
    'hiringGoalIds': _selectedHiringGoals,
  };

  Future<bool> _registerIfNeeded() async {
    final email = _emailController.text.trim();
    if (_registeredEmail == email) return true;
    final result = await sl<AuthRepository>().signup(
      fullName: _fullNameController.text.trim(),
      email: email,
      password: _passwordController.text,
      role: UserRole.client,
      signupData: {
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _cityController.text.trim(),
      },
    );
    if (result.isFailure) {
      if (!mounted) return false;
      showSignupTopMessage(
        context,
        result.failureOrNull!.message,
        isSuccess: false,
      );
      return false;
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
    final budgetRes = await repo.getHiringBudgetRanges();
    final cRes = await repo.getCountries();

    if (!mounted) return;
    setState(() {
      if (indRes.isSuccess && indRes.valueOrNull!.isNotEmpty) {
        _industries = indRes.valueOrNull!.map((e) => e.name).toList();
      }
      if (csRes.isSuccess && csRes.valueOrNull!.isNotEmpty) {
        _companySizes = csRes.valueOrNull!;
      }
      if (hgRes.isSuccess && hgRes.valueOrNull!.isNotEmpty) {
        _hiringGoals = hgRes.valueOrNull!;
      }
      if (budgetRes.isSuccess && budgetRes.valueOrNull!.isNotEmpty) {
        _budgetRanges = budgetRes.valueOrNull!;
      }
      if (cRes.isSuccess && cRes.valueOrNull!.isNotEmpty) {
        _countries = cRes.valueOrNull!;
      }

      if (_hiringGoals.isEmpty) {
        _hiringGoals = [
          'Hire freelancers',
          'Build project team',
          'Consult experts',
          'Long-term hiring',
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
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Password and confirm password must match';
    }
    if (_selectedCountry == null) return 'Please select country';
    if (_selectedState == null) return 'Please select state';
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
      if (_businessNameController.text.isEmpty) {
        showSignupTopMessage(
          context,
          'Please enter Business / Company Name',
          isSuccess: false,
        );
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
      if (!await _submitDraft(step: 4, completed: true)) return;
      await SignupProgressStore.clear();
      setState(() => _currentStep = 5);
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else if (widget.onBackToRoleSelection != null) {
      widget.onBackToRoleSelection!();
    } else if (context.canPop()) {
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

    return SignupScaffold(
      title: title,
      subtitle: subtitle,
      currentStep: _currentStep,
      totalSteps: 5,
      onBack:
          (_currentStep > widget.initialStep) ||
              (widget.initialStep == 1 && _currentStep == 1)
          ? _onBack
          : null,
      onContinue: _onContinue,
      isLoading: _isLoading,
      continueLabel: _currentStep == 4 ? 'Skip or Continue' : 'Continue',
      child: _buildStepContent(),
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
          states: _states,
          selectedCountry: _selectedCountry,
          selectedState: _selectedState,
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
          onStateChanged: (val) {
            setState(() => _selectedState = val);
            _persistCurrentProgress();
          },
          termsAccepted: _termsAccepted,
          onTermsChanged: (val) {
            setState(() => _termsAccepted = val);
            _persistCurrentProgress();
          },
          onEmailVerificationChanged: (val) =>
              setState(() => _emailVerified = val),
          initialVerifiedEmail: _emailVerified
              ? _emailController.text.trim()
              : widget.verifiedEmail,
        );
      case 2:
        return Column(
          children: [
            AppTextField(
              controller: _businessNameController,
              label: 'Company Name *',
              hint: 'Enter Company Name',
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Industry *',
              hint: 'Select Industry',
              value: _selectedIndustry,
              items: _industries,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedIndustry = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Company Size *',
              hint: 'Select Company Size',
              value: _selectedCompanySize,
              items: _companySizes,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedCompanySize = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _companySiteController,
              label: 'Company Site Link',
              hint: 'Enter Company Site Link',
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            AppTextField(
              controller: _jobRoleController,
              label: 'Job Role',
              hint: 'Enter Job Role',
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              label: 'Hiring Goal',
              selectedItems: _selectedHiringGoals,
              availableOptions: _hiringGoals,
              minSelection: 1,
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
              label: 'Current Team Size',
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
            AppDropdown<String>(
              label: 'Project / Hiring Budget Range',
              hint: 'Select Project / Hiring Budget Range',
              value: _selectedBudgetRange,
              items: _budgetRanges,
              itemLabel: (value) => value,
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
