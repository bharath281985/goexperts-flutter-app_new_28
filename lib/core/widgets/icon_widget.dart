import 'package:flutter/material.dart';

import '../../app/constants/app_assets.dart';
import '../../app/constants/app_colors.dart';

class IconTapWidget extends StatelessWidget {
  const IconTapWidget({
    super.key,
    required this.onTap,
    this.iconImage = AppAssets.backIcon,
    this.isDecorate = true,
    this.padding = 5,
  });

  final VoidCallback? onTap;
  final String? iconImage;
  final bool? isDecorate;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          padding: EdgeInsets.all(padding ?? 5),
          decoration: isDecorate == true
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.9),
                )
              : null,
          child: Image.asset(
            iconImage ?? AppAssets.backIcon,
            width: 25,
            height: 25,
          ),
        ),
      ),
    );
  }
}
