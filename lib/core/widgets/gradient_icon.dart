import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../extensions/context_extensions.dart';

/// A reusable icon widget that applies a gradient shader.
///
/// Can be customized with a custom [gradient], a list of [colors],
/// or defaults to the theme's primary and secondary colors.
class GradientIcon extends StatelessWidget {
  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.gradient,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.blendMode = BlendMode.srcIn,
    this.semanticLabel,
  });

  /// Factory constructor for brand primary gradient.
  factory GradientIcon.primary({
    Key? key,
    required IconData icon,
    double size = 24.0,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    String? semanticLabel,
  }) {
    return GradientIcon(
      key: key,
      icon: icon,
      size: size,
      gradient: AppColors.primaryGradient,
      begin: begin,
      end: end,
      semanticLabel: semanticLabel,
    );
  }

  /// Factory constructor for medium gold gradient.
  factory GradientIcon.gold({
    Key? key,
    required IconData icon,
    double size = 24.0,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    String? semanticLabel,
  }) {
    return GradientIcon(
      key: key,
      icon: icon,
      size: size,
      gradient: AppColors.goldGradient,
      begin: begin,
      end: end,
      semanticLabel: semanticLabel,
    );
  }

  final IconData icon;
  final double size;
  final Gradient? gradient;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final BlendMode blendMode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ??
        (colors != null && colors!.isNotEmpty
            ? (colors!.length == 1
                ? LinearGradient(
                    begin: begin,
                    end: end,
                    colors: [colors!.first, colors!.first],
                  )
                : LinearGradient(
                    begin: begin,
                    end: end,
                    colors: colors!,
                  ))
            : LinearGradient(
                begin: begin,
                end: end,
                colors: [
                  context.colors.primary,
                  context.colors.secondary,
                ],
              ));

    return ShaderMask(
      blendMode: blendMode,
      shaderCallback: (Rect bounds) => effectiveGradient.createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
