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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/profile_save_success_dialog.dart';
import '../../../../core/widgets/profile_completion_warning_dialog.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../core/widgets/profile_completion_card.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/ticket_size_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';

class InvestorProfilePage extends StatefulWidget {
  const InvestorProfilePage({super.key});

  @override
  State<InvestorProfilePage> createState() => _InvestorProfilePageState();
}

class _InvestorProfilePageState extends State<InvestorProfilePage> {
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _firm = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _ticketMin = TextEditingController();
  final _ticketMax = TextEditingController();
  final _focusAreasDisplayController = TextEditingController();
  final _categorySearch = TextEditingController();

  MasterOption? _selectedCountry;
  MasterOption? _selectedState;
  MasterOption? _selectedInvestorType;
  MasterOption? _selectedPreferredStage;
  TicketSizeOption? _selectedTicketSize;
  num? _rawTicketMin;
  num? _rawTicketMax;
  final Set<String> _selectedFocusAreaIds = {};
  final Map<String, String> _focusAreaNameMap = {};

  List<MasterOption> _countries = [];
  List<MasterOption> _states = [];
  List<MasterOption> _investorTypes = [];
  List<MasterOption> _investorStages = [];
  List<TicketSizeOption> _ticketSizes = [];
  List<MasterOption> _focusAreaOptions = [];
  final List<String> _prefilledFocusAreaNames = [];
  List<SkillCategory> _categories = [];

  String? _avatarUrl;
  String? _localAvatarPath;
  bool _loading = true;
  bool _saving = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _firm.dispose();
    _city.dispose();
    _bio.dispose();
    _ticketMin.dispose();
    _ticketMax.dispose();
    _focusAreasDisplayController.dispose();
    _categorySearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final masterRepo = sl<MasterDataRepository>();

    final cRes = await masterRepo.getCountriesOptions();
    if (mounted && cRes.isSuccess) _countries = cRes.valueOrNull ?? [];

    final itRes = await masterRepo.getInvestorTypeOptions();
    if (mounted && itRes.isSuccess) _investorTypes = itRes.valueOrNull ?? [];

    final stRes = await masterRepo.getInvestorStageOptions();
    if (mounted && stRes.isSuccess) _investorStages = stRes.valueOrNull ?? [];

    final catRes = await masterRepo.getSkillCategories();
    if (mounted && catRes.isSuccess) _categories = catRes.valueOrNull ?? [];

    final tsRes = await masterRepo.getTicketSizeOptions();
    if (mounted && tsRes.isSuccess) _ticketSizes = tsRes.valueOrNull ?? [];

    final indRes = await masterRepo.getIndustryOptions();
    if (mounted && indRes.isSuccess) {
      _focusAreaOptions = indRes.valueOrNull ?? [];
    }

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
      int? completion;
      final rawComp = userMap['profileCompletion'] ??
          userMap['profile_completion'] ??
          userMap['completionPercentage'] ??
          userMap['completion_percentage'];
      if (rawComp is num) {
        completion = rawComp.toInt();
      } else if (rawComp is String) {
        completion = int.tryParse(rawComp);
      }

      final current = context.read<AuthBloc>().state.user;
      if (current != null && completion != null) {
        context.read<AuthBloc>().add(
          AuthUserUpdated(current.copyWith(profileCompletion: completion)),
        );
      }

      _verified =
          userMap['isVerified'] as bool? ??
          userMap['verified'] as bool? ??
          false;
      _avatarUrl = userMap['avatarUrl']?.toString();

      final emailVal = userMap['email']?.toString();
      if (emailVal != null && emailVal.isNotEmpty) _email.text = emailVal;

      final fn =
          userMap['fullName']?.toString() ?? userMap['full_name']?.toString();
      if (fn != null && fn.isNotEmpty) _fullName.text = fn.toTitleCase();

      final bioVal = userMap['bio']?.toString();
      if (bioVal != null && bioVal.isNotEmpty) _bio.text = bioVal.toTitleCase();

      final locVal =
          userMap['city']?.toString() ?? userMap['location']?.toString();
      if (locVal != null && locVal.isNotEmpty) _city.text = locVal.toTitleCase();

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

