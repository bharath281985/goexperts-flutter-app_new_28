import 'package:country_code_picker/country_code_picker.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/phone_validation.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_file_upload.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/services/google_places_service.dart';
import '../bloc/auth_bloc.dart';

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
  final _certifications = TextEditingController();
  final _education = TextEditingController();
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
  String? _category;
  String _plan = 'Freelancer Annual';
  String? _businessType;
  String? _teamSize;
  String? _primaryService;
  String? _primarySubService;
  String? _clientProjectCategory;
  String? _clientProjectSubcategory;
  String? _remoteType;
  String? _urgency;
  String? _lookingForGoal;
  String? _expansionGoal;
  String? _investorType;
  String? _stagePreference;
  String? _investmentMode;
  String? _targetIndustry;
  String? _investorIntent;
  String? _founderType;
  String? _startupStage;
  String? _founderCategory;
  String? _founderSubCategory;
  String? _founderGoal;
  String? _profilePhotoName;
  ImageProvider? _profilePhotoPreview;
  String? _portfolioDocName;
  String? _verificationDocName;
  bool _agree = false;
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  List<String> _industryOptions = _categories;
  List<String> _businessTypeOptions = _businessTypes;
  List<_CountryOption> _countryOptions = const [];
  List<String> _founderTypeOptions = _founderTypes;
  List<String> _startupStageOptions = _startupStages;
  List<String> _investorTypeOptions = _investorTypes;
  final List<String> _stagePreferenceOptions = _stagePreferences;
  final List<String> _targetIndustryOptions = _targetIndustries;

  static const _categories = [
    'Agriculture',
    'Design & Creative',
    'Development & IT',
    'Finance & Accounting',
    'Marketing',
    'Writing & Translation',
  ];
  static const _skillSuggestions = [
    'AWS Services',
    'TypeScript',
    'Django',
    'DevOps',
    'Data Science',
    'Go Lang',
    'PostgreSQL',
    'MongoDB',
    'Blockchain',
    'React',
    'UI/UX Design',
    'GraphQL',
    'Laravel',
    'Flutter',
    'Machine Learning',
    'Node.js',
    'Angular',
    'Python',
    'Docker',
    'Swift',
    'Kubernetes',
    'Vue.js',
    'Redis',
    'Kotlin',
    'Terraform',
  ];
  static const _plans = [
    _PlanOption('Freelancer Annual', '₹5,999/yr'),
    _PlanOption('Freelancer Pro', '₹799/mo'),
    _PlanOption('Freelancer Starter', '₹299/mo'),
    _PlanOption('Freelancer Elite', '₹1,499/mo'),
  ];
  static const _businessTypes = [
    'Individual Client',
    'Small Business',
    'Startup',
    'Agency',
    'Enterprise',
    'Shop Owner',
    'Service Provider',
    'Manufacturer',
    'Franchise Owner',
  ];
  static const _teamSizes = ['1-10', '11-50', '51-200', '201-500', '500+'];
  static const Map<String, List<String>> _clientProjectCategories = {
    'Website & App Development': [
      'Business Website',
      'E-commerce Website',
      'Custom Website',
      'Mobile App',
      'iOS App',
      'Android App',
      'Hybrid App',
      'Landing Page',
    ],
    'Design & Branding': [
      'Logo Design',
      'Brand Identity',
      'UI/UX Design',
      'Graphic Design',
      'Packaging Design',
      'Social Media Creatives',
    ],
    'Digital Marketing': [
      'SEO',
      'Social Media Marketing',
      'Google Ads',
      'Meta Ads',
      'Email Marketing',
      'Influencer Marketing',
    ],
    'Business & Finance': [
      'Business Plan',
      'Financial Modeling',
      'Accounting',
      'Tax Consulting',
      'Legal Documentation',
      'Market Research',
    ],
    'Technology Services': [
      'Cloud Services',
      'DevOps',
      'Cybersecurity',
      'AI / ML',
      'Data Analytics',
      'ERP / CRM',
    ],
    'Content & Media': [
      'Blog Writing',
      'Website Content',
      'Technical Writing',
      'Video Editing',
      'Promotional Videos',
      'Explainer Videos',
    ],
  };
  static const _lookingForOptions = [
    'Hire Freelancer',
    'Post a Project',
    'Hire Agency',
    'Get Business Consultation',
    'Build Website / App',
    'Marketing Support',
    'Design Services',
    'Long-Term Team',
    'One-Time Service',
    'Monthly Maintenance',
  ];
  static const _expansionOptions = [
    'Find Distributors',
    'Find Suppliers',
    'Find Business Partners',
    'Seek Investors',
    'Open Franchise',
    'Cross-border Expansion',
  ];
  static const _remoteTypes = ['Remote', 'On-site', 'Hybrid'];
  static const _urgencies = [
    'High (Immediate)',
    'Medium (Within a month)',
    'Low (Flexible)',
  ];
  static const _investorTypes = [
    'Angel',
    'Individual',
    'Family office',
    'VC',
    'Corporate',
    'PE',
    'Incubator/Accelerator',
    'NRI Investor',
  ];
  static const _stagePreferences = [
    'Idea',
    'MVP',
    'Seed',
    'Early Revenue',
    'Growth',
    'Pre-IPO',
  ];
  static const _investmentModes = [
    'Equity',
    'Debt',
    'Convertible Note',
    'SAFE',
    'Partnership/JV',
    'Grants',
  ];
  static const _targetIndustries = [
    'Technology Startups',
    'AI & SaaS',
    'E-commerce',
    'Fintech',
    'HealthTech',
    'EdTech',
    'Real Estate',
    'Manufacturing',
    'Food & Beverage',
    'Local Services',
    'Franchise Business',
    'Green Energy',
    'Logistics',
    'Agriculture',
    'Retail Business',
  ];
  static const _investorIntents = [
    'Invest in Startups',
    'Discover Business Ideas',
    'Fund Existing Businesses',
    'Partner with Founders',
    'Mentor Startups',
    'Buy Equity Stake',
    'Explore Franchise Opportunities',
  ];
  static const _founderTypes = [
    'Idea Creator',
    'Solo Founder',
    'Co-Founder',
    'Startup Team',
    'Existing Business Founder',
    'Student Founder',
    'Tech Founder',
    'Non-Tech Founder',
  ];
  static const _startupStages = [
    'Idea Stage',
    'Prototype',
    'MVP Ready',
    'Launched',
    'Revenue Generating',
    'Scaling',
    'Looking for Funding',
  ];
  static const _founderCategories = [
    'Technology',
    'E-commerce',
    'Services',
    'Fintech',
    'Education',
    'Healthcare',
    'Real Estate',
    'Food & Beverage',
  ];
  static const _founderSubCategories = [
    'SaaS',
    'AI Tools',
    'Mobile App',
    'Web Platform',
    'Marketplace',
    'Cloud Software',
    'Cybersecurity',
    'Automation',
  ];
  static const _founderGoals = [
    'Looking for Investor',
    'Looking for Co-Founder',
    'Looking for Mentor',
    'Looking for Developer',
    'Looking for Marketing Support',
    'Looking for Business Partner',
    'Looking for Clients',
    'Looking for Franchise Partners',
    'Looking for Funding + Tech Support',
  ];

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
        'Business Details',
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
    _certifications.dispose();
    _education.dispose();
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
      _phone.text = PhoneValidation.trimToRequiredLength(
        _phone.text,
        _countryIsoCode,
      );
    });
    _formKey.currentState?.validate();
  }

  void _setCountryOption(_CountryOption country) {
    setState(() {
      _country.text = country.name;
      _countryName = country.name;
      if (country.code.isNotEmpty) _countryIsoCode = country.code;
      if (country.phoneCode.isNotEmpty) _countryCode = country.phoneCode;
      _phone.text = PhoneValidation.trimToRequiredLength(
        _phone.text,
        _countryIsoCode,
      );
    });
    _formKey.currentState?.validate();
  }

  Future<void> _loadPublicSignupOptions() async {
    await Future.wait([
      _loadPublicStringOptions(
        ApiEndpoints.publicIndustries,
        (item) => item['name']?.toString(),
        (items) => _industryOptions = items,
      ),
      _loadPublicStringOptions(
        ApiEndpoints.publicBusinessTypes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _businessTypeOptions = items,
      ),
      _loadCountries(),
      _loadPublicStringOptions(
        ApiEndpoints.publicFounderTypes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _founderTypeOptions = items,
      ),
      _loadPublicStringOptions(
        ApiEndpoints.publicStartupStages,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _startupStageOptions = items,
      ),
      _loadPublicStringOptions(
        ApiEndpoints.publicInvestorTypes,
        (item) => item['value']?.toString() ?? item['label']?.toString(),
        (items) => _investorTypeOptions = items,
      ),
    ]);
    if (mounted) setState(() {});
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
      final items = raw
          .whereType<Map>()
          .where((item) => item['status'] == null || item['status'] == 'active')
          .map((item) => labelOf(Map<String, dynamic>.from(item))?.trim())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
      if (items.isNotEmpty) apply(items);
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
        '${AppConfig.baseUrl}${ApiEndpoints.sendEmailVerification}',
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
        '${AppConfig.baseUrl}${ApiEndpoints.verifyEmailVerification}',
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
        if (_category == null || _category!.trim().isEmpty) {
          context.showSnack('Please choose a category', isError: true);
          return false;
        }
        return true;
      case 'Skills & Experience':
        if (_skills.text.trim().isEmpty) {
          context.showSnack('Please enter top skills', isError: true);
          return false;
        }
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
      case 'Business type':
        if (_businessType == null || _businessType!.trim().isEmpty) {
          context.showSnack('Please choose business type', isError: true);
          return false;
        }
        return true;
      case 'Services & Requirements':
        if (_primaryService == null || _primaryService!.trim().isEmpty) {
          context.showSnack('Please choose primary service', isError: true);
          return false;
        }
        if (_primarySubService == null || _primarySubService!.trim().isEmpty) {
          context.showSnack('Please choose sub-service', isError: true);
          return false;
        }
        return true;
      case 'Looking For':
        if (_lookingForGoal == null || _lookingForGoal!.trim().isEmpty) {
          context.showSnack('Please choose your goal', isError: true);
          return false;
        }
        return true;
      case 'Expansion':
        if (_expansionGoal == null || _expansionGoal!.trim().isEmpty) {
          context.showSnack('Please choose expansion goal', isError: true);
          return false;
        }
        return true;
      case 'Verification':
        if (_role == UserRole.investor || _role == UserRole.founder) {
          if (!_isEmailVerified) {
            context.showSnack(
              'Please verify your email address',
              isError: true,
            );
            return false;
          }
          return true;
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

  void _submit(AuthState state) {
    if (state.isSubmitting || _role == null) return;
    context.read<AuthBloc>().add(
      AuthSignupDraftSaved(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        countryCode: _countryCode,
        password: _password.text,
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

  Future<void> _pickPortfolioDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() => _portfolioDocName = file.name);
  }

  Future<void> _pickVerificationDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
    );
    final file = result?.files.single;
    if (file == null || !mounted) return;
    setState(() => _verificationDocName = file.name);
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
                              isSubmitting: state.isSubmitting,
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
          onSelected: (role) => setState(() => _role = role),
        );
      case 'Account':
        if (_role == UserRole.investor) {
          return _BasicRoleAccountStep(
            formKey: _formKey,
            name: _name,
            email: _email,
            phone: _phone,
            password: _password,
            confirm: _confirm,
            country: _country,
            countryOptions: _countryOptions,
            stateLocation: _stateLocation,
            city: _city,
            countryIsoCode: _countryIsoCode,
            onCountryChanged: _setCountryCode,
            onCountrySelected: _setCountryOption,
            onCountryPlaceSelected: (place) =>
                _keepPlaceNameOnly(_country, place),
            onStatePlaceSelected: (place) =>
                _keepPlaceNameOnly(_stateLocation, place),
            onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
            onEmailChanged: (_) {
              if (_isEmailVerified) setState(() => _isEmailVerified = false);
            },
            validatePhone: _validatePhone,
          );
        }
        if (_role == UserRole.founder) {
          return _FounderAccountStep(
            formKey: _formKey,
            name: _name,
            email: _email,
            phone: _phone,
            password: _password,
            confirm: _confirm,
            founderType: _founderType,
            founderTypeOptions: _founderTypeOptions,
            country: _country,
            countryOptions: _countryOptions,
            stateLocation: _stateLocation,
            city: _city,
            countryIsoCode: _countryIsoCode,
            onCountryChanged: _setCountryCode,
            onCountrySelected: _setCountryOption,
            onFounderTypeChanged: (value) =>
                setState(() => _founderType = value),
            onCountryPlaceSelected: (place) =>
                _keepPlaceNameOnly(_country, place),
            onStatePlaceSelected: (place) =>
                _keepPlaceNameOnly(_stateLocation, place),
            onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
            onEmailChanged: (_) {
              if (_isEmailVerified) setState(() => _isEmailVerified = false);
            },
            validatePhone: _validatePhone,
          );
        }
        if (_role == UserRole.client) {
          return _ClientAccountStep(
            formKey: _formKey,
            name: _name,
            email: _email,
            phone: _phone,
            password: _password,
            confirm: _confirm,
            businessName: _businessName,
            country: _country,
            countryOptions: _countryOptions,
            stateLocation: _stateLocation,
            city: _city,
            countryIsoCode: _countryIsoCode,
            onCountryChanged: _setCountryCode,
            onCountrySelected: _setCountryOption,
            onCountryPlaceSelected: (place) =>
                _keepPlaceNameOnly(_country, place),
            onStatePlaceSelected: (place) =>
                _keepPlaceNameOnly(_stateLocation, place),
            onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
            onEmailChanged: (_) {
              if (_isEmailVerified) setState(() => _isEmailVerified = false);
            },
            validatePhone: _validatePhone,
          );
        }
        return _AccountStep(
          formKey: _formKey,
          name: _name,
          email: _email,
          phone: _phone,
          password: _password,
          confirm: _confirm,
          country: _country,
          countryOptions: _countryOptions,
          stateLocation: _stateLocation,
          city: _city,
          countryIsoCode: _countryIsoCode,
          onCountryChanged: _setCountryCode,
          onCountrySelected: _setCountryOption,
          onCountryPlaceSelected: (place) =>
              _keepPlaceNameOnly(_country, place),
          onStatePlaceSelected: (place) =>
              _keepPlaceNameOnly(_stateLocation, place),
          onCityPlaceSelected: (place) => _keepPlaceNameOnly(_city, place),
          onEmailChanged: (_) {
            if (_isEmailVerified) setState(() => _isEmailVerified = false);
          },
          validatePhone: _validatePhone,
        );
      case 'Category':
        return _CategoryStep(
          category: _category,
          categories: _industryOptions,
          onChanged: (value) => setState(() => _category = value),
        );
      case 'Skills & Experience':
        return _SkillsStep(
          skills: _skills,
          experience: _experience,
          bio: _bio,
          selectedSkills: _selectedSkills,
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
            minTicket: _minTicket,
            maxTicket: _maxTicket,
            stagePreference: _stagePreference,
            investmentMode: _investmentMode,
            targetIndustry: _targetIndustry,
            stageOptions: _stagePreferenceOptions,
            industryOptions: _targetIndustryOptions,
            onPickProfilePhoto: _openProfilePhotoPicker,
            onStageChanged: (value) => setState(() => _stagePreference = value),
            onModeChanged: (value) => setState(() => _investmentMode = value),
            onIndustryChanged: (value) =>
                setState(() => _targetIndustry = value),
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
            onPickProfilePhoto: _openProfilePhotoPicker,
            onTeamSizeChanged: (value) => setState(() => _teamSize = value),
          );
        }
        if (_role == UserRole.client) {
          return _ClientProfileStep(
            logoName: _profilePhotoName,
            logoPreview: _profilePhotoPreview,
            businessDescription: _businessDescription,
            website: _website,
            industry: _industry,
            gstNumber: _gstNumber,
            teamSize: _teamSize,
            annualRequirement: _annualRequirement,
            serviceLocation: _serviceLocation,
            onPickLogo: _openProfilePhotoPicker,
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
          portfolioDocName: _portfolioDocName,
          onPickPortfolioDocument: _pickPortfolioDocument,
        );
      case 'Badges':
        return _BadgesStep(
          certifications: _certifications,
          education: _education,
        );
      case 'Billing':
        return _BillingStep(
          plans: _plans,
          selectedPlan: _plan,
          onSelected: (plan) => setState(() => _plan = plan),
        );
      case 'Business type':
        return _ClientBusinessTypeStep(
          value: _businessType,
          items: _businessTypeOptions,
          onChanged: (value) => setState(() => _businessType = value),
        );
      case 'Services & Requirements':
        return _ClientServiceStep(
          value: _primaryService,
          subService: _primarySubService,
          serviceMap: _clientProjectCategories,
          onChanged: (value) => setState(() {
            _primaryService = value;
            _primarySubService = null;
          }),
          onSubServiceChanged: (value) =>
              setState(() => _primarySubService = value),
        );
      case 'Business Details':
        return _ClientBusinessDetailsStep(companyName: _companyName);
      case 'Looking For':
        return _SingleChoiceListStep(
          title: 'What are your goals?',
          options: _lookingForOptions,
          value: _lookingForGoal,
          onChanged: (value) => setState(() => _lookingForGoal = value),
        );
      case 'Projects':
        return _ClientProjectsStep(
          title: _projectTitle,
          category: _clientProjectCategory,
          subcategory: _clientProjectSubcategory,
          budget: _projectBudget,
          timeline: _projectTimeline,
          description: _projectDescription,
          preferredSkills: _projectPreferredSkills,
          locationPreference: _projectLocationPreference,
          remoteType: _remoteType,
          urgency: _urgency,
          categoryMap: _clientProjectCategories,
          onCategoryChanged: (value) => setState(() {
            _clientProjectCategory = value;
            _clientProjectSubcategory = null;
          }),
          onSubcategoryChanged: (value) =>
              setState(() => _clientProjectSubcategory = value),
          onRemoteTypeChanged: (value) => setState(() => _remoteType = value),
          onUrgencyChanged: (value) => setState(() => _urgency = value),
        );
      case 'Expansion':
        return _SingleChoiceListStep(
          title: 'Business Expansion Goals',
          options: _expansionOptions,
          value: _expansionGoal,
          onChanged: (value) => setState(() => _expansionGoal = value),
        );
      case 'Subscription':
        return _BillingStep(
          plans: _plans,
          selectedPlan: _plan,
          onSelected: (plan) => setState(() => _plan = plan),
        );
      case 'Investor type':
        return _ClientBusinessTypeStep(
          value: _investorType,
          items: _investorTypeOptions,
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
          onStageChanged: (value) => setState(() => _startupStage = value),
        );
      case 'Taxonomy':
        return _FounderTaxonomyStep(
          category: _founderCategory,
          subcategory: _founderSubCategory,
          onCategoryChanged: (value) =>
              setState(() => _founderCategory = value),
          onSubcategoryChanged: (value) =>
              setState(() => _founderSubCategory = value),
        );
      case 'Goals':
        if (_role == UserRole.investor) {
          return _TwoColumnChoiceStep(
            title: 'Looking For (Intent)',
            options: _investorIntents,
            value: _investorIntent,
            onChanged: (value) => setState(() => _investorIntent = value),
          );
        }
        if (_role == UserRole.founder) {
          return _TwoColumnChoiceStep(
            title: 'What are you looking for?',
            options: _founderGoals,
            value: _founderGoal,
            onChanged: (value) => setState(() => _founderGoal = value),
          );
        }
        break;
      case 'Verification':
        if (_role == UserRole.investor) {
          return _SimpleVerificationStep(
            email: _email,
            emailOtp: _emailOtp,
            aadhaar: _aadhaar,
            pan: _pan,
            documentName: _verificationDocName,
            isEmailVerified: _isEmailVerified,
            isSendingOtp: _isSendingOtp,
            isVerifyingOtp: _isVerifyingOtp,
            agree: _agree,
            documentLabel: 'Company Proof (Optional)',
            documentHint:
                'Upload Incorporation Certificate, Partnership Deed, etc.',
            secondDocumentLabel: 'Investor KYC (Mandatory for Premium)',
            secondDocumentHint: 'Upload Aadhar, Passport, or equivalent ID.',
            onSendOtp: _sendEmailOtp,
            onVerifyOtp: _verifyEmailOtp,
            onPickDocument: _pickVerificationDocument,
            onAgreeChanged: (value) => setState(() => _agree = value ?? false),
          );
        }
        if (_role == UserRole.founder) {
          return _SimpleVerificationStep(
            email: _email,
            emailOtp: _emailOtp,
            aadhaar: _aadhaar,
            pan: _pan,
            documentName: _verificationDocName,
            isEmailVerified: _isEmailVerified,
            isSendingOtp: _isSendingOtp,
            isVerifyingOtp: _isVerifyingOtp,
            agree: _agree,
            documentLabel: 'Supporting Documents (Optional)',
            documentHint: 'Upload relevant files.',
            onSendOtp: _sendEmailOtp,
            onVerifyOtp: _verifyEmailOtp,
            onPickDocument: _pickVerificationDocument,
            onAgreeChanged: (value) => setState(() => _agree = value ?? false),
          );
        }
        return _VerificationStep(
          email: _email,
          emailOtp: _emailOtp,
          accountPhone: _phone,
          countryIsoCode: _countryIsoCode,
          aadhaar: _aadhaar,
          pan: _pan,
          documentName: _verificationDocName,
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
    required this.phone,
    required this.password,
    required this.confirm,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.city,
    required this.countryIsoCode,
    required this.onCountryChanged,
    required this.onCountrySelected,
    required this.onCountryPlaceSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
    required this.validatePhone,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirm;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final TextEditingController city;
  final String countryIsoCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;
  final String? Function(String?) validatePhone;

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
              hint: 'Enter name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Email',
              hint: 'Enter email address',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
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
                AppSizes.hGapSm,
                Expanded(
                  child: _PhoneFieldWithCounter(
                    controller: phone,
                    label: 'Mobile number',
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
              label: 'Password',
              hint: 'Enter password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              validator: Validators.password,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: confirm,
              label: 'Confirm password',
              hint: 'Re-enter password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              validator: (v) => Validators.confirmPassword(v, password.text),
            ),
            AppSizes.vGapLg,
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
            AppLocationField(
              controller: stateLocation,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
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
    required this.phone,
    required this.password,
    required this.confirm,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.city,
    required this.countryIsoCode,
    required this.onCountryChanged,
    required this.onCountrySelected,
    required this.onCountryPlaceSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
    required this.validatePhone,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirm;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final TextEditingController city;
  final String countryIsoCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;
  final String? Function(String?) validatePhone;

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
              hint: 'Enter name',
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Email',
              hint: 'Enter email',
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: password,
              label: 'Password',
              hint: 'Enter password',
              obscure: true,
              validator: Validators.password,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: confirm,
              label: 'Confirm password',
              hint: 'Re-enter password',
              obscure: true,
              validator: (v) => Validators.confirmPassword(v, password.text),
            ),
            AppSizes.vGapLg,
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
            AppLocationField(
              controller: stateLocation,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
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
            AppSizes.vGapLg,
            _PhoneWithCountryCodeRow(
              phone: phone,
              countryIsoCode: countryIsoCode,
              onCountryChanged: onCountryChanged,
              validatePhone: validatePhone,
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
    required this.phone,
    required this.password,
    required this.confirm,
    required this.founderType,
    required this.founderTypeOptions,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.city,
    required this.countryIsoCode,
    required this.onCountryChanged,
    required this.onCountrySelected,
    required this.onFounderTypeChanged,
    required this.onCountryPlaceSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
    required this.validatePhone,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirm;
  final String? founderType;
  final List<String> founderTypeOptions;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final TextEditingController city;
  final String countryIsoCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<String?> onFounderTypeChanged;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;
  final String? Function(String?) validatePhone;

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
              hint: 'Enter name',
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Email',
              hint: 'Enter email',
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: password,
              label: 'Password',
              hint: 'Enter password',
              obscure: true,
              validator: Validators.password,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: confirm,
              label: 'Confirm password',
              hint: 'Re-enter password',
              obscure: true,
              validator: (v) => Validators.confirmPassword(v, password.text),
            ),
            AppSizes.vGapLg,
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
            AppLocationField(
              controller: stateLocation,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
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
            AppSizes.vGapLg,
            _PhoneWithCountryCodeRow(
              phone: phone,
              countryIsoCode: countryIsoCode,
              onCountryChanged: onCountryChanged,
              validatePhone: validatePhone,
            ),
            AppSizes.vGapLg,
            AppDropdown<String>(
              label: 'Founder Type',
              hint: 'Select founder type',
              value: founderType,
              items: founderTypeOptions,
              itemLabel: (item) => item,
              onChanged: onFounderTypeChanged,
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
            label: 'Mobile number',
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
    this.label = 'Mobile number',
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
    required this.phone,
    required this.password,
    required this.confirm,
    required this.businessName,
    required this.country,
    required this.countryOptions,
    required this.stateLocation,
    required this.city,
    required this.countryIsoCode,
    required this.onCountryChanged,
    required this.onCountrySelected,
    required this.onCountryPlaceSelected,
    required this.onStatePlaceSelected,
    required this.onCityPlaceSelected,
    required this.onEmailChanged,
    required this.validatePhone,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirm;
  final TextEditingController businessName;
  final TextEditingController country;
  final List<_CountryOption> countryOptions;
  final TextEditingController stateLocation;
  final TextEditingController city;
  final String countryIsoCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<_CountryOption> onCountrySelected;
  final ValueChanged<SelectedPlace> onCountryPlaceSelected;
  final ValueChanged<SelectedPlace> onStatePlaceSelected;
  final ValueChanged<SelectedPlace> onCityPlaceSelected;
  final ValueChanged<String> onEmailChanged;
  final String? Function(String?) validatePhone;

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
              hint: 'Enter name',
              validator: (v) => Validators.minLength(v, 3, field: 'Name'),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: email,
              label: 'Work email',
              hint: 'Enter work email',
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              validator: Validators.email,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: password,
              label: 'Password',
              hint: 'Enter password',
              obscure: true,
              validator: Validators.password,
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: confirm,
              label: 'Confirm password',
              hint: 'Re-enter password',
              obscure: true,
              validator: (v) => Validators.confirmPassword(v, password.text),
            ),
            AppSizes.vGapLg,
            AppTextField(
              controller: businessName,
              label: 'Business Name',
              hint: 'e.g. Acme Corp',
              validator: (v) => Validators.required(v, field: 'Business name'),
            ),
            AppSizes.vGapLg,
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
            AppLocationField(
              controller: stateLocation,
              label: 'State',
              hint: 'Search and select state',
              validator: (v) => Validators.required(v, field: 'State'),
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
                AppSizes.hGapSm,
                Expanded(
                  child: _PhoneFieldWithCounter(
                    controller: phone,
                    label: 'Mobile number',
                    countryIsoCode: countryIsoCode,
                    validator: validatePhone,
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

class _ClientBusinessTypeStep extends StatelessWidget {
  const _ClientBusinessTypeStep({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: AppDropdown<String>(
        label: 'Type',
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
    required this.businessDescription,
    required this.website,
    required this.industry,
    required this.gstNumber,
    required this.teamSize,
    required this.annualRequirement,
    required this.serviceLocation,
    required this.onPickLogo,
    required this.onTeamSizeChanged,
  });

  final String? logoName;
  final ImageProvider? logoPreview;
  final TextEditingController businessDescription;
  final TextEditingController website;
  final TextEditingController industry;
  final TextEditingController gstNumber;
  final String? teamSize;
  final TextEditingController annualRequirement;
  final TextEditingController serviceLocation;
  final VoidCallback onPickLogo;
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
            controller: businessDescription,
            label: 'Business Description',
            hint: 'Tell us about your business...',
            maxLines: 4,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: website,
            label: 'Website',
            hint: 'https://...',
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: industry,
            label: 'Industry',
            hint: 'e.g. Technology, Retail, Healthcare...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: gstNumber,
            label: 'GST Number (Optional)',
            hint: 'Enter GST Number',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Team Size',
            hint: 'Select size',
            value: teamSize,
            items: _SignupPageState._teamSizes,
            itemLabel: (item) => item,
            onChanged: onTeamSizeChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: annualRequirement,
            label: 'Annual Requirement',
            hint: 'e.g. ₹10 Lakhs',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: serviceLocation,
            label: 'Service Location',
            hint: 'e.g. Global, India, Regional',
          ),
        ],
      ),
    );
  }
}

class _ClientServiceStep extends StatelessWidget {
  const _ClientServiceStep({
    required this.value,
    required this.subService,
    required this.serviceMap,
    required this.onChanged,
    required this.onSubServiceChanged,
  });

  final String? value;
  final String? subService;
  final Map<String, List<String>> serviceMap;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String?> onSubServiceChanged;

  @override
  Widget build(BuildContext context) {
    final serviceItems = serviceMap.keys.toList();
    final subServiceItems = value == null
        ? <String>[]
        : serviceMap[value] ?? <String>[];
    return _StepCard(
      child: Column(
        children: [
          AppDropdown<String>(
            label: 'Primary Service',
            hint: 'Select a service',
            value: value,
            items: serviceItems,
            itemLabel: (item) => item,
            onChanged: onChanged,
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Sub-Service',
            hint: 'Select specific sub-service',
            value: subServiceItems.contains(subService) ? subService : null,
            items: subServiceItems,
            itemLabel: (item) => item,
            onChanged: subServiceItems.isEmpty ? null : onSubServiceChanged,
          ),
        ],
      ),
    );
  }
}

class _ClientBusinessDetailsStep extends StatelessWidget {
  const _ClientBusinessDetailsStep({required this.companyName});

  final TextEditingController companyName;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: AppTextField(
        controller: companyName,
        label: 'Company name',
        hint: 'Enter company name',
      ),
    );
  }
}

class _SingleChoiceListStep extends StatelessWidget {
  const _SingleChoiceListStep({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleMedium),
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
                  decoration: BoxDecoration(
                    color: value == option
                        ? AppColors.primary.withValues(alpha: 0.04)
                        : context.theme.cardColor,
                    border: Border.all(
                      color: value == option
                          ? AppColors.primary
                          : context.theme.dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        value == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
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
    required this.subcategory,
    required this.budget,
    required this.timeline,
    required this.description,
    required this.preferredSkills,
    required this.locationPreference,
    required this.remoteType,
    required this.urgency,
    required this.categoryMap,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.onRemoteTypeChanged,
    required this.onUrgencyChanged,
  });

  final TextEditingController title;
  final String? category;
  final String? subcategory;
  final TextEditingController budget;
  final TextEditingController timeline;
  final TextEditingController description;
  final TextEditingController preferredSkills;
  final TextEditingController locationPreference;
  final String? remoteType;
  final String? urgency;
  final Map<String, List<String>> categoryMap;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final ValueChanged<String?> onRemoteTypeChanged;
  final ValueChanged<String?> onUrgencyChanged;

  @override
  Widget build(BuildContext context) {
    final categoryItems = categoryMap.keys.toList();
    final subcategoryItems = category == null
        ? <String>[]
        : categoryMap[category] ?? <String>[];
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: title,
            label: 'Project Title',
            hint: 'e.g. Build an E-commerce Website',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Project Category',
            hint: 'Select Category',
            value: category,
            items: categoryItems,
            itemLabel: (item) => item,
            onChanged: onCategoryChanged,
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Project Subcategory',
            hint: 'Select Subcategory',
            value: subcategoryItems.contains(subcategory) ? subcategory : null,
            items: subcategoryItems,
            itemLabel: (item) => item,
            onChanged: subcategoryItems.isEmpty ? null : onSubcategoryChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: budget,
            label: 'Budget',
            hint: 'e.g. ₹50,000',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: timeline,
            label: 'Timeline',
            hint: 'e.g. 2 months',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: description,
            label: 'Description',
            hint: 'Describe the project requirements...',
            maxLines: 4,
          ),
          AppSizes.vGapLg,
          Text("Project reference files", style: context.text.titleSmall),
          AppSizes.vGapSm,
          Center(
            child: AppFileUpload(
              label: 'Choose Files',
              hint: 'Upload project reference files.',
              icon: Icons.attach_file_rounded,
            ),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: preferredSkills,
            label: 'Preferred Skills',
            hint: 'e.g. React, Node.js, Figma',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: locationPreference,
            label: 'Location Preference',
            hint: 'e.g. India',
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
    required this.category,
    required this.categories,
    required this.onChanged,
  });

  final String? category;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: AppDropdown<String>(
        label: 'Primary category',
        hint: 'Select category',
        value: category,
        items: categories,
        itemLabel: (item) => item,
        onChanged: onChanged,
        validator: (value) =>
            value == null || value.isEmpty ? 'Select category' : null,
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
    required this.onSkillSelected,
    required this.onSkillRemoved,
    required this.onManualSkillsChanged,
  });

  final TextEditingController skills;
  final TextEditingController experience;
  final TextEditingController bio;
  final List<String> selectedSkills;
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
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              for (final skill in _SignupPageState._skillSuggestions)
                _SkillChoiceChip(
                  skill: skill,
                  selected: selectedSkills.contains(skill),
                  onTap: () => selectedSkills.contains(skill)
                      ? onSkillRemoved(skill)
                      : onSkillSelected(skill),
                ),
            ],
          ),
          AppSizes.vGapXl,
          AppTextField(
            controller: experience,
            label: 'Years of experience',
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
            hint: 'Enter LinkedIn URL',
            prefixIcon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: github,
            label: 'GitHub URL',
            hint: 'Enter GitHub URL',
            prefixIcon: Icons.code_rounded,
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: portfolioUrl,
            label: 'Portfolio URL',
            hint: 'Enter portfolio URL',
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
        label: 'Hourly rate (USD)',
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
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String hint;
  final String? fileName;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.titleSmall),
        AppSizes.vGapSm,
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

