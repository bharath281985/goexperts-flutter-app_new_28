import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../utils/image_url.dart';

class CustomCachedImage extends StatelessWidget {
  const CustomCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = normalizeImageUrl(imageUrl);
    final fallback =
        errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.primary.withValues(alpha: 0.06),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.mutedText,
            ),
          ),
        );
    final loading =
        placeholder ??
        Container(
          width: width,
          height: height,
          color: AppColors.primary.withValues(alpha: 0.06),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );

    final image = Image(
      image: CachedNetworkImageProvider(resolvedImageUrl),
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return loading;
      },
      errorBuilder: (_, __, ___) => fallback,
    );

    final radius = borderRadius;
    if (radius == null) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}
