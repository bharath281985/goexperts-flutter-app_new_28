import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/meeting.dart';

/// Reusable meeting card.
class AppMeetingCard extends StatelessWidget {
  const AppMeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
    this.onJoin,
  });

  final Meeting meeting;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  meeting.title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSizes.hGapSm,
              AppStatusChip.status(meeting.status, dense: true),
            ],
          ),

          AppSizes.vGapMd,
          const Divider(height: 1),
          AppSizes.vGapMd,

          // Exactly like the Detailed "Meeting With" widget row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meeting With', style: context.text.labelSmall),
                    Text(
                      meeting.withName,
                      style: context.text.titleSmall?.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppAvatar(
                name: meeting.withName,
                imageUrl: meeting.withAvatar,
                size: 36,
              ),
            ],
          ),

          AppSizes.vGapMd,
          const Divider(height: 1),
          AppSizes.vGapMd,

          // Bottom Row: Date/Time + Action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      meeting.isVideo
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${Formatters.date(meeting.startTime)} · ${Formatters.time(meeting.startTime)}',
                      style: context.text.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (meeting.isUpcoming) ...[
                AppSizes.hGapSm,
                FilledButton.icon(
                  onPressed: onJoin ?? onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text(
                    'Join',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
