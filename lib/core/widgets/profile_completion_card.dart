import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../core/widgets/app_card.dart';
import '../extensions/context_extensions.dart';

class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({super.key, required this.percent});
  
  final int percent;

  Color get _color {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      color: _color.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                percent >= 80
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: _color,
                size: 18,
              ),
              AppSizes.hGapSm,
              Expanded(
                child: Text(
                  percent >= 80
                      ? 'Great! Your profile looks strong.'
                      : percent >= 50
                          ? 'Profile is taking shape — keep going!'
                          : 'Complete your profile to get hired faster.',
                  style: context.text.bodySmall?.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: context.text.titleSmall?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          AppSizes.vGapSm,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ],
      ),
    );
  }
}
