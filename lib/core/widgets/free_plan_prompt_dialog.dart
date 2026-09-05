import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/constants/app_colors.dart';

/// Shows a beautiful animated dialog prompting the founder to complete
/// their profile / documents to unlock the full plan experience.
///
/// Call [FreePlanPromptDialog.show] from the dashboard after the data loads.
class FreePlanPromptDialog extends StatefulWidget {
  const FreePlanPromptDialog({
    super.key,
    required this.profileCompletion,
    required this.verificationMissingCount,
    required this.onComplete,
  });

  /// 0–100 profile completion percentage from the dashboard API.
  final int profileCompletion;

  /// Number of missing verification documents.
  final int verificationMissingCount;

  /// Called when the user taps the action button.
  /// [navigateToProfile] true  → go to profile page
  ///                      false → go to verification page
  final void Function({required bool navigateToProfile}) onComplete;

  /// Convenience helper to show the dialog.
  static Future<void> show(
    BuildContext context, {
    required int profileCompletion,
    required int verificationMissingCount,
    required void Function({required bool navigateToProfile}) onComplete,
  }) {
    if (!kIsWeb && Platform.isIOS) {
      return Future.value();
    }
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Free Plan Prompt',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => FreePlanPromptDialog(
        profileCompletion: profileCompletion,
        verificationMissingCount: verificationMissingCount,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<FreePlanPromptDialog> createState() => _FreePlanPromptDialogState();
}

class _FreePlanPromptDialogState extends State<FreePlanPromptDialog>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _orbCtrl;

  late final Animation<double> _shimmerAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _orbAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_orbCtrl);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  bool get _needsProfile => widget.profileCompletion < 100;

  void _onActionTap() {
    Navigator.of(context).pop();
    widget.onComplete(navigateToProfile: _needsProfile);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: screenHeight * 0.85, // never exceed 85% of screen
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF044071).withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbAnim, _shimmerAnim, _pulseAnim]),
      builder: (context, child) {
        final orbAngle = _orbAnim.value * 2 * math.pi;
        return Container(
          width: double.infinity,
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF044071), Color(0xFF0A6EBC), Color(0xFF1589DD)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated background orb 1
              Positioned(
                left: 180 + 60 * math.cos(orbAngle),
                top: 20 + 30 * math.sin(orbAngle),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              // Animated background orb 2
              Positioned(
                left: -20 + 25 * math.sin(orbAngle * 0.7),
                top: 60 + 20 * math.cos(orbAngle * 0.7),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Animated background orb 3
              Positioned(
                right: 30 + 15 * math.cos(orbAngle * 1.3),
                bottom: 10 + 15 * math.sin(orbAngle * 1.3),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Shimmer sweep
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment(_shimmerAnim.value - 1, 0),
                    end: Alignment(_shimmerAnim.value, 0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ).createShader(rect),
                  child: Container(color: Colors.white),
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Claim Your Free Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Complete setup to get free plan access worth of 999',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          _buildProgressRow(),
          const SizedBox(height: 20),

          // Steps
          _buildStep(
            icon: Icons.person_outline_rounded,
            label: 'Complete your profile',
            done: !_needsProfile,
            accent: const Color(0xFF0A6EBC),
          ),
          const SizedBox(height: 10),
          _buildStep(
            icon: Icons.verified_outlined,
            label: 'Upload verification documents',
            done: widget.verificationMissingCount == 0,
            accent: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 24),

          // Description text
          Text(
            _needsProfile
                ? 'Your profile is ${widget.profileCompletion}% complete. Finish your profile first, then upload your documents to get verified.'
                : 'Great! Your profile is complete. Upload ${widget.verificationMissingCount} missing verification document${widget.verificationMissingCount == 1 ? '' : 's'} to get fully verified.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),

          // Action button with shimmer
          _buildActionButton(),
          const SizedBox(height: 10),

          // Dismiss link
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Remind me later',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9AA0A6),
              ),
            ),
          ),
        ],
      ),
    );
  }
      
  Widget _buildProgressRow() {
    final progress = (widget.profileCompletion / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profile Completion',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              '${widget.profileCompletion}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF044071),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF0A6EBC)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required bool done,
    required Color accent,
  }) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? accent.withValues(alpha: 0.12)
                : const Color(0xFFF3F4F6),
            border: Border.all(
              color: done ? accent : const Color(0xFFD1D5DB),
              width: 1.5,
            ),
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            size: 16,
            color: done ? accent : const Color(0xFF9AA0A6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: accent,
            ),
          ),
        ),
        if (done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    final label = _needsProfile ? 'Complete Profile →' : 'Upload Documents →';
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        return GestureDetector(
          onTap: _onActionTap,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF044071), Color(0xFF0A6EBC)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF044071).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer on button
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment(_shimmerAnim.value - 1, 0),
                      end: Alignment(_shimmerAnim.value, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ).createShader(rect),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
