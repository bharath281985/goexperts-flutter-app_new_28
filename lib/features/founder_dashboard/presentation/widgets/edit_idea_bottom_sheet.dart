import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../app/constants/app_colors.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../startup_ideas/domain/entities/startup.dart';

class EditIdeaBottomSheet extends StatefulWidget {
  const EditIdeaBottomSheet({
    required this.startup,
    this.rawStartup,
    super.key,
  });

  final Startup startup;
  final Map<String, dynamic>? rawStartup;

  @override
  State<EditIdeaBottomSheet> createState() => EditIdeaBottomSheetState();
}

class EditIdeaBottomSheetState extends State<EditIdeaBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _fundingController;
  late final TextEditingController _equityController;
  late final TextEditingController _teamSizeController;

  String? _stage;
  String? _categoryId;
  String? _industryId;

  // Fallback initial values if not mapped
  String _initialCategory = '';
  String _initialIndustry = '';

  String? _localLogoPath;
  String? _localCoverPath;
  String? _localPitchDiskPath;
  String? _localBusinessPlanPath;

  String? _networkLogoUrl;
  String? _networkCoverUrl;
  String? _networkPitchDiskUrl;
  String? _networkBusinessPlanUrl;

  bool _loading = false;
  bool _loadingOptions = true;
  List<Map<String, dynamic>> _stagesList = [];
  List<Map<String, dynamic>> _categoriesList = [];
  List<Map<String, dynamic>> _industriesList = [];
  String? _stageId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.startup.name);
    _fullNameController = TextEditingController(
      text: widget.startup.founderName,
    );
    _bioController = TextEditingController(text: widget.startup.tagline);

    final rawInd = widget.rawStartup?['industry'];
    final rawCat = widget.rawStartup?['category'];
    final rawStage = widget.rawStartup?['stage'];

    _initialIndustry =
        widget.rawStartup?['industryId']?.toString() ??
        (rawInd is Map
            ? (rawInd['id'] ?? rawInd['name'])?.toString()
            : rawInd?.toString()) ??
        widget.startup.industry;

    _initialCategory =
        widget.rawStartup?['categoryId']?.toString() ??
        (rawCat is Map
            ? (rawCat['id'] ?? rawCat['name'])?.toString()
            : rawCat?.toString()) ??
        (widget.startup.tags.isNotEmpty
            ? widget.startup.tags.first
            : widget.startup.industry);

    _stage =
        widget.rawStartup?['stageId']?.toString() ??
        (rawStage is Map
            ? (rawStage['id'] ??
                      rawStage['value'] ??
                      rawStage['label'] ??
                      rawStage['name'])
                  ?.toString()
            : rawStage?.toString()) ??
        widget.startup.stage;

    _fundingController = TextEditingController(
      text: widget.startup.fundingRequired.toStringAsFixed(0),
    );
    _equityController = TextEditingController(
      text: widget.startup.equityOffered.toStringAsFixed(0),
    );
    // Parse team size if we can, otherwise default 1
    final tsStr =
        widget.rawStartup?['teamSize']?.toString() ??
        widget.startup.tags.where((t) => t.contains('Team')).firstOrNull;
    _teamSizeController = TextEditingController(
      text: tsStr != null ? tsStr.replaceAll(RegExp(r'[^0-9]'), '') : '1',
    );

    _networkLogoUrl = widget.startup.logoUrl;
    _networkCoverUrl = widget.startup.coverUrl;
    _networkPitchDiskUrl = widget.startup.pitchDeckUrl;
    _networkBusinessPlanUrl = widget.startup.businessPlanUrl;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final futures = await Future.wait([
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        '${ApiEndpoints.publicStartupStages}?limit=250',
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        '${ApiEndpoints.publicCategories}?limit=250',
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
      sl<ApiClientHelper>().get<List<Map<String, dynamic>>>(
        '${ApiEndpoints.publicIndustries}?limit=250',
        parser: (raw) => (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
    ]);

    if (!mounted) return;

    if (futures[0].isSuccess) {
      _stagesList = futures[0].valueOrNull ?? [];
      final stageStr = (_stage ?? '').trim().toLowerCase();
      _stageId = _stagesList.firstWhere((e) {
        final id = e['id']?.toString().trim().toLowerCase();
        final val = e['value']?.toString().trim().toLowerCase();
        final lbl = e['label']?.toString().trim().toLowerCase();
        final nm = e['name']?.toString().trim().toLowerCase();
        return id == stageStr ||
            val == stageStr ||
            lbl == stageStr ||
            nm == stageStr;
      }, orElse: () => {})['id']?.toString();
      if (_stageId == null && _stage != null && _stage!.isNotEmpty) {
        _stagesList.insert(0, {'id': _stage!, 'label': _stage!});
        _stageId = _stage;
      }
    }

    if (futures[1].isSuccess) {
      _categoriesList = futures[1].valueOrNull ?? [];
      final catStr = _initialCategory.trim().toLowerCase();
      _categoryId = _categoriesList.firstWhere((e) {
        final id = e['id']?.toString().trim().toLowerCase();
        final val = e['value']?.toString().trim().toLowerCase();
        final lbl = e['label']?.toString().trim().toLowerCase();
        final nm = e['name']?.toString().trim().toLowerCase();
        return id == catStr || val == catStr || lbl == catStr || nm == catStr;
      }, orElse: () => {})['id']?.toString();
      if (_categoryId == null && _initialCategory.isNotEmpty) {
        _categoriesList.insert(0, {
          'id': _initialCategory,
          'name': _initialCategory,
        });
        _categoryId = _initialCategory;
      }
    }

    if (futures[2].isSuccess) {
      _industriesList = futures[2].valueOrNull ?? [];
      final indStr = _initialIndustry.trim().toLowerCase();
      _industryId = _industriesList.firstWhere((e) {
        final id = e['id']?.toString().trim().toLowerCase();
        final val = e['value']?.toString().trim().toLowerCase();
        final lbl = e['label']?.toString().trim().toLowerCase();
        final nm = e['name']?.toString().trim().toLowerCase();
        return id == indStr || val == indStr || lbl == indStr || nm == indStr;
      }, orElse: () => {})['id']?.toString();
      if (_industryId == null && _initialIndustry.isNotEmpty) {
        _industriesList.insert(0, {
          'id': _initialIndustry,
          'name': _initialIndustry,
        });
        _industryId = _initialIndustry;
      }
    }

    setState(() {
      _loadingOptions = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _fundingController.dispose();
    _equityController.dispose();
    super.dispose();
  }

  Future<void> _pickPitchDisk() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );
      if (picked != null && picked.files.single.path != null) {
        setState(() {
          _localPitchDiskPath = picked.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showTopSnack('Failed to pick Pitch Deck: $e', isError: true);
      }
    }
  }

  Future<void> _pickBusinessPlan() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );
      if (picked != null && picked.files.single.path != null) {
        setState(() {
          _localBusinessPlanPath = picked.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showTopSnack('Failed to pick Business Plan: $e', isError: true);
      }
    }
  }

  Widget _buildDocPickerItem({
    required String label,
    required String? localPath,
    required String? networkUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    if (localPath != null || (networkUrl != null && networkUrl.isNotEmpty)) {
      final fileName = localPath != null
          ? p.basename(localPath)
          : networkUrl!.split('/').last;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    fileName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onPick,
              tooltip: 'Change',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 38),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPick,
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: Text('Upload $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20, top: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const Text(
                      'Edit Startup Idea',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    _buildDocPickerItem(
                      label: 'Pitch Deck',
                      localPath: _localPitchDiskPath,
                      networkUrl: _networkPitchDiskUrl,
                      onPick: _pickPitchDisk,
                      onRemove: () => setState(() {
                        _localPitchDiskPath = null;
                        _networkPitchDiskUrl = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _buildDocPickerItem(
                      label: 'Business Plan',
                      localPath: _localBusinessPlanPath,
                      networkUrl: _networkBusinessPlanUrl,
                      onPick: _pickBusinessPlan,
                      onRemove: () => setState(() {
                        _localBusinessPlanPath = null;
                        _networkBusinessPlanUrl = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _bioController,
                      label: 'Bio',
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nameController,
                      label: 'Startup Name',
                      hint: 'e.g. HealthBridge AI',
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    if (_loadingOptions)
                      const Center(child: CircularProgressIndicator())
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _industryId,
                            decoration: const InputDecoration(
                              labelText: 'Industry',
                              border: OutlineInputBorder(),
                            ),
                            items: _industriesList
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e['id']?.toString() ?? '',
                                    child: Text(
                                      (e['name'] ??
                                                  e['label'] ??
                                                  e['value'] ??
                                                  e['id'])
                                              ?.toString() ??
                                          '',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _industryId = val),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _categoriesList
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e['id']?.toString() ?? '',
                                    child: Text(
                                      (e['name'] ??
                                                  e['label'] ??
                                                  e['value'] ??
                                                  e['id'])
                                              ?.toString() ??
                                          '',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _categoryId = val),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _stageId,
                            decoration: const InputDecoration(
                              labelText: 'Stage',
                              border: OutlineInputBorder(),
                            ),
                            items: _stagesList
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e['id']?.toString() ?? '',
                                    child: Text(
                                      (e['label'] ??
                                                  e['name'] ??
                                                  e['value'] ??
                                                  e['id'])
                                              ?.toString() ??
                                          '',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() => _stageId = val),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _fundingController,
                            label: 'Funding Ask',
                            hint: 'e.g. 15000',
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'Invalid'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _equityController,
                            label: 'Equity (%)',
                            hint: 'e.g. 5',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final eq = double.tryParse(v ?? '');
                              if (eq == null || eq < 0 || eq > 100) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(80, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 44),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => _loading = true);

                                  String? logoUrl = _networkLogoUrl;
                                  String? coverUrl = _networkCoverUrl;
                                  String? pitchDiskUrl = _networkPitchDiskUrl;
                                  String? businessPlanUrl =
                                      _networkBusinessPlanUrl;

                                  final uploadHelper = sl<FileUploadHelper>();
                                  if (_localLogoPath != null) {
                                    final res = await uploadHelper.uploadUrl(
                                      path: _localLogoPath!,
                                      endpoint: ApiEndpoints.filesUpload,
                                      fields: {'category': 'startup_logo'},
                                    );
                                    res.fold((_) {}, (url) => logoUrl = url);
                                  }

                                  if (_localCoverPath != null) {
                                    final res = await uploadHelper.uploadUrl(
                                      path: _localCoverPath!,
                                      endpoint: ApiEndpoints.filesUpload,
                                      fields: {'category': 'startup_cover'},
                                    );
                                    res.fold((_) {}, (url) => coverUrl = url);
                                  }

                                  if (_localPitchDiskPath != null) {
                                    final res = await uploadHelper.uploadUrl(
                                      path: _localPitchDiskPath!,
                                      endpoint: ApiEndpoints.filesUpload,
                                      fields: {
                                        'category': 'startup_pitch_deck',
                                      },
                                    );
                                    res.fold(
                                      (_) {},
                                      (url) => pitchDiskUrl = url,
                                    );
                                  }

                                  if (_localBusinessPlanPath != null) {
                                    final res = await uploadHelper.uploadUrl(
                                      path: _localBusinessPlanPath!,
                                      endpoint: ApiEndpoints.filesUpload,
                                      fields: {
                                        'category': 'startup_business_plan',
                                      },
                                    );
                                    res.fold(
                                      (_) {},
                                      (url) => businessPlanUrl = url,
                                    );
                                  }

                                  if (!mounted) return;
                                  Navigator.pop(context, {
                                    'logo': logoUrl ?? '',
                                    'coverUrl': coverUrl ?? '',
                                    'pitchDeck': pitchDiskUrl ?? '',
                                    'businessPlan': businessPlanUrl ?? '',
                                    'startupName': _nameController.text.trim(),
                                    'industry': _industryId ?? _initialIndustry,
                                    'industryId': _industryId,
                                    'category': _categoryId ?? _initialCategory,
                                    'categoryId': _categoryId,
                                    'stage': _stageId ?? _stage,
                                    'stageId': _stageId ?? _stage,
                                    'funding':
                                        double.tryParse(
                                          _fundingController.text.trim(),
                                        ) ??
                                        0.0,
                                    'equity':
                                        double.tryParse(
                                          _equityController.text.trim(),
                                        ) ??
                                        0.0,
                                  });
                                },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
