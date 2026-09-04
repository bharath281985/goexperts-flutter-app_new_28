import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/contact_workflow.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_action_sheet.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../freelancer_dashboard/presentation/pages/freelancer_subpages.dart';
import '../../../investor_dashboard/presentation/pages/portfolio_list_view.dart';
import '../../domain/entities/review.dart';

enum PublicProfileType { freelancer, company, investor, founder }

/// View-model that adapts any role entity into a public profile layout.
class ProfileViewData {
  const ProfileViewData({
    this.id,
    required this.name,
    required this.headline,
    required this.location,
    this.avatarUrl,
    this.isVerified = true,
    this.about = '',
    this.rating,
    this.reviewsCount = 0,
    this.followers = 0,
    this.stats = const {},
    this.skills = const [],
    this.industries = const [],
    this.workModes = const [],
    this.preferredStages = const [],
    this.primaryActionLabel = 'Contact',
    this.primaryActionIcon = Icons.mail_outline_rounded,
    this.isFollowing = false,
    this.isSaved = false,
    this.type = PublicProfileType.freelancer,
    this.phone = '+91 98765 43210',
    this.email = 'info@goexperts.example',
    this.experience = '',
    this.experienceLevel = '',
    this.education = '',
    this.linkedin = '',
    this.website = '',
    this.portfolioUrl = '',
    this.linkedInUrl = '',
    this.githubUrl = '',
    this.websiteUrl = '',
    this.hourlyRate,
  });

