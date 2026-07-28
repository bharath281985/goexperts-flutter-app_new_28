import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.lineColor,
    this.tagLabel = 'Live data',
    this.tagColor = AppColors.success,
    this.showIcon = true,
  });

  final String title;
  final String value;
  final Color lineColor;
  final String tagLabel;
  final Color tagColor;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlack.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.subtleText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (tagLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon) ...[
                        Icon(Icons.arrow_outward, size: 8, color: tagColor),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        tagLabel,
                        style: TextStyle(
                          fontSize: 8,
                          color: tagColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (showIcon)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_outward, size: 10, color: tagColor),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
