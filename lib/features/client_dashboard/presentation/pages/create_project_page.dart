import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_file_upload.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../../projects/domain/repositories/project_repository.dart';

/// 5-step create / edit project wizard without category/subcategory.
class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key, this.projectId});

  final String? projectId;

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  int _step = 0;
  final _basicsFormKey = GlobalKey<FormState>();
  final _budgetFormKey = GlobalKey<FormState>();

  static const _steps = [
    'Basics',
    'Industry & Skills',
    'Budget & Scope',
    'Attachments',
    'Review',
  ];

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _skillSearch = TextEditingController();

  // Industry & Skills
  String? _industryId;
  String _industryName = '';
  String? _industryError;
  final Set<String> _selectedSkillIds = {};
  final Map<String, String> _skillNamesById = {};
  final Map<String, List<SkillOption>> _skillsByIndustryId = {};
  List<SkillOption> _visibleSkills = [];
  bool _loadingSkills = false;
  String? _skillsError;

  // Master Data Options
  List<MasterOption> _industries = [];
  List<MasterOption> _workModes = [];
  List<MasterOption> _experienceLevels = [];
  List<MasterOption> _budgetRanges = [];
  bool _loadingMasterData = true;

  // Budget & Scope
  String? _workModeId;
  String _workModeName = '';
  String? _workModeError;

  String? _experienceLevelId;
  String _experienceLevelName = '';
  String? _experienceLevelError;

  String? _budgetRangeId;
  String _budgetRangeName = '';
  String? _budgetRangeError;

  DateTime? _startDate;
  String? _startDateError;
  DateTime? _endDate;
  String? _endDateError;

  // Attachments
  final List<_ProjectAttachment> _attachments = [];
  final List<String> _existingAttachmentUrls = [];
  bool _publishing = false;
  bool _loadingExisting = false;
  String? _attachmentsError;

  bool get _isEdit => (widget.projectId ?? '').isNotEmpty;

  static const _maxAttachments = 20;
  static const _allowedAttachmentExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'rtf',
    'odt',
    'ods',
    'odp',
    'zip',
    'rar',
    '7z',
  };
  static const _blockedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'svg',
    'ico',
    'tif',
    'tiff',
  };

  int get _attachmentCount =>
      _attachments.length + _existingAttachmentUrls.length;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    setState(() => _loadingMasterData = true);
    final repo = sl<MasterDataRepository>();

    final results = await Future.wait([
      repo.getIndustryOptions(),
      repo.getWorkModeOptions(),
      repo.getExperienceLevelOptions(),
      repo.getBudgetRangeOptions(),
    ]);

    if (!mounted) return;

    final industryRes = results[0];
    final workModeRes = results[1];
    final expLevelRes = results[2];
    final budgetRes = results[3];

    setState(() {
      _industries = industryRes.valueOrNull ?? [];
      _workModes = workModeRes.valueOrNull ?? [];
      _experienceLevels = expLevelRes.valueOrNull ?? [];
      _budgetRanges = budgetRes.valueOrNull ?? [];
      _loadingMasterData = false;
    });

    if (_isEdit) {
      await _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    final res = await sl<ProjectRepository>().getProject(widget.projectId!);
    if (!mounted) return;
    res.fold(
      (f) {
        setState(() => _loadingExisting = false);
        context.showSnack(f.message, isError: true);
      },
      (project) {
        _title.text = project.title;
        _desc.text = project.description;
        _industryId = project.industryId;
        _industryName = project.industryName;

        _selectedSkillIds
          ..clear()
          ..addAll(project.skillIds);
        for (var i = 0; i < project.skillIds.length; i++) {
          final id = project.skillIds[i];
          final name = i < project.skills.length ? project.skills[i] : id;
          _skillNamesById[id] = name;
        }

        // Match Industry
        _industryId = project.industryId;
        if (_industryId == null || _industryId!.isEmpty) {
          final match = _industries.firstWhere(
            (i) =>
                i.id == project.industryName ||
                i.name.toLowerCase() == project.industryName.toLowerCase(),
            orElse: () => const MasterOption(id: '', name: ''),
          );
          if (match.id.isNotEmpty) _industryId = match.id;
        }
        _industryName = project.industryName;

        // Match Work Mode
        _workModeId = null;
        final rawWorkId = project.workModeId?.trim() ?? '';
        final rawWorkName = project.workMode.trim();

        if (rawWorkId.isNotEmpty && _workModes.any((w) => w.id == rawWorkId)) {
          _workModeId = rawWorkId;
        } else if (rawWorkName.isNotEmpty &&
            _workModes.any((w) => w.id == rawWorkName)) {
          _workModeId = rawWorkName;
        } else if (rawWorkName.isNotEmpty) {
          final match = _workModes.firstWhere(
            (w) => w.name.toLowerCase() == rawWorkName.toLowerCase(),
            orElse: () => const MasterOption(id: '', name: ''),
          );
          if (match.id.isNotEmpty) _workModeId = match.id;
        }
        _workModeName = _workModes
            .firstWhere(
              (w) => w.id == _workModeId,
              orElse: () => MasterOption(id: '', name: project.workMode),
            )
            .name;

        // Match Experience Level
        _experienceLevelId = null;
        final rawExpId = project.experienceLevelId?.trim() ?? '';
        final rawExpName = project.experienceLevel.trim();

        if (rawExpId.isNotEmpty &&
            _experienceLevels.any((e) => e.id == rawExpId)) {
          _experienceLevelId = rawExpId;
        } else if (rawExpName.isNotEmpty &&
            _experienceLevels.any((e) => e.id == rawExpName)) {
          _experienceLevelId = rawExpName;
        } else if (rawExpName.isNotEmpty) {
          final cleanExp = rawExpName
              .replaceAll('mo_experience_level_', '')
              .replaceAll('_', ' ')
              .toLowerCase();
          final match = _experienceLevels.firstWhere(
            (e) =>
                e.name.toLowerCase() == cleanExp ||
                e.id.toLowerCase() == cleanExp ||
                cleanExp.contains(e.name.toLowerCase()) ||
                e.name.toLowerCase().contains(cleanExp),
            orElse: () => const MasterOption(id: '', name: ''),
          );
          if (match.id.isNotEmpty) _experienceLevelId = match.id;
        }
        _experienceLevelName = _experienceLevels
            .firstWhere(
              (e) => e.id == _experienceLevelId,
              orElse: () => MasterOption(id: '', name: project.experienceLevel),
            )
            .name;

        // Match Budget Range
        _budgetRangeId = null;
        final rawBudgetId = project.budgetRangeId?.trim() ?? '';
        final rawBudgetName = project.budgetRangeName.trim();

        if (rawBudgetId.isNotEmpty &&
            _budgetRanges.any((b) => b.id == rawBudgetId)) {
          _budgetRangeId = rawBudgetId;
        } else if (rawBudgetName.isNotEmpty &&
            _budgetRanges.any((b) => b.id == rawBudgetName)) {
          _budgetRangeId = rawBudgetName;
        } else if (rawBudgetName.isNotEmpty) {
          final cleanBudgetName = rawBudgetName
              .replaceAll('₹', '')
              .replaceAll(',', '')
              .replaceAll(' ', '')
              .toLowerCase();
          final match = _budgetRanges.firstWhere((b) {
            final cleanOptName = b.name
                .replaceAll('₹', '')
                .replaceAll(',', '')
                .replaceAll(' ', '')
                .toLowerCase();
            return cleanOptName == cleanBudgetName ||
                b.id == rawBudgetId ||
                b.name.toLowerCase() == rawBudgetName.toLowerCase();
          }, orElse: () => const MasterOption(id: '', name: ''));
          if (match.id.isNotEmpty) _budgetRangeId = match.id;
        }
        _budgetRangeName = _budgetRanges
            .firstWhere(
              (b) => b.id == _budgetRangeId,
              orElse: () => MasterOption(id: '', name: project.budgetRangeName),
            )
            .name;

        _startDate = project.startDate;
        _endDate = project.endDate;

        _existingAttachmentUrls
          ..clear()
          ..addAll(project.attachments);

        setState(() => _loadingExisting = false);

        if (_industryId != null && _industryId!.isNotEmpty) {
          _loadSkillsForIndustry(_industryId!);
        }
      },
    );
  }

  String _skillLabels() {
    if (_selectedSkillIds.isEmpty) return '—';
    return _selectedSkillIds
        .map((id) => _skillNamesById[id] ?? id)
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  @override
  void dispose() {
    _onSkillsUpdated = null;
    _title.dispose();
    _desc.dispose();
    _skillSearch.dispose();
    super.dispose();
  }

  bool _validateBasicsStep() {
    final valid = _basicsFormKey.currentState?.validate() ?? false;
    return valid;
  }

  bool _validateIndustrySkillsStep() {
    var valid = true;
    if (_industryId == null || _industryId!.isEmpty) {
      _industryError = 'Please select an industry';
      valid = false;
    } else {
      _industryError = null;
    }

    if (_selectedSkillIds.isEmpty) {
      _skillsError = 'Please select at least 1 skill';
      valid = false;
    } else {
      _skillsError = null;
    }

    setState(() {});
    return valid;
  }

  bool _validateBudgetScopeStep() {
    var valid = true;
    if (_workModeId == null || _workModeId!.isEmpty) {
      _workModeError = 'Please select a work mode';
      valid = false;
    } else {
      _workModeError = null;
    }

    if (_experienceLevelId == null || _experienceLevelId!.isEmpty) {
      _experienceLevelError = 'Please select an experience level';
      valid = false;
    } else {
      _experienceLevelError = null;
    }

    if (_budgetRangeId == null || _budgetRangeId!.isEmpty) {
      _budgetRangeError = 'Please select a budget range';
      valid = false;
    } else {
      _budgetRangeError = null;
    }

    if (_startDate == null) {
      _startDateError = 'Start date is required';
      valid = false;
    } else {
      _startDateError = null;
    }

    if (_endDate == null) {
      _endDateError = 'End date is required';
      valid = false;
    } else if (_startDate != null &&
        (_endDate!.isBefore(_startDate!) ||
            _endDate!.isAtSameMomentAs(_startDate!))) {
      _endDateError = 'End date must be after start date';
      valid = false;
    } else {
      _endDateError = null;
    }

    setState(() {});
    return valid;
  }

  bool _validateAttachmentsStep() {
    if (_attachmentCount > _maxAttachments) {
      setState(() {
        _attachmentsError = 'You can upload up to $_maxAttachments files.';
      });
      return false;
    }
    setState(() => _attachmentsError = null);
    return true;
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  bool _isAllowedAttachment(String name) {
    final extension = _extensionOf(name);
    return _allowedAttachmentExtensions.contains(extension) &&
        !_blockedImageExtensions.contains(extension);
  }

  Future<void> _pickAttachments() async {
    final remaining = _maxAttachments - _attachmentCount;
    if (remaining <= 0) {
      context.showSnack(
        'Maximum $_maxAttachments files allowed.',
        isError: true,
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedAttachmentExtensions.toList(),
    );
    if (result == null) return;

    final rejected = <String>[];
    final selected = <_ProjectAttachment>[];

    for (final file in result.files) {
      if (file.path == null || !_isAllowedAttachment(file.name)) {
        rejected.add(file.name);
        continue;
      }

      selected.add(
        _ProjectAttachment(name: file.name, path: file.path!, size: file.size),
      );
    }

    final skippedForLimit = selected.length > remaining
        ? selected.length - remaining
        : 0;
    final toAdd = selected.take(remaining);

    if (!mounted) return;
    setState(() {
      for (final attachment in toAdd) {
        final alreadySelected = _attachments.any(
          (item) => item.path == attachment.path,
        );
        if (!alreadySelected) _attachments.add(attachment);
      }
      if (_attachments.isNotEmpty) _attachmentsError = null;
    });

    if (rejected.isNotEmpty) {
      context.showSnack(
        'Images are not allowed. Upload PDF, DOC, Excel, PPT, ZIP or text documents.',
        isError: true,
      );
    } else if (skippedForLimit > 0) {
      context.showSnack(
        'Only $_maxAttachments files allowed. $skippedForLimit file(s) were skipped.',
        isError: true,
      );
    }
  }

  Future<List<String>?> _uploadAttachments() async {
    if (_attachments.isEmpty) return [];
    final uploader = sl<FileUploadHelper>();
    final urls = <String>[];

    for (final attachment in _attachments) {
      final upload = await uploader.uploadUrl(
        path: attachment.path,
        endpoint: ApiEndpoints.filesUpload,
        fields: {'category': 'project_attachment'},
      );

      String? error;
      upload.fold((failure) => error = failure.message, (url) {
        urls.add(url.isNotEmpty ? url : attachment.name);
      });

      if (error != null) {
        if (mounted) context.showSnack(error!, isError: true);
        return null;
      }
    }

    return urls;
  }

  Future<void> _next() async {
    if (_step == 0 && !_validateBasicsStep()) return;
    if (_step == 1 && !_validateIndustrySkillsStep()) return;
    if (_step == 2 && !_validateBudgetScopeStep()) return;
    if (_step == 3 && !_validateAttachmentsStep()) return;

    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _publishing = true);
    final attachmentUrls = await _uploadAttachments();
    if (!mounted) return;
    if (attachmentUrls == null) {
      setState(() => _publishing = false);
      return;
    }

    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'industryId': _industryId,
      'workModeId': _workModeId,
      'experienceLevelId': _experienceLevelId,
      'projectHireBudgetId': _budgetRangeId,
      'budgetRangeId': _budgetRangeId,
      'skillIds': _selectedSkillIds.toList(),
      if (_startDate != null)
        'startDate': _startDate!.toUtc().toIso8601String(),
      if (_endDate != null) 'endDate': _endDate!.toUtc().toIso8601String(),
      'attachments': [..._existingAttachmentUrls, ...attachmentUrls],
    };

    final userRole = context.read<AuthBloc>().state.user?.role;
    if (_isEdit) {
      final res = await sl<ProjectRepository>().updateProject(
        widget.projectId!,
        body,
      );
      if (!mounted) return;
      setState(() => _publishing = false);
      res.fold((f) => context.showSnack(f.message, isError: true), (_) {
        context.showSnack('Project updated successfully!');
        Navigator.of(context).maybePop(true);
      });
      return;
    }

    final api = sl<ApiClientHelper>();
    final res = await api.post<Map<String, dynamic>>(
      ApiEndpoints.roleProjects(userRole),
      body: body,
      parser: (data) => Map<String, dynamic>.from(data as Map),
      allowNullData: false,
    );
    if (!mounted) return;
    setState(() => _publishing = false);
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack('Project published successfully!');
      Navigator.of(context).maybePop(true);
    });
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  VoidCallback? _onSkillsUpdated;

  Future<void> _loadSkillsForIndustry(String industryId) async {
    final cleanId = industryId.trim();
    if (cleanId.isEmpty) {
      setState(() {
        _visibleSkills = [];
        _loadingSkills = false;
      });
      _onSkillsUpdated?.call();
      return;
    }

    if (_skillsByIndustryId.containsKey(cleanId) &&
        (_skillsByIndustryId[cleanId] ?? []).isNotEmpty) {
      setState(() {
        _visibleSkills = _skillsByIndustryId[cleanId] ?? [];
        _loadingSkills = false;
      });
      _populateSkillNames();
      _onSkillsUpdated?.call();
      return;
    }

    setState(() {
      _loadingSkills = true;
    });
    _onSkillsUpdated?.call();

    final repo = sl<MasterDataRepository>();
    final allSkills = <SkillOption>[];
    var page = 1;
    const pageSize = 100;
    var total = 0;

    try {
      final result = await repo.getSkills(
        categoryId: cleanId,
        page: 1,
        pageSize: 200,
      );
      if (mounted && result.isSuccess) {
        final batch = result.valueOrNull ?? [];
        allSkills.addAll(batch.where((skill) => skill.name.isNotEmpty));
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;

    for (final skill in allSkills) {
      _skillNamesById[skill.id] = skill.name;
    }

    setState(() {
      _skillsByIndustryId[cleanId] = allSkills;
      _visibleSkills = allSkills;
      _loadingSkills = false;
    });
    _populateSkillNames();
    _onSkillsUpdated?.call();
  }

  void _populateSkillNames() {
    for (final s in _visibleSkills) {
      _skillNamesById[s.id] = s.name;
    }
  }

  void _toggleSkill(String skillId) {
    setState(() {
      if (_selectedSkillIds.contains(skillId)) {
        _selectedSkillIds.remove(skillId);
      } else {
        _selectedSkillIds.add(skillId);
      }
      _skillsError = null;
    });
  }

  void _showSkillsBottomSheet() {
    if (_industryId == null || _industryId!.isEmpty) {
      context.showSnack('Please select an industry first', isError: true);
      return;
    }

    if (_visibleSkills.isEmpty && !_loadingSkills) {
      _loadSkillsForIndustry(_industryId!);
    }

    var isSheetMounted = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            _onSkillsUpdated = () {
              if (mounted && isSheetMounted) {
                try {
                  setSheetState(() {});
                } catch (_) {}
              }
            };

            final query = _skillSearch.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? _visibleSkills
                : _visibleSkills
                      .where((s) => s.name.toLowerCase().contains(query))
                      .toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      0,
                      AppSizes.screenPadding,
                      AppSizes.md,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Skills (${_selectedSkillIds.length})',
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: const Text(
                                'Done',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        AppSizes.vGapSm,
                        AppTextField(
                          controller: _skillSearch,
                          hint: 'Search skills…',
                          prefixIcon: Icons.search_rounded,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        AppSizes.vGapMd,
                        Expanded(
                          child: _loadingSkills
                              ? const Center(child: CircularProgressIndicator())
                              : filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSizes.lg),
                                    child: Text(
                                      _visibleSkills.isEmpty
                                          ? 'No skills found for this industry'
                                          : 'No matching skills found',
                                      textAlign: TextAlign.center,
                                      style: context.text.bodyMedium?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final skill = filtered[index];
                                    final isSelected = _selectedSkillIds.contains(
                                      skill.id,
                                    );
                                    return CheckboxListTile(
                                      title: Text(skill.name),
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (_) {
                                        _toggleSkill(skill.id);
                                        setSheetState(() {});
                                      },
                                    );
                                  },
                                ),
                        ),
                        AppSizes.vGapMd,
                        AppPrimaryButton(
                          label: 'Done (${_selectedSkillIds.length} selected)',
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      isSheetMounted = false;
      _onSkillsUpdated = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(_isEdit ? 'Edit Project/Task' : 'Post a Project/Task'),
      ),
      body: _loadingMasterData || _loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: AppStepper(steps: _steps, currentStep: _step),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    child: _buildStep(),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Row(
                      children: [
                        if (_step > 0)
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Back',
                              onPressed: _back,
                            ),
                          ),
                        if (_step > 0) AppSizes.hGapMd,
                        Expanded(
                          flex: 2,
                          child: AppPrimaryButton(
                            label: _step == _steps.length - 1
                                ? (_isEdit ? 'Save Changes' : 'Publish Project')
                                : 'Continue',
                            isLoading: _publishing,
                            onPressed: _next,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildBasicsStep();
      case 1:
        return _buildIndustrySkillsStep();
      case 2:
        return _buildBudgetScopeStep();
      case 3:
        return _buildAttachmentsStep();
      default:
        return _review();
    }
  }

  Widget _buildBasicsStep() {
    return Form(
      key: _basicsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _title,
            label: 'Project/Task Title',
            hint: 'Enter your project title',
            validator: (v) =>
                Validators.minLength(v, 5, field: 'Project/Task title'),
          ),
          AppSizes.vGapLg,
          AppTextField(
            controller: _desc,
            label: 'Description',
            hint:
                'Describe your project requirements, goals, and deliverables…',
            maxLines: 6,
            validator: (v) => Validators.minLength(v, 20, field: 'Description'),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustrySkillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown<String>(
          label: 'Industry',
          hint: 'Select industry',
          value: _industries.any((i) => i.id == _industryId)
              ? _industryId
              : null,
          items: _industries.map((i) => i.id).toList(),
          itemLabel: (id) => _industries
              .firstWhere(
                (i) => i.id == id,
                orElse: () => const MasterOption(id: '', name: ''),
              )
              .name,
          onChanged: (id) {
            setState(() {
              _industryId = id;
              _industryName = _industries
                  .firstWhere(
                    (i) => i.id == id,
                    orElse: () => const MasterOption(id: '', name: ''),
                  )
                  .name;
              _industryError = null;
              _selectedSkillIds.clear();
            });
            if (id != null && id.isNotEmpty) {
              _loadSkillsForIndustry(id);
            }
          },
        ),
        if (_industryError != null) ...[
          AppSizes.vGapXs,
          Text(
            _industryError!,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
        if (_industryId != null && _industryId!.isNotEmpty) ...[
          AppSizes.vGapLg,
          Text(
            'Skills',
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSizes.vGapXs,
          InkWell(
            onTap: _showSkillsBottomSheet,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md,
              ),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: _skillsError != null
                      ? context.colors.error
                      : context.colors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSkillIds.isEmpty
                          ? 'Select skills for this project'
                          : '${_selectedSkillIds.length} skill(s) selected',
                      style: _selectedSkillIds.isEmpty
                          ? context.text.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            )
                          : context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_skillsError != null) ...[
            AppSizes.vGapXs,
            Text(
              _skillsError!,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
          if (_selectedSkillIds.isNotEmpty) ...[
            AppSizes.vGapMd,
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: _selectedSkillIds.map((id) {
                final name = _skillNamesById[id] ?? id;
                return Chip(
                  label: Text(name),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => _toggleSkill(id),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  labelStyle: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBudgetScopeStep() {
    return Form(
      key: _budgetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDropdown<String>(
            label: 'Work Mode',
            hint: 'Select work mode',
            value: _workModes.any((w) => w.id == _workModeId)
                ? _workModeId
                : null,
            items: _workModes.map((w) => w.id).toList(),
            itemLabel: (id) => _workModes
                .firstWhere(
                  (w) => w.id == id,
                  orElse: () => const MasterOption(id: '', name: ''),
                )
                .name,
            onChanged: (id) => setState(() {
              _workModeId = id;
              _workModeName = _workModes
                  .firstWhere(
                    (w) => w.id == id,
                    orElse: () => const MasterOption(id: '', name: ''),
                  )
                  .name;
              _workModeError = null;
            }),
          ),
          if (_workModeError != null) ...[
            AppSizes.vGapXs,
            Text(
              _workModeError!,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Experience Level',
            hint: 'Select experience level',
            value: _experienceLevels.any((e) => e.id == _experienceLevelId)
                ? _experienceLevelId
                : null,
            items: _experienceLevels.map((e) => e.id).toList(),
            itemLabel: (id) => _experienceLevels
                .firstWhere(
                  (e) => e.id == id,
                  orElse: () => const MasterOption(id: '', name: ''),
                )
                .name,
            onChanged: (id) => setState(() {
              _experienceLevelId = id;
              _experienceLevelName = _experienceLevels
                  .firstWhere(
                    (e) => e.id == id,
                    orElse: () => const MasterOption(id: '', name: ''),
                  )
                  .name;
              _experienceLevelError = null;
            }),
          ),
          if (_experienceLevelError != null) ...[
            AppSizes.vGapXs,
            Text(
              _experienceLevelError!,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
          AppSizes.vGapLg,
          AppDropdown<String>(
            label: 'Budget Range',
            hint: 'Select budget range',
            value: _budgetRanges.any((b) => b.id == _budgetRangeId)
                ? _budgetRangeId
                : null,
            items: _budgetRanges.map((b) => b.id).toList(),
            itemLabel: (id) => _budgetRanges
                .firstWhere(
                  (b) => b.id == id,
                  orElse: () => const MasterOption(id: '', name: ''),
                )
                .name,
            onChanged: (id) => setState(() {
              _budgetRangeId = id;
              _budgetRangeName = _budgetRanges
                  .firstWhere(
                    (b) => b.id == id,
                    orElse: () => const MasterOption(id: '', name: ''),
                  )
                  .name;
              _budgetRangeError = null;
            }),
          ),
          if (_budgetRangeError != null) ...[
            AppSizes.vGapXs,
            Text(
              _budgetRangeError!,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
          AppSizes.vGapLg,
          AppDatePicker(
            label: 'Start Date',
            value: _startDate,
            firstDate: _isEdit
                ? DateTime(2020)
                : DateTime.now().subtract(const Duration(hours: 12)),
            onChanged: (d) => setState(() {
              _startDate = d;
              _startDateError = null;
              if (_endDate != null &&
                  (_endDate!.isBefore(d) || _endDate!.isAtSameMomentAs(d))) {
                _endDate = null;
              }
            }),
          ),
          if (_startDateError != null) ...[
            AppSizes.vGapXs,
            Text(
              _startDateError!,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
          AppSizes.vGapLg,
          AppDatePicker(
            label: 'End Date',
            value: _endDate,
            firstDate: _startDate != null
                ? _startDate!.add(const Duration(days: 1))
                : DateTime.now().add(const Duration(days: 1)),
            onChanged: (d) => setState(() {
              _endDate = d;
              _endDateError = null;
            }),
          ),
          if (_endDateError != null) ...[
            AppSizes.vGapXs,
            Text(
              _endDateError!,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFileUpload(
          label: 'Upload attachments',
          hint:
              'Optional. Up to $_maxAttachments files: PDF, DOC, Excel, PPT, ZIP or text. Images not allowed.',
          onTap: _pickAttachments,
          fileName: _attachmentCount == 0
              ? null
              : '$_attachmentCount / $_maxAttachments document(s)',
        ),
        if (_attachmentsError != null) ...[
          AppSizes.vGapXs,
          Text(
            _attachmentsError!,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
        if (_existingAttachmentUrls.isNotEmpty) ...[
          AppSizes.vGapMd,
          for (final url in _existingAttachmentUrls)
            Container(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.outline, width: 1),
                borderRadius: BorderRadius.circular(AppSizes.sm),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                leading: Icon(_attachmentIcon(url), color: AppColors.primary),
                title: Text(
                  _attachmentName(url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _attachmentType(url),
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _viewExistingAttachment(url),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.colors.error,
                        size: 20,
                      ),
                      tooltip: 'Remove',
                      onPressed: () =>
                          setState(() => _existingAttachmentUrls.remove(url)),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (_attachments.isNotEmpty) ...[
          AppSizes.vGapMd,
          for (final attachment in _attachments) _attachmentTile(attachment),
        ],
      ],
    );
  }

  Widget _review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Publish', style: context.text.titleMedium),
        AppSizes.vGapMd,
        _row('Title', _title.text.isEmpty ? '—' : _title.text),
        _row('Description', _desc.text.isEmpty ? '—' : _desc.text),
        _row('Industry', _industryName.isEmpty ? '—' : _industryName),
        _row('Skills', _skillLabels()),
        _row('Work Mode', _workModeName.isEmpty ? '—' : _workModeName),
        _row(
          'Level',
          _experienceLevelName.isEmpty ? '—' : _experienceLevelName,
        ),
        _row('Budget', _budgetRangeName.isEmpty ? '—' : _budgetRangeName),
        _row(
          'Start Date',
          _startDate == null
              ? '—'
              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
        ),
        _row(
          'End Date',
          _endDate == null
              ? '—'
              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
        ),
        _row(
          'Attachments',
          _attachmentCount == 0
              ? 'None'
              : [
                  ..._existingAttachmentUrls.map((u) => u.split('/').last),
                  ..._attachments.map((file) => file.name),
                ].join(', '),
        ),
      ],
    );
  }

  Widget _attachmentTile(_ProjectAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outline, width: 1),
        borderRadius: BorderRadius.circular(AppSizes.sm),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        leading: Icon(_attachmentIcon(attachment.name), color: AppColors.primary),
        title: Text(
          attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_attachmentType(attachment.name)} · ${_formatFileSize(attachment.size)}',
          style: context.text.labelSmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _viewLocalAttachment(attachment),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View'),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: context.colors.error,
                size: 20,
              ),
              tooltip: 'Remove',
              onPressed: () => setState(() {
                _attachments.remove(attachment);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewExistingAttachment(String rawUrl) async {
    final url = _resolveAttachmentUrl(rawUrl);
    if (url.isEmpty) {
      context.showSnack('Attachment URL is empty', isError: true);
      return;
    }
    final name = _attachmentName(rawUrl);
    final type = _attachmentType(rawUrl);

    if (type == 'Image') {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (dialogCtx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CustomCachedImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      context.showSnack('Invalid attachment URL', isError: true);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched && mounted) {
        final fallback = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!fallback && mounted) {
          context.showSnack('Could not open attachment', isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          context.showSnack('Could not open attachment: $e', isError: true);
        }
      }
    }
  }

  Future<void> _viewLocalAttachment(_ProjectAttachment attachment) async {
    final type = _attachmentType(attachment.name);
    final file = File(attachment.path);
    final exists = await file.exists();
    if (!exists) {
      if (mounted) context.showSnack('File not found on device', isError: true);
      return;
    }

    if (type == 'Image') {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (dialogCtx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      attachment.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final uri = Uri.file(attachment.path);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        context.showSnack(
          'Could not open local file: ${attachment.name}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnack('Could not open file: $e', isError: true);
      }
    }
  }

  String _resolveAttachmentUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    return '$base${url.startsWith('/') ? '' : '/'}$url';
  }

  String _attachmentName(String url) {
    final clean = url.split('?').first.split('#').first;
    final name = clean.split('/').last;
    return name.isNotEmpty ? name : 'Attachment';
  }

  String _attachmentType(String nameOrUrl) {
    final ext = nameOrUrl
        .split('?')
        .first
        .split('#')
        .first
        .split('.')
        .last
        .toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) {
      return 'Image';
    }
    if (ext == 'pdf') return 'PDF';
    if (['doc', 'docx'].contains(ext)) return 'Word';
    if (['xls', 'xlsx', 'csv'].contains(ext)) return 'Excel';
    if (['ppt', 'pptx'].contains(ext)) return 'PowerPoint';
    return 'Document';
  }

  IconData _attachmentIcon(String nameOrUrl) {
    final type = _attachmentType(nameOrUrl);
    switch (type) {
      case 'Image':
        return Icons.image_outlined;
      case 'PDF':
        return Icons.picture_as_pdf_outlined;
      case 'Word':
        return Icons.description_outlined;
      case 'Excel':
        return Icons.table_chart_outlined;
      case 'PowerPoint':
        return Icons.slideshow_outlined;
      default:
        return Icons.attach_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Document';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: context.text.labelMedium),
        ),
        Expanded(child: Text(value, style: context.text.bodyMedium)),
      ],
    ),
  );
}

class _ProjectAttachment {
  const _ProjectAttachment({
    required this.name,
    required this.path,
    required this.size,
  });

  final String name;
  final String path;
  final int size;
}
