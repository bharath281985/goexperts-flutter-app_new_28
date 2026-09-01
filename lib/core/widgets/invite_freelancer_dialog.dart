import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/dependency_injection/service_locator.dart';
import '../../features/freelancer_dashboard/domain/repositories/freelancer_repository.dart';
import '../../features/projects/domain/entities/project.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../extensions/context_extensions.dart';
import '../utils/paginated.dart';

/// Shows an invitation bottom sheet.
///
/// Projects are fetched BEFORE the sheet is shown so there is zero
/// async setState inside the sheet widget — preventing the Flutter
/// `!semantics.parentDataDirty` assertion.
class InviteFreelancerDialog {
  InviteFreelancerDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required String freelancerId,
    required String freelancerName,
    String? freelancerAvatar,
  }) async {
    // ── 1. Fetch projects before opening the sheet ──────────────────────────
    List<Project> projects = [];
    try {
      final res = await sl<ProjectRepository>().getProjects(
        const QueryParams(page: 1, pageSize: 100),
      );
      projects = res.valueOrNull?.items ?? [];
    } catch (_) {
      // ignore – sheet will show "no projects" state
    }

    if (!context.mounted) return false;

    // ── 2. Show the sheet with the data already available ──────────────────
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (sheetCtx) => _InviteSheet(
        freelancerId: freelancerId,
        freelancerName: freelancerName,
        freelancerAvatar: freelancerAvatar,
        projects: projects,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sheet widget – receives pre-loaded projects, no async setState
// ─────────────────────────────────────────────────────────────────────────────
class _InviteSheet extends StatefulWidget {
  const _InviteSheet({
    required this.freelancerId,
    required this.freelancerName,
    this.freelancerAvatar,
    required this.projects,
  });

  final String freelancerId;
  final String freelancerName;
  final String? freelancerAvatar;
  final List<Project> projects;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  late final TextEditingController _msgCtrl;
  Project? _selectedProject;
  bool _submitting = false;
  String? _projectError;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(
      text:
          'Hi ${widget.freelancerName}, I would like to invite you to submit a proposal for my project.',
    );
    if (widget.projects.length == 1) {
      _selectedProject = widget.projects.first;
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selectedProject == null) {
      setState(() => _projectError = 'Please select a project');
      return;
    }
    setState(() {
      _submitting = true;
      _projectError = null;
    });
    try {
      final res = await sl<FreelancerRepository>().invite(widget.freelancerId);
      if (!mounted) return;
      if (res.isSuccess) {
        context.showSnack('Invitation sent to ${widget.freelancerName}');
        Navigator.of(context).pop(true);
      } else {
        context.showSnack(
          res.failureOrNull?.message ?? 'Failed to send invitation',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) context.showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Invite ${widget.freelancerName}',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Select Project ─────────────────────────────────────────────
          Text(
            'Select Project',
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.projects.isEmpty)
            _emptyProjects()
          else
            _projectPicker(),
          if (_projectError != null) ...[
            const SizedBox(height: 4),
            Text(
              _projectError!,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.error),
            ),
          ],
          const SizedBox(height: 16),

          // ── Message ────────────────────────────────────────────────────
          Text(
            'Message (Optional)',
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: context.text.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Write your message…',
              hintStyle:
                  context.text.bodyMedium?.copyWith(color: AppColors.mutedText),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                borderSide:
                    BorderSide(color: context.colors.outline.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                borderSide:
                    BorderSide(color: context.colors.outline.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Action Buttons ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: context.text.labelLarge?.copyWith(
                    color: context.theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _submitting ? null : _send,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? 'Sending…' : 'Send Invitation'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyProjects() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mutedText.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: context.colors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'No open projects found. Please create a project first.',
        style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
      ),
    );
  }

  Widget _projectPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: _projectError != null
              ? context.colors.error
              : context.colors.outline.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Project>(
          value: _selectedProject,
          isExpanded: true,
          hint: Text(
            '-- Choose an open project --',
            style: context.text.bodyMedium
                ?.copyWith(color: AppColors.mutedText),
          ),
          items: widget.projects
              .map(
                (p) => DropdownMenuItem<Project>(
                  value: p,
                  child: Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() {
            _selectedProject = val;
            _projectError = null;
          }),
        ),
      ),
    );
  }
}
