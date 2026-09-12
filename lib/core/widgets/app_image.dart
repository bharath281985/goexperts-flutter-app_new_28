import 'package:flutter/material.dart';

import '../../app/constants/app_assets.dart';

class AppImage extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        image.startsWith('http://') || image.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        image,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(
          AppAssets.appLogo,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    return Image.asset(
      image,
      width: width,
      height: height,
      fit: fit,
    );
  }
}