import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../client_dashboard/domain/repositories/client_proposal_repository.dart';
import '../../../proposals/domain/entities/proposal.dart';

Widget _proposalCard(BuildContext context, Proposal p) => AppCard(
  onTap: () => context.push('${Routes.proposalDetails}/${p.id}'),
  child: Row(
    children: [
      AppAvatar(name: p.freelancerName, imageUrl: p.freelancerAvatar, size: 44),
      AppSizes.hGapMd,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.freelancerName, style: context.text.titleSmall),
            Text(
              p.projectTitle,
              style: context.text.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            AppSizes.vGapXs,
            Text(
              '${Formatters.compactCurrency(p.bidAmount)}${p.isHourly ? '/hr' : ''}',
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
      AppStatusChip.status(p.status, dense: true),
    ],
  ),
);

class ClientApplicationsPage extends StatelessWidget {
  const ClientApplicationsPage({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Applications')),
    body: CatalogView<Proposal>(
      fetcher: (q) => sl<ClientProposalRepository>().getProposals(q),
      searchHint: 'Search applicants…',
      emptyTitle: 'No applications yet',
      itemBuilder: (context, p, __) => _proposalCard(context, p),
    ),
  );
}

class ClientShortlistedPage extends StatelessWidget {
  const ClientShortlistedPage({super.key});

  Future<Result<Paginated<Proposal>>> _fetch(QueryParams q) async {
    final res = await sl<ClientProposalRepository>().getProposals(q);
    return res.fold((f) => Err(f), (p) {
      final items = p.items
          .where(
            (x) =>
                x.status == EntityStatus.shortlisted ||
                x.status == EntityStatus.accepted,
          )
          .toList();
      return Success(
        Paginated(
          items: items,
          page: p.page,
          totalPages: 1,
          totalItems: items.length,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Shortlisted')),
    body: CatalogView<Proposal>(
      fetcher: _fetch,
      searchHint: 'Search shortlisted…',
      emptyTitle: 'No one shortlisted yet',
      emptyIcon: Icons.star_outline_rounded,
      itemBuilder: (context, p, __) => _proposalCard(context, p),
    ),
  );
}

class ClientTask {
  const ClientTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.priority,
    required this.status,
    required this.progress,
    this.assignedTo,
    this.dueDate,
    this.projectTitle,
  });

  final String id;
  final String projectId;
  final String title;
  final String priority;
  final String status;
  final int progress;
  final String? assignedTo;
  final DateTime? dueDate;
  final String? projectTitle;

  factory ClientTask.fromApiJson(Map<String, dynamic> json) {
    final project = json['project'];
    return ClientTask(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Task',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'In Progress',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      assignedTo:
          json['assignedTo']?.toString() ?? json['assignee']?.toString(),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),
      projectTitle: project is Map
          ? project['title']?.toString()
          : json['projectTitle']?.toString(),
    );
  }
}

class ClientProjectOption {
  const ClientProjectOption({required this.id, required this.title});

  final String id;
  final String title;

  factory ClientProjectOption.fromApiJson(Map<String, dynamic> json) {
    return ClientProjectOption(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Project',
    );
  }
}

class ClientTasksPage extends StatefulWidget {
  const ClientTasksPage({super.key});

  @override
  State<ClientTasksPage> createState() => _ClientTasksPageState();
}

class _ClientTasksPageState extends State<ClientTasksPage> {
  int _refreshKey = 0;

  Future<Result<Paginated<ClientTask>>> _fetch(QueryParams q) async {
    try {
      final response = await sl<DioClient>().raw.get<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}${ApiEndpoints.clientTasks}',
        queryParameters: q.toApiQuery(),
      );
      final body = response.data ?? const <String, dynamic>{};
      final raw = body['data'] ?? body['rows'] ?? const [];
      final items = (raw is List ? raw : const [])
          .whereType<Map>()
          .map((e) => ClientTask.fromApiJson(Map<String, dynamic>.from(e)))
          .toList();
      final meta = body['meta'] is Map
          ? Map<String, dynamic>.from(body['meta'] as Map)
          : const <String, dynamic>{};
      final total =
          meta['total'] as int? ?? body['total'] as int? ?? items.length;
      final limit = meta['limit'] as int? ?? q.pageSize;
      final page = meta['page'] as int? ?? q.page;
      final totalPages =
          meta['totalPages'] as int? ??
          (total == 0 ? 1 : (total / limit).ceil().clamp(1, 999999));
      return Success(
        Paginated(
          items: items,
          page: page,
          totalPages: totalPages,
          totalItems: total,
        ),
      );
    } catch (_) {
      return const Err(ServerFailure('Failed to load tasks'));
    }
  }

  Future<void> _openAddTask() async {
    final created = await context.push<bool>(Routes.clientAddTask);
    if (created == true && mounted) {
      setState(() => _refreshKey++);
    }
  }

  Future<void> _openEditTask(ClientTask task) async {
    final updated = await context.push<bool>(Routes.clientAddTask, extra: task);
    if (updated == true && mounted) {
      setState(() => _refreshKey++);
    }
  }

  Future<void> _deleteTask(ClientTask task) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete task?',
      message: 'This task will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirm || !mounted) return;

    try {
      final response = await sl<DioClient>().raw.delete<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}${ApiEndpoints.clientTasks}/${task.id}',
      );
      final body = response.data ?? const <String, dynamic>{};
      if (!mounted) return;
      if (body['success'] == false) {
        context.showSnack(
          body['message']?.toString() ?? 'Failed to delete task',
          isError: true,
        );
      } else {
        context.showSnack('Task deleted');
        setState(() => _refreshKey++);
      }
    } catch (_) {
      if (mounted) context.showSnack('Failed to delete task', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: CatalogView<ClientTask>(
        key: ValueKey(_refreshKey),
        fetcher: _fetch,
        searchHint: 'Search tasks...',
        emptyTitle: 'No tasks yet',
        emptyIcon: Icons.task_alt_outlined,
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddTask,
          child: const Icon(Icons.add_rounded),
        ),
        itemBuilder: (context, task, __) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: context.text.titleMedium),
                        if ((task.projectTitle ?? '').isNotEmpty) ...[
                          AppSizes.vGapXs,
                          Text(
                            task.projectTitle!,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppStatusChip(
                        label: task.status,
                        dense: true,
                        color: AppColors.info,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openEditTask(task);
                          } else if (value == 'delete') {
                            _deleteTask(task);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              AppSizes.vGapMd,
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  AppStatusChip(
                    label: task.priority,
                    dense: true,
                    color: _priorityColor(task.priority),
                  ),
                  AppStatusChip(
                    label: '${task.progress}%',
                    dense: true,
                    color: AppColors.info,
                  ),
                  if (task.dueDate != null)
                    AppStatusChip(
                      label: 'Due ${Formatters.date(task.dueDate!)}',
                      dense: true,
                      color: AppColors.warning,
                    ),
                  if ((task.assignedTo ?? '').isNotEmpty)
                    AppStatusChip(
                      label: task.assignedTo!,
                      dense: true,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.danger;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }
}

class ClientAddTaskPage extends StatefulWidget {
  const ClientAddTaskPage({super.key, this.task});

  final ClientTask? task;

  @override
  State<ClientAddTaskPage> createState() => _ClientAddTaskPageState();
}

class _ClientAddTaskPageState extends State<ClientAddTaskPage> {
  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const _statuses = [
    'Todo',
    'In Progress',
    'Review',
    'Blocked',
    'Completed',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _projectController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _progressController = TextEditingController(text: '0');
  final _dueDateController = TextEditingController();
  final _dateFormatter = DateFormat('yyyy-MM-dd');

  ClientProjectOption? _project;
  DateTime? _dueDate;
  String? _priority;
  String? _status;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task == null) return;
    _titleController.text = task.title;
    _project = ClientProjectOption(
      id: task.projectId,
      title: task.projectTitle ?? 'Project',
    );
    _projectController.text = _project!.title;
    _assigneeController.text = task.assignedTo ?? '';
    _progressController.text = task.progress.toString();
    _priority = task.priority;
    _status = task.status;
    _dueDate = task.dueDate;
    if (_dueDate != null) {
      _dueDateController.text = _dateFormatter.format(_dueDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _projectController.dispose();
    _assigneeController.dispose();
    _progressController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickProject() async {
    final selected = await showModalBottomSheet<ClientProjectOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ProjectPickerSheet(),
    );
    if (selected != null && mounted) {
      setState(() {
        _project = selected;
        _projectController.text = selected.title;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _dueDateController.text = _dateFormatter.format(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _project == null ||
        _priority == null ||
        _status == null) {
      if (_project == null) {
        context.showSnack('Please select a project', isError: true);
      } else if (_priority == null) {
        context.showSnack('Please select priority', isError: true);
      } else if (_status == null) {
        context.showSnack('Please select status', isError: true);
      }
      return;
    }

    setState(() => _saving = true);
    final progress = int.tryParse(_progressController.text.trim()) ?? 0;
    final body = <String, dynamic>{
      'title': _titleController.text.trim(),
      'projectId': _project!.id,
      'priority': _priority!,
      'status': _status!,
      'progress': progress.clamp(0, 100),
      if (_assigneeController.text.trim().isNotEmpty)
        'assignee': _assigneeController.text.trim(),
      if (_dueDate != null) 'dueDate': _dateFormatter.format(_dueDate!),
    };

    final res = _isEditing ? await _updateTask(body) : await _createTask(body);
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack(_isEditing ? 'Task updated' : 'Task added');
      context.pop(true);
    });
  }

  Future<Result<bool>> _createTask(Map<String, dynamic> body) async {
    try {
      final response = await sl<DioClient>().raw.post<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}${ApiEndpoints.clientTasks}',
        data: body,
      );
      final responseBody = response.data ?? const <String, dynamic>{};
      if (responseBody['success'] == false) {
        return Err(
          ServerFailure(
            responseBody['message']?.toString() ?? 'Failed to add task',
          ),
        );
      }
      return const Success(true);
    } catch (_) {
      return const Err(ServerFailure('Failed to add task'));
    }
  }

  Future<Result<bool>> _updateTask(Map<String, dynamic> body) async {
    try {
      final response = await sl<DioClient>().raw.put<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}${ApiEndpoints.clientTasks}/${widget.task!.id}',
        data: body,
      );
      final responseBody = response.data ?? const <String, dynamic>{};
      if (responseBody['success'] == false) {
        return Err(
          ServerFailure(
            responseBody['message']?.toString() ?? 'Failed to update task',
          ),
        );
      }
      return const Success(true);
    } catch (_) {
      return const Err(ServerFailure('Failed to update task'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = context.isMobile ? 1 : 2;
    return AppScaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Add New Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            AppCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: AppSizes.lg,
                    runSpacing: AppSizes.lg,
                    children: [
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppTextField(
                          controller: _titleController,
                          label: 'Title *',
                          hint: 'Task title',
                          
                        ),
                      ),
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppTextField(
                          label: 'Project *',
                          hint: 'Select project',
                          controller: _projectController,
                          readOnly: true,
                          onTap: _pickProject,
                          suffixIcon: const Icon(Icons.expand_more_rounded),
                       
                        ),
                      ),
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppDropdown<String>(
                          label: 'Priority',
                          value: _priority,
                          hint: 'Select priority',
                          items: _priorities,
                          itemLabel: (v) => v,
                        
                          onChanged: (v) => setState(() => _priority = v),
                        ),
                      ),
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppDropdown<String>(
                          label: 'Status',
                          value: _status,
                          hint: 'Select status',
                          items: _statuses,
                          itemLabel: (v) => v,
                       
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ),
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppTextField(
                          controller: _progressController,
                          label: 'Progress',
                          hint: '0',
                          keyboardType: TextInputType.number,
                         
                        ),
                      ),
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppTextField(
                          controller: _dueDateController,
                          label: 'Due Date',
                          hint: 'Select due date',
                          readOnly: true,
                          onTap: _pickDueDate,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      _fieldBox(
                        constraints.maxWidth,
                        columns,
                        AppTextField(
                          controller: _assigneeController,
                          label: 'Assignee',
                          hint: 'Assignee name',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            AppSizes.vGapLg,
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: context.isMobile ? double.infinity : 220,
                child: AppPrimaryButton(
                  label: _isEditing ? 'Save Task' : 'Add Task',
                  icon: _isEditing
                      ? Icons.save_outlined
                      : Icons.add_task_outlined,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldBox(double maxWidth, int columns, Widget child) {
    final spacing = columns == 1 ? 0 : AppSizes.lg;
    final width = columns == 1 ? maxWidth : (maxWidth - spacing) / columns;
    return SizedBox(width: width, child: child);
  }
}

class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet();

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  List<ClientProjectOption> _projects = const [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadProjects);
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await sl<DioClient>().raw.get<Map<String, dynamic>>(
        '${AppConfig.authBaseUrl}${ApiEndpoints.clientProjects}',
        queryParameters: {
          'page': 1,
          'limit': 15,
          'search': _searchController.text.trim(),
        },
      );
      final body = response.data ?? const <String, dynamic>{};
      final raw =
          body['rows'] ??
          body['data'] ??
          body['projects'] ??
          body['items'] ??
          const [];
      final projects = (raw is List ? raw : const [])
          .whereType<Map>()
          .map(
            (e) =>
                ClientProjectOption.fromApiJson(Map<String, dynamic>.from(e)),
          )
          .where((p) => p.id.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _projects = projects;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load projects';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          top: AppSizes.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg,
        ),
        child: SizedBox(
          height: context.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Project', style: context.text.titleLarge),
              AppSizes.vGapMd,
              AppTextField(
                controller: _searchController,
                hint: 'Search projects',
                prefixIcon: Icons.search_rounded,
                onChanged: _onSearch,
              ),
              AppSizes.vGapMd,
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _projects.isEmpty
                    ? const Center(child: Text('No projects found'))
                    : ListView.separated(
                        itemCount: _projects.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(project.title),
                            onTap: () => Navigator.pop(context, project),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientTeamsPage extends StatefulWidget {
  const ClientTeamsPage({super.key});

  @override
  State<ClientTeamsPage> createState() => _ClientTeamsPageState();
}

class _ClientTeamsPageState extends State<ClientTeamsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _members = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final res = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientTeam,
      parser: (env) {
        final list = env.data as List?;
        if (list == null) return const [];
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
    if (!mounted) return;
    res.fold((_) {}, (list) => _members = list);
    setState(() => _loading = false);
  }

  Future<void> _invite() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite member'),
        content: AppTextField(
          controller: ctrl,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final api = sl<ApiClientHelper>();
              final res = await api.postAction(
                '${ApiEndpoints.clientTeam}/invite',
                body: {'email': ctrl.text.trim()},
              );
              if (!mounted) return;
              res.fold(
                (f) => context.showSnack(f.message),
                (_) => context.showSnack('Invitation sent'),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            onPressed: _invite,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (_members.isEmpty)
                  const AppCard(child: Text('No team members yet')),
                for (final m in _members)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: m['name']?.toString() ?? 'Member',
                          size: 44,
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['name']?.toString() ?? 'Member',
                                style: context.text.titleSmall,
                              ),
                              Text(
                                m['role']?.toString() ?? 'Member',
                                style: context.text.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        if (m['admin'] == true ||
                            m['role']?.toString().toLowerCase() == 'admin')
                          AppStatusChip(
                            label: 'Admin',
                            dense: true,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
