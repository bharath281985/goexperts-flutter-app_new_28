import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_search_dropdown.dart';
import '../widgets/signup_success_view.dart';

class ClientSignupFlow extends StatefulWidget {
  const ClientSignupFlow({super.key});

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
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;

  // Step 2 Business
  final _businessNameController = TextEditingController();
  String? _selectedIndustry = 'Software & Technology';
  String? _selectedCompanySize = '11-50 employees';
  String? _selectedCountry = 'India';
  String? _selectedCity = 'Mumbai';

  // Step 3 Profile
  String? _selectedDesignation = 'Founder / CEO';

  // Step 4 Team (Optional)
  final _teamEmailController = TextEditingController();

  final List<String> _industries = [
    'Software & Technology',
    'Financial Services & FinTech',
    'Healthcare & HealthTech',
    'E-Commerce & Retail',
    'Education & EdTech',
  ];
  final List<String> _companySizes = ['1-10 employees', '11-50 employees', '51-200 employees', '201-500 employees', '500+ employees'];
  final List<String> _designations = ['Founder / CEO', 'CTO / Engineering VP', 'Product Manager', 'HR Manager', 'Business Owner'];
  final List<String> _countries = ['India', 'United States', 'United Kingdom', 'Canada', 'Australia'];
  final List<String> _cities = ['Mumbai', 'Bengaluru', 'Delhi', 'Hyderabad', 'Pune', 'Chennai'];

  void _onContinue() async {
    if (_currentStep == 1) {
      if (_fullNameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || !_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields and accept terms')),
        );
        return;
      }
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(
            SignupRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              role: 'client',
            ),
          );
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      if (_businessNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Business / Company Name')));
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
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
        roleTitle: 'Client / Business Owner',
        dashboardRoute: '/client',
        completedSteps: const [
          'Client Account Created',
          'Business Profile Configured',
          'Designation Set',
          'Team Workspace Ready',
        ],
        onGoToDashboard: () => context.go('/client'),
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
        title = 'Professional Role';
        subtitle = 'Specify your designation within the business.';
        break;
      case 4:
        title = 'Invite Team (Optional)';
        subtitle = 'Add team members to manage projects together.';
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
      continueLabel: _currentStep == 4 ? 'Skip or Continue' : 'Continue',
      child: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address *', border: OutlineInputBorder()),
            ),
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
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business / Company Name *',
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
              label: 'Company Size *',
              value: _selectedCompanySize,
              placeholder: 'Select Company Size',
              options: _companySizes,
              onChanged: (val) => setState(() => _selectedCompanySize = val),
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
      case 3:
        return SignupSearchDropdown(
          label: 'Designation *',
          value: _selectedDesignation,
          placeholder: 'Select Designation',
          options: _designations,
          onChanged: (val) => setState(() => _selectedDesignation = val),
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _teamEmailController,
              decoration: const InputDecoration(
                labelText: 'Team Member Email',
                hintText: 'colleague@company.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can invite additional team members anytime from your dashboard settings.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