  final String? id;
  final String name;
  final String headline;
  final String location;
  final String? avatarUrl;
  final bool isVerified;
  final String about;
  final double? rating;
  final int reviewsCount;
  final int followers;
  final Map<String, String> stats;
  final List<String> skills;
  final List<String> industries;
  final List<String> workModes;
  // Nullable keeps existing view-model instances safe across hot reloads when
  // this field is introduced; rendering always normalizes null to an empty list.
  final List<String>? preferredStages;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final bool isFollowing;
  final bool isSaved;
  final PublicProfileType type;
  final String phone;
  final String email;
  final String experience;
  final String experienceLevel;
  final String education;
  final String linkedin;
  final String website;
  final String portfolioUrl;
  final String linkedInUrl;
  final String githubUrl;
  final String websiteUrl;
  final double? hourlyRate;
}

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.data,
    this.reviews = const [],
    this.onPrimaryAction,
    this.onMessage,

    this.onBookmark,
    this.onShare,
  });

  final ProfileViewData data;
  final List<Review> reviews;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onMessage;

  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final displaySkills = _uniqueSkills(data.skills);

    if (data.type == PublicProfileType.investor) {
      return _investorView(context, displaySkills);
    }

    if (data.type == PublicProfileType.founder) {
      return _founderView(context, displaySkills);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _banner(context),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppAvatar(
                    name: data.name,
                    imageUrl: data.avatarUrl,
                    size: 84,
                  ),
                ),
                AppSizes.vGapMd,
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        data.name,
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                Text(data.headline, style: context.text.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data.location,
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data.rating != null) ...[
                      AppSizes.hGapMd,
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      Text(
                        ' ${data.rating} (${data.reviewsCount})',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ],
                ),
                AppSizes.vGapLg,
                _actions(context),
                AppSizes.vGapLg,
                if (data.stats.isNotEmpty) _statsCard(context),
                if (data.about.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'About'),
                  AppSizes.vGapSm,
                  Text(data.about, style: context.text.bodyMedium),
                ],
                if (displaySkills.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  if (data.type == PublicProfileType.investor)
                    _investmentFocus(context, displaySkills)
                  else ...[
                    const AppSectionHeader(title: 'Skills & Expertise'),
                    AppSizes.vGapSm,
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: [
                        for (final skill in displaySkills)
                          _chip(context, skill),
                      ],
                    ),
                  ],
                ],
                if (data.industries.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Industry & Domain'),
                  AppSizes.vGapSm,
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      for (final ind in data.industries)
                        _chip(context, ind),
                    ],
                  ),
                ],
                if (data.workModes.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Work Mode'),
                  AppSizes.vGapSm,
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      for (final mode in data.workModes)
                        _chip(context, mode),
                    ],
                  ),
                ],
                if (data.experience.isNotEmpty ||
                    data.experienceLevel.isNotEmpty ||
                    data.education.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Background & Expertise'),
                  AppSizes.vGapSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.experienceLevel.isNotEmpty ||
                            data.experience.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.work_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              AppSizes.hGapMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          'Experience Level',
                                          style: context.text.labelSmall
                                              ?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data.experienceLevel.isNotEmpty
                                          ? data.experienceLevel
                                          : data.experience,
                                      style: context.text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((data.experienceLevel.isNotEmpty ||
                                data.experience.isNotEmpty) &&
                            data.education.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 24.0,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Container(
                              width: 2,
                              height: 24,
                              color: AppColors.border,
                            ),
                          ),
                        ],
                        if (data.education.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                              ),
                              AppSizes.hGapMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          'Education',
                                          style: context.text.labelSmall
                                              ?.copyWith(
                                                color: AppColors.warning,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data.education,
                                      style: context.text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                () {
                  final links = <Widget>[];
                  final freelancerId = data.id;
                  if ((freelancerId != null && freelancerId.isNotEmpty) ||
                      data.portfolioUrl.trim().isNotEmpty) {
                    links.add(
                      _linkCard(
                        context,
                        'Portfolio',
                        'View Portfolio',
                        Icons.folder_special_outlined,
                        data.portfolioUrl.trim(),
                        onTap: freelancerId != null && freelancerId.isNotEmpty
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FreelancerPortfolioPage(
                                      freelancerId: freelancerId,
                                      isReadOnly: true,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  }
                  final linkedIn = data.linkedInUrl.trim().isNotEmpty
                      ? data.linkedInUrl.trim()
                      : data.linkedin.trim();
                  if (linkedIn.isNotEmpty) {
                    links.add(
                      _linkCard(
                        context,
                        'LinkedIn',
                        'Professional Profile',
                        Icons.link_rounded,
                        linkedIn,
                      ),
                    );
                  }
                  if (data.githubUrl.trim().isNotEmpty) {
                    links.add(
                      _linkCard(
                        context,
                        'GitHub',
                        'Code Repositories',
                        Icons.code_rounded,
                        data.githubUrl.trim(),
                      ),
                    );
                  }
                  final website = data.websiteUrl.trim().isNotEmpty
                      ? data.websiteUrl.trim()
                      : data.website.trim();
                  if (website.isNotEmpty) {
                    links.add(
                      _linkCard(
                        context,
                        'Website',
                        'Personal Website',
                        Icons.language_rounded,
                        website,
                      ),
                    );
                  }

                  if (links.isEmpty) return const SizedBox.shrink();

                  final rows = <Widget>[];
                  for (int i = 0; i < links.length; i += 2) {
                    if (i + 1 < links.length) {
                      rows.add(
                        Row(
                          children: [
                            Expanded(child: links[i]),
                            AppSizes.hGapMd,
                            Expanded(child: links[i + 1]),
                          ],
                        ),
                      );
                    } else {
                      rows.add(
                        Row(
                          children: [
                            Expanded(child: links[i]),
                          ],
                        ),
                      );
                    }
                    if (i + 2 < links.length) {
                      rows.add(AppSizes.vGapMd);
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSizes.vGapXl,
                      const AppSectionHeader(title: 'Portfolio & Links'),
                      AppSizes.vGapMd,
                      ...rows,
                    ],
                  );
                }(),
                if (reviews.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Reviews'),
                  AppSizes.vGapSm,
                  for (final r in reviews) _review(context, r),
                ],
                AppSizes.vGapXxl,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _investorView(BuildContext context, List<String> focusAreas) {
    final stages = _uniqueSkills(data.preferredStages ?? const <String>[]);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _banner(context),
        Transform.translate(
          offset: const Offset(0, -34),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _investorIdentity(context),
                AppSizes.vGapMd,
                _investorActions(context),
                if (data.stats.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  _statsCard(context),
                ],
                if (data.id != null && data.id!.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  _investorPortfolioCard(context),
                ],
                AppSizes.vGapLg,
                _investorThesis(context),
                if (focusAreas.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  _investmentFocus(context, focusAreas),
                ],
                if (stages.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  _preferredStages(context, stages),
                ],
                if (data.phone.isNotEmpty || data.email.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  _investorContact(context),
                ],
                if (reviews.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Founder Reviews'),
                  AppSizes.vGapSm,
                  for (final review in reviews) _review(context, review),
                ],
                AppSizes.vGapXxl,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _investorIdentity(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSizes.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  width: 2,
                ),
              ),
              child: AppAvatar(
                name: data.name,
                imageUrl: data.avatarUrl,
                size: 74,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                'INVESTOR DOSSIER',
                style: context.text.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        AppSizes.vGapMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                data.name,
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            if (data.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          data.headline,
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (data.location.trim().isNotEmpty) ...[
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.location,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _investorActions(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onPrimaryAction,
              icon: Icon(data.primaryActionIcon, size: 18),
              label: Text(data.primaryActionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
          AppSizes.hGapSm,
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ),
      AppSizes.vGapSm,
      Row(
        children: [
          Expanded(
            child: _dossierAction(
              context,
              icon: data.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              label: data.isSaved ? 'Saved' : 'Save',
              onTap: onBookmark,
              active: data.isSaved,
            ),
          ),
          AppSizes.hGapSm,
          Expanded(
            child: _dossierAction(
              context,
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: onShare,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _dossierAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool active = false,
  }) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 17),
    label: Text(label, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: active ? AppColors.primary : null,
      backgroundColor: active
          ? AppColors.primary.withValues(alpha: 0.06)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size.fromHeight(42),
      side: BorderSide(
        color: active
            ? AppColors.primary.withValues(alpha: 0.45)
            : Theme.of(context).dividerColor,
      ),
    ),
  );

  Widget _investorThesis(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSizes.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            AppSizes.hGapSm,
            Text(
              'Investment Thesis',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        AppSizes.vGapMd,
        Text(
          data.about.trim().isEmpty
              ? 'This investor has not shared a public investment thesis yet. Explore their focus areas and preferred stages below.'
              : data.about,
          style: context.text.bodyMedium?.copyWith(
            color: data.about.trim().isEmpty ? AppColors.mutedText : null,
            height: 1.55,
          ),
        ),
      ],
    ),
  );

  Widget _preferredStages(BuildContext context, List<String> stages) => AppCard(
    padding: const EdgeInsets.all(AppSizes.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Stages',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Company maturity this investor typically considers',
          style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
        AppSizes.vGapMd,
        for (var i = 0; i < stages.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.flag_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              AppSizes.hGapSm,
              Expanded(
                child: Text(
                  stages[i],
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (i != stages.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Divider(height: 1, color: Theme.of(context).dividerColor),
            ),
        ],
      ],
    ),
  );

  Widget _investorContact(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSizes.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact',
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Available after you are ready to start a conversation',
          style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
        AppSizes.vGapMd,
        if (data.email.isNotEmpty)
          _contactLine(context, Icons.mail_outline_rounded, data.email),
        if (data.email.isNotEmpty && data.phone.isNotEmpty) AppSizes.vGapMd,
        if (data.phone.isNotEmpty)
          _contactLine(context, Icons.phone_outlined, data.phone),
      ],
    ),
  );

  Widget _contactLine(BuildContext context, IconData icon, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      AppSizes.hGapSm,
      Expanded(
        child: Text(
          value,
          style: context.text.bodyMedium?.copyWith(height: 1.35),
        ),
      ),
    ],
  );

  Widget _founderView(BuildContext context, List<String> displaySkills) {
    final startupEntry = data.stats.entries
        .cast<MapEntry<String, String>?>()
        .firstWhere(
          (entry) => entry!.key.toLowerCase().contains('startup'),
          orElse: () => null,
        );
    final raisedEntry = data.stats.entries
        .cast<MapEntry<String, String>?>()
        .firstWhere(
          (entry) => entry!.key.toLowerCase().contains('raised'),
          orElse: () => null,
        );
    final goalEntry = data.stats.entries
        .cast<MapEntry<String, String>?>()
        .firstWhere((entry) {
          final key = entry!.key.toLowerCase();
          return key.contains('goal') || key.contains('target');
        }, orElse: () => null);
    final startupName = startupEntry?.value.trim().isNotEmpty == true
        ? startupEntry!.value
        : (data.headline.trim().isNotEmpty ? data.headline : data.name);
    final metrics = data.stats.entries
        .where(
          (entry) =>
              entry.key != startupEntry?.key &&
              entry.key != raisedEntry?.key &&
              entry.key != goalEntry?.key,
        )
        .take(3)
        .toList(growable: false);
    final raised = _founderNumericValue(raisedEntry?.value);
    final goal = _founderNumericValue(goalEntry?.value);
    final fundingProgress = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
    final profileChips = <String>[
      for (final entry in data.stats.entries)
        if (entry.key.toLowerCase().contains('industry') ||
            entry.key.toLowerCase().contains('type') ||
            entry.key.toLowerCase().contains('stage'))
          entry.value,
      if (data.location.trim().isNotEmpty) data.location,
    ].where((value) => value.trim().isNotEmpty).take(3).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AspectRatio(
              aspectRatio: 2.45,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/profile_cover.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.darkGradient,
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3111111)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSizes.screenPadding,
              bottom: -42,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: AppAvatar(
                  name: data.name,
                  imageUrl: data.avatarUrl,
                  size: 80,
                ),
              ),
            ),
            Positioned(
              right: AppSizes.screenPadding,
              bottom: 12,
              child: Row(
                children: [
                  _founderCoverAction(
                    icon: Icons.share_outlined,
                    onTap: onShare,
                  ),
                  const SizedBox(width: 8),
                  _founderCoverAction(
                    icon: data.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    onTap: onBookmark,
                    active: data.isSaved,
                  ),
                  const SizedBox(width: 8),
                  _founderCoverAction(
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _more(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            54,
            AppSizes.screenPadding,
            AppSizes.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    'STARTUP PROFILE',
                    style: context.text.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              AppSizes.vGapSm,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      startupName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall?.copyWith(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (data.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.projectVerified,
                      size: 21,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                data.headline.isNotEmpty && data.headline != startupName
                    ? data.headline
                    : data.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              if (data.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.mutedText,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        data.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (profileChips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: profileChips
                      .map((value) => _founderMetaChip(context, value))
                      .toList(),
                ),
              ],
              if (metrics.isNotEmpty) ...[
                AppSizes.vGapLg,
                const AppSectionHeader(title: 'Overview'),
                AppSizes.vGapSm,
                AppCard(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 360 ? 3 : 2;
                      final itemWidth =
                          (constraints.maxWidth -
                              (AppSizes.sm * (columns - 1))) /
                          columns;
                      return Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: metrics
                            .map(
                              (metric) => Container(
                                width: itemWidth,
                                constraints: const BoxConstraints(
                                  minHeight: 76,
                                ),
                                padding: const EdgeInsets.all(AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      metric.value,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.titleMedium?.copyWith(
                                        color: AppColors.darkText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      metric.key,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelSmall?.copyWith(
                                        color: AppColors.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
              if (raisedEntry != null || goalEntry != null) ...[
                AppSizes.vGapMd,
                AppCard(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal > 0 ? 'Funding progress' : 'Funding',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSizes.vGapSm,
                      if (goal > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: fundingProgress,
                            backgroundColor: AppColors.border,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSizes.vGapSm,
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                raisedEntry == null
                                    ? 'Raised —'
                                    : 'Raised ${raisedEntry.value}',
                                style: context.text.bodySmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Goal ${goalEntry!.value}',
                                textAlign: TextAlign.end,
                                style: context.text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            AppSizes.hGapMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    raisedEntry == null
                                        ? 'Raised amount not public'
                                        : 'Raised ${raisedEntry.value}',
                                    style: context.text.titleMedium?.copyWith(
                                      color: AppColors.darkText,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Funding target is not public',
                                    style: context.text.bodySmall?.copyWith(
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              AppSizes.vGapLg,
              _founderSection(
                context,
                title: 'About the startup',
                icon: Icons.person_outline_rounded,
                child: Text(
                  data.about.isEmpty
                      ? 'This founder has not added an introduction yet.'
                      : data.about,
                  style: context.text.bodyMedium?.copyWith(
                    color: data.about.isEmpty
                        ? AppColors.mutedText
                        : AppColors.darkText,
                    height: 1.55,
                  ),
                ),
              ),
              AppSizes.vGapLg,
              _founderSection(
                context,
                title: 'Team',
                icon: Icons.groups_2_outlined,
                child: Row(
                  children: [
                    AppAvatar(
                      name: data.name,
                      imageUrl: data.avatarUrl,
                      size: 48,
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Founder',
                            style: context.text.bodySmall?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (displaySkills.isNotEmpty) ...[
                AppSizes.vGapLg,
                _founderSection(
                  context,
                  title: 'Goals & expertise',
                  icon: Icons.auto_awesome_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displaySkills
                        .map((skill) => _chip(context, skill))
                        .toList(),
                  ),
                ),
              ],
              if (data.email.isNotEmpty ||
                  data.phone.isNotEmpty ||
                  data.website.isNotEmpty ||
                  data.linkedin.isNotEmpty) ...[
                AppSizes.vGapLg,
                _founderSection(
                  context,
                  title: 'Profile details',
                  icon: Icons.contact_page_outlined,
                  child: Column(
                    children: [
                      if (data.email.isNotEmpty)
                        _founderDetail(
                          context,
                          Icons.mail_outline_rounded,
                          data.email,
                        ),
                      if (data.phone.isNotEmpty)
                        _founderDetail(
                          context,
                          Icons.phone_outlined,
                          data.phone,
                        ),
                      if (data.website.isNotEmpty)
                        _founderDetail(
                          context,
                          Icons.language_rounded,
                          data.website,
                        ),
                      if (data.linkedin.isNotEmpty)
                        _founderDetail(
                          context,
                          Icons.link_rounded,
                          data.linkedin,
                        ),
                    ],
                  ),
                ),
              ],
              if (reviews.isNotEmpty) ...[
                AppSizes.vGapLg,
                const AppSectionHeader(title: 'Founder Reviews'),
                AppSizes.vGapSm,
                for (final review in reviews) _review(context, review),
              ],
              AppSizes.vGapLg,
              _founderBottomActions(context),
            ],
          ),
        ),
      ],
    );
  }

  double _founderNumericValue(String? value) {
    if (value == null) return 0;
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  Widget _founderMetaChip(BuildContext context, String value) => Container(
    constraints: const BoxConstraints(maxWidth: 210),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.labelMedium?.copyWith(
        color: AppColors.darkText,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _founderBottomActions(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSizes.sm),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Message'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
        AppSizes.hGapSm,
        Expanded(
          child: FilledButton.icon(
            onPressed: onPrimaryAction,
            icon: Icon(data.primaryActionIcon, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(data.primaryActionLabel),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _founderCoverAction({
    required IconData icon,
    VoidCallback? onTap,
    bool active = false,
  }) => Material(
    color: Colors.black.withValues(alpha: 0.58),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(
          icon,
          color: active ? AppColors.primary : Colors.white,
          size: 21,
        ),
      ),
    ),
  );

  Widget _founderSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) => AppCard(
    padding: const EdgeInsets.all(AppSizes.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: context.text.titleMedium?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        AppSizes.vGapMd,
        child,
      ],
    ),
  );

  Widget _founderDetail(BuildContext context, IconData icon, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.mutedText, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      );

  Widget _banner(BuildContext context) => Container(
    height: 150,
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      image: const DecorationImage(
        image: AssetImage('assets/images/profile_cover.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.black.withAlpha(30),
            AppColors.black.withAlpha(150),
          ],
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _bannerAction(context, Icons.share_outlined, onShare ?? () {}),
                // _bannerAction(
                //   context,
                //   Icons.more_vert_rounded,
                //   () => _more(context),
                // ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onPrimaryAction,
            icon: Icon(data.primaryActionIcon, size: 18),
            label: Text(data.primaryActionLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
        AppSizes.hGapMd,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
        AppSizes.hGapMd,
        if (data.type != PublicProfileType.founder) ...[],
        _iconAction(
          context,
          data.isSaved
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          onBookmark,
        ),
      ],
    );
  }

  Widget _iconAction(
    BuildContext context,
    IconData icon,
    VoidCallback? onTap,
  ) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: context.theme.dividerColor),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: icon == Icons.bookmark_rounded ? AppColors.primary : null,
      ),
    ),
  );

  Widget _statsCard(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: 0),
    child: Row(
      children: [
        for (int i = 0; i < data.stats.length; i++) ...[
          if (i > 0) Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.stats.values.elementAt(i),
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.stats.keys.elementAt(i),
                    style: context.text.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _chip(BuildContext context, String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
    ),
    child: Text(
      s,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  List<String> _uniqueSkills(List<String> skills) {
    final seen = <String>{};
    return skills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty && seen.add(skill.toLowerCase()))
        .toList(growable: false);
  }

  Widget _investmentFocus(BuildContext context, List<String> focusAreas) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.55);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                          ),
                          AppSizes.hGapMd,
                          Expanded(
                            child: Text(
                              'Investment Focus',
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sectors this investor actively explores',
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                          height: 1.35,
                        ),
                      ),
                      AppSizes.vGapMd,
                      for (var index = 0; index < focusAreas.length; index++)
                        _focusAreaRow(
                          context,
                          focusAreas[index],
                          index: index,
                          isLast: index == focusAreas.length - 1,
                          dividerColor: dividerColor,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusAreaRow(
    BuildContext context,
    String focusArea, {
    required int index,
    required bool isLast,
    required Color dividerColor,
  }) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.32),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
        ),
        AppSizes.hGapSm,
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            margin: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.sm),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: dividerColor)),
            ),
            alignment: Alignment.topLeft,
            child: Text(
              focusArea,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _investorPortfolioCard(BuildContext context) => AppCard(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicInvestorPortfolioPage(
            investorId: data.id!,
            investorName: data.name,
          ),
        ),
      );
    },
    padding: const EdgeInsets.all(AppSizes.md),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pie_chart_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        AppSizes.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portfolio & Investments',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'View verified portfolio holdings & backed ventures',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.mutedText,
        ),
      ],
    ),
  );

  Widget _linkCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String url, {
    VoidCallback? onTap,
  }) => InkWell(
    onTap: () async {
      if (onTap != null) {
        onTap();
        return;
      }
      if (url.trim().isEmpty) return;
      var cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        context.showSnack('Opening $title ($cleanUrl)...');
      }
    },
    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    child: Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: AppColors.mutedText,
              ),
            ],
          ),
          AppSizes.vGapMd,
          Text(
            title,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.text.labelSmall?.copyWith(
              color: AppColors.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );

  Widget _review(BuildContext context, Review r) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: r.authorName, imageUrl: r.authorAvatar, size: 34),
              AppSizes.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.authorName, style: context.text.titleSmall),
                    Text(r.context, style: context.text.labelSmall),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  Text(
                    ' ${r.rating}',
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSizes.vGapSm,
          Text(r.comment, style: context.text.bodySmall),
          const SizedBox(height: 4),
          Text(
            Formatters.relative(r.createdAt),
            style: context.text.labelSmall,
          ),
        ],
      ),
    ),
  );

  void _more(BuildContext context) => AppActionSheet.show(
    context,
    title: data.name,
    actions: [
      AppAction(
        label: 'Share Profile',
        icon: Icons.share_outlined,
        onTap: () => onShare?.call(),
      ),
      AppAction(
        label: 'Contact Now (Call/Email/WA)',
        icon: Icons.contact_phone_outlined,
        onTap: () => ContactWorkflow.showContactOptions(
          context,
          name: data.name,
          phone: data.phone,
          emailAddress: data.email,
        ),
      ),
      AppAction(
        label: 'Schedule Meeting',
        icon: Icons.event_outlined,
        onTap: () => ContactWorkflow.scheduleMeeting(context, data.name),
      ),
      AppAction(
        label: 'Book Consultation',
        icon: Icons.calendar_today_outlined,
        onTap: () => ContactWorkflow.bookConsultation(context, data.name),
      ),
      AppAction(
        label: 'Voice Call Placeholder',
        icon: Icons.phone_callback_outlined,
        onTap: () =>
            context.showSnack('Voice calling ${data.name} (WebRTC ready)â€¦'),
      ),
      AppAction(
        label: 'Video Call Placeholder',
        icon: Icons.video_call_outlined,
        onTap: () =>
            context.showSnack('Video calling ${data.name} (WebRTC ready)â€¦'),
      ),
      AppAction(
        label: 'Invite ${data.name}',
        icon: Icons.person_add_alt_1_outlined,
        onTap: () => ContactWorkflow.invite(context, data.name),
      ),
      if (data.type == PublicProfileType.freelancer)
        AppAction(
          label: 'Hire Now',
          icon: Icons.handshake_outlined,
          onTap: () => ContactWorkflow.hire(context, data.name),
        ),

      AppAction(
        label: 'Copy Profile Link',
        icon: Icons.link_rounded,
        onTap: () {
          context.showSnack('Profile link copied to clipboard!');
        },
      ),
      if (data.type == PublicProfileType.freelancer)
        AppAction(
          label: 'Download Resume',
          icon: Icons.download_rounded,
          onTap: () =>
              context.showSnack('Downloading Resume of ${data.name}â€¦'),
        ),
      if (data.type == PublicProfileType.company)
        AppAction(
          label: 'Download Company Profile',
          icon: Icons.download_rounded,
          onTap: () => context.showSnack('Downloading Company Profileâ€¦'),
        ),
      if (data.type == PublicProfileType.founder)
        AppAction(
          label: 'Download Pitch Deck',
          icon: Icons.download_rounded,
          onTap: () => context.showSnack('Downloading Pitch Deckâ€¦'),
        ),
      AppAction(
        label: 'Download Portfolio',
        icon: Icons.download_rounded,
        onTap: () => context.showSnack('Downloading Portfolioâ€¦'),
      ),
      AppAction(
        label: 'Report Profile',
        icon: Icons.flag_outlined,
        isDestructive: true,
        onTap: () => context.showSnack('Report submitted for investigation.'),
      ),
    ],
  );
}
