import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/validators/validators.dart';
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
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerEditProfilePage extends StatefulWidget {
  const FreelancerEditProfilePage({super.key});

  @override
  State<FreelancerEditProfilePage> createState() =>
      _FreelancerEditProfilePageState();
}

class _FreelancerEditProfilePageState extends State<FreelancerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _categoryDisplayController = TextEditingController();
  final _skillsDisplayController = TextEditingController();
  final _categorySearch = TextEditingController();
  final _skillSearch = TextEditingController();

  // Social & Link Controllers
  final _github = TextEditingController();
  final _portfolio = TextEditingController();
  final _linkedin = TextEditingController();
  final _website = TextEditingController();

  // Selected Master Options
  MasterOption? _selectedCountry;
  MasterOption? _selectedState;
  MasterOption? _selectedExperience;
  MasterOption? _selectedAvailability;

  List<MasterOption> _countries = [];
  List<MasterOption> _states = [];
  List<MasterOption> _experienceLevels = [];
  List<MasterOption> _availabilities = [];

  // Categories & Skills
  List<SkillCategory> _categories = [];
  String? _selectedCategoryId;
  List<SkillOption> _visibleSkills = [];
  final Set<String> _selectedSkillIds = {};
  final Map<String, List<SkillOption>> _skillsByCategoryId = {};

  // Loading States
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _loadingCategories = false;
  bool _loadingSkills = false;

  String? _localAvatarPath;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _title.dispose();
    _city.dispose();
    _bio.dispose();
    _hourlyRate.dispose();
    _categoryDisplayController.dispose();
    _skillsDisplayController.dispose();
    _categorySearch.dispose();
    _skillSearch.dispose();
    _github.dispose();
    _portfolio.dispose();
    _linkedin.dispose();
    _website.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadMasterData() async {
    final repo = sl<MasterDataRepository>();

    final cRes = await repo.getCountriesOptions();
    if (mounted && cRes.isSuccess) {
      _countries = cRes.valueOrNull ?? [];
    }

    final expRes = await repo.getExperienceLevelOptions();
    if (mounted && expRes.isSuccess) {
      _experienceLevels = expRes.valueOrNull ?? [];
    }

    final availRes = await repo.getAvailabilityOptions();
    if (mounted && availRes.isSuccess) {
      _availabilities = availRes.valueOrNull ?? [];
    }

    _loadCategories();
  }

  Future<void> _loadStatesForCountry(String countryIdOrCode) async {
    final res = await sl<MasterDataRepository>().getStatesOptions(
      countryIdOrCode,
    );
    if (!mounted) return;
    _states = res.valueOrNull ?? [];
    _matchAllDropdowns();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final result = await sl<MasterDataRepository>().getIndustries();
    if (!mounted) return;

    final categories = result.valueOrNull ?? [];
    setState(() {
      _categories = categories;
      _loadingCategories = false;
      if (_selectedCategoryId != null) {
        final cat = _selectedCategory;
        if (cat != null && _categoryDisplayController.text.isEmpty) {
          _categoryDisplayController.text = cat.name;
        }
      }
    });

    if (_selectedCategoryId != null) {
      _loadSkillsForCategory(_selectedCategoryId!);
    }
  }

  Future<void> _loadSkillsForCategory(String categoryId) async {
    if (_skillsByCategoryId.containsKey(categoryId)) {
      setState(() {
        _selectedCategoryId = categoryId;
        _visibleSkills = _skillsByCategoryId[categoryId] ?? [];
      });
      _updateSkillsDisplayText();
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
      _loadingSkills = true;
    });

    final repo = sl<MasterDataRepository>();
    final allSkills = <SkillOption>[];
    var page = 1;
    const pageSize = 100;
    var total = 0;

    while (true) {
      final result = await repo.getSkills(
        categoryId: categoryId,
        page: page,
        pageSize: pageSize,
      );
      if (!mounted) return;

      final batch = result.valueOrNull ?? [];
      if (batch.isEmpty) break;

      allSkills.addAll(batch.where((skill) => skill.id.isNotEmpty));

      if (page == 1) {
        final totalResult = await repo.getSkillsTotal(categoryId: categoryId);
        total = totalResult.valueOrNull ?? batch.length;
      }

      if (allSkills.length >= total || batch.length < pageSize) break;
      page++;
    }

    setState(() {
      _skillsByCategoryId[categoryId] = allSkills;
      _visibleSkills = allSkills;
      _loadingSkills = false;
    });
    _updateSkillsDisplayText();
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
      if (_experienceLevels.isNotEmpty) {
        _selectedExperience = _matchOption(
          _selectedExperience,
          _experienceLevels,
        );
      }
      if (_availabilities.isNotEmpty) {
        _selectedAvailability = _matchOption(
          _selectedAvailability,
          _availabilities,
        );
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    await _loadMasterData();

    try {
      final res = await sl<ApiClientHelper>().getEnvelope<Map<String, dynamic>>(
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

      if (res.isSuccess) {
        final userMap = res.valueOrNull ?? {};
        final emailVal = userMap['email']?.toString();
        if (emailVal != null && emailVal.isNotEmpty) _email.text = emailVal;

        final fn =
            userMap['fullName']?.toString() ?? userMap['full_name']?.toString();
        if (fn != null && fn.isNotEmpty) _fullName.text = fn;

        final bioVal = userMap['bio']?.toString();
        if (bioVal != null && bioVal.isNotEmpty) _bio.text = bioVal;

        final locVal =
            userMap['city']?.toString() ?? userMap['location']?.toString();
        if (locVal != null && locVal.isNotEmpty) _city.text = locVal;

        _currentAvatarUrl =
            userMap['avatarUrl']?.toString() ??
            userMap['avatar_url']?.toString();

        if (userMap['country'] is Map) {
          final cMap = Map<String, dynamic>.from(userMap['country'] as Map);
          final cid =
              (cMap['id'] ?? cMap['code'] ?? cMap['_id'])?.toString() ?? '';
          final cname = (cMap['name'] ?? cMap['label'])?.toString() ?? cid;
          if (cid.isNotEmpty && cname.isNotEmpty) {
            _selectedCountry = MasterOption(id: cid, name: cname);
            await _loadStatesForCountry(cid);
          }
        } else if (userMap['country'] is String) {
          final cstr = userMap['country'].toString();
          if (cstr.isNotEmpty) {
            _selectedCountry = MasterOption(id: cstr, name: cstr);
            await _loadStatesForCountry(cstr);
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
        } else if (userMap['state'] is String) {
          final sstr = userMap['state'].toString();
          if (sstr.isNotEmpty) {
            _selectedState = MasterOption(id: sstr, name: sstr);
          }
        }

        if (userMap['profile'] is Map) {
          final pMap = Map<String, dynamic>.from(userMap['profile'] as Map);

          final headlineVal =
              (pMap['titleHeadline'] ?? pMap['headline'] ?? pMap['title'])
                  ?.toString();
          if (headlineVal != null && headlineVal.isNotEmpty) {
            _title.text = headlineVal;
          }

          final rateVal = pMap['hourlyRate'] ?? pMap['hourly_rate'];
          if (rateVal != null) {
            _hourlyRate.text = rateVal.toString();
          }

          _github.text =
              (pMap['githubUrl'] ?? pMap['github'])?.toString() ?? '';
          _portfolio.text =
              (pMap['portfolioUrl'] ?? pMap['portfolio'])?.toString() ?? '';
          _linkedin.text =
              (pMap['linkedInUrl'] ?? pMap['linkedin'])?.toString() ?? '';
          _website.text =
              (pMap['websiteUrl'] ?? pMap['website'])?.toString() ?? '';

          if (pMap['experience'] is Map) {
            final expMap = Map<String, dynamic>.from(pMap['experience'] as Map);
            final eid = (expMap['id'] ?? expMap['_id'])?.toString() ?? '';
            final ename =
                (expMap['name'] ?? expMap['label'])?.toString() ?? eid;
            if (eid.isNotEmpty && ename.isNotEmpty) {
              _selectedExperience = MasterOption(id: eid, name: ename);
            }
          }

          if (pMap['availability'] is Map) {
            final availMap = Map<String, dynamic>.from(
              pMap['availability'] as Map,
            );
            final aid = (availMap['id'] ?? availMap['_id'])?.toString() ?? '';
            final aname =
                (availMap['name'] ?? availMap['label'])?.toString() ?? aid;
            if (aid.isNotEmpty && aname.isNotEmpty) {
              _selectedAvailability = MasterOption(id: aid, name: aname);
            }
          }

          if (pMap['industry'] is Map) {
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

          if (pMap['skills'] is List) {
            final skillsList = pMap['skills'] as List;
            final prefilledNames = <String>[];
            for (final s in skillsList) {
              if (s is Map) {
                final sid = (s['id'] ?? s['_id'])?.toString();
                final sname = (s['name'] ?? s['label'])?.toString();
                if (sid != null && sid.isNotEmpty) {
                  _selectedSkillIds.add(sid);
                }
                if (sname != null && sname.isNotEmpty) {
                  prefilledNames.add(sname);
                }
              } else if (s is String && s.isNotEmpty) {
                _selectedSkillIds.add(s);
              }
            }
            if (prefilledNames.isNotEmpty) {
              _skillsDisplayController.text = prefilledNames.join(', ');
            }
          }
        }
      }
    } catch (_) {}

    _matchAllDropdowns();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      context.showSnack('Industry / Category is required', isError: true);
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'fullName': _fullName.text.trim(),
      'titleHeadline': _title.text.trim(),
      'bio': _bio.text.trim(),
      'city': _city.text.trim(),
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      if (_selectedState != null) ...{
        'stateId': _selectedState!.id,
        'stateid': _selectedState!.id,
      },
      if (_selectedExperience != null) ...{
        'experienceLevelId': _selectedExperience!.id,
        'experienceId': _selectedExperience!.id,
      },
      if (_selectedAvailability != null)
        'availabilityId': _selectedAvailability!.id,
      if (_selectedCategoryId != null) ...{
        'industryId': _selectedCategoryId,
        'categoryId': _selectedCategoryId,
      },
      if (_hourlyRate.text.trim().isNotEmpty)
        'hourlyRate':
            double.tryParse(_hourlyRate.text.trim()) ?? _hourlyRate.text.trim(),
      if (_selectedSkillIds.isNotEmpty) ...{
        'skillIds': _selectedSkillIds.toList().join(','),
        'skills': _selectedSkillIds.toList(),
      },
      'portfolioUrl': _portfolio.text.trim(),
      'githubUrl': _github.text.trim(),
      'linkedInUrl': _linkedin.text.trim(),
      'websiteUrl': _website.text.trim(),
      if (_currentAvatarUrl != null) 'avatarUrl': _currentAvatarUrl,
    };

    final res = await sl<ApiClientHelper>().putEnvelope<Map<String, dynamic>>(
      ApiEndpoints.updateMe,
      body: payload,
      parser: (envelope) => {
        'message': envelope.message ?? 'Profile updated successfully',
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    res.fold((f) => context.showSnack(f.message, isError: true), (data) {
      final msg =
          data['message']?.toString() ?? 'Profile updated successfully!';
      context.showSnack(msg);
      context.read<AuthBloc>().add(const AuthRefreshUser());
      Navigator.of(context).pop();
    });
  }

  Future<void> _uploadAvatar(String path) async {
    setState(() {
      _localAvatarPath = path;
      _uploadingAvatar = true;
    });
    final res = await sl<FreelancerProfileRepository>().uploadAvatar(path);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    res.fold((f) => context.showSnack(f.message, isError: true), (url) async {
      setState(() {
        _localAvatarPath = null;
        _currentAvatarUrl = url;
      });
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Avatar updated successfully!');
      await _load();
    });
  }

  void _onCategorySelected(String categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSkillIds.clear();
      _skillsDisplayController.clear();
      _visibleSkills = [];
    });
    final cat = _selectedCategory;
    if (cat != null) {
      _categoryDisplayController.text = cat.name;
    }
    _loadSkillsForCategory(categoryId);
  }

  SkillCategory? get _selectedCategory {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) return category;
    }
    return null;
  }

  void _toggleSkill(String skillId) {
    setState(() {
      if (_selectedSkillIds.contains(skillId)) {
        _selectedSkillIds.remove(skillId);
      } else {
        _selectedSkillIds.add(skillId);
      }
    });
    _updateSkillsDisplayText();
  }

  void _updateSkillsDisplayText() {
    final selectedNames = <String>[];
    for (final categorySkills in _skillsByCategoryId.values) {
      for (final s in categorySkills) {
        if (_selectedSkillIds.contains(s.id) &&
            !selectedNames.contains(s.name)) {
          selectedNames.add(s.name);
        }
      }
    }
    for (final s in _visibleSkills) {
      if (_selectedSkillIds.contains(s.id) && !selectedNames.contains(s.name)) {
        selectedNames.add(s.name);
      }
    }
    if (selectedNames.isNotEmpty) {
      _skillsDisplayController.text = selectedNames.join(', ');
    } else if (_selectedSkillIds.isEmpty) {
      _skillsDisplayController.clear();
    }
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
                        'Select Industry / Category',
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
                        child: _loadingCategories
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
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
                                      _onCategorySelected(cat.id);
                                      _categoryDisplayController.text =
                                          cat.name;
                                      _skillsDisplayController.clear();
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

  void _showSkillsBottomSheet() {
    if (_selectedCategoryId == null) {
      context.showSnack(
        'Please select an Industry / Category first',
        isError: true,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _skillSearch.text.trim().toLowerCase();
            final filtered = search.isEmpty
                ? _visibleSkills
                : _visibleSkills
                      .where((s) => s.name.toLowerCase().contains(search))
                      .toList();

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
                            'Select Skills (${_selectedSkillIds.length})',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _updateSkillsDisplayText();
                              Navigator.of(context).pop();
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
                        hint: 'Search skills...',
                        prefixIcon: Icons.search,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      AppSizes.vGapMd,
                      Expanded(
                        child: _loadingSkills
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
                            ? const Center(child: Text('No skills found'))
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
                          _updateSkillsDisplayText();
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

  // ─── Completion Percentage ─────────────────────────────────────────────────

  int _completionPercent() {
    final checks = [
      _bio.text.trim().isNotEmpty,
      _hourlyRate.text.trim().isNotEmpty,
      _selectedCategoryId != null,
      _selectedCountry != null,
      _selectedState != null,
      _selectedExperience != null,
      _selectedAvailability != null,
      _fullName.text.trim().isNotEmpty,
      _title.text.trim().isNotEmpty,
      _city.text.trim().isNotEmpty,
      (_localAvatarPath ?? _currentAvatarUrl ?? '').isNotEmpty,
    ];
    final filled = checks.where((c) => c).length;
    return ((filled / checks.length) * 100).round();
  }

  // ─── UI Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Edit Profile'),
        actions: [
          if (!_saving)
            TextButton.icon(
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
              onPressed: _save,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Completion Card
                    _CompletionCard(percent: _completionPercent()),
                    AppSizes.vGapLg,

                    // Profile Photo
                    const _SectionLabel('Profile Photo'),
                    AppSizes.vGapSm,
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ProfileAvatarEditor(
                          localPath: _localAvatarPath,
                          networkUrl: _currentAvatarUrl,
                          onPathPicked: _uploadAvatar,
                          size: 110,
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    AppSizes.vGapLg,

                    // Personal Info
                    const _SectionLabel('About You'),
                    AppSizes.vGapSm,
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      hint: 'Email Address',
                      readOnly: true,
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _fullName,
                      label: 'Full Name *',
                      hint: 'Enter your full name',
                      validator: (v) =>
                          Validators.minLength(v, 2, field: 'Full Name'),
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _title,
                      label: 'Professional Title *',
                      hint: 'e.g. Senior Flutter Developer',
                      validator: (v) => Validators.minLength(
                        v,
                        3,
                        field: 'Professional Title',
                      ),
                    ),
                    AppSizes.vGapLg,

                    // Location
                    const _SectionLabel('Location'),
                    AppSizes.vGapSm,
                    AppLocationField(
                      controller: _city,
                      label: 'City / Location *',
                      hint: 'Search and select city / location',
                      validator: (v) =>
                          Validators.required(v, field: 'City / Location'),
                    ),
                    AppSizes.vGapMd,
                    AppDropdown<MasterOption>(
                      label: 'Country *',
                      hint: 'Select Country',
                      value: _selectedCountry,
                      items: _countries,
                      itemLabel: (item) => item.name,
                      validator: (v) =>
                          Validators.required(v?.name, field: 'Country'),
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
                      validator: (v) =>
                          Validators.required(v?.name, field: 'State'),
                      onChanged: (opt) => setState(() => _selectedState = opt),
                    ),
                    AppSizes.vGapLg,

                    // Professional Bio
                    const _SectionLabel('Professional Bio'),
                    AppSizes.vGapSm,
                    AppTextField(
                      controller: _bio,
                      label: 'Bio *',
                      hint:
                          'Tell clients about yourself, your expertise, and what makes you unique…',
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      validator: (v) =>
                          Validators.minLength(v, 10, field: 'Bio'),
                    ),
                    AppSizes.vGapLg,

                    // Work Preferences
                    const _SectionLabel('Work Preferences'),
                    AppSizes.vGapSm,
                    AppTextField(
                      controller: _hourlyRate,
                      label: 'Hourly Rate (\$/hr) *',
                      hint: 'e.g. 120 or 230.99',
                      prefixIcon: Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final reqErr = Validators.required(
                          v,
                          field: 'Hourly Rate',
                        );
                        if (reqErr != null) return reqErr;
                        if (double.tryParse(v!.trim()) == null) {
                          return 'Please enter a valid rate (e.g. 230.99)';
                        }
                        return null;
                      },
                    ),
                    AppSizes.vGapMd,
                    AppDropdown<MasterOption>(
                      label: 'Availability *',
                      hint: 'Select Availability',
                      value: _selectedAvailability,
                      items: _availabilities,
                      itemLabel: (item) => item.name,
                      validator: (v) =>
                          Validators.required(v?.name, field: 'Availability'),
                      onChanged: (opt) =>
                          setState(() => _selectedAvailability = opt),
                    ),
                    AppSizes.vGapMd,
                    AppDropdown<MasterOption>(
                      label: 'Experience Level *',
                      hint: 'Select Experience Level',
                      value: _selectedExperience,
                      items: _experienceLevels,
                      itemLabel: (item) => item.name,
                      validator: (v) => Validators.required(
                        v?.name,
                        field: 'Experience Level',
                      ),
                      onChanged: (opt) =>
                          setState(() => _selectedExperience = opt),
                    ),
                    AppSizes.vGapLg,

                    // Industry & Skills
                    const _SectionLabel('Industry & Skills'),
                    AppSizes.vGapSm,
                    AppTextField(
                      controller: _categoryDisplayController,
                      label: 'Industry / Category *',
                      hint: 'Select Industry / Category',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: _showCategoryBottomSheet,
                      validator: (v) =>
                          Validators.required(v, field: 'Industry / Category'),
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _skillsDisplayController,
                      label: 'Skills (optional)',
                      hint: _selectedCategoryId == null
                          ? 'Select industry first'
                          : 'Select skills',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: _showSkillsBottomSheet,
                    ),
                    AppSizes.vGapLg,

                    // Social Links
                    const _SectionLabel('Social & Links'),
                    AppSizes.vGapSm,
                    AppTextField(
                      controller: _portfolio,
                      label: 'Portfolio URL',
                      hint: 'https://...',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _github,
                      label: 'GitHub URL',
                      hint: 'https://github.com/...',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _linkedin,
                      label: 'LinkedIn Profile',
                      hint: 'https://linkedin.com/in/...',
                    ),
                    AppSizes.vGapMd,
                    AppTextField(
                      controller: _website,
                      label: 'Website',
                      hint: 'https://...',
                    ),
                    AppSizes.vGapXl,

                    // Save Button
                    AppPrimaryButton(
                      label: 'Save Profile',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    AppSizes.vGapLg,
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percent});
  final int percent;

  Color get _color {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      color: _color.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                percent >= 80
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: _color,
                size: 18,
              ),
              AppSizes.hGapSm,
              Expanded(
                child: Text(
                  percent >= 80
                      ? 'Great! Your profile looks strong.'
                      : percent >= 50
                      ? 'Profile is taking shape — keep going!'
                      : 'Complete your profile to get hired faster.',
                  style: context.text.bodySmall?.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: context.text.titleSmall?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          AppSizes.vGapSm,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ],
      ),
    );
  }
}
