import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
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
  String? _selectedIndustry;
  List<String> _selectedSkills = [];

  // Step 4 Experience
  String? _experienceLevel;
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
    }
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
    if (_currentStep <= 1 && _registeredEmail == null) return;
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
    final restoredIndustries = _stringList(fields['industry']);
    _selectedIndustry = restoredIndustries.isNotEmpty
        ? restoredIndustries.first
        : fields['industry']?.toString();
    _selectedSkills = _stringList(fields['skills']);
    _selectedWorkModes = _stringList(fields['workMode']);
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
    'titleHeadline': _headlineController.text.trim(),
    'bio': _bioController.text.trim(),
    'experienceLevel': _experienceLevel,
    'hourlyRate': double.tryParse(_hourlyRateController.text.trim()),
    'portfolioUrl': _portfolioController.text.trim(),
    'linkedInUrl': _linkedinController.text.trim(),
    'githubUrl': _githubController.text.trim(),
    'industry': _selectedIndustry == null ? [] : [_selectedIndustry],
    'skills': _selectedSkills.map((name) {
      final option = _skillsMap[name];
      final skillId =
          option?.id ??
          'static_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      return {'id': skillId, 'value': name, 'name': name};
    }).toList(),
    'workMode': _selectedWorkModes,
  };

  Future<bool> _registerIfNeeded() async {
    final email = _emailController.text.trim();
    if (_registeredEmail == email) return true;
    final result = await sl<AuthRepository>().signup(
      fullName: _fullNameController.text.trim(),
      email: email,
      password: _passwordController.text,
      role: UserRole.freelancer,
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

  Future<List<SkillOption>> _fetchSkillsApi({String? query}) async {
    String? industryId;
    if (_selectedIndustry != null && _availableIndustries.isNotEmpty) {
      final match = _availableIndustries.firstWhere(
        (ind) => ind.name == _selectedIndustry,
        orElse: () => const SkillCategory(id: '', name: ''),
      );
      if (match.id.isNotEmpty) {
        industryId = match.id;
      }
    }

    try {
      final res = await sl<ApiClientHelper>().getEnvelope<List<SkillOption>>(
        ApiEndpoints.publicSkills,
        query: {
          if (industryId != null && industryId.isNotEmpty)
            'industryId': industryId,
          'page': 1,
          'limit': 50,
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
      if (!await _submitDraft(step: 2)) return;
      await _saveProgress(3);
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_selectedIndustry == null) {
        showSignupTopMessage(
          context,
          'Please select an Industry',
          isSuccess: false,
        );
        return;
      }
      if (!await _submitDraft(step: 3)) return;
      await _saveProgress(4);
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      final hourlyRate = _hourlyRateController.text.trim();
      if (hourlyRate.isEmpty) {
        showSignupTopMessage(
          context,
          'Please enter hourly rate amount',
          isSuccess: false,
        );
        return;
      }
      if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(hourlyRate)) {
        showSignupTopMessage(
          context,
          'Hourly rate can contain up to 2 decimals',
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
        roleTitle: 'Freelancer',
        dashboardRoute: Routes.freelancerDashboard,
        completedSteps: const [
          'Account Registered',
          'Professional Profile Created',
          'Skills & Technologies Added',
          'Experience Level Configured',
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
        title = 'Professional Profile';
        subtitle = 'Tell clients about your expertise and background.';
        break;
      case 3:
        title = 'Skills & Technologies';
        subtitle = 'Select your core technical and professional skills.';
        break;
      case 4:
        title = 'Experience & Level';
        subtitle =
            'Specify your overall experience range and work preferences.';
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
              controller: _headlineController,
              label: 'Professional Title *',
              hint: 'Enter Professional Title',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _bioController,
              maxLines: 3,
              label: 'Brief Bio',
              hint: 'Enter Brief Bio',
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            AppDropdown<String>(
              label: 'Industry *',
              hint: 'Select Industry',
              value: _selectedIndustry,
              items: _industries,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _selectedIndustry = val);
                _persistCurrentProgress();
                _fetchSkillsApi().then((skills) {
                  if (!mounted) return;
                  setState(() {
                    for (final s in skills) {
                      _skillsMap[s.name] = s;
                    }
                    _availableSkillNames = skills.map((s) => s.name).toList();
                  });
                });
              },
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              label: 'Skills',
              selectedItems: _selectedSkills,
              availableOptions: _availableSkillNames.isNotEmpty
                  ? _availableSkillNames
                  : const [
                      'React.js',
                      'Node.js',
                      'Flutter',
                      'TypeScript',
                      'Python',
                      'Go',
                      'AWS',
                      'UI/UX Design',
                      'SQL',
                      '.NET',
                      'Java',
                      'C#',
                    ],
              minSelection: 0,
              onSearchApi: _searchSkillsApi,
              onChanged: (items) {
                setState(() => _selectedSkills = items);
                _persistCurrentProgress();
              },
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            AppDropdown<String>(
              label: 'Experience Year *',
              hint: 'Select Experience Year',
              value: _experienceLevel,
              items: _expLevels,
              itemLabel: (value) => value,
              onChanged: (val) {
                setState(() => _experienceLevel = val);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            SignupMultiSelectSheet(
              label: 'Preferred Work Mode',
              selectedItems: _selectedWorkModes,
              availableOptions: _workModes,
              minSelection: 1,
              onChanged: (items) {
                setState(() => _selectedWorkModes = items);
                _persistCurrentProgress();
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _hourlyRateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              label: 'Hourly Rate Amount *',
              hint: 'Enter Hourly Rate Amount',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _portfolioController,
              label: 'Portfolio Link',
              hint: 'Enter Portfolio Link',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _githubController,
              label: 'Github Link',
              hint: 'Enter Github Link',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _linkedinController,
              label: 'LinkedIn Link',
              hint: 'Enter LinkedIn Link',
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
