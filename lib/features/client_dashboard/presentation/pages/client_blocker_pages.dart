import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/payments/payment_checkout_service.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

class ClientCompanyProfilePage extends StatefulWidget {
  const ClientCompanyProfilePage({super.key});

  @override
  State<ClientCompanyProfilePage> createState() =>
      _ClientCompanyProfilePageState();
}

class _ClientCompanyProfilePageState extends State<ClientCompanyProfilePage> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _companyNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _website = TextEditingController();
  final _linkedin = TextEditingController();
  final _categoryDisplayController = TextEditingController();
  final _hiringGoalsDisplayController = TextEditingController();
  final _categorySearch = TextEditingController();

  MasterOption? _selectedCountry;
  MasterOption? _selectedState;
  MasterOption? _selectedCompanySize;
  MasterOption? _selectedBudgetRange;
  String? _selectedCategoryId;
  final Set<String> _selectedHiringGoalIds = {};

  List<MasterOption> _countries = [];
  List<MasterOption> _states = [];
  List<MasterOption> _companySizes = [];
  List<MasterOption> _budgetRanges = [];
  List<MasterOption> _hiringGoals = [];
  List<MasterOption> _categories = [];

  bool _loading = true;
  bool _saving = false;
  Company? _companyData;
  String? _localLogoPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _city.dispose();
    _bio.dispose();
    _website.dispose();
    _linkedin.dispose();
    _categoryDisplayController.dispose();
    _hiringGoalsDisplayController.dispose();
    _categorySearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final masterRepo = sl<MasterDataRepository>();

    final cRes = await masterRepo.getCountriesOptions();
    if (mounted && cRes.isSuccess) _countries = cRes.valueOrNull ?? [];

    final csRes = await masterRepo.getCompanySizeOptions();
    if (mounted && csRes.isSuccess) _companySizes = csRes.valueOrNull ?? [];

    final bRes = await masterRepo.getHiringBudgetOptions();
    if (mounted && bRes.isSuccess) _budgetRanges = bRes.valueOrNull ?? [];

    final hgRes = await masterRepo.getHiringGoalOptions();
    if (mounted && hgRes.isSuccess) _hiringGoals = hgRes.valueOrNull ?? [];

    final catRes = await masterRepo.getIndustryOptions();
    if (mounted && catRes.isSuccess) _categories = catRes.valueOrNull ?? [];

    final meRes = await api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.me,
      parser: (env) {
        if (env.data is Map && (env.data as Map)['user'] is Map) {
          return Map<String, dynamic>.from((env.data as Map)['user'] as Map);
        }
        if (env.data is Map) {
          return Map<String, dynamic>.from(env.data as Map);
        }
        return {};
      },
    );

    if (!mounted) return;
    final userMap = meRes.valueOrNull ?? {};
    if (userMap.isNotEmpty) {
      final emailVal = userMap['email']?.toString();
      if (emailVal != null && emailVal.isNotEmpty) _email.text = emailVal;

      final fn =
          userMap['fullName']?.toString() ?? userMap['full_name']?.toString();
      if (fn != null && fn.isNotEmpty) _name.text = fn;

      final bioVal = userMap['bio']?.toString();
      if (bioVal != null && bioVal.isNotEmpty) _bio.text = bioVal;

      final locVal =
          userMap['city']?.toString() ?? userMap['location']?.toString();
      if (locVal != null && locVal.isNotEmpty) _city.text = locVal;

      if (userMap['country'] is Map) {
        final cMap = Map<String, dynamic>.from(userMap['country'] as Map);
        final cid =
            (cMap['id'] ?? cMap['code'] ?? cMap['_id'])?.toString() ?? '';
        final cname = (cMap['name'] ?? cMap['label'])?.toString() ?? cid;
        if (cid.isNotEmpty && cname.isNotEmpty) {
          _selectedCountry = MasterOption(id: cid, name: cname);
          _loadStatesForCountry(cid);
        }
      }

      if (userMap['state'] is Map) {
        final sMap = Map<String, dynamic>.from(userMap['state'] as Map);
        final sid =
            (sMap['id'] ?? sMap['code'] ?? sMap['_id'])?.toString() ?? '';
        final sname = (sMap['name'] ?? sMap['label'])?.toString() ?? sid;
        if (sid.isNotEmpty && sname.isNotEmpty) {
          _selectedState = MasterOption(id: sid, name: sname);
        }
      }

      if (userMap['profile'] is Map) {
        final pMap = Map<String, dynamic>.from(userMap['profile'] as Map);

        final compVal = pMap['company']?.toString();
        if (compVal != null && compVal.isNotEmpty) {
          _companyNameController.text = compVal;
        }

        final jtVal =
            (pMap['jobTitle'] ??
                    pMap['titleHeadline'] ??
                    pMap['headline'] ??
                    pMap['title'])
                ?.toString();
        if (jtVal != null && jtVal.isNotEmpty) {
          _jobTitleController.text = jtVal;
        }

        final webVal = (pMap['websiteUrl'] ?? pMap['website'])?.toString();
        if (webVal != null && webVal.isNotEmpty) {
          _website.text = webVal;
        }

        final linkVal = (pMap['linkedInUrl'] ?? pMap['linkedin'])?.toString();
        if (linkVal != null && linkVal.isNotEmpty) {
          _linkedin.text = linkVal;
        }

        if (pMap['industryId'] is Map) {
          final indMap = Map<String, dynamic>.from(pMap['industryId'] as Map);
          final indId = (indMap['id'] ?? indMap['_id'])?.toString();
          final indName = (indMap['name'] ?? indMap['label'])?.toString();
          if (indId != null && indId.isNotEmpty) {
            _selectedCategoryId = indId;
            if (indName != null && indName.isNotEmpty) {
              _categoryDisplayController.text = indName;
            }
          }
        } else if (pMap['industry'] is Map) {
          final indMap = Map<String, dynamic>.from(pMap['industry'] as Map);
          final indId = (indMap['id'] ?? indMap['_id'])?.toString();
          final indName = (indMap['name'] ?? indMap['label'])?.toString();
          if (indId != null && indId.isNotEmpty) {
            _selectedCategoryId = indId;
            if (indName != null && indName.isNotEmpty) {
              _categoryDisplayController.text = indName;
            }
          }
        }

        if (pMap['companySizeId'] is Map) {
          final csMap = Map<String, dynamic>.from(pMap['companySizeId'] as Map);
          final csId = (csMap['id'] ?? csMap['_id'])?.toString() ?? '';
          final csName = (csMap['name'] ?? csMap['label'])?.toString() ?? csId;
          if (csId.isNotEmpty && csName.isNotEmpty) {
            _selectedCompanySize = MasterOption(id: csId, name: csName);
          }
        }

        if (pMap['projectHireBudgetId'] is Map) {
          final bMap = Map<String, dynamic>.from(
            pMap['projectHireBudgetId'] as Map,
          );
          final bId = (bMap['id'] ?? bMap['_id'])?.toString() ?? '';
          final bName = (bMap['name'] ?? bMap['label'])?.toString() ?? bId;
          if (bId.isNotEmpty && bName.isNotEmpty) {
            _selectedBudgetRange = MasterOption(id: bId, name: bName);
          }
        }

        if (pMap['hiringGoalId'] is List) {
          final hgList = pMap['hiringGoalId'] as List;
          final names = <String>[];
          for (final goal in hgList) {
            if (goal is Map) {
              final gid = (goal['id'] ?? goal['_id'])?.toString();
              final gname = (goal['name'] ?? goal['label'])?.toString();
              if (gid != null && gid.isNotEmpty) {
                _selectedHiringGoalIds.add(gid);
              }
              if (gname != null && gname.isNotEmpty) names.add(gname);
            } else if (goal is String && goal.isNotEmpty) {
              _selectedHiringGoalIds.add(goal);
              names.add(goal);
            }
          }
          if (names.isNotEmpty) {
            _hiringGoalsDisplayController.text = names.join(', ');
          }
        }
      }
    }

    _matchAllDropdowns();
    setState(() => _loading = false);
  }

  MasterOption? _matchOption(MasterOption? current, List<MasterOption> list) {
    if (current == null || list.isEmpty) return null;
    for (final item in list) {
      if (item == current) return item;
      if (current.id.isNotEmpty && item.id == current.id) return item;
      if (current.name.isNotEmpty &&
          item.name.trim().toLowerCase() == current.name.trim().toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  void _matchAllDropdowns() {
    if (!mounted) return;
    setState(() {
      if (_countries.isNotEmpty) {
        _selectedCountry = _matchOption(_selectedCountry, _countries);
      }
      if (_states.isNotEmpty) {
        _selectedState = _matchOption(_selectedState, _states);
      }
      if (_companySizes.isNotEmpty) {
        _selectedCompanySize = _matchOption(
          _selectedCompanySize,
          _companySizes,
        );
      }
      if (_budgetRanges.isNotEmpty) {
        _selectedBudgetRange = _matchOption(
          _selectedBudgetRange,
          _budgetRanges,
        );
      }
    });
  }

  Future<void> _loadStatesForCountry(String countryIdOrCode) async {
    final res = await sl<MasterDataRepository>().getStatesOptions(
      countryIdOrCode,
    );
    if (!mounted) return;
    _states = res.valueOrNull ?? [];
    _matchAllDropdowns();
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
            final filtered = search.isEmpty
                ? _categories
                : _categories
                      .where((c) => c.name.toLowerCase().contains(search))
                      .toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Column(
                    children: [
                      Text(
                        'Select Category / Industry',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSizes.vGapMd,
                      AppTextField(
                        controller: _categorySearch,
                        hint: 'Search categories...',
                        prefixIcon: Icons.search,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      AppSizes.vGapMd,
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No categories found'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final cat = filtered[index];
                                  final isSelected =
                                      cat.id == _selectedCategoryId;
                                  return ListTile(
                                    title: Text(cat.name),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryId = cat.id;
                                        _categoryDisplayController.text =
                                            cat.name;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showHiringGoalsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Hiring Goals (${_selectedHiringGoalIds.length})',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _updateHiringGoalsDisplayText();
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Done',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      AppSizes.vGapMd,
                      Expanded(
                        child: _hiringGoals.isEmpty
                            ? const Center(child: Text('No goals available'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _hiringGoals.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final goal = _hiringGoals[index];
                                  final isSelected = _selectedHiringGoalIds
                                      .contains(goal.id);
                                  return CheckboxListTile(
                                    title: Text(goal.name),
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    onChanged: (_) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedHiringGoalIds.remove(
                                            goal.id,
                                          );
                                        } else {
                                          _selectedHiringGoalIds.add(goal.id);
                                        }
                                      });
                                      setSheetState(() {});
                                      _updateHiringGoalsDisplayText();
                                    },
                                  );
                                },
                              ),
                      ),
                      AppSizes.vGapMd,
                      AppPrimaryButton(
                        label:
                            'Done (${_selectedHiringGoalIds.length} selected)',
                        onPressed: () {
                          _updateHiringGoalsDisplayText();
                          Navigator.of(context).pop();
                        },
                      ),
                      AppSizes.vGapLg,
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateHiringGoalsDisplayText() {
    final names = <String>[];
    for (final goal in _hiringGoals) {
      if (_selectedHiringGoalIds.contains(goal.id)) {
        names.add(goal.name);
      }
    }
    if (names.isNotEmpty) {
      _hiringGoalsDisplayController.text = names.join(', ');
    } else if (_selectedHiringGoalIds.isEmpty) {
      _hiringGoalsDisplayController.clear();
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      context.showSnack('Full name is required', isError: true);
      return;
    }
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'fullName': _name.text.trim(),
      'city': _city.text.trim(),
      'bio': _bio.text.trim(),
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      if (_selectedState != null) 'stateId': _selectedState!.id,
      'company': _companyNameController.text.trim(),
      'jobTitle': _jobTitleController.text.trim(),
      if (_selectedCategoryId != null) 'industryId': _selectedCategoryId,
      if (_selectedCompanySize != null)
        'companySizeId': _selectedCompanySize!.id,
      if (_selectedBudgetRange != null)
        'projectHireBudgetId': _selectedBudgetRange!.id,
      if (_selectedHiringGoalIds.isNotEmpty)
        'hiringGoalId': _selectedHiringGoalIds.toList(),
      'websiteUrl': _website.text.trim(),
      'linkedInUrl': _linkedin.text.trim(),
      if (_localLogoPath != null || _companyData?.logoUrl != null)
        'logo': _localLogoPath ?? _companyData?.logoUrl,
    };

    final res = await sl<ApiClientHelper>().putEnvelope<Map<String, dynamic>>(
      ApiEndpoints.updateMe,
      body: payload,
      parser: (env) =>
          env.data is Map ? Map<String, dynamic>.from(env.data as Map) : {},
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res.isSuccess) {
      final msg =
          res.valueOrNull?['message']?.toString() ??
          'Company profile updated successfully';
      context.showSnack(msg);
      final currentUser = context.read<AuthBloc>().state.user;
      if (currentUser != null) {
        context.read<AuthBloc>().add(
          AuthUserUpdated(currentUser.copyWith(fullName: _name.text.trim())),
        );
      }
      Navigator.of(context).pop();
    } else {
      context.showSnack(
        res.failureOrNull?.message ?? 'Failed to update company profile',
        isError: true,
      );
    }
  }

  Future<void> _uploadDoc() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (picked == null || picked.files.single.path == null) return;
    final res = await sl<CompanyRepository>().uploadClientDocument(
      picked.files.single.path!,
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Document uploaded'),
    );
  }

  Future<void> _uploadLogo(String path) async {
    setState(() => _localLogoPath = path);
    final result = await sl<CompanyRepository>().uploadClientLogo(path);
    if (!mounted) return;
    result.fold(
      (failure) => context.showSnack(failure.message, isError: true),
      (url) async {
        setState(() {
          _localLogoPath = null;
        });
        context.read<AuthBloc>().add(const AuthRefreshUser());
        context.showSnack('Company logo updated');
        await _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Company Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companyData?.isVerified == true
                            ? 'Verified business'
                            : 'Verification pending',
                      ),
                      const SizedBox(height: 6),
                      Text('Profile completion: ${_completionPercent()}%'),
                    ],
                  ),
                ),
                AppSizes.vGapMd,
                ProfileAvatarEditor(
                  localPath: _localLogoPath,
                  networkUrl: _companyData?.logoUrl,
                  onPathPicked: _uploadLogo,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'Email Address',
                  readOnly: true,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _name,
                  label: 'Full Name *',
                  hint: 'Enter your full name',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _jobTitleController,
                  label: 'Job Title *',
                  hint: 'e.g. VP of Engineering',
                ),
                AppSizes.vGapLg,
                Text('Company Info', style: context.text.titleMedium),
                AppSizes.vGapSm,
                AppTextField(
                  controller: _companyNameController,
                  label: 'Company Name *',
                  hint: 'Enter company name',
                ),
                AppSizes.vGapMd,
                AppLocationField(
                  controller: _city,
                  label: 'Location / City *',
                  hint: 'Search and select city location',
                ),
                AppSizes.vGapMd,
                AppDropdown<MasterOption>(
                  label: 'Country *',
                  hint: 'Select Country',
                  value: _selectedCountry,
                  items: _countries,
                  itemLabel: (item) => item.name,
                  onChanged: (opt) {
                    setState(() {
                      _selectedCountry = opt;
                      _selectedState = null;
                      _states = [];
                    });
                    if (opt != null) {
                      _loadStatesForCountry(opt.id);
                    }
                  },
                ),
                AppSizes.vGapMd,
                AppDropdown<MasterOption>(
                  label: 'State *',
                  hint: 'Select State',
                  value: _selectedState,
                  items: _states,
                  itemLabel: (item) => item.name,
                  onChanged: (opt) => setState(() => _selectedState = opt),
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _categoryDisplayController,
                  label: 'Category / Industry *',
                  hint: 'Select Category / Industry',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onTap: _showCategoryBottomSheet,
                ),
                AppSizes.vGapMd,
                AppDropdown<MasterOption>(
                  label: 'Company Size *',
                  hint: 'Select Company Size',
                  value: _selectedCompanySize,
                  items: _companySizes,
                  itemLabel: (item) => item.name,
                  onChanged: (opt) =>
                      setState(() => _selectedCompanySize = opt),
                ),
                AppSizes.vGapMd,
                AppDropdown<MasterOption>(
                  label: 'Project / Hiring Budget *',
                  hint: 'Select Budget Range',
                  value: _selectedBudgetRange,
                  items: _budgetRanges,
                  itemLabel: (item) => item.name,
                  onChanged: (opt) =>
                      setState(() => _selectedBudgetRange = opt),
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _hiringGoalsDisplayController,
                  label: 'Hiring Goals',
                  hint: 'Select Hiring Goals',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onTap: _showHiringGoalsBottomSheet,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _bio,
                  label: 'Biography / Overview',
                  hint: 'Brief description about the company',
                  maxLines: 3,
                ),
                AppSizes.vGapLg,
                Text('Links', style: context.text.titleMedium),
                AppSizes.vGapSm,
                AppTextField(
                  controller: _website,
                  label: 'Website',
                  hint: 'Enter website URL',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _linkedin,
                  label: 'LinkedIn URL',
                  hint: 'Enter LinkedIn URL',
                ),
                AppSizes.vGapLg,
                AppPrimaryButton(
                  label: 'Upload Document',
                  onPressed: _uploadDoc,
                  icon: Icons.upload_file_outlined,
                ),
                AppSizes.vGapMd,
                AppPrimaryButton(
                  label: 'Save Profile',
                  isLoading: _saving,
                  onPressed: _save,
                ),
                SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
              ],
            ),
    );
  }

  int _completionPercent() {
    final vals = [
      _name.text.trim(),
      _companyNameController.text.trim(),
      _bio.text.trim(),
      _city.text.trim(),
      _selectedCountry?.name ?? '',
      _selectedState?.name ?? '',
      if ((_companyData?.logoUrl ?? '').isNotEmpty || _localLogoPath != null)
        'logo',
    ];
    final filled = vals.where((e) => e.isNotEmpty).length;
    return ((filled / 7) * 100).round();
  }
}

