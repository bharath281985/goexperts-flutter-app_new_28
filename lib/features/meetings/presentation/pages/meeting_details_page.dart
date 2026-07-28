import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/utils/enums.dart';

class MeetingDetailsPage extends StatefulWidget {
  const MeetingDetailsPage({super.key, required this.id});
  final String id;

  @override
  State<MeetingDetailsPage> createState() => _MeetingDetailsPageState();
}

class _MeetingDetailsPageState extends State<MeetingDetailsPage> {
  late Future<Result<Meeting>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = sl<MeetingRepository>().getMeeting(widget.id);
  }

  Future<void> _reschedule(Meeting meeting) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: meeting.startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(meeting.startTime),
    );
    if (pickedTime == null || !mounted) return;

    final newStartTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final res = await sl<MeetingRepository>().reschedule(
      widget.id,
      newStartTime,
    );
    if (!mounted) return;

    res.fold((fail) => context.showSnack(fail.message, isError: true), (_) {
      context.showSnack('Meeting rescheduled successfully!');
      setState(() {
        _load();
      });
    });
  }

  Future<void> _cancelMeeting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meeting'),
        content: const Text('Are you sure you want to cancel this meeting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final res = await sl<MeetingRepository>().cancel(widget.id);
    if (!mounted) return;

    res.fold((fail) => context.showSnack(fail.message, isError: true), (_) {
      context.showSnack('Meeting cancelled successfully!');
      context.pop();
    });
  }

  Future<void> _launchUrl(String url) async {
    String finalUrl = url.trim();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    final uri = Uri.tryParse(finalUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted)
          context.showSnack('Could not launch meeting link', isError: true);
      }
    } else {
      if (mounted) context.showSnack('Invalid meeting link', isError: true);
    }
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    context.showSnack('Meeting link copied to clipboard!');
  }

  void _shareLink(Meeting m) {
    final formatTime =
        '${Formatters.date(m.startTime)} at ${Formatters.time(m.startTime)}';
    final text =
        'Join me for a meeting: ${m.title}\nTime: $formatTime\n\nLink: ${m.meetingLink}';
    Share.share(text, subject: 'Meeting Invitation: ${m.title}');
  }

  void _showShareSheet(BuildContext context, Meeting m) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                0,
                AppSizes.screenPadding,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Meeting Invite',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.meetingLink,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share via apps (WhatsApp, Gmail…)'),
              onTap: () {
                Navigator.of(context).pop();
                _shareLink(m);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.of(context).pop();
                _copyLink(m.meetingLink);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<Meeting>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meeting Details')),
            body: const AppLoadingShimmer(itemCount: 4, height: 110),
          );
        }
        final meeting = snapshot.data?.valueOrNull;
        if (meeting == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meeting Details')),
            body: const AppErrorState(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Meeting Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _showShareSheet(context, meeting),
                tooltip: 'Share options',
              ),
              IconButton(
                icon: const Icon(Icons.event_available_outlined),
                onPressed: () => context.showSnack('Added to calendar'),
              ),
              if (meeting.status != EntityStatus.cancelled)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: _cancelMeeting,
                ),
            ],
          ),
          body: _content(context, meeting),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  if (meeting.status != EntityStatus.cancelled) ...[
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Reschedule',
                        icon: Icons.schedule_rounded,
                        onPressed: () => _reschedule(meeting),
                      ),
                    ),
                    AppSizes.hGapMd,
                  ],
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      label: meeting.status == EntityStatus.cancelled
                          ? 'Cancelled'
                          : 'Join Meeting',
                      icon: Icons.videocam_rounded,
                      onPressed: meeting.status == EntityStatus.cancelled
                          ? null
                          : () => _launchUrl(meeting.meetingLink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, Meeting m) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      children: [
        // Premium Meeting Header Card
        Container(
          padding: const EdgeInsets.all(AppSizes.xl),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.isVideo ? 'Video Call' : 'Voice Call',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppStatusChip.status(m.status, dense: true),
                ],
              ),
              AppSizes.vGapMd,
              Text(
                m.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              if (m.agenda.isNotEmpty) ...[
                AppSizes.vGapSm,
                Text(
                  m.agenda,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        AppSizes.vGapLg,
        AppSizes.vGapSm,

        // Date & Time specific breakdown card
        AppSectionHeader(title: 'When & Where'),
        AppSizes.vGapSm,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: context.text.labelSmall),
                          Text(
                            Formatters.date(m.startTime),
                            style: context.text.titleSmall?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time & Limit', style: context.text.labelSmall),
                          Text(
                            '${Formatters.time(m.startTime)} - ${Formatters.time(m.endTime)} (${m.durationMinutes} min)',
                            style: context.text.titleSmall?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meeting With',
                              style: context.text.labelSmall,
                            ),
                            Text(
                              m.withName,
                              style: context.text.titleSmall?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppAvatar(
                        name: m.withName,
                        imageUrl: m.withAvatar,
                        size: 38,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchUrl(m.meetingLink),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSizes.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: const Icon(
                            Icons.link_rounded,
                            color: AppColors.info,
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meeting Link',
                                style: context.text.labelSmall,
                              ),
                              Text(
                                m.meetingLink,
                                style: context.text.bodyMedium?.copyWith(
                                  color: AppColors.info,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyLink(m.meetingLink),
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 20,
                            color: AppColors.mutedText,
                          ),
                          tooltip: 'Copy Link',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        AppSizes.vGapLg,
        AppSizes.vGapSm,
        AppSectionHeader(title: 'Participants'),
        AppSizes.vGapSm,

        // Participants elegant card
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (m.hostName != null)
                _participantTile(context, m.hostName!, m.hostAvatar, 'Host'),
              if (m.hostName != null) const Divider(height: 1),
              _participantTile(
                context,
                m.withName,
                m.withAvatar,
                'Participant',
              ),

              for (final p in m.participants)
                if (!RegExp(r'^[0-9a-fA-F]{8}-').hasMatch(p) &&
                    !p.startsWith('inv-') &&
                    !p.startsWith('usr-') &&
                    !p.startsWith('client-') &&
                    !p.startsWith('founder-')) ...[
                  const Divider(height: 1),
                  _participantTile(context, p, null, 'Participant'),
                ],
            ],
          ),
        ),

        // Add bottom padding resolving overflow issues near the bottom actions
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _participantTile(
    BuildContext context,
    String name,
    String? avatarUrl,
    String role,
  ) {
    final isHost = role.toLowerCase() == 'host';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          AppAvatar(name: name, imageUrl: avatarUrl, size: 42),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.text.titleSmall?.copyWith(fontSize: 15),
                ),
                Text(
                  role,
                  style: context.text.labelSmall?.copyWith(
                    color: isHost ? AppColors.primary : AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HOST',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
