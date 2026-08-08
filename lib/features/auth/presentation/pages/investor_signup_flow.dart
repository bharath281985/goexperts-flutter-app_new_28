import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_search_dropdown.dart';
import '../widgets/signup_multi_select_sheet.dart';
import '../widgets/signup_success_view.dart';

class InvestorSignupFlow extends StatefulWidget {
  const InvestorSignupFlow({super.key});

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
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;

  // Step 2 Profile
  String? _selectedDesignation = 'Managing Partner';
  String? _selectedCountry = 'India';
  String? _selectedCity = 'Mumbai';
  final _firmNameController = TextEditingController();

  // Step 3 Preferences
  List<String> _preferredIndustries = ['Software & Technology', 'Financial Services & FinTech'];
  String? _selectedStage = 'Seed / Pre-Seed';
  String? _selectedTicketRange = '₹10L - ₹50L';

  final List<String> _designations = ['Angel Investor', 'Managing Partner', 'Venture Partner', 'Investment Analyst', 'Family Office Manager'];
  final List<String> _countries = ['India', 'United States', 'United Kingdom', 'Singapore', 'UAE'];
  final List<String> _cities = ['Mumbai', 'Bengaluru', 'Delhi', 'Hyderabad', 'Pune'];
  final List<String> _industries = [
    'Software & Technology',
    'Financial Services & FinTech',
    'Healthcare & HealthTech',
    'E-Commerce & Retail',
    'Education & EdTech',
    'AI & DeepTech',
    'CleanTech & Energy'
  ];
  final List<String> _stages = ['Idea / Pre-Revenue', 'Seed / Pre-Seed', 'Early Traction (Series A)', 'Growth (Series B+)'];
  final List<String> _ticketRanges = ['< ₹10L', '₹10L - ₹50L', '₹50L - ₹2Cr', '₹2Cr - ₹10Cr', '₹10Cr+'];

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
              role: 'investor',
            ),
          );
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_preferredIndustries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 preferred industry')));
        return;
      }
      setState(() => _currentStep = 4);
    }
  }

  void _onBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 4) {
      return SignupSuccessView(
        roleTitle: 'Investor',
        dashboardRoute: '/investor',
        completedSteps: const [
          'Investor Account Registered',
          'Investor Profile Configured',
          'Investment Preferences & Ticket Ranges Set',
        ],
        onGoToDashboard: () => context.go('/investor'),
      );
    }

    String title = '';
    String subtitle = '';

    switch (_currentStep) {
      case 1:
        title = 'Create Investor Account';
        subtitle = 'Discover high-potential startups and promising investment deals.';
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

    return SignupScaffold(
      title: title,
      subtitle: subtitle,
      currentStep: _currentStep,
      totalSteps: 4,
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
            SignupSearchDropdown(
              label: 'Designation *',
              value: _selectedDesignation,
              placeholder: 'Select Designation',
              options: _designations,
              onChanged: (val) => setState(() => _selectedDesignation = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firmNameController,
              decoration: const InputDecoration(
                labelText: 'Organization / Firm Name (Optional)',
                hintText: 'e.g. Apex Ventures',
                border: OutlineInputBorder(),
              ),
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
        return Column(
          children: [
            SignupMultiSelectSheet(
              label: 'Preferred Industries',
              selectedItems: _preferredIndustries,
              availableOptions: _industries,
              minSelection: 1,
              maxSelection: 5,
              onChanged: (items) => setState(() => _preferredIndustries = items),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'Investment Stage *',
              value: _selectedStage,
              placeholder: 'Select Stage',
              options: _stages,
              onChanged: (val) => setState(() => _selectedStage = val),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'Ticket Size / Investment Range *',
              value: _selectedTicketRange,
              placeholder: 'Select Ticket Range',
              options: _ticketRanges,
              onChanged: (val) => setState(() => _selectedTicketRange = val),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