class _PortfolioUploadsStep extends StatelessWidget {
  const _PortfolioUploadsStep({
    required this.portfolioDocName,
    required this.onPickPortfolioDocument,
  });

  final String? portfolioDocName;
  final VoidCallback onPickPortfolioDocument;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: AppFileUpload(
        label: 'Portfolio Project Uploads & Media Attachments',
        hint: 'Upload PDF, DOC, Excel, or PPT files.',
        icon: Icons.upload_file_rounded,
        fileName: portfolioDocName,
        onTap: onPickPortfolioDocument,
      ),
    );
  }
}

class _BadgesStep extends StatelessWidget {
  const _BadgesStep({required this.certifications, required this.education});

  final TextEditingController certifications;
  final TextEditingController education;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        children: [
          AppTextField(
            controller: certifications,
            label: 'Certifications',
            hint: 'Enter certifications',
            prefixIcon: Icons.verified_outlined,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: education,
            label: 'Education',
            hint: 'Enter education',
            prefixIcon: Icons.school_outlined,
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
                        selected: selectedPlan == plan.name,
                        onTap: () => onSelected(plan.name),
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
            color: selected ? AppColors.primary : context.theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: context.text.titleMedium),
            AppSizes.vGapMd,
            Text(plan.price, style: context.text.headlineSmall),
            AppSizes.vGapMd,
            Text('Standard access plan', style: context.text.bodyMedium),
          ],
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
    required this.aadhaar,
    required this.pan,
    required this.documentName,
    required this.isEmailVerified,
    required this.isSendingOtp,
    required this.isVerifyingOtp,
    required this.agree,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onCountryChanged,
    required this.onEmailChanged,
    required this.onPickDocument,
    required this.validatePhone,
    required this.onAgreeChanged,
  });

  final TextEditingController email;
  final TextEditingController emailOtp;
  final TextEditingController accountPhone;
  final String countryIsoCode;
  final TextEditingController aadhaar;
  final TextEditingController pan;
  final String? documentName;
  final bool isEmailVerified;
  final bool isSendingOtp;
  final bool isVerifyingOtp;
  final bool agree;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onPickDocument;
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
                hint: 'Enter Email OTP',
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
                  label: 'Mobile Number',
                  prefixIcon: Icons.phone_outlined,
                  countryIsoCode: countryIsoCode,
                  validator: validatePhone,
                ),
              ),
            ],
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: aadhaar,
            label: 'Aadhaar Card Number *',
            hint: 'Enter 12-digit Aadhaar Number (e.g. 1234 5678 9012)',
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
            hint: 'Enter 10-character PAN Number (e.g. ABCDE1234F)',
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
            onTap: onPickDocument,
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
    required this.minTicket,
    required this.maxTicket,
    required this.stagePreference,
    required this.investmentMode,
    required this.targetIndustry,
    required this.stageOptions,
    required this.industryOptions,
    required this.onPickProfilePhoto,
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
  final TextEditingController minTicket;
  final TextEditingController maxTicket;
  final String? stagePreference;
  final String? investmentMode;
  final String? targetIndustry;
  final List<String> stageOptions;
  final List<String> industryOptions;
  final VoidCallback onPickProfilePhoto;
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
            label: 'Company/Fund Name',
            hint: 'e.g. Acme Capital',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: linkedin,
            label: 'LinkedIn Profile',
            hint: 'https://linkedin.com/in/...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: website,
            label: 'Website URL',
            hint: 'https://...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: bio,
            label: 'Bio (Thesis)',
            hint: 'Sectors, geographies, stages...',
            maxLines: 5,
          ),
          AppSizes.vGapLg,
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: minTicket,
                  label: 'Min Ticket Size (₹)',
                  hint: 'e.g. 500000',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: AppTextField(
                  controller: maxTicket,
                  label: 'Max Ticket Size (₹)',
                  hint: 'e.g. 50000000',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          AppSizes.vGapLg,
          _CompactRadioGroup(
            title: 'Stage Preference',
            options: stageOptions,
            value: stagePreference,
            onChanged: onStageChanged,
          ),
          AppSizes.vGapLg,
          _CompactRadioGroup(
            title: 'Investment Mode',
            options: _SignupPageState._investmentModes,
            value: investmentMode,
            onChanged: onModeChanged,
          ),
          AppSizes.vGapLg,
          _CompactRadioGroup(
            title: 'Target Industries / Categories',
            options: industryOptions,
            value: targetIndustry,
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
            label: 'Bio',
            hint: 'Tell us about yourself...',
            maxLines: 5,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: skills,
            label: 'Skills',
            hint: 'e.g. Marketing, AI, Product Management',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: experience,
            label: 'Experience',
            hint: 'Years of experience or key roles',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: education,
            label: 'Education',
            hint: 'University, degree, etc.',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: linkedin,
            label: 'LinkedIn',
            hint: 'https://linkedin.com/in/...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: portfolioUrl,
            label: 'Website / Portfolio',
            hint: 'https://...',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Team Size',
            hint: 'Select team size',
            value: teamSize,
            items: _SignupPageState._teamSizes,
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
    required this.onStageChanged,
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
  final ValueChanged<String?> onStageChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: startupName,
            label: 'Startup Name',
            hint: 'Enter startup name',
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Startup Stage',
            hint: 'Select stage',
            value: startupStage,
            items: startupStageOptions,
            itemLabel: (item) => item,
            onChanged: onStageChanged,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: shortPitch,
            label: 'Short Pitch (One-liner)',
            hint: 'e.g. Uber for dog walking',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: longDescription,
            label: 'Long Description',
            hint: 'Describe your startup idea in detail...',
            maxLines: 4,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: problemStatement,
            label: 'Problem Statement',
            hint: 'Enter problem statement',
            maxLines: 3,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: solution,
            label: 'Solution',
            hint: 'Enter solution',
            maxLines: 3,
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: targetCustomers,
            label: 'Target Customers',
            hint: 'Enter target customers',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: marketSize,
            label: 'Market Size',
            hint: r'e.g. $10B TAM',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: businessModel,
            label: 'Business Model',
            hint: 'B2B, B2C, Marketplace...',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: revenueModel,
            label: 'Revenue Model',
            hint: 'SaaS, Transactional, Ads...',
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
            hint: r'e.g. $500K',
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: equityOffered,
            label: 'Equity Offered',
            hint: 'e.g. 10%',
          ),
          AppSizes.vGapLg,
          Text("Pitch Deck Upload", style: context.text.titleSmall),
          AppSizes.vGapSm,
          Center(
            child: AppFileUpload(
              label: 'Choose file',
              hint: 'Upload pitch deck file.',
              icon: Icons.upload_file_rounded,
            ),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: demoLink,
            label: 'Demo Video / App / Website Link',
            hint: 'https://...',
          ),
        ],
      ),
    );
  }
}

