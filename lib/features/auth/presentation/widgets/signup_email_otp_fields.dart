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
    this.isReadOnly=false,
  });

  final TextEditingController emailController;
  final ValueChanged<bool> onVerificationChanged;
  final String? initialVerifiedEmail;
  final bool isReadOnly;

  @override
  State<SignupEmailOtpFields> createState() => _SignupEmailOtpFieldsState();
}

class _SignupEmailOtpFieldsState extends State<SignupEmailOtpFields> {
  final _otpController = TextEditingController();
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
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
  bool _otpSent = false;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;
  String? _verifiedEmail;
  String? _otpSentEmail;

  @override
  void initState() {
    super.initState();
    final cachedEmail = widget.initialVerifiedEmail?.trim();
    if (widget.isReadOnly || (cachedEmail != null && cachedEmail.isNotEmpty)) {
      _isVerified = true;
      _verifiedEmail = cachedEmail ?? widget.emailController.text.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onVerificationChanged(true);
      });
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
    final activeVerifiedEmail = _verifiedEmail ?? widget.initialVerifiedEmail?.trim();

    if (_otpSent && email != _otpSentEmail) {
      setState(() {
        _otpSent = false;
      });
    } else if (!_otpSent && _otpSentEmail != null && email == _otpSentEmail) {
      setState(() {
        _otpSent = true;
      });
    }

    if (activeVerifiedEmail != null &&
        activeVerifiedEmail.isNotEmpty &&
        email != activeVerifiedEmail &&
        _isVerified) {
      setState(() {
        _isVerified = false;
      });
      widget.onVerificationChanged(false);
    } else if (activeVerifiedEmail != null &&
        activeVerifiedEmail.isNotEmpty &&
        email == activeVerifiedEmail &&
        !_isVerified) {
      setState(() {
        _isVerified = true;
        _otpSent = false;
      });
      widget.onVerificationChanged(true);
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
      debugPrint('=== SEND OTP RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.data}');
      debugPrint('========================');
      if (!mounted) return;
      final data = response.data ?? {};
      _showMessage(
        data['message']?.toString() ?? 'Verification OTP sent to your email.',
        isSuccess: true,
      );
      if (widget.emailController.text.trim() == email) {
        setState(() {
          _otpSent = true;
          _otpSentEmail = email;
        });
        _startResendTimer();
      }
    } catch (e) {
      debugPrint('=== SEND OTP ERROR ===');
      debugPrint('Type: ${e.runtimeType}');
      if (e is DioException) {
        debugPrint('DioException type: ${e.type}');
        debugPrint('Status code: ${e.response?.statusCode}');
        debugPrint('Response headers: ${e.response?.headers}');
        debugPrint('Response body: ${e.response?.data}');
        debugPrint('Message: ${e.message}');
        debugPrint('Error: ${e.error}');
      } else {
        debugPrint('Error: $e');
      }
      debugPrint('======================');
      if (!mounted) return;
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
      debugPrint('=== VERIFY OTP RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.data}');
      debugPrint('===========================');
      if (!mounted) return;
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
      debugPrint('=== VERIFY OTP ERROR ===');
      debugPrint('Type: ${e.runtimeType}');
      if (e is DioException) {
        debugPrint('DioException type: ${e.type}');
        debugPrint('Status code: ${e.response?.statusCode}');
        debugPrint('Response headers: ${e.response?.headers}');
        debugPrint('Response body: ${e.response?.data}');
        debugPrint('Message: ${e.message}');
        debugPrint('Error: ${e.error}');
      } else {
        debugPrint('Error: $e');
      }
      debugPrint('========================');
      if (!mounted) return;
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

      // Try common backend error keys in order of priority
      if (data is Map) {
        for (final key in ['message', 'error', 'detail', 'msg']) {
          final val = data[key];
          if (val != null && val.toString().trim().isNotEmpty) {
            return val.toString().trim();
          }
        }
        // Some backends send errors as a list under 'errors'
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.map((e) => e.toString()).join(', ');
        }
        // Last resort: show raw response body so nothing is hidden
        if (data.isNotEmpty) {
          return 'Server error: $data';
        }
      }

      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }

      // Network / timeout / connection errors
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please check your network.';
        case DioExceptionType.receiveTimeout:
          return 'Server took too long to respond. Try again.';
        case DioExceptionType.sendTimeout:
          return 'Request timed out while sending. Try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          return status != null
              ? 'Server returned error $status.'
              : fallback;
        default:
          break;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldTheme = theme.inputDecorationTheme;

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: fieldTheme.copyWith(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIconColor: const Color(0xFF4B4B50),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w400,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:  BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Email Address *',
                  
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              if (_isVerified) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF3),
                    border: Border.all(color: const Color(0xFFA7E8C3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Color(0xFF087A43),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Enter your email address',
                  prefixIcon: Icons.alternate_email_rounded,
                  readOnly: widget.isReadOnly,
                ),
              ),

              if( !widget.isReadOnly)if (!_isVerified && !_otpSent) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 104,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF737378),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Get OTP', maxLines: 1),
                          ),
                  ),
                ),
              ],
            ],
          ),
          if (!_isVerified && _otpSent) ...[
            const SizedBox(height: 12),
            AppTextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              hint: 'Enter Email OTP',
              prefixIcon: Icons.password_rounded,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isVerifying || _isVerified)
                          ? null
                          : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.45,
                        ),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 19,
                              width: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify OTP'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_isSending ||
                              _isVerified ||
                              _resendSecondsRemaining > 0)
                          ? null
                          : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha:0.5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF737378),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 19,
                              width: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_sendOtpLabel, maxLines: 1),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
