import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'signup_top_message.dart';

class SignupEmailOtpFields extends StatefulWidget {
  const SignupEmailOtpFields({
    super.key,
    required this.emailController,
    required this.onVerificationChanged,
    this.initialVerifiedEmail,
  });

  final TextEditingController emailController;
  final ValueChanged<bool> onVerificationChanged;
  final String? initialVerifiedEmail;

  @override
  State<SignupEmailOtpFields> createState() => _SignupEmailOtpFieldsState();
}

class _SignupEmailOtpFieldsState extends State<SignupEmailOtpFields> {
  final _otpController = TextEditingController();
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.authBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  bool _isSending = false;
  bool _isVerifying = false;
  bool _isVerified = false;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;
  String? _verifiedEmail;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.emailController.text.trim();
    final cachedEmail = widget.initialVerifiedEmail?.trim();
    if (cachedEmail != null &&
        cachedEmail.isNotEmpty &&
        initialEmail == cachedEmail) {
      _isVerified = true;
      _verifiedEmail = cachedEmail;
    }
    widget.emailController.addListener(_handleEmailChanged);
  }

  @override
  void dispose() {
    widget.emailController.removeListener(_handleEmailChanged);
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _handleEmailChanged() {
    final email = widget.emailController.text.trim();
    final cachedEmail = widget.initialVerifiedEmail?.trim();
    if (!_isVerified &&
        cachedEmail != null &&
        cachedEmail.isNotEmpty &&
        email == cachedEmail) {
      _resendTimer?.cancel();
      setState(() {
        _isVerified = true;
        _verifiedEmail = cachedEmail;
        _resendSecondsRemaining = 0;
      });
      widget.onVerificationChanged(true);
      return;
    }
    if (_verifiedEmail != null && email != _verifiedEmail) {
      _resendTimer?.cancel();
      setState(() {
        _isVerified = false;
        _verifiedEmail = null;
        _resendSecondsRemaining = 0;
      });
      widget.onVerificationChanged(false);
    }
  }

  void _showMessage(String message, {required bool isSuccess}) {
    showSignupTopMessage(context, message, isSuccess: isSuccess);
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
        return;
      }
      setState(() => _resendSecondsRemaining--);
    });
  }

  String get _sendOtpLabel {
    if (_isVerified) return 'Email Verified';
    if (_resendSecondsRemaining > 0) {
      return 'Resend in ${_resendSecondsRemaining}s';
    }
    return _verifiedEmail == null ? 'Get Email OTP' : 'Resend OTP';
  }

  Future<void> _sendOtp() async {
    final email = widget.emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter email address', isSuccess: false);
      return;
    }

    setState(() => _isSending = true);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/send-otp',
        data: {'email': email},
      );
      final data = response.data ?? {};
      _showMessage(
        data['message']?.toString() ?? 'Verification OTP sent to your email.',
        isSuccess: true,
      );
      _verifiedEmail = email;
      _startResendTimer();
    } catch (e) {
      _showMessage(
        _messageFromError(e, 'Failed to send email OTP'),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = widget.emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || otp.isEmpty) {
      _showMessage('Please enter email and OTP', isSuccess: false);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final data = response.data ?? {};
      _resendTimer?.cancel();
      setState(() {
        _isVerified = true;
        _verifiedEmail = email;
        _resendSecondsRemaining = 0;
      });
      widget.onVerificationChanged(true);
      _showMessage(
        data['message']?.toString() ?? 'Email verified.',
        isSuccess: true,
      );
    } catch (e) {
      setState(() {
        _isVerified = false;
        _verifiedEmail = null;
      });
      widget.onVerificationChanged(false);
      _showMessage(_messageFromError(e, 'Invalid OTP'), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _messageFromError(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Email Verification (OTP sent to Mail) *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (_isVerified)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8FBE8),
                  border: Border.all(color: const Color(0xFF7CE0A7)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF009966),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Color(0xFF007A52),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          hint: 'Enter email address',
          prefixIcon: Icons.alternate_email,
        ),
        if (!_isVerified) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            hint: 'Enter Email OTP',
            prefixIcon: Icons.password_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isVerifying || _isVerified) ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify OTP'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (_isSending || _isVerified || _resendSecondsRemaining > 0)
                      ? null
                      : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_sendOtpLabel),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
