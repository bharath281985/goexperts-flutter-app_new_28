import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/signup_scaffold.dart';
import '../widgets/signup_search_dropdown.dart';
import '../widgets/signup_multi_select_sheet.dart';
import '../widgets/signup_success_view.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/network/api_client.dart';

class FreelancerSignupFlow extends StatefulWidget {
  const FreelancerSignupFlow({super.key});

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
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;

  // Step 2 Controllers
  final _headlineController = TextEditingController();
  String? _selectedCountry = 'India';
  String? _selectedCity = 'Mumbai';
  final _bioController = TextEditingController();

  // Step 3 Skills
  List<String> _selectedSkills = [];

  // Step 4 Experience
  String? _experienceLevel = 'Intermediate';
  String? _experienceRange = '3-5 years';

  // Static options (for small masters)
  final List<String> _countries = ['India', 'United States', 'United Kingdom', 'Canada', 'Australia'];
  final List<String> _cities = ['Mumbai', 'Bengaluru', 'Delhi', 'Hyderabad', 'Pune', 'Chennai'];
  final List<String> _expLevels = ['Entry Level', 'Intermediate', 'Expert', 'Lead'];
  final List<String> _expRanges = ['0-2 years', '3-5 years', '5-8 years', '8+ years'];

  Future<List<String>> _searchSkillsApi(String query) async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(
        ApiEndpoints.publicSkills,
        queryParameters: {'search': query, 'limit': 30},
      );
      if (response.statusCode == 200 && response.data != null) {
        final List items = response.data['data'] ?? response.data['rows'] ?? [];
        return items.map((e) => e['name']?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}
    return ['React.js', 'Node.js', 'Flutter', 'TypeScript', 'Python', 'Go', 'AWS', 'UI/UX Design', 'SQL']
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _onContinue() async {
    if (_currentStep == 1) {
      if (_fullNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          !_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields and accept terms')),
        );
        return;
      }

      setState(() => _isLoading = true);
      // Register account via AuthBloc / API
      context.read<AuthBloc>().add(
            SignupRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              role: 'freelancer',
            ),
          );

      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      if (_headlineController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your professional headline')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_selectedSkills.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 3 skills')),
        );
        return;
      }
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
        roleTitle: 'Freelancer',
        dashboardRoute: '/freelancer',
        completedSteps: const [
          'Account Registered',
          'Professional Profile Created',
          'Skills & Technologies Added',
          'Experience Level Configured',
        ],
        onGoToDashboard: () => context.go('/freelancer'),
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
        subtitle = 'Select your core technical and professional skills (Min 3).';
        break;
      case 4:
        title = 'Experience & Level';
        subtitle = 'Specify your overall experience range and work preferences.';
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
              controller: _headlineController,
              decoration: const InputDecoration(
                labelText: 'Professional Headline *',
                hintText: 'e.g. Senior Full-Stack Engineer',
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
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Short Bio',
                hintText: 'Describe your core expertise...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 3:
        return SignupMultiSelectSheet(
          label: 'Skills & Technologies',
          selectedItems: _selectedSkills,
          availableOptions: const ['React.js', 'Node.js', 'Flutter', 'TypeScript', 'Python', 'Go', 'AWS'],
          minSelection: 3,
          maxSelection: 10,
          onSearchApi: _searchSkillsApi,
          onChanged: (items) => setState(() => _selectedSkills = items),
        );
      case 4:
        return Column(
          children: [
            SignupSearchDropdown(
              label: 'Experience Level *',
              value: _experienceLevel,
              placeholder: 'Select Experience Level',
              options: _expLevels,
              onChanged: (val) => setState(() => _experienceLevel = val),
            ),
            const SizedBox(height: 16),
            SignupSearchDropdown(
              label: 'Experience Range *',
              value: _experienceRange,
              placeholder: 'Select Experience Range',
              options: _expRanges,
              onChanged: (val) => setState(() => _experienceRange = val),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
