import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import 'app_primary_button.dart';

/// Shows a dialog informing users to access team members via the website.
Future<void> showTeamAccessWebDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => const TeamAccessWebDialog(),
  );
}

class TeamAccessWebDialog extends StatelessWidget {
  const TeamAccessWebDialog({super.key});

  static const String _teamWebUrl = 'https://goexperts.in/business/teams';

  Future<void> _launchTeamUrl() async {
    final uri = Uri.parse(_teamWebUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xxl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    AppSizes.hGapSm,
                    Text(
                      'Team Access',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            AppSizes.vGapLg,
            Text(
              'To access and manage team members, please visit our website.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            AppSizes.vGapXl,
            AppPrimaryButton(
              label: 'Visit Website',
              icon: Icons.open_in_new_rounded,
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchTeamUrl();
              },
            ),
          ],
        ),
      ),
    );
  }
}