      // if (userMap['state'] is Map) {
      //   final sMap = Map<String, dynamic>.from(userMap['state'] as Map);
      //   final sid =
      //       (sMap['id'] ?? sMap['code'] ?? sMap['_id'])?.toString() ?? '';
      //   final sname = (sMap['name'] ?? sMap['label'])?.toString() ?? sid;
      //   if (sid.isNotEmpty && sname.isNotEmpty) {
      //     _selectedState = MasterOption(id: sid, name: sname);
      //   }
      // }

      if (userMap['profile'] is Map) {
        final pMap = Map<String, dynamic>.from(userMap['profile'] as Map);

        final firmVal = (pMap['firm'] ?? pMap['company'])?.toString();
        if (firmVal != null && firmVal.isNotEmpty) {
          _firm.text = firmVal.toTitleCase();
        }

        final tMin = pMap['ticketMin'] ?? pMap['minTicket'];
        if (tMin != null) {
          _ticketMin.text = tMin.toString();
          _rawTicketMin = num.tryParse(tMin.toString());
        }

        final tMax = pMap['ticketMax'] ?? pMap['maxTicket'];
        if (tMax != null) {
          _ticketMax.text = tMax.toString();
          _rawTicketMax = num.tryParse(tMax.toString());
        }

        if (pMap['investorTypeId'] is Map) {
          final itMap = Map<String, dynamic>.from(
            pMap['investorTypeId'] as Map,
          );
          final itId = (itMap['id'] ?? itMap['_id'])?.toString() ?? '';
          final itName = (itMap['name'] ?? itMap['label'])?.toString() ?? itId;
          if (itId.isNotEmpty && itName.isNotEmpty) {
            _selectedInvestorType = MasterOption(id: itId, name: itName);
          }
        } else if (pMap['investorTypeId'] is String) {
          final itStr = pMap['investorTypeId'].toString();
          if (itStr.isNotEmpty) {
            _selectedInvestorType = MasterOption(id: itStr, name: itStr);
          }
        }

        if (pMap['preferredStageId'] is Map) {
          final psMap = Map<String, dynamic>.from(
            pMap['preferredStageId'] as Map,
          );
          final psId = (psMap['id'] ?? psMap['_id'])?.toString() ?? '';
          final psName = (psMap['name'] ?? psMap['label'])?.toString() ?? psId;
          if (psId.isNotEmpty && psName.isNotEmpty) {
            _selectedPreferredStage = MasterOption(id: psId, name: psName);
          }
        } else if (pMap['preferredStageId'] is String) {
          final psStr = pMap['preferredStageId'].toString();
          if (psStr.isNotEmpty) {
            _selectedPreferredStage = MasterOption(id: psStr, name: psStr);
          }
        }

        bool isFuzzyMatch(String str1, String str2) {
          final s1 = str1.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          final s2 = str2.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          if (s1.isEmpty || s2.isEmpty) return false;
          if (s1 == s2) return true;
          if (s1.contains(s2) || s2.contains(s1)) return true;

          final words1 = s1.split(' ').where((w) => w.length > 2).toSet();
          final words2 = s2.split(' ').where((w) => w.length > 2).toSet();
          if (words1.isEmpty || words2.isEmpty) return false;
          final common = words1.intersection(words2);
          if (common.length >= words1.length || common.length >= words2.length) return true;
          if (words1.length > 1 && words2.length > 1 && common.length >= 2) return true;
          return false;
        }

        void addFocusAreaMatch(String? rawId, String? rawName) {
          final rId = (rawId ?? '').trim();
          final rName = (rawName ?? '').trim();
          if (rId.isEmpty && rName.isEmpty) return;

          final options = _focusAreaOptions.isNotEmpty
              ? _focusAreaOptions
              : _categories
                    .map((c) => MasterOption(id: c.id, name: c.name))
                    .toList();

          if (options.isNotEmpty) {
            for (final c in options) {
              final cId = c.id;
              final cName = c.name.trim();

              if (rId.isNotEmpty && cId == rId) {
                _selectedFocusAreaIds.add(cId);
                return;
              }
              if (rName.isNotEmpty && isFuzzyMatch(cName, rName)) {
                _selectedFocusAreaIds.add(cId);
                return;
              }
              if (rId.isNotEmpty && isFuzzyMatch(cName, rId)) {
                _selectedFocusAreaIds.add(cId);
                return;
              }
            }
          }
          if (rId.isNotEmpty) {
            _selectedFocusAreaIds.add(rId);
            if (rName.isNotEmpty) _focusAreaNameMap[rId] = rName;
          }
        }

        if (pMap['focusAreasId'] is List) {
          final faList = pMap['focusAreasId'] as List;
          _selectedFocusAreaIds.clear();
          _focusAreaNameMap.clear();
          _prefilledFocusAreaNames.clear();
          for (final area in faList) {
            if (area is Map) {
              final fid = (area['id'] ?? area['_id'])?.toString();
              final fname = (area['name'] ?? area['label'])?.toString();
              addFocusAreaMatch(fid, fname);
            } else if (area is String && area.isNotEmpty) {
              addFocusAreaMatch(area, area);
            }
          }
        }
      }
    }

    _matchAllDropdowns();
    _updateFocusAreasDisplayText();
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
      if (_investorTypes.isNotEmpty) {
        _selectedInvestorType = _matchOption(
          _selectedInvestorType,
          _investorTypes,
        );
      }
      if (_investorStages.isNotEmpty) {
        _selectedPreferredStage = _matchOption(
          _selectedPreferredStage,
          _investorStages,
        );
      }
      if (_ticketSizes.isNotEmpty &&
          (_rawTicketMin != null || _rawTicketMax != null)) {
        for (final opt in _ticketSizes) {
          if (opt.min == _rawTicketMin && opt.max == _rawTicketMax) {
            _selectedTicketSize = opt;
            break;
          }
        }
        _selectedTicketSize ??= _ticketSizes.firstWhere(
          (opt) => opt.min == _rawTicketMin || opt.max == _rawTicketMax,
          orElse: () => _ticketSizes.first,
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

  void _showFocusAreasBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
            final options = _focusAreaOptions.isNotEmpty
                ? List<MasterOption>.from(_focusAreaOptions)
                : _categories
                      .map((c) => MasterOption(id: c.id, name: c.name))
                      .toList();

            for (final selId in _selectedFocusAreaIds) {
              if (!options.any((o) => o.id == selId)) {
                final displayName = _focusAreaNameMap[selId] ?? selId;
                options.add(MasterOption(id: selId, name: displayName));
              }
            }

            final filtered = (search.isEmpty
                ? List<MasterOption>.from(options)
                : options
                      .where((c) => c.name.toLowerCase().contains(search))
                      .toList())
              ..sort((a, b) {
                final aSel = _selectedFocusAreaIds.contains(a.id);
                final bSel = _selectedFocusAreaIds.contains(b.id);
                if (aSel && !bSel) return -1;
                if (!aSel && bSel) return 1;
                return 0;
              });

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      0,
                      AppSizes.md,
                      AppSizes.md,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Focus Areas (${_selectedFocusAreaIds.length})',
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _updateFocusAreasDisplayText();
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
                          controller: _categorySearch,
                          hint: 'Search focus areas...',
                          prefixIcon: Icons.search,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        AppSizes.vGapMd,
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(child: Text('No sectors found'))
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final cat = filtered[index];
                                    final isSelected = _selectedFocusAreaIds
                                        .contains(cat.id);
                                    return CheckboxListTile(
                                      title: Text(cat.name),
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (_) {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedFocusAreaIds.remove(cat.id);
                                          } else {
                                            _selectedFocusAreaIds.add(cat.id);
                                          }
                                        });
                                        setSheetState(() {});
                                        _updateFocusAreasDisplayText();
                                      },
                                    );
                                  },
                                ),
                        ),
                        AppSizes.vGapMd,
                        AppPrimaryButton(
                          label:
                              'Done (${_selectedFocusAreaIds.length} selected)',
                          onPressed: () {
                            _updateFocusAreasDisplayText();
                            Navigator.of(context).pop();
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
    );
  }

  void _updateFocusAreasDisplayText() {
    final names = <String>[];
    final options = _focusAreaOptions.isNotEmpty
        ? _focusAreaOptions
        : _categories.map((c) => MasterOption(id: c.id, name: c.name)).toList();
    for (final opt in options) {
      if (_selectedFocusAreaIds.contains(opt.id)) {
        names.add(opt.name);
      }
    }
    if (names.isEmpty && _prefilledFocusAreaNames.isNotEmpty) {
      names.addAll(_prefilledFocusAreaNames);
    }
    if (names.isNotEmpty) {
      _focusAreasDisplayController.text = names.join(', ');
    } else if (_selectedFocusAreaIds.isEmpty) {
      _focusAreasDisplayController.clear();
    }
  }

  Future<void> _save() async {
    final fullName = _fullName.text.trim();
    if (fullName.isEmpty) {
      context.showSnack('Full name is required', isError: true);
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'fullName': fullName,
      'city': _city.text.trim(),
      if (_bio.text.trim().isNotEmpty) 'bio': _bio.text.trim(),
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      // if (_selectedState != null) 'stateId': _selectedState!.id,
      'firm': _firm.text.trim(),
      if (_selectedInvestorType != null)
        'investorTypeId': _selectedInvestorType!.id,
      if (_selectedPreferredStage != null)
        'preferredStageId': _selectedPreferredStage!.id,
      if (_selectedFocusAreaIds.isNotEmpty)
        'focusAreasId': _selectedFocusAreaIds.toList(),
      if (_selectedTicketSize != null) ...{
        'ticketMin': _selectedTicketSize!.min,
        'ticketMax': _selectedTicketSize!.max,
      } else ...{
        if (_ticketMin.text.trim().isNotEmpty)
          'ticketMin':
              double.tryParse(_ticketMin.text.trim()) ?? _ticketMin.text.trim(),
        if (_ticketMax.text.trim().isNotEmpty)
          'ticketMax':
              double.tryParse(_ticketMax.text.trim()) ?? _ticketMax.text.trim(),
      },
      if (_avatarUrl != null && _avatarUrl!.startsWith('http')) ...{
        'avatarUrl': _avatarUrl,
        'logo': _avatarUrl,
      },
    };

    final res = await sl<ApiClientHelper>().putEnvelope<Map<String, dynamic>>(
      ApiEndpoints.updateMe,
      body: payload,
      parser: (env) {
        int? newCompletion;
        final rawData = env.data;
        if (rawData is Map) {
          final p = rawData['profileCompletion'] ??
              rawData['profile_completion'] ??
              rawData['completionPercentage'] ??
              rawData['completion_percentage'];
          if (p is num) newCompletion = p.toInt();
          else if (p is String) newCompletion = int.tryParse(p);

          if (newCompletion == null && rawData['user'] is Map) {
            final u = rawData['user'];
            final p2 = u['profileCompletion'] ?? u['profile_completion'] ?? u['completionPercentage'] ?? u['completion_percentage'];
            if (p2 is num) newCompletion = p2.toInt();
            else if (p2 is String) newCompletion = int.tryParse(p2);
          }
        }
        final map = env.data is Map ? Map<String, dynamic>.from(env.data as Map) : <String, dynamic>{};
        map['profileCompletion'] = newCompletion;
        return map;
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res.isSuccess) {
      final msg =
          res.valueOrNull?['message']?.toString() ??
          'Investor profile updated successfully';
      context.showSnack(msg);
      // Patch the cached user locally — no extra /me round-trip needed.
      final current = context.read<AuthBloc>().state.user;
      final newCompletion = res.valueOrNull?['profileCompletion'] as int?;
      
      if (current != null) {
        final city = _city.text.trim();
        final country = _selectedCountry?.name ?? '';
        final locationParts = [city, country]
            .where((s) => s.isNotEmpty)
            .toList();
        context.read<AuthBloc>().add(
          AuthUserUpdated(
            current.copyWith(
              fullName: fullName.isNotEmpty ? fullName : null,
              headline: _bio.text.trim().isNotEmpty ? _bio.text.trim() : null,
              location: locationParts.isNotEmpty
                  ? locationParts.join(', ')
                  : null,
              avatarUrl: (_avatarUrl?.isNotEmpty == true) ? _avatarUrl : null,
              profileCompletion: newCompletion ?? current.profileCompletion,
            ),
          ),
        );
      }
      // Stay on page and refresh data
      await _load();
      
      if (!mounted) return;
      
      if (newCompletion == 100) {
        ProfileSaveSuccessDialog.show(context);
      } else if (newCompletion == null) {
        final updatedUser = context.read<AuthBloc>().state.user;
        if (updatedUser?.profileCompletion == 100) {
          ProfileSaveSuccessDialog.show(context);
        }
      }
    } else {
      context.showSnack(
        res.failureOrNull?.message ?? 'Failed to update profile',
        isError: true,
      );
    }
  }

  Future<void> _uploadAvatar(String path) async {
    setState(() => _localAvatarPath = path);
    final result = await sl<FileUploadHelper>().uploadUrl(
      path: path,
      endpoint: ApiEndpoints.updateMeAvatar,
      method: 'put',
      fileField: 'file',
    );
    if (!mounted) return;
    result.fold(
      (failure) => context.showSnack(failure.message, isError: true),
      (url) {
        if (url.trim().isEmpty) {
          context.showSnack(
            'Photo uploaded, but the server did not return its URL.',
            isError: true,
          );
          return;
        }
        setState(() {
          _avatarUrl = url;
          _localAvatarPath = null;
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = context.watch<AuthBloc>().state.user?.profileCompletion == 100;

    return PopScope(
      canPop: isComplete,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await ProfileCompletionWarningDialog.show(context);
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
        appBar: AppBar(
          leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
          title: const Text('Investor Profile'),
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                // if (_verified)
                //   AppCard(
                //     child: Row(
                //       children: [
                //         const Icon(Icons.verified, color: Colors.green, size: 20),
                //         const SizedBox(width: 8),
                //         const Text('Verified investor'),
                //       ],
                //     ),
                //   ),
                if (_verified) AppSizes.vGapMd,
                ProfileCompletionCard(
                  percent: context.watch<AuthBloc>().state.user?.profileCompletion ?? 0,
                ),
                AppSizes.vGapXl,
                ProfileAvatarEditor(
                  localPath: _localAvatarPath,
                  networkUrl: _avatarUrl,
                  onPathPicked: _uploadAvatar,
                ),
                AppSizes.vGapXl,
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'Enter Email',
                  readOnly: true,
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _fullName,
                  label: 'Full Name *',
                  hint: 'Enter Full Name',
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _firm,
                  label: 'Firm / Entity Name',
                  hint: 'Enter Firm / Entity Name',
                ),
                AppSizes.vGapMd,
                AppDropdown<MasterOption>(
                  label: 'Investor Type *',
                  hint: 'Select Investor Type',
                  value: _selectedInvestorType,
                  items: _investorTypes,
                  itemLabel: (item) => item.name,
                  onChanged: (opt) =>
                      setState(() => _selectedInvestorType = opt),
                ),
                AppSizes.vGapMd,
                AppDropdown<MasterOption>(
                  label: 'Preferred Investment Stage *',
                  hint: 'Select Preferred Investment Stage',
                  value: _selectedPreferredStage,
                  items: _investorStages,
                  itemLabel: (item) => item.name,
                  onChanged: (opt) =>
                      setState(() => _selectedPreferredStage = opt),
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _focusAreasDisplayController,
                  label: _selectedFocusAreaIds.isEmpty
                      ? 'Focus Areas / Sectors'
                      : 'Focus Areas / Sectors (${_selectedFocusAreaIds.length})',
                  hint: 'Select Focus Industries / Sector',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onTap: _showFocusAreasBottomSheet,
                ),
                AppSizes.vGapMd,
                AppLocationField(
                  controller: _city,
                  label: 'Location / City *',
                  hint: 'Select Location / City',
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
                // AppSizes.vGapMd,
                // AppDropdown<MasterOption>(
                //   label: 'State *',
                //   hint: 'Select State',
                //   prefixIcon: Icons.map_outlined,
                //   value: _selectedState,
                //   items: _states,
                //   itemLabel: (item) => item.name,
                //   onChanged: (opt) => setState(() => _selectedState = opt),
                // ),
                // AppSizes.vGapMd,
                AppDropdown<TicketSizeOption>(
                  label: 'Ticket Size *',
                  hint: 'Select Ticket Size',
                  value: _selectedTicketSize,
                  items: _ticketSizes,
                  itemLabel: (item) => item.label,
                  onChanged: (opt) => setState(() => _selectedTicketSize = opt),
                ),
                AppSizes.vGapMd,
                AppTextField(
                  controller: _bio,
                  label: 'About / Bio',
                  hint: 'Enter About / Bio',
                  maxLines: 3,
                ),
                AppSizes.vGapXl,
                AppPrimaryButton(
                  label: 'Save Profile',
                  isLoading: _saving,
                  onPressed: _save,
                ),
                AppSizes.vGapXl,
              ],
            ),
      ),
    );
  }

}

class InvestorDocumentsLivePage extends StatefulWidget {
  const InvestorDocumentsLivePage({super.key});

  @override
  State<InvestorDocumentsLivePage> createState() =>
      _InvestorDocumentsLivePageState();
}

class _InvestorDocumentsLivePageState extends State<InvestorDocumentsLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _docs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.investorDocuments,
          parser: (e) {
            final list = e.data as List?;
            if (list == null) return const [];
            return list
                .whereType<Map>()
                .map((x) => Map<String, dynamic>.from(x))
                .toList();
          },
        );
    if (!mounted) return;
    _docs = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _upload() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = picked?.files.single.path;
    if (path == null) return;
    final direct = await sl<FileUploadHelper>().uploadUrl(
      path: path,
      endpoint: ApiEndpoints.investorDocumentsUpload,
    );
    if (!mounted) return;
    if (direct.isSuccess) {
      context.showSnack('Uploaded');
      await _load();
      return;
    }
    final fallback = await sl<FileUploadHelper>().uploadUrl(
      path: path,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'investor_document'},
    );
    if (!mounted) return;
    fallback.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Uploaded via files API'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [TextButton(onPressed: _upload, child: const Text('Upload'))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  if (_docs.isEmpty)
                    const AppCard(child: Text('No documents yet')),
                  for (final d in _docs)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Text(
                        d['name']?.toString() ??
                            d['title']?.toString() ??
                            'Document',
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class InvestorReportsLivePage extends StatefulWidget {
  const InvestorReportsLivePage({super.key});

  @override
  State<InvestorReportsLivePage> createState() =>
      _InvestorReportsLivePageState();
}

class _InvestorReportsLivePageState extends State<InvestorReportsLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _reports = const [];
  Map<String, dynamic> _portfolio = const {};
  Map<String, dynamic> _roi = const {};
  Map<String, dynamic> _analytics = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final r = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.investorReports,
      parser: (e) {
        final list = e.data as List?;
        if (list == null) return const [];
        return list
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
      },
    );
    final p = await api.get<Map<String, dynamic>>(
      ApiEndpoints.investorReportsPortfolio,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final roi = await api.get<Map<String, dynamic>>(
      ApiEndpoints.investorReportsRoi,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final analytics = await api.get<Map<String, dynamic>>(
      ApiEndpoints.investorAnalytics,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (!mounted) return;
    _reports = r.valueOrNull ?? const [];
    _portfolio = p.valueOrNull ?? const {};
    _roi = roi.valueOrNull ?? const {};
    _analytics = analytics.valueOrNull ?? const {};
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Investor Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  AppCard(
                    child: Text(
                      'Portfolio report: ${_portfolio['summary'] ?? '—'}',
                    ),
                  ),
                  AppSizes.vGapSm,
                  AppCard(child: Text('ROI report: ${_roi['summary'] ?? '—'}')),
                  AppSizes.vGapSm,
                  AppCard(
                    child: Text(
                      'Analytics summary: ${_analytics['summary'] ?? _analytics['portfolioValue'] ?? '—'}',
                    ),
                  ),
                  AppSizes.vGapSm,
                  for (final rep in _reports)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Text(rep['title']?.toString() ?? 'Report'),
                    ),
                ],
              ),
            ),
    );
  }
}

class InvestorAnalyticsLivePage extends StatefulWidget {
  const InvestorAnalyticsLivePage({super.key});

  @override
  State<InvestorAnalyticsLivePage> createState() =>
      _InvestorAnalyticsLivePageState();
}

class _InvestorAnalyticsLivePageState extends State<InvestorAnalyticsLivePage> {
  bool _loading = true;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().get<Map<String, dynamic>>(
      ApiEndpoints.investorAnalytics,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (!mounted) return;
    _data = res.valueOrNull ?? const {};
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Investor Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  _metric('Portfolio Value', _data['portfolioValue']),
                  _metric('Investments', _data['investments']),
                  _metric('Watchlist', _data['watchlist']),
                  _metric('Meetings', _data['meetings']),
                  _metric('Recommendations', _data['recommendations']),
                  _metric('Notifications', _data['notifications']),
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
