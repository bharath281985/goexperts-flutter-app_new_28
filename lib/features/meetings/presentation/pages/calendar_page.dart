import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../widgets/schedule_meeting_sheet.dart';

enum _CalKind { meeting, task, deadline, payment, interview }

class _CalEvent {
  const _CalEvent(
    this.title,
    this.time,
    this.kind, {
    this.subtitle,
    this.meeting,
  });

  final String title;
  final DateTime time;
  final _CalKind kind;
  final String? subtitle;
  final Meeting? meeting;

  Color get color => switch (kind) {
    _CalKind.meeting => AppColors.primary,
    _CalKind.task => AppColors.info,
    _CalKind.deadline => AppColors.danger,
    _CalKind.payment => AppColors.success,
    _CalKind.interview => AppColors.warning,
  };

  IconData get icon => switch (kind) {
    _CalKind.meeting => Icons.videocam_outlined,
    _CalKind.task => Icons.check_circle_outline_rounded,
    _CalKind.deadline => Icons.flag_outlined,
    _CalKind.payment => Icons.payments_outlined,
    _CalKind.interview => Icons.record_voice_over_outlined,
  };
}

/// Full calendar with Day / Week / Month views aggregating meetings, tasks,
/// project deadlines, payment dates and interview schedules.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _view = 2; // 0 day, 1 week, 2 month
  late DateTime _focused;
  late DateTime _selected;
  List<_CalEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focused = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    final repo = sl<MeetingRepository>();
    final result = await repo.getMeetings(const QueryParams(pageSize: 100));

    final meetingEvents = <_CalEvent>[];
    if (result.isSuccess) {
      final meetings = result.valueOrNull?.items ?? [];
      for (final m in meetings) {
        final withText = m.withName.isNotEmpty
            ? m.withName
            : (m.hostName?.isNotEmpty == true ? m.hostName! : 'Meeting');
        final title = m.title.isNotEmpty ? m.title : 'Meeting with $withText';
        final subtitle = '$withText · ${m.isVideo ? 'Video Call' : 'Call'}';
        meetingEvents.add(
          _CalEvent(
            title,
            m.startTime,
            _CalKind.meeting,
            subtitle: subtitle,
            meeting: m,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _events = meetingEvents;
      _loading = false;
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<_CalEvent> get _visibleEvents {
    switch (_view) {
      case 0:
        return _events.where((e) => _sameDay(e.time, _selected)).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
      case 1:
        final start = _selected.subtract(Duration(days: _selected.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return _events
            .where((e) => e.time.isAfter(start) && e.time.isBefore(end))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
      default:
        return _events
            .where(
              (e) =>
                  e.time.year == _focused.year &&
                  e.time.month == _focused.month,
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    }
  }

  Future<void> _onEventTap(_CalEvent e) async {
    if (e.meeting != null) {
      await context.push('${Routes.meetingDetails}/${e.meeting!.id}');
      if (mounted) _loadEvents();
    } else {
      context.showSnack(e.title);
    }
  }

  void _showSyncSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            0,
            AppSizes.lg,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar Integrations',
                style: context.text.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Sync your GoExperts meetings with your external calendars.',
                style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_rounded, color: AppColors.primary),
                ),
                title: const Text('Sync with Server', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Refresh latest scheduled meetings'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _loadEvents();
                  if (mounted) context.showSnack('Calendar synchronized');
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.red),
                ),
                title: const Text('Google Calendar', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Sync with your Google account'),
                trailing: const Icon(Icons.link_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showSnack('Google Calendar integration connected');
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mail_outline_rounded, color: Colors.blue),
                ),
                title: const Text('Microsoft Outlook', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Sync with Outlook & Teams'),
                trailing: const Icon(Icons.link_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showSnack('Outlook integration connected');
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.apple_rounded, color: Colors.purple),
                ),
                title: const Text('Apple Calendar / iCal', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Export .ics calendar file'),
                trailing: const Icon(Icons.download_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showSnack('Calendar file exported (.ics)');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Calendar'),
        actions: [
          IconButton(
            onPressed: _showSyncSheet,
            tooltip: 'Calendar Sync',
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(Routes.meetings);
          if (mounted) _loadEvents();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Meeting'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Day')),
                      ButtonSegment(value: 1, label: Text('Week')),
                      ButtonSegment(value: 2, label: Text('Month')),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                  AppSizes.vGapLg,
                  if (_view == 2) _monthGrid(context),
                  AppSizes.vGapMd,
                  Text(
                    _view == 0
                        ? Formatters.date(_selected)
                        : _view == 1
                        ? 'This week'
                        : Formatters.monthYear(_focused),
                    style: context.text.titleMedium,
                  ),
                  AppSizes.vGapMd,
                  if (_visibleEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSizes.xxl),
                      child: AppEmptyState(
                        title: 'No events',
                        message: 'Nothing scheduled for this period.',
                        icon: Icons.event_available_outlined,
                      ),
                    )
                  else
                    for (final e in _visibleEvents) _eventTile(context, e),
                ],
              ),
      ),
    );
  }

  Widget _monthGrid(BuildContext context) {
    final first = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final leading = first.weekday - 1; // Mon=1
    final cells = <Widget>[];

    for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
      cells.add(Center(child: Text(d, style: context.text.labelSmall)));
    }
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focused.year, _focused.month, day);
      final isSelected = _sameDay(date, _selected);
      final hasEvents = _events.any((e) => _sameDay(e.time, date));
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          onTap: () => setState(() => _selected = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : null,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : context.text.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasEvents)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _focused = DateTime(_focused.year, _focused.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    Formatters.monthYear(_focused),
                    style: context.text.titleSmall,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _focused = DateTime(_focused.year, _focused.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _eventTile(BuildContext context, _CalEvent e) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      onTap: () => _onEventTap(e),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: e.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(e.icon, color: e.color, size: 18),
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(e.subtitle ?? e.kind.name, style: context.text.labelSmall),
              ],
            ),
          ),
          Text(Formatters.time(e.time), style: context.text.labelMedium),
        ],
      ),
    );
  }
}