class _FounderTaxonomyStep extends StatelessWidget {
  const _FounderTaxonomyStep({
    required this.category,
    required this.subcategory,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
  });

  final String? category;
  final String? subcategory;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: Column(
        children: [
          AppDropdown<String>(
            label: 'Primary Category',
            hint: 'Select a category',
            value: category,
            items: _SignupPageState._founderCategories,
            itemLabel: (item) => item,
            onChanged: onCategoryChanged,
          ),
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Sub-Category',
            hint: 'Select a sub-category',
            value: subcategory,
            items: _SignupPageState._founderSubCategories,
            itemLabel: (item) => item,
            onChanged: onSubcategoryChanged,
          ),
        ],
      ),
    );
  }
}

class _TwoColumnChoiceStep extends StatelessWidget {
  const _TwoColumnChoiceStep({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      child: _CompactRadioGroup(
        title: title,
        options: options,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _CompactRadioGroup extends StatelessWidget {
  const _CompactRadioGroup({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleSmall),
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
                          value == option
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        AppSizes.hGapSm,
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
      ],
    );
  }
}

class _SimpleVerificationStep extends StatelessWidget {
  const _SimpleVerificationStep({
    required this.email,
    required this.emailOtp,
    required this.aadhaar,
    required this.pan,
    required this.documentName,
    required this.isEmailVerified,
    required this.isSendingOtp,
    required this.isVerifyingOtp,
    required this.agree,
    required this.documentLabel,
    required this.documentHint,
    this.secondDocumentLabel,
    this.secondDocumentHint,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onPickDocument,
    required this.onAgreeChanged,
  });

  final TextEditingController email;
  final TextEditingController emailOtp;
  final TextEditingController aadhaar;
  final TextEditingController pan;
  final String? documentName;
  final bool isEmailVerified;
  final bool isSendingOtp;
  final bool isVerifyingOtp;
  final bool agree;
  final String documentLabel;
  final String documentHint;
  final String? secondDocumentLabel;
  final String? secondDocumentHint;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onPickDocument;
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
            hint: 'Enter email address',
            suffixIcon: isEmailVerified
                ? const Icon(Icons.verified_rounded, color: AppColors.success)
                : null,
          ),
          AppSizes.vGapMd,
          AppTextField(controller: emailOtp, hint: 'Enter Email OTP'),
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
          AppTextField(
            controller: aadhaar,
            label: 'Aadhaar Card Number *',
            hint: 'Enter 12-digit Aadhaar Number (e.g. 1234 5678 9012)',
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
            hint: 'Enter 10-character PAN Number (e.g. ABCDE1234F)',
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
            icon: Icons.file_present_outlined,
            onTap: onPickDocument,
          ),
          if (secondDocumentLabel != null) ...[
            AppSizes.vGapLg,
            _TitledFileUpload(
              label: secondDocumentLabel!,
              hint: secondDocumentHint ?? 'Upload relevant files.',
              fileName: documentName,
              icon: Icons.badge_outlined,
              onTap: onPickDocument,
            ),
          ],
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
      itemLabel: (item) => item.displayName,
      validator: (value) => validator(value?.name),
      onChanged: (value) {
        if (value == null) return;
        onCountrySelected(value);
      },
    );
  }
}

class _CountryOption {
  const _CountryOption({
    required this.name,
    required this.code,
    required this.phoneCode,
    required this.flag,
    required this.allowRegistration,
  });

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

  factory _CountryOption.fromJson(Map<String, dynamic> json) {
    return _CountryOption(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      phoneCode: json['phoneCode']?.toString() ?? '',
      flag: json['flag']?.toString() ?? '',
      allowRegistration: json['allowRegistration'] != false,
    );
  }
}

class _PlanOption {
  const _PlanOption(this.name, this.price);

  final String name;
  final String price;
}
