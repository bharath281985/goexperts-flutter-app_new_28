import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/freelancer.dart';

/// Premium, unique freelancer card for discovery & recommendations.
class AppFreelancerCard extends StatelessWidget {
  const AppFreelancerCard({
    super.key,
    required this.freelancer,
    this.onTap,
    this.onSave,
    this.onInvite,
    this.showInvite = true,
  });

  final Freelancer freelancer;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onInvite;
  final bool showInvite;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Headline & Bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: freelancer.name,
                imageUrl: freelancer.avatarUrl,
                size: 56,
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            freelancer.name,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.isDark ? AppColors.white : AppColors.primaryBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (freelancer.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.projectVerified,
                          ),
                        ],
                      ],
                    ),
                    AppSizes.vGapXs,
                    Text(
                      freelancer.headline.isNotEmpty ? freelancer.headline : 'Independent Professional',
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSave,
                icon: Icon(
                  freelancer.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: freelancer.isSaved ? AppColors.primary : AppColors.mutedText,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          
          AppSizes.vGapMd,
          
          // Stats Row: Rating, Location, Experience
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: [
              _StatPill(
                context,
                icon: Icons.star_rounded,
                iconColor: AppColors.warning,
                text: '${freelancer.rating} (${freelancer.reviewsCount})',
              ),
              _StatPill(
                context,
                icon: Icons.location_on_rounded,
                iconColor: AppColors.primary,
                text: freelancer.location,
              ),
              _StatPill(
                context,
                icon: Icons.work_rounded,
                iconColor: AppColors.info,
                text: '${freelancer.experienceYears}+ yrs exp',
              ),
            ],
          ),
          
          AppSizes.vGapMd,
          
          // Skills
          if (freelancer.skills.isNotEmpty) ...[
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.xs,
              children: [
                for (final s in freelancer.skills.take(2)) _tag(context, s),
                if (freelancer.skills.length > 2)
                  _tag(context, '+${freelancer.skills.length - 2}'),
              ],
            ),
            AppSizes.vGapMd,
          ],
          
          const Divider(height: 1),
          AppSizes.vGapMd,
          
          // Footer: Hourly Rate & Invite
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hourly Rate', 
                      style: context.text.labelSmall?.copyWith(color: AppColors.subtleText),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          Formatters.currency(freelancer.hourlyRate),
                          style: context.text.titleMedium?.copyWith(
                            color: context.isDark ? AppColors.white : AppColors.primaryBlack,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/hr', 
                          style: context.text.labelMedium?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showInvite)
                FilledButton.icon(
                  onPressed: onInvite,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha: 0.7),
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Invite', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _StatPill(BuildContext context, {required IconData icon, required Color iconColor, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: context.isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: context.text.labelSmall?.copyWith(
                color: context.isDark ? AppColors.darkText2 : AppColors.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
    ),
    child: Text(
      text,
      style: context.text.labelSmall?.copyWith(
        color: AppColors.success,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
