import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'signup_email_otp_fields.dart';

int signupMobileLengthForCountryCode(String countryCode) {
  switch (countryCode) {
    case '+91':
      return 10;
    case '+1':
      return 10;
    case '+44':
      return 10;
    case '+61':
      return 9;
    case '+971':
      return 9;
    default:
      return 10;
  }
}

class SignupAccountStep extends StatelessWidget {
  const SignupAccountStep({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.mobileController,
    required this.selectedMobileCountryCode,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.cityController,
    required this.countries,
    required this.states,
    required this.selectedCountry,
    required this.selectedState,
    required this.onCountryChanged,
    required this.onMobileCountryCodeChanged,
    required this.onStateChanged,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.onEmailVerificationChanged,
    this.initialVerifiedEmail,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final String selectedMobileCountryCode;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController cityController;
  final List<String> countries;
  final List<String> states;
  final String? selectedCountry;
  final String? selectedState;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onMobileCountryCodeChanged;
  final ValueChanged<String> onStateChanged;
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onEmailVerificationChanged;
  final String? initialVerifiedEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: fullNameController,
          label: 'Full Name *',
          hint: 'Enter full name',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        SignupEmailOtpFields(
          emailController: emailController,
          onVerificationChanged: onEmailVerificationChanged,
          initialVerifiedEmail: initialVerifiedEmail,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: passwordController,
          obscure: true,
          label: 'Password *',
          hint: 'Enter password',
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: confirmPasswordController,
          obscure: true,
          label: 'Confirm Password *',
          hint: 'Confirm password',
          prefixIcon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),
        AppDropdown<String>(
          label: 'Country *',
          hint: 'Select Country',
          value: selectedCountry,
          items: countries,
          itemLabel: (value) => value,
          prefixIcon: Icons.public,
          onChanged: (value) {
            if (value != null) onCountryChanged(value);
          },
        ),
        const SizedBox(height: 16),
        AppDropdown<String>(
          label: 'State *',
          hint: 'Select State',
          value: selectedState,
          items: states,
          itemLabel: (value) => value,
          prefixIcon: Icons.map_outlined,
          onChanged: (value) {
            if (value != null) onStateChanged(value);
          },
        ),
        const SizedBox(height: 16),
        AppLocationField(
          controller: cityController,
          label: 'City *',
          hint: 'Search and select city',
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: termsAccepted,
                  onChanged: (val) => onTermsChanged(val ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms Conditions',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push(Routes.termsOfService);
                          },
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push(Routes.privacyPolicy);
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
