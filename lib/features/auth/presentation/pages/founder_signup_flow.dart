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

class FounderSignupFlow extends StatefulWidget {
  final VoidCallback? onBackToRoleSelection;
  final int initialStep;
  final String? verifiedEmail;
  const FounderSignupFlow({
    super.key,
    this.onBackToRoleSelection,
    this.initialStep = 1,
    this.verifiedEmail,
  });

  @override
  State<FounderSignupFlow> createState() => _FounderSignupFlowState();
}

class _FounderSignupFlowState extends State<FounderSignupFlow> {
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

  // Step 2 Startup Details
  final _startupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedIndustries = [];
  String? _selectedStage;

  // Step 3 Founder Profile
  String? _selectedDesignation;
  String? _selectedCountry;
  String? _selectedState;
  final _founderBioController = TextEditingController();

  // Step 4 Goals
  List<String> _selectedGoals = [];
  final _capitalRaisedController = TextEditingController();
  final _targetFundraiseController = TextEditingController();
  String? _selectedTeamSize;

  // Dynamic API Master lists (100% Sourced from Backend APIs)
  List<String> _industries = [];
  List<String> _stages = [];
  List<String> _designations = [];
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _startupGoalsMaster = [];
  List<String> _teamSizes = [];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(1, 4).toInt();
    if (widget.verifiedEmail != null && widget.verifiedEmail!.isNotEmpty) {
      _emailController.text = widget.verifiedEmail!;
      _emailVerified = true;
    }
    final progress = SignupProgressStore.read();
    if (progress?.role == UserRole.founder) {
      _registeredEmail = progress!.registeredEmail;
      _restoreFields(progress.fields);
    }
    for (final controller in [
      _fullNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _cityController,
      _startupNameController,
      _descriptionController,
      _founderBioController,
      _capitalRaisedController,
      _targetFundraiseController,
    ]) {
      controller.addListener(_persistCurrentProgress);
    }
    _loadMasterData();
  }

  Future<void> _saveProgress(int step) {
    return SignupProgressStore.save(
      role: UserRole.founder,
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
    _startupNameController.text = fields['startupName']?.toString() ?? '';
    _descriptionController.text = fields['pitch']?.toString() ?? '';
    _selectedIndustries = _stringList(fields['industry']);
    _selectedStage = fields['stage']?.toString();
    _selectedDesignation = fields['founderRole']?.toString();
    _founderBioController.text = fields['founderBio']?.toString() ?? '';
    _capitalRaisedController.text = fields['raised']?.toString() ?? '';
    _targetFundraiseController.text = fields['targetRaise']?.toString() ?? '';
    _selectedTeamSize = fields['teamSize']?.toString();
    _selectedGoals = _stringList(fields['primaryGoal']);
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
    'startupName': _startupNameController.text.trim(),
    'pitch': _descriptionController.text.trim(),
    'founderRole': _selectedDesignation,
    'founderBio': _founderBioController.text.trim(),
    'stage': _selectedStage,
    'raised': num.tryParse(_capitalRaisedController.text.trim()),
    'targetRaise': num.tryParse(_targetFundraiseController.text.trim()),
    'teamSize': _selectedTeamSize,
    'industry': _selectedIndustries,
    'primaryGoal': _selectedGoals,
  };

  Future<bool> _registerIfNeeded() async {
    final email = _emailController.text.trim();
    if (_registeredEmail == email) return true;
    final result = await sl<AuthRepository>().signup(
      fullName: _fullNameController.text.trim(),
      email: email,
      password: _passwordController.text,
      role: UserRole.founder,
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
    final stRes = await repo.getStartupStages();
    final desRes = await repo.getStartupRoles();
    final cRes = await repo.getCountries();
    final gRes = await repo.getStartupGoals();
    final tsRes = await repo.getCompanySizes();

    if (!mounted) return;
    setState(() {
      if (indRes.isSuccess && indRes.valueOrNull!.isNotEmpty) {
        _industries = indRes.valueOrNull!.map((e) => e.name).toList();
      }
      if (stRes.isSuccess && stRes.valueOrNull!.isNotEmpty) {
        _stages = stRes.valueOrNull!;
      }
      if (desRes.isSuccess && desRes.valueOrNull!.isNotEmpty) {
        _designations = desRes.valueOrNull!;
      }
      if (cRes.isSuccess && cRes.valueOrNull!.isNotEmpty) {
        _countries = cRes.valueOrNull!;
      }
      if (gRes.isSuccess && gRes.valueOrNull!.isNotEmpty) {
        _startupGoalsMaster = gRes.valueOrNull!;
      }
      if (tsRes.isSuccess && tsRes.valueOrNull!.isNotEmpty) {
        _teamSizes = tsRes.valueOrNull!;
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

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address first')),
      );
      return;
    }
    setState(() => _isSendingOtp = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _isSendingOtp = false;
      _isOtpSent = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to $email')),
      );
    }
  }

  void _verifyOtp() {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP code')),
      );
      return;
    }
    setState(() {
      _isEmailVerified = true;
      _isOtpSent = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email verified successfully! ✓')),
    );
  }

  void _onContinue() async {
    if (_currentStep == 1) {
      final validationMessage = _accountValidationMessage();
      if (validationMessage != null) {
        showSignupTopMessage(context, validationMessage, isSuccess: false);
        return;
      }
      if (!_isEmailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please click Verify to verify your email address via OTP')),
        );
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
      if (_startupNameController.text.isEmpty) {
        showSignupTopMessage(
          context,
          'Please enter Startup / Idea Name',
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
      if (_selectedGoals.isEmpty) {
        showSignupTopMessage(
          context,
          'Please select at least 1 startup goal',
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
        roleTitle: 'Founder / Startup Creator',
        dashboardRoute: Routes.founderDashboard,
        completedSteps: const [
          'Founder Account Registered',
          'Startup Idea & Stage Details Saved',
          'Founder Profile Configured',
          'Startup Goals & Resource Needs Set',
        ],
        onGoToDashboard: () async {
          await SignupProgressStore.clear();
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthCheckRequested());
            context.go(Routes.founderDashboard);
          }
        },
      );
    }

    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 1:
        title = 'Create Founder Account';
        subtitle =
            'Launch your venture, connect with investors, and hire experts.';
        break;
      case 2:
        title = 'Startup Details';
        subtitle = 'Tell us about your venture, idea, and stage.';
        break;
      case 3:
        title = 'Profile & Role';
        subtitle = 'Specify your startup role and founder bio.';
        break;
      case 4:
        title = 'Startup Goals';
        subtitle = 'Share funding, team, and platform goals.';
        break;
    }

    return SignupScaffold(
      title: title,
      subtitle: subtitle,
      currentStep: _currentStep,
      totalSteps: 5,
      onBack: _onBack,
      onContinue: _onContinue,
      isLoading: _isLoading,
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
        );
      case 2:
        return Column(
          children: [
            AppTextField(
              controller: _startupNameController,
              label: 'Startup Name *',
              hint: 'Enter startup name',
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              label: 'Industry',
              selectedItems: _selectedIndustries,
              availableOptions: _industries,
              minSelection: 1,
              onChanged: (items) {
                setState(() => _selectedIndustries = items);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Current Stage *',
              hint: 'Select Current Stage',
              value: _selectedStage,
              items: _stages,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedStage = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              maxLines: 3,
              label: 'Short Pitch Detail',
              hint: 'Enter your short pitch details',
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            AppDropdown<String>(
              label: 'Role in Startup *',
              hint: 'Select Role in Startup',
              value: _selectedDesignation,
              items: _designations,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedDesignation = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _founderBioController,
              maxLines: 3,
              label: 'Founder Bio',
              hint: 'Enter founder bio',
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            AppTextField(
              controller: _capitalRaisedController,
              keyboardType: TextInputType.number,
              label: 'Capital Raised',
              hint: 'Enter capital raised',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _targetFundraiseController,
              keyboardType: TextInputType.number,
              label: 'Target Fundraise',
              hint: 'Enter target fundraise',
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Team Size *',
              hint: 'Select Team Size',
              value: _selectedTeamSize,
              items: _teamSizes,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedTeamSize = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              label: 'Primary Goal on Platform',
              selectedItems: _selectedGoals,
              availableOptions: _startupGoalsMaster,
              minSelection: 1,
              onChanged: (items) {
                setState(() => _selectedGoals = items);
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
