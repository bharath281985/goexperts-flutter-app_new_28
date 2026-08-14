import 'package:flutter/material.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

/// Shared scaffold for auth screens: branded header + card body.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.backAlignment = Alignment.centerLeft,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final AlignmentGeometry backAlignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF4F6FB),

      body: Stack(
        children: [
          // Background ambient gradient glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.06),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ResponsiveWrapper(
              maxWidth: 480,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Branded App Logo
                    SizedBox(
                      height:
                          50, // Shaves off the invisible vertical padding of the image file
                      child: OverflowBox(
                        maxHeight: 150,
                        child: Image.asset(
                          AppAssets.logo,
                          width: 100, // Keeps the logo visually this wide
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Working With You. For You..',
                                style: context.text.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Page Header Title & Subtitle
                    Text(
                      context.tr(title),
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.white : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(subtitle),
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.subtleText
                            : AppColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Elevated Card Container
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),

                      child: child,
                    ),
                    const SizedBox(height: 24),
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
