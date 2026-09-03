import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';

/// Ultra-premium surface card with multiple luxury styles:
/// - [AppCard.premium]: Luxury gold/brand gradient border with ambient glow
/// - [AppCard.glass]: Frosted glassmorphism with blur and specular rim border
/// - [AppCard.gold]: Soft warm gold surface with gold ambient highlights
/// - [AppCard.gradient]: Branded gradient fill with rich depth
/// - [AppCard]: Clean modern card with multi-layer shadow and tap physics
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    this.onTap,
    this.color,
    this.gradient,
    this.borderGradient,
    this.border = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.radius = AppSizes.radiusLg,
    this.margin,
    this.elevation = 4.0,
    this.glowColor,
    this.glowRadius = 12.0,
    this.isGlass = false,
    this.blur = 12.0,
    this.enablePressScale = true,
  });

  /// Factory constructor for an ultra-premium card with a luxury gradient border and glow.
  factory AppCard.premium({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSizes.lg),
    VoidCallback? onTap,
    Color? surfaceColor,
    Gradient? borderGradient,
    Color? glowColor,
    double radius = AppSizes.radiusLg,
    EdgeInsetsGeometry? margin,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      onTap: onTap,
      color: surfaceColor,
      borderGradient: borderGradient ??
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gold,
              AppColors.primary,
              AppColors.gold,
            ],
          ),
      borderWidth: 1.2,
      glowColor: glowColor ?? AppColors.gold.withValues(alpha: 0.18),
      glowRadius: 16.0,
      radius: radius,
      margin: margin,
      child: child,
    );
  }

  /// Factory constructor for a modern frosted glassmorphism card.
  factory AppCard.glass({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSizes.lg),
    VoidCallback? onTap,
    Color? tintColor,
    double blur = 14.0,
    double radius = AppSizes.radiusLg,
    EdgeInsetsGeometry? margin,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      onTap: onTap,
      isGlass: true,
      blur: blur,
      color: tintColor,
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.08),
        ],
      ),
      borderWidth: 1.0,
      glowColor: AppColors.primaryBlack.withValues(alpha: 0.04),
      radius: radius,
      margin: margin,
      child: child,
    );
  }

  /// Factory constructor for a gold luxury card background using the second primary medium gold color.
  factory AppCard.gold({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSizes.lg),
    VoidCallback? onTap,
    bool border = true,
    double radius = AppSizes.radiusLg,
    EdgeInsetsGeometry? margin,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      onTap: onTap,
      color: AppColors.cardGoldSurface,
      borderColor: AppColors.cardGoldBorder,
      border: border,
      glowColor: AppColors.gold.withValues(alpha: 0.12),
      glowRadius: 14.0,
      radius: radius,
      margin: margin,
      child: child,
    );
  }

  /// Factory constructor for a branded gradient card background.
  factory AppCard.gradient({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSizes.lg),
    VoidCallback? onTap,
    Gradient gradient = AppColors.primaryGradient,
    Color? glowColor,
    bool border = false,
    Color? borderColor,
    Gradient? borderGradient,
    double borderWidth = 1.0,
    double radius = AppSizes.radiusLg,
    EdgeInsetsGeometry? margin,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      onTap: onTap,
      gradient: gradient,
      glowColor: glowColor ?? AppColors.primary.withValues(alpha: 0.22),
      glowRadius: 16.0,
      border: border || borderColor != null || borderGradient != null,
      borderColor: borderColor,
      borderGradient: borderGradient,
      borderWidth: borderWidth,
      radius: radius,
      margin: margin,
      child: child,
    );
  }

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Gradient? borderGradient;
  final bool border;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final Color? glowColor;
  final double glowRadius;
  final bool isGlass;
  final double blur;
  final bool enablePressScale;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null && widget.enablePressScale) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp([TapUpDetails? _]) {
    if (widget.onTap != null && widget.enablePressScale && _isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && widget.enablePressScale && _isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    final isDark = context.isDark;

    // Multi-layer ambient & key shadows for rich depth
    final effectiveShadows = <BoxShadow>[
      // Ambient shadow
      BoxShadow(
        color: AppColors.shadow.withValues(
          alpha: isDark ? 0.28 : 0.06,
        ),
        blurRadius: widget.elevation * 3,
        offset: Offset(0, widget.elevation),
      ),
      // Micro-contact shadow
      BoxShadow(
        color: AppColors.shadow.withValues(
          alpha: isDark ? 0.18 : 0.04,
        ),
        blurRadius: widget.elevation,
        offset: const Offset(0, 1),
      ),
      // Optional ambient glow (Gold / Brand)
      if (widget.glowColor != null)
        BoxShadow(
          color: widget.glowColor!,
          blurRadius: widget.glowRadius,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
    ];

    // Background fill
    final defaultBg = widget.isGlass
        ? (isDark
            ? AppColors.darkCard.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.72))
        : (widget.color ?? context.theme.cardColor);

    Widget cardContent = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    // Frosted Glassmorphism Blur
    if (widget.isGlass) {
      cardContent = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: cardContent,
        ),
      );
    }

    // Interactive Ink Ripple
    final interactiveBody = widget.onTap == null
        ? cardContent
        : Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: widget.onTap,
              splashColor: AppColors.gold.withValues(alpha: 0.12),
              highlightColor: AppColors.primary.withValues(alpha: 0.06),
              child: cardContent,
            ),
          );

    // Build the outer decoration
    Widget finalCard;

    if (widget.borderGradient != null) {
      // Luxury Gradient Border container
      finalCard = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          gradient: widget.borderGradient,
          borderRadius: borderRadius,
          boxShadow: effectiveShadows,
        ),
        child: Container(
          margin: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            color: widget.gradient == null ? defaultBg : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(
              (widget.radius - widget.borderWidth).clamp(0, double.infinity),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: interactiveBody,
        ),
      );
    } else {
      // Solid Border & Gradient / Solid Fill container
      final effectiveBorderColor = widget.border
          ? (widget.borderColor ?? context.theme.dividerColor)
          : Colors.transparent;

      finalCard = Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.gradient == null ? defaultBg : null,
          gradient: widget.gradient,
          borderRadius: borderRadius,
          border: widget.border
              ? Border.all(
                  color: effectiveBorderColor,
                  width: widget.borderWidth,
                )
              : null,
          boxShadow: effectiveShadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: interactiveBody,
      );
    }

    // Micro-interaction Scale animation on press
    if (widget.onTap != null && widget.enablePressScale) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.translucent,
        child: AnimatedScale(
          scale: _isPressed ? 0.982 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: finalCard,
        ),
      );
    }

    return finalCard;
  }
}
