import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/profile_completion_warning_dialog.dart';
import '../../../../core/widgets/profile_save_success_dialog.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../core/widgets/profile_completion_card.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';
import '../../../auth/presentation/widgets/signup_multi_select_sheet.dart';

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
  final _phone = TextEditingController();
  final _fullName = TextEditingController();
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _categoryDisplayController = TextEditingController();
  final _skillsDisplayController = TextEditingController();
  final _categorySearch = TextEditingController();
  final _skillSearch = TextEditingController();
  final _otherSkillController = TextEditingController();

  // Social & Link Controllers
  final _github = TextEditingController();
  final _portfolio = TextEditingController();
  final _linkedin = TextEditingController();

  // Selected Master Options
  MasterOption? _selectedCountry;
  MasterOption? _selectedState;
  MasterOption? _selectedExperience;
  MasterOption? _selectedAvailability;

  String? _educationLevel;
  final List<String> _educationLevels = [
    'High School',
    'Diploma',
    'Bachelors',
    'Masters',
    'Doctorate (Ph.D.)',
    'Other',
  ];

  List<MasterOption> _countries = [];
  List<MasterOption> _states = [];
  List<MasterOption> _experienceLevels = [];
  List<MasterOption> _availabilities = [];

  // Categories & Skills
  List<SkillCategory> _categories = [];
  List<String> _selectedCategoryIds = [];
  List<SkillOption> _visibleSkills = [];
  final Set<String> _selectedSkillIds = {};
  List<String> _selectedSkillNames = [];
  List<String> _availableSkillNames = [];
  final Map<String, SkillOption> _skillsMap = {};
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
    _phone.dispose();
    _fullName.dispose();
    _title.dispose();
    _city.dispose();
    _bio.dispose();
    _hourlyRate.dispose();
    _categoryDisplayController.dispose();
    _skillsDisplayController.dispose();
    _categorySearch.dispose();
    _skillSearch.dispose();
    _otherSkillController.dispose();
    _github.dispose();
    _portfolio.dispose();
    _linkedin.dispose();
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
      if (_selectedCategoryIds.isNotEmpty) {
        final names = _categories
            .where((c) => _selectedCategoryIds.contains(c.id))
            .map((c) => c.name)
            .join(', ');
        if (names.isNotEmpty && _categoryDisplayController.text.isEmpty) {
          _categoryDisplayController.text = names;
        }
      }
    });

    if (_selectedCategoryIds.isNotEmpty) {
      _loadSkillsForCategory();
    }
  }

  Future<void> _loadSkillsForCategory() async {
    if (_selectedCategoryIds.isEmpty) return;

    final selectedCategoriesSorted = List<String>.from(_selectedCategoryIds)
      ..sort();
    final cacheKey = selectedCategoriesSorted.join('_');
    if (_skillsByCategoryId.containsKey(cacheKey) &&
        (_skillsByCategoryId[cacheKey] ?? []).isNotEmpty) {
      setState(() {
        _visibleSkills = _skillsByCategoryId[cacheKey] ?? [];
      });
      _updateSkillsDisplayText();
      return;
    }

    setState(() {
      _loadingSkills = true;
    });

    final repo = sl<MasterDataRepository>();
    const pageSize = 100;
    final allSkills = <SkillOption>[];
    final seenNames = <String>{};

    for (final categoryId in _selectedCategoryIds) {
      final skillsForCat = await _fetchSkillsForSingleCategory(
        repo,
        categoryId,
        pageSize,
      );
      if (!mounted) return;
      for (final skill in skillsForCat) {
        if (seenNames.add(skill.name)) {
          allSkills.add(skill);
        }
      }
    }

    allSkills.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    for (final skill in allSkills) {
      for (final sIdOrName in List<String>.from(_selectedSkillIds)) {
        if (sIdOrName.trim().toLowerCase() == skill.name.trim().toLowerCase() ||
            sIdOrName == skill.id) {
          _selectedSkillIds.remove(sIdOrName);
          _selectedSkillIds.add(skill.id);
        }
      }
    }

    setState(() {
      _skillsByCategoryId[cacheKey] = allSkills;
      _visibleSkills = allSkills;

      _skillsMap.clear();
      for (final skill in allSkills) {
        _skillsMap[skill.name] = skill;
      }

      _availableSkillNames = allSkills.map((s) => s.name).toList();
      if (!_availableSkillNames.contains('Other')) {
        _availableSkillNames.add('Other');
      }

      _loadingSkills = false;
    });
    _updateSkillsDisplayText();
  }

  Future<List<SkillOption>> _fetchSkillsForSingleCategory(
    MasterDataRepository repo,
    String? categoryId,
    int pageSize,
  ) async {
    final list = <SkillOption>[];
    var page = 1;
    var total = 0;
    while (true) {
      final result = await repo.getSkills(
        categoryId: categoryId ?? '',
        page: page,
        pageSize: pageSize,
      );
      if (!mounted) break;

      final batch = result.valueOrNull ?? [];
      if (batch.isEmpty) break;

      list.addAll(batch.where((skill) => skill.name.isNotEmpty));

      if (page == 1) {
        final totalResult = await repo.getSkillsTotal(
          categoryId: categoryId ?? '',
        );
        total = totalResult.valueOrNull ?? batch.length;
      }

      if (list.length >= total || batch.length < pageSize) break;
      page++;
    }
    return list;
  }

  MasterOption? _matchOption(MasterOption? current, List<MasterOption> list) {
    if (current == null) return null;
    if (list.isEmpty) return current;
    for (final item in list) {
      if (item == current) return item;
      if (current.id.isNotEmpty && item.id == current.id) return item;
      if (current.name.isNotEmpty &&
          item.name.trim().toLowerCase() == current.name.trim().toLowerCase()) {
        return item;
      }
    }
    return current;
  }

  void _matchAllDropdowns() {
    if (!mounted) return;
    setState(() {
      if (_countries.isNotEmpty) {
        _selectedCountry = _matchOption(_selectedCountry, _countries);
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

        final phoneVal =
            userMap['phone']?.toString() ??
            userMap['mobile']?.toString() ??
            userMap['phoneNumber']?.toString() ??
            (userMap['profile'] is Map
                ? userMap['profile']['phone']?.toString()
                : null);
        if (phoneVal != null && phoneVal.isNotEmpty) _phone.text = phoneVal;

        final fn =
            userMap['fullName']?.toString() ?? userMap['full_name']?.toString();
        if (fn != null && fn.isNotEmpty) _fullName.text = fn.toTitleCase();

        final bioVal = userMap['bio']?.toString();
        if (bioVal != null && bioVal.isNotEmpty)
          _bio.text = bioVal.toTitleCase();

        final locVal =
            userMap['city']?.toString() ?? userMap['location']?.toString();
        if (locVal != null && locVal.isNotEmpty)
          _city.text = locVal.toTitleCase();

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

        if (userMap['profile'] is Map) {
          final pMap = Map<String, dynamic>.from(userMap['profile'] as Map);

          final headlineVal =
              (pMap['titleHeadline'] ?? pMap['headline'] ?? pMap['title'])
                  ?.toString();
          if (headlineVal != null && headlineVal.isNotEmpty) {
            _title.text = headlineVal.toTitleCase();
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

          final expObj =
              pMap['ExperienceLevel'] ??
              pMap['experienceLevel'] ??
              pMap['experienceLevelId'] ??
              pMap['experience'];
          if (expObj is Map) {
            final expMap = Map<String, dynamic>.from(expObj);
            final eid =
                (expMap['experienceLevelId'] ?? expMap['id'] ?? expMap['_id'])
                    ?.toString() ??
                '';
            final ename =
                (expMap['experienceLevelName'] ??
                        expMap['name'] ??
                        expMap['label'])
                    ?.toString() ??
                eid;
            if (eid.isNotEmpty && ename.isNotEmpty) {
              _selectedExperience = MasterOption(id: eid, name: ename);
            }
          } else if (expObj is String && expObj.isNotEmpty) {
            _selectedExperience = MasterOption(id: expObj, name: expObj);
          }

          final eduObj = pMap['education'];
          if (eduObj is String && eduObj.isNotEmpty) {
            _educationLevel = eduObj;
          }

          final availObj =
              pMap['Availability'] ??
              pMap['availability'] ??
              pMap['availabilityId'];
          if (availObj is Map) {
            final availMap = Map<String, dynamic>.from(availObj);
            final aid =
                (availMap['availabilityId'] ??
                        availMap['id'] ??
                        availMap['_id'])
                    ?.toString() ??
                '';
            final aname =
                (availMap['availabilityName'] ??
                        availMap['name'] ??
                        availMap['label'])
                    ?.toString() ??
                aid;
            if (aid.isNotEmpty && aname.isNotEmpty) {
              _selectedAvailability = MasterOption(id: aid, name: aname);
            }
          } else if (availObj is String && availObj.isNotEmpty) {
            _selectedAvailability = MasterOption(id: availObj, name: availObj);
          }

          void addCategoryMatch(String? rawId, String? rawName) {
            final rId = (rawId ?? '').trim();
            final rName = (rawName ?? '').trim();
            if (rId.isEmpty && rName.isEmpty) return;

            if (_categories.isNotEmpty) {
              for (final c in _categories) {
                final cId = c.id;
                final cName = c.name.trim();

                if (rId.isNotEmpty && cId == rId) {
                  _selectedCategoryIds.add(cId);
                  return;
                }
                if (rName.isNotEmpty &&
                    cName.toLowerCase() == rName.toLowerCase()) {
                  _selectedCategoryIds.add(cId);
                  return;
                }
                if (rId.isNotEmpty &&
                    cName.toLowerCase() == rId.toLowerCase()) {
                  _selectedCategoryIds.add(cId);
                  return;
                }
                if (rName.isNotEmpty &&
                    (cName.toLowerCase().contains(rName.toLowerCase()) ||
                        rName.toLowerCase().contains(cName.toLowerCase()))) {
                  _selectedCategoryIds.add(cId);
                  return;
                }
                if (rId.isNotEmpty &&
                    (cName.toLowerCase().contains(rId.toLowerCase()) ||
                        rId.toLowerCase().contains(cName.toLowerCase()))) {
                  _selectedCategoryIds.add(cId);
                  return;
                }
              }
            }
            if (rId.isNotEmpty) _selectedCategoryIds.add(rId);
          }

          _addCategoryMatch(String? rId, String? rName) =>
              addCategoryMatch(rId, rName);

          final indObj =
              pMap['industryId'] ?? pMap['categoryId'] ?? pMap['industry'];
          if (indObj is List) {
            for (final item in indObj) {
              if (item is Map) {
                final id = (item['id'] ?? item['_id'])?.toString();
                final name = (item['name'] ?? item['label'] ?? item['title'])
                    ?.toString();
                _addCategoryMatch(id, name);
              } else if (item is String) {
                _addCategoryMatch(item, item);
              }
            }
          } else if (indObj is Map) {
            final indId = (indObj['id'] ?? indObj['_id'])?.toString();
            final indName = (indObj['name'] ?? indObj['label'])?.toString();
            _addCategoryMatch(indId, indName);
          } else if (indObj is String && indObj.isNotEmpty) {
            for (final s in indObj.split(',')) {
              _addCategoryMatch(s.trim(), s.trim());
            }
          }

          if (_selectedCategoryIds.isNotEmpty && _categories.isNotEmpty) {
            _categoryDisplayController.text = _categories
                .where((c) => _selectedCategoryIds.contains(c.id))
                .map((c) => c.name)
                .join(', ');
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
                prefilledNames.add(s);
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
    if (_selectedCategoryIds.isNotEmpty) {
      await _loadSkillsForCategory();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      context.showSnack('Industry / Domain is required', isError: true);
      return;
    }

    if (_bio.text.trim().isNotEmpty && _bio.text.trim().length < 30) {
      context.showSnack('Biography / Overview must be at least 30 characters', isError: true);
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'fullName': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'mobile': _phone.text.trim(),
      'titleHeadline': _title.text.trim(),
      'bio': _bio.text.trim(),
      'city': _city.text.trim(),
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      // if (_selectedState != null) ...{
      //   'stateId': _selectedState!.id,
      //   'stateid': _selectedState!.id,
      // },
      if (_selectedExperience != null) ...{
        'experienceLevelId': _selectedExperience!.id,
        'experienceId': _selectedExperience!.id,
      },
      if (_educationLevel != null) 'education': _educationLevel,
      if (_selectedAvailability != null)
        'availabilityId': _selectedAvailability!.id,
      if (_selectedCategoryIds.isNotEmpty) ...{
        'industryId': _selectedCategoryIds.join(','),
        'categoryId': _selectedCategoryIds.join(','),
      },
      if (_hourlyRate.text.trim().isNotEmpty)
        'hourlyRate':
            double.tryParse(_hourlyRate.text.trim()) ?? _hourlyRate.text.trim(),
      if (_selectedSkillIds.isNotEmpty) ...{
        'skillIds': _selectedSkillIds.toList().join(','),
        'skills': _selectedSkillIds.toList(),
      },
      if (_otherSkillController.text.trim().isNotEmpty)
        'otherSkill': _otherSkillController.text.trim(),
      'portfolioUrl': _portfolio.text.trim(),
      'githubUrl': _github.text.trim(),
      'linkedInUrl': _linkedin.text.trim(),
      if (_currentAvatarUrl != null) 'avatarUrl': _currentAvatarUrl,
    };

    final res = await sl<ApiClientHelper>().putEnvelope<Map<String, dynamic>>(
      ApiEndpoints.updateMe,
      body: payload,
      parser: (envelope) {
        int? newCompletion;
        final rawData = envelope.data;
        if (rawData is Map) {
          final p =
              rawData['profileCompletion'] ??
              rawData['profile_completion'] ??
              rawData['completionPercentage'] ??
              rawData['completion_percentage'];
          if (p is num)
            newCompletion = p.toInt();
          else if (p is String)
            newCompletion = int.tryParse(p);

          if (newCompletion == null && rawData['user'] is Map) {
            final u = rawData['user'];
            final p2 =
                u['profileCompletion'] ??
                u['profile_completion'] ??
                u['completionPercentage'] ??
                u['completion_percentage'];
            if (p2 is num)
              newCompletion = p2.toInt();
            else if (p2 is String)
              newCompletion = int.tryParse(p2);
          }
        }
        return {
          'message': envelope.message ?? 'Profile updated successfully',
          'profileCompletion': newCompletion,
        };
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    res.fold((f) => context.showSnack(f.message, isError: true), (data) async {
      final msg =
          data['message']?.toString() ?? 'Profile updated successfully!';
      context.showSnack(msg);
      // Patch the cached user locally — no extra /me round-trip needed.
      final current = context.read<AuthBloc>().state.user;
      final newCompletion = data['profileCompletion'] as int?;

      if (current != null) {
        final city = _city.text.trim();
        final country = _selectedCountry?.name ?? '';
        final locationParts = [
          city,
          country,
        ].where((s) => s.isNotEmpty).toList();
        context.read<AuthBloc>().add(
          AuthUserUpdated(
            current.copyWith(
              fullName: _fullName.text.trim().isNotEmpty
                  ? _fullName.text.trim()
                  : null,
              phone: _phone.text.trim().isNotEmpty ? _phone.text.trim() : null,
              headline: _bio.text.trim().isNotEmpty ? _bio.text.trim() : null,
              location: locationParts.isNotEmpty
                  ? locationParts.join(', ')
                  : null,
              categoryId: _selectedCategoryIds.isNotEmpty
                  ? _selectedCategoryIds.join(',')
                  : null,
              industryId: _selectedCategoryIds.isNotEmpty
                  ? _selectedCategoryIds.join(',')
                  : null,
              skillIds: _selectedSkillIds.isNotEmpty
                  ? _selectedSkillIds.toList()
                  : null,
              avatarUrl: _currentAvatarUrl?.isNotEmpty == true
                  ? _currentAvatarUrl
                  : null,
              profileCompletion: newCompletion ?? current.profileCompletion,
            ),
          ),
        );
      }
      // Stay on page and refresh data
      await _load();

      if (!mounted) return;

      int missingDocs = 1;
      try {
        missingDocs = context.read<DashboardCubit>().state.verificationMissingCount;
      } catch (_) {}

      if (newCompletion == 100 && missingDocs > 0) {
        ProfileSaveSuccessDialog.show(context);
      } else if (newCompletion == null) {
        // Fallback if API didn't return completion percentage
        final updatedUser = context.read<AuthBloc>().state.user;
        if (updatedUser?.profileCompletion == 100 && missingDocs > 0) {
          ProfileSaveSuccessDialog.show(context);
        }
      }
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
    res.fold((failure) => context.showSnack(failure.message, isError: true), (
      url,
    ) {
      if (url.trim().isEmpty) {
        context.showSnack(
          'Photo uploaded, but the server did not return its URL.',
          isError: true,
        );
        return;
      }
      setState(() {
        _localAvatarPath = null;
        _currentAvatarUrl = url;
      });
      // Patch only the avatar in the cached user.
      final current = context.read<AuthBloc>().state.user;
      if (current != null) {
        context.read<AuthBloc>().add(
          AuthUserUpdated(current.copyWith(avatarUrl: url)),
        );
      }
      context.showSnack('Avatar updated successfully!');
      _load();
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
      _selectedSkillIds.clear();
      _skillsDisplayController.clear();
    });
    _updateCategoryDisplayText();
    _loadSkillsForCategory();
  }

  void _updateCategoryDisplayText() {
    final selectedNames = _categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    if (selectedNames.isNotEmpty) {
      _categoryDisplayController.text = selectedNames.join(', ');
    } else {
      _categoryDisplayController.clear();
    }
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

    if (_otherSkillController.text.trim().isNotEmpty &&
        !selectedNames.contains('Other')) {
      selectedNames.add('Other');
    }

    if (selectedNames.isNotEmpty) {
      _skillsDisplayController.text = selectedNames.join(', ');
      _selectedSkillNames = selectedNames;
    } else if (_selectedSkillIds.isEmpty) {
      _skillsDisplayController.clear();
      _selectedSkillNames = [];
    }
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
            final filtered =
                (search.isEmpty
                      ? List<SkillCategory>.from(_categories)
                      : _categories
                            .where((c) => c.name.toLowerCase().contains(search))
                            .toList())
                  ..sort((a, b) {
                    final aSel = _selectedCategoryIds.contains(a.id);
                    final bSel = _selectedCategoryIds.contains(b.id);
                    if (aSel && !bSel) return -1;
                    if (!aSel && bSel) return 1;
                    return 0;
                  });

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Industry / Domain (${_selectedCategoryIds.length})',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
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
                                  final isSelected = _selectedCategoryIds
                                      .contains(cat.id);
                                  return CheckboxListTile(
                                    title: Text(cat.name),
                                    value: isSelected,
                                    onChanged: (val) {
                                      _toggleCategory(cat.id);
                                      setSheetState(() {});
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

  // ─── UI Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final percent =
            context.read<AuthBloc>().state.user?.profileCompletion ?? 0;
        if (percent < 100) {
          final shouldLeave = await ProfileCompletionWarningDialog.show(
            context,
          );
          if (shouldLeave == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
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
                      ProfileCompletionCard(
                        percent:
                            context
                                .watch<AuthBloc>()
                                .state
                                .user
                                ?.profileCompletion ??
                            0,
                      ),
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
                        hint: 'Enter Your Email',
                        readOnly: true,
                      ),
                      AppSizes.vGapMd,
                      AppTextField(
                        controller: _phone,
                        label: 'Phone Number (optional)',
                        hint: 'Enter 10-digit Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) => Validators.phone(v),
                      ),
                      AppSizes.vGapMd,
                      AppTextField(
                        controller: _fullName,
                        label: 'Full Name *',
                        hint: 'Enter Your Full Name',
                        validator: (v) => Validators.minLength(
                          v,
                          2,
                          field: 'Enter Your Full Name',
                        ),
                      ),
                      AppSizes.vGapMd,
                      AppTextField(
                        controller: _title,
                        label: 'Professional Title *',
                        hint: 'e.g., Full-Stack Developer | UI/UX Designer',
                      ),
                      AppSizes.vGapLg,

                      // Location
                      const _SectionLabel('Location'),
                      AppSizes.vGapMd,
                      AppDropdown<MasterOption>(
                        label: 'Country *',
                        hint: 'Choose the country you’re based in',
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
                      AppSizes.vGapSm,
                      AppLocationField(
                        controller: _city,
                        country: _selectedCountry?.name,
                        label: 'City *',
                        hint: 'Search and select your city ',
                      ),

                      AppSizes.vGapMd,
                      // AppDropdown<MasterOption>(
                      //   label: 'State *',
                      //   hint: 'Select State',
                      //   prefixIcon: Icons.map_outlined,
                      //   value: _selectedState,
                      //   items: _states,
                      //   itemLabel: (item) => item.name,
                      //   validator: (v) =>
                      //       Validators.required(v?.name, field: 'State'),
                      //   onChanged: (opt) => setState(() => _selectedState = opt),
                      // ),
                      // AppSizes.vGapLg,

                      // Professional Bio

                      // Work Preferences
                      const _SectionLabel('Work Preferences'),
                      AppSizes.vGapSm,
                      AppTextField(
                        controller: _hourlyRate,
                        label: 'Hourly Rate (₹/hr) *',
                        hint: 'Set your preferred hourly rate',
                        prefixIcon: Icons.currency_rupee_sharp,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      AppSizes.vGapMd,
                      AppDropdown<MasterOption>(
                        label: 'Availability *',
                        hint: 'Select when you’re available',
                        value: _selectedAvailability,
                        items: _availabilities,
                        itemLabel: (item) => item.name,

                        onChanged: (opt) =>
                            setState(() => _selectedAvailability = opt),
                      ),
                      AppSizes.vGapMd,
                      AppDropdown<MasterOption>(
                        label: 'Total Experience *',
                        hint: 'Highlight your professional journey...',
                        value: _selectedExperience,
                        items: _experienceLevels,
                        itemLabel: (item) => item.name,

                        onChanged: (opt) =>
                            setState(() => _selectedExperience = opt),
                      ),
                      AppSizes.vGapMd,
                      // AppDropdown<String>(
                      //   label: 'Education Level *',
                      //   hint: 'Select Education Level',
                      //   value: _educationLevel,
                      //   items: _educationLevels,
                      //   itemLabel: (item) => item,

                      //   onChanged: (val) => setState(() => _educationLevel = val),
                      // ),
                      // AppSizes.vGapLg,

                      // Industry & Skills
                      const _SectionLabel('Industry & Skills'),
                      AppSizes.vGapSm,
                      AppTextField(
                        controller: _categoryDisplayController,
                        label: 'Primary Industry / Domain *',
                        hint: 'Choose the industry that matches your skills',
                        readOnly: true,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                        onTap: _showCategoryBottomSheet,
                      ),
                      AppSizes.vGapMd,
                      SignupMultiSelectSheet(
                        hint: _selectedCategoryIds.isEmpty
                            ? 'Select industry first'
                            : 'Select skills e.g., Flutter, UI/UX.....',
                        label: 'Skills',
                        selectedItems: _selectedSkillNames,
                        availableOptions: _availableSkillNames,
                        minSelection: 0,
                        onSearchApi: (query) async {
                          if (query.isEmpty) return _availableSkillNames;
                          final q = query.toLowerCase();
                          return _availableSkillNames
                              .where((s) => s.toLowerCase().contains(q))
                              .toList();
                        },
                        onChanged: (items) {
                          setState(() {
                            _selectedSkillNames = items;
                            _selectedSkillIds.clear();
                            for (final name in items) {
                              if (name == 'Other') continue;
                              final option = _skillsMap[name];
                              if (option != null) {
                                _selectedSkillIds.add(option.id);
                              } else {
                                _selectedSkillIds.add(
                                  'static_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}',
                                );
                              }
                            }
                          });
                        },
                        onTap: () {
                          if (_selectedCategoryIds.isEmpty) {
                            context.showSnack(
                              'Please select an Industry / Domain first',
                              isError: true,
                            );
                          } else {
                            final selectedCategoriesSorted = List<String>.from(
                              _selectedCategoryIds,
                            )..sort();
                            final cacheKey = selectedCategoriesSorted.join('_');
                            if (!_skillsByCategoryId.containsKey(cacheKey) ||
                                _skillsByCategoryId[cacheKey]!.isEmpty) {
                              _loadSkillsForCategory();
                            }
                          }
                        },
                      ),
                      if (_selectedSkillNames.contains('Other')) ...[
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _otherSkillController,
                          label: 'Other Skill *',
                          hint: 'Enter your area of expertise ',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your skill';
                            }
                            return null;
                          },
                        ),
                      ],
                      AppSizes.vGapLg,

                      // Social Links
                      // const _SectionLabel('Social & Links'),
                      // AppSizes.vGapSm,
                      // AppTextField(
                      //   controller: _portfolio,
                      //   label: 'Portfolio URL',
                      //   hint: 'Enter Portfolio URL',
                      //   validator: Validators.url,
                      // ),
                      // AppSizes.vGapMd,
                      // AppTextField(
                      //   controller: _github,
                      //   label: 'GitHub URL',
                      //   hint: 'Enter GitHub URL',
                      //   validator: Validators.url,
                      // ),
                      // AppSizes.vGapMd,
                      // AppTextField(
                      //   controller: _linkedin,
                      //   label: 'LinkedIn Profile',
                      //   hint: 'Enter LinkedIn Profile',
                      //   validator: Validators.url,
                      // ),
                      // AppSizes.vGapXl,

                      // Save Button
                      const _SectionLabel('Professional Bio'),
                      AppSizes.vGapSm,
                      AppTextField(
                        controller: _bio,
                        label: 'Brief Bio / Summary *',
                        hint:
                            'Turn your experience into your next opportunity...',
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),
                      AppSizes.vGapLg,
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
