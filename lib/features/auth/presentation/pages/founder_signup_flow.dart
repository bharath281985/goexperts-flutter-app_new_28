import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_search_dropdown.dart';
import '../widgets/signup_multi_select_sheet.dart';
import '../widgets/signup_success_view.dart';

class FounderSignupFlow extends StatefulWidget {
  const FounderSignupFlow({super.key});

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
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _termsAccepted = false;
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _isOtpSent = false;

  // Step 2 Startup Details
  final _startupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIndustry = 'Software & Technology';
  String? _selectedStage = 'MVP / Prototype';

  // Step 3 Founder Profile
  String? _selectedDesignation = 'Founder / Co-Founder';
  String? _selectedCountry = 'India';
  String? _selectedCity = 'Bengaluru';

  // Step 4 Goals (Sourced from 39-item Master)
  List<String> _selectedGoals = ['Raise Seed Capital', 'Hire Technical Team'];

  final List<String> _industries = [
    'Software & Technology',
    'Financial Services & FinTech',
    'Healthcare & HealthTech',
    'E-Commerce & Retail',
    'Education & EdTech',
    'AI & DeepTech',
    'CleanTech & Energy'
  ];
  final List<String> _stages = ['Idea Stage', 'MVP / Prototype', 'Early Revenue', 'Scaling & Growth'];
  final List<String> _designations = ['Founder / Co-Founder', 'Technical Founder (CTO)', 'CEO', 'Product Lead'];
  final List<String> _countries = ['India', 'United States', 'United Kingdom', 'Singapore', 'UAE'];
  final List<String> _cities = ['Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad', 'Pune'];

  final List<String> _startupGoalsMaster = [
    'Raise Seed Capital',
    'Raise Pre-Series A / Series A',
    'Hire Technical Team (Developers, Tech Leads)',
    'Find Co-Founder (Technical, Commercial)',
    'UI/UX Product Redesign',
    'Go-to-Market (GTM) Strategy',
    'Legal & Incorporation Support',
    'Investor Pitch Deck Review',
    'Customer Acquisition & Growth Marketing',
    'Financial Modeling & Valuation',
    'Intellectual Property (IP) & Patent Guidance',
    'Mentorship & Strategic Advisors',
  ];

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
      if (_fullNameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || !_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields and accept terms')),
        );
        return;
      }
      if (!_isEmailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please click Verify to verify your email address via OTP')),
        );
        return;
      }
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(
            SignupRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              role: 'founder',
            ),
          );
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      if (_startupNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Startup / Idea Name')));
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      if (_selectedGoals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 startup goal')));
        return;
      }
      setState(() => _currentStep = 5);
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 5) {
      return SignupSuccessView(
        roleTitle: 'Founder / Startup Creator',
        dashboardRoute: '/founder',
        completedSteps: const [
          'Founder Account Registered',
          'Startup Idea & Stage Details Saved',
          'Founder Profile Configured',
          'Startup Goals & Resource Needs Set',
        ],
        onGoToDashboard: () => context.go('/founder'),
      );
    }

    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 1:
        title = 'Create Founder Account';
        subtitle = 'Launch your venture, connect with investors, and hire experts.';
        break;
      case 2:
        title = 'Startup Details';
        subtitle = 'Tell us about your venture, idea, and stage.';
        break;
      case 3:
        title = 'Founder Profile';
        subtitle = 'Specify your designation and location.';
        break;
      case 4:
        title = 'Startup Goals & Needs';
        subtitle = 'Select your primary goals and immediate resource requirements.';
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: !_isEmailVerified,
              onChanged: (v) {
                if (_isEmailVerified) setState(() => _isEmailVerified = false);
              },
              decoration: InputDecoration(
                labelText: 'Email Address *',
                border: const OutlineInputBorder(),
                suffixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: _isEmailVerified
                      ? const Chip(
                          avatar: Icon(Icons.check_circle, color: Colors.green, size: 16),
                          label: Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                          backgroundColor: Color(0xFFE8F5E9),
                          visualDensity: VisualDensity.compact,
                        )
                      : TextButton(
                          onPressed: _isSendingOtp ? null : _sendOtp,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          child: Text(_isSendingOtp ? 'Sending...' : (_isOtpSent ? 'Resend' : 'Verify')),
                        ),
                ),
              ),
            ),
            if (!_isEmailVerified && _isOtpSent) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'Enter 6-digit OTP',
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Verify OTP'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _termsAccepted,
              title: const Text('I agree to the Terms of Service & Privacy Policy'),
              onChanged: (val) => setState(() => _termsAccepted = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            TextField(
              controller: _startupNameController,
              decoration: const InputDecoration(
                labelText: 'Startup / Idea Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Short One-Line Description',
                hintText: 'e.g. AI-driven financial intelligence platform',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'Industry *',
              value: _selectedIndustry,
              placeholder: 'Select Industry',
              options: _industries,
              onChanged: (val) => setState(() => _selectedIndustry = val),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'Startup Stage *',
              value: _selectedStage,
              placeholder: 'Select Stage',
              options: _stages,
              onChanged: (val) => setState(() => _selectedStage = val),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            SignupSearchDropdown(
              label: 'Designation *',
              value: _selectedDesignation,
              placeholder: 'Select Designation',
              options: _designations,
              onChanged: (val) => setState(() => _selectedDesignation = val),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'Country *',
              value: _selectedCountry,
              placeholder: 'Select Country',
              options: _countries,
              onChanged: (val) => setState(() => _selectedCountry = val),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'City *',
              value: _selectedCity,
              placeholder: 'Select City',
              options: _cities,
              onChanged: (val) => setState(() => _selectedCity = val),
            ),
          ],
        );
      case 4:
        return SignupMultiSelectSheet(
          label: 'Startup Goals & Needs',
          selectedItems: _selectedGoals,
          availableOptions: _startupGoalsMaster,
          minSelection: 1,
          maxSelection: 6,
          onChanged: (items) => setState(() => _selectedGoals = items),
        );
      default:
        return const SizedBox();
    }
  }
}
