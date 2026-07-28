import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

class DashboardActionButton extends StatelessWidget {
  const DashboardActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    this.width = 120,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// A fixed width keeps the action strip safe inside a horizontal ListView,
  /// where the available width is intentionally unbounded.
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlack.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: AppColors.white),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.subtleText,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryBlack,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