class ClientReportsHubPage extends StatefulWidget {
  const ClientReportsHubPage({super.key});

  @override
  State<ClientReportsHubPage> createState() => _ClientReportsHubPageState();
}

class _ClientReportsHubPageState extends State<ClientReportsHubPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = const [];
  List<Map<String, dynamic>> _milestones = const [];
  List<Map<String, dynamic>> _payments = const [];
  List<Map<String, dynamic>> _documents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final tasks = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientTasks,
      parser: (e) => _asMapList(e.data),
    );
    final milestones = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientMilestones,
      parser: (e) => _asMapList(e.data),
    );
    final payments = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientPayments,
      parser: (e) => _asMapList(e.data),
    );
    final docs = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.clientDocuments,
      parser: (e) => _asMapList(e.data),
    );
    if (!mounted) return;
    _tasks = tasks.valueOrNull ?? const [];
    _milestones = milestones.valueOrNull ?? const [];
    _payments = payments.valueOrNull ?? const [];
    _documents = docs.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _patchTaskStatus(String id, String status) async {
    final res = await sl<ApiClientHelper>().patchAction(
      ApiEndpoints.clientTaskStatus(id),
      body: {'status': status},
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Task updated'),
    );
    await _load();
  }

  Future<void> _milestoneAction(String id, bool approve) async {
    final res = await sl<ApiClientHelper>().patchAction(
      approve
          ? ApiEndpoints.clientMilestoneApprove(id)
          : ApiEndpoints.clientMilestoneReject(id),
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Milestone updated'),
    );
    await _load();
  }

  Future<void> _initiatePayment() async {
    final checkout = sl<PaymentCheckoutService>();
    final result = await checkout.checkoutWithEasebuzz(
      purpose: 'client_payment',
      amount: 1,
      metadata: const {'source': 'client_payments_page'},
    );
    if (!mounted) return;
    await result.fold((f) async => context.showSnack(f.message), (paid) async {
      final sdk = paid.checkout;
      final verify = await checkout.verify(
        paymentId: paid.payment.paymentId,
        gateway: paid.payment.gateway,
        purpose: 'client_payment',
        verification: {
          'status': 'success',
          'orderId': paid.payment.orderId,
          'txnid': paid.payment.orderId,
          ...sdk.raw,
          if (sdk.raw['payment_response'] is Map)
            ...Map<String, dynamic>.from(sdk.raw['payment_response'] as Map),
        },
      );
      if (!mounted) return;
      verify.fold(
        (f) => context.showSnack(f.message),
        (_) => context.showSnack('Payment completed and verified'),
      );
    });
  }

  Future<void> _verifyPayment() async {
    context.showSnack(
      'Verification runs automatically after Easebuzz checkout',
    );
  }

  Future<void> _uploadDocument() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = picked?.files.single.path;
    if (path == null) return;
    final uploader = sl<FileUploadHelper>();
    final direct = await uploader.uploadUrl(
      path: path,
      endpoint: '${ApiEndpoints.clientDocuments}/upload',
    );
    if (!mounted) return;
    if (direct.isSuccess) {
      context.showSnack('Document uploaded');
      await _load();
      return;
    }
    final fallback = await uploader.uploadUrl(
      path: path,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'client_document'},
    );
    if (!mounted) return;
    fallback.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Document uploaded via files API'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Client Operations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Initiate Payment',
                            onPressed: _initiatePayment,
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Verify Payment',
                            onPressed: _verifyPayment,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tasks'),
                        for (final t in _tasks.take(5))
                          ListTile(
                            dense: true,
                            title: Text(t['title']?.toString() ?? 'Task'),
                            subtitle: Text(
                              'Status: ${t['status'] ?? 'pending'}',
                            ),
                            trailing: IconButton(
                              onPressed: () => _patchTaskStatus(
                                t['id']?.toString() ?? '',
                                'completed',
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Milestones'),
                        for (final m in _milestones.take(5))
                          ListTile(
                            dense: true,
                            title: Text(m['title']?.toString() ?? 'Milestone'),
                            subtitle: Text(
                              'Status: ${m['status'] ?? 'pending'}',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () => _milestoneAction(
                                    m['id']?.toString() ?? '',
                                    true,
                                  ),
                                  icon: const Icon(Icons.check),
                                ),
                                IconButton(
                                  onPressed: () => _milestoneAction(
                                    m['id']?.toString() ?? '',
                                    false,
                                  ),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Documents'),
                            const Spacer(),
                            TextButton(
                              onPressed: _uploadDocument,
                              child: const Text('Upload'),
                            ),
                          ],
                        ),
                        for (final d in _documents.take(5))
                          ListTile(
                            dense: true,
                            title: Text(
                              d['name']?.toString() ??
                                  d['title']?.toString() ??
                                  'Document',
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payments'),
                        for (final p in _payments.take(5))
                          ListTile(
                            dense: true,
                            title: Text(p['title']?.toString() ?? 'Payment'),
                            subtitle: Text(
                              'Status: ${p['status'] ?? 'unknown'}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    final list = raw as List?;
    if (list == null) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class ClientAnalyticsLivePage extends StatefulWidget {
  const ClientAnalyticsLivePage({super.key});

  @override
  State<ClientAnalyticsLivePage> createState() =>
      _ClientAnalyticsLivePageState();
}

class _ClientAnalyticsLivePageState extends State<ClientAnalyticsLivePage> {
  bool _loading = true;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.clientAnalytics,
      parser: (e) => Map<String, dynamic>.from(e.data as Map),
    );
    if (!mounted) return;
    _data = res.valueOrNull ?? const {};
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Client Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  _metric('Spend', _data['spend']),
                  _metric('Projects', _data['projects']),
                  _metric('Proposals', _data['proposals']),
                  _metric('Contracts', _data['contracts']),
                  _metric('Payments', _data['payments']),
                  _metric('Hiring Funnel', _data['hiringFunnel']),
                ],
              ),
            ),
    );
  }

  Widget _metric(String label, dynamic value) => AppCard(
    child: Row(
      children: [Text(label), const Spacer(), Text(value?.toString() ?? '—')],
    ),
  );
}
