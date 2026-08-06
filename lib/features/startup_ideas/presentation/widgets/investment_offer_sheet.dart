import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../domain/repositories/startup_repository.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Shows the investment offer bottom sheet and waits for result.
/// Returns `true` if investment was submitted successfully.
Future<bool?> showInvestmentOfferSheet(
  BuildContext context, {
  required String startupId,
  required String startupName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        InvestmentOfferSheet(startupId: startupId, startupName: startupName),
  );
}

class InvestmentOfferSheet extends StatefulWidget {
  const InvestmentOfferSheet({
    super.key,
    required this.startupId,
    required this.startupName,
  });
  final String startupId;
  final String startupName;

  @override
  State<InvestmentOfferSheet> createState() => _InvestmentOfferSheetState();
}

class _InvestmentOfferSheetState extends State<InvestmentOfferSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _offer = TextEditingController();
  final _equity = TextEditingController();
  final _message = TextEditingController();

  DateTime? _meetingDate;
  bool _submitting = false;
  bool _success = false;

  late final AnimationController _successCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn));
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _offer.dispose();
    _equity.dispose();

    _successCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final body = {
      'startupId': widget.startupId,
      'offer': double.tryParse(_offer.text.trim()) ?? 0,
      'equity': double.tryParse(_equity.text.trim()) ?? 0,
      'message': _message.text.trim(),
    };

    final Result<bool> res = await sl<StartupRepository>().submitOffer(body);

    if (!mounted) return;

    if (res.isFailure) {
      setState(() => _submitting = false);
      context.showSnack(res.failureOrNull!.message, isError: true);
      return;
    }

    // ── success ──────────────────────────────────────────────────────────────
    setState(() {
      _submitting = false;
      _success = true;
    });
    HapticFeedback.lightImpact();
    _successCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _confettiCtrl.forward();

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _success ? _successView() : _formView(),
    );
  }

  // ── Success View ───────────────────────────────────────────────────────────
  Widget _successView() {
    return SizedBox(
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated confetti particles
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 420),
              painter: _ConfettiPainter(progress: _confettiCtrl.value),
            ),
          ),

          // Success card
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsing circle with check
                    _PulseCircle(),
                    const SizedBox(height: 28),
                    Text(
                      'Offer Submitted! 🎉',
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your investment offer for\n${widget.startupName} has been sent.\nThe founder will review and get back to you.',
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // Animated status pill
                    _AnimatedStatusPill(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form View ──────────────────────────────────────────────────────────────
  Widget _formView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          0,
          AppSizes.screenPadding,
          AppSizes.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Investment Offer',
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.startupName,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Offer Amount  +  Equity %
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _FieldLabel(
                      label: 'Offer Amount (₹)',
                      child: TextFormField(
                        controller: _offer,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDeco(
                          hint: 'e.g. 500000',
                          prefixIcon: Icons.currency_rupee_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if ((double.tryParse(v.trim()) ?? 0) <= 0) {
                            return 'Must be > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    flex: 2,
                    child: _FieldLabel(
                      label: 'Equity (%)',
                      child: TextFormField(
                        controller: _equity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDeco(
                          hint: 'e.g. 10.5',
                          prefixIcon: Icons.pie_chart_outline_rounded,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final d = double.tryParse(v.trim());
                          if (d == null || d <= 0 || d > 100) {
                            return '0–100';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Meeting Date
              const SizedBox(height: 16),

              // Message
              _FieldLabel(
                label: 'Message to Founder',
                child: TextFormField(
                  controller: _message,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: _inputDeco(
                    hint:
                        "Introduce yourself and share why you're interested in this startup...",
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 20) {
                      return 'Please write at least 20 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: _submitting ? null : AppColors.primaryGradient,
                    color: _submitting ? AppColors.border : null,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: _submitting
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: MaterialButton(
                    onPressed: _submitting ? null : _submit,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.mutedText,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Submit Offer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your offer will be reviewed by the founder.',
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.subtleText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Pulsing Green Check Circle ───────────────────────────────────────────────

class _PulseCircle extends StatefulWidget {
  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.14,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withAlpha(80),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}

// ── Animated "Pending Review" Status Pill ────────────────────────────────────

class _AnimatedStatusPill extends StatefulWidget {
  @override
  State<_AnimatedStatusPill> createState() => _AnimatedStatusPillState();
}

class _AnimatedStatusPillState extends State<_AnimatedStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: const Color(0xFF16A34A).withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFF16A34A),
                  const Color(0xFF86EFAC),
                  _ctrl.value,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Under Review — Awaiting Founder Response',
            style: TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti Painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});
  final double progress;

  static final _rng = math.Random(42);
  static final _particles = List.generate(50, (i) {
    final color = [
      const Color(0xFFE30613),
      const Color(0xFF16A34A),
      const Color(0xFFF59E0B),
      const Color(0xFF4F46E5),
      const Color(0xFFDB2777),
      const Color(0xFF0EA5E9),
    ][i % 6];
    return _Particle(
      x: _rng.nextDouble(),
      startY: -0.05 - _rng.nextDouble() * 0.2,
      speedY: 0.4 + _rng.nextDouble() * 0.5,
      angle: _rng.nextDouble() * math.pi * 2,
      spin: (_rng.nextBool() ? 1 : -1) * (_rng.nextDouble() * 8 + 2),
      size: 5 + _rng.nextDouble() * 7,
      color: color,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    for (final p in _particles) {
      final y = p.startY + p.speedY * progress;
      if (y > 1.1) continue;
      final paint = Paint()
        ..color = p.color.withAlpha((255 * (1 - progress * 0.6)).toInt());
      canvas.save();
      canvas.translate(p.x * size.width, y * size.height);
      canvas.rotate(p.angle + p.spin * progress);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.5,
      );
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.startY,
    required this.speedY,
    required this.angle,
    required this.spin,
    required this.size,
    required this.color,
  });
  final double x, startY, speedY, angle, spin, size;
  final Color color;
}
