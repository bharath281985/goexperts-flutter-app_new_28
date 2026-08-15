import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';

class FounderPitchDeckLivePage extends StatefulWidget {
  const FounderPitchDeckLivePage({super.key});

  @override
  State<FounderPitchDeckLivePage> createState() =>
      _FounderPitchDeckLivePageState();
}

class FounderProfileLivePage extends StatefulWidget {
  const FounderProfileLivePage({super.key});

  @override
  State<FounderProfileLivePage> createState() => _FounderProfileLivePageState();
}

class _FounderProfileLivePageState extends State<FounderProfileLivePage> {
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _city = TextEditingController();
  final _startupName = TextEditingController();
  final _pitch = TextEditingController();
  final _targetRaise = TextEditingController();
  final _bio = TextEditingController();
  final _industrySearchController = TextEditingController();
  final _goalSearchController = TextEditingController();
  final _industryDisplayController = TextEditingController();
  final _primaryGoalDisplayController = TextEditingController();

  MasterOption? _selectedCountry;
  MasterOption? _selectedState;
  MasterOption? _selectedIndustry;
  final Set<String> _selectedFounderGoalIds = {};
  MasterOption? _selectedStage;
  MasterOption? _selectedRole;
  MasterOption? _selectedTeamSize;
  MasterOption? _selectedPrimaryGoal;

  List<MasterOption> _countries = [];
  List<MasterOption> _states = [];
  List<MasterOption> _industries = [];
  List<MasterOption> _stages = [];
  List<MasterOption> _roles = [];
  List<MasterOption> _teamSizes = [];
  List<MasterOption> _founderGoals = [];

  String? _avatarUrl;
  String? _localAvatarPath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _city.dispose();
    _startupName.dispose();
    _pitch.dispose();
    _targetRaise.dispose();
    _bio.dispose();
    _industrySearchController.dispose();
    _goalSearchController.dispose();
    _industryDisplayController.dispose();
    _primaryGoalDisplayController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final masterRepo = sl<MasterDataRepository>();
    final api = sl<ApiClientHelper>();

    final cRes = await masterRepo.getCountriesOptions();
    if (mounted && cRes.isSuccess) _countries = cRes.valueOrNull ?? [];

    final indRes = await masterRepo.getIndustryOptions();
    if (mounted && indRes.isSuccess) _industries = indRes.valueOrNull ?? [];

    final stgRes = await masterRepo.getStartupStageOptions();
    if (mounted && stgRes.isSuccess) _stages = stgRes.valueOrNull ?? [];

    final rolRes = await masterRepo.getStartupRoleOptions();
    if (mounted && rolRes.isSuccess) _roles = rolRes.valueOrNull ?? [];

    final tsRes = await masterRepo.getCompanySizeOptions();
    if (mounted && tsRes.isSuccess) _teamSizes = tsRes.valueOrNull ?? [];

    final fgRes = await masterRepo.getFounderGoalOptions();
    if (mounted && fgRes.isSuccess) _founderGoals = fgRes.valueOrNull ?? [];

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

    if (meRes.isSuccess) {
      final userMap = meRes.valueOrNull ?? {};
      _email.text = userMap['email']?.toString() ?? '';
      _fullName.text = userMap['fullName']?.toString() ?? '';
      _city.text =
          userMap['city']?.toString() ?? userMap['location']?.toString() ?? '';
      _bio.text = userMap['bio']?.toString() ?? '';
      _avatarUrl = userMap['avatarUrl']?.toString();

      if (userMap['country'] is Map) {
        final cMap = Map<String, dynamic>.from(userMap['country'] as Map);
        final cid = cMap['id']?.toString() ?? '';
        final cname = cMap['name']?.toString() ?? cid;
        if (cid.isNotEmpty) {
          _selectedCountry = MasterOption(id: cid, name: cname);
          _loadStatesForCountry(cid);
        }
      }

      if (userMap['state'] is Map) {
        final sMap = Map<String, dynamic>.from(userMap['state'] as Map);
        final sid = sMap['id']?.toString() ?? '';
        final sname = sMap['name']?.toString() ?? sid;
        if (sid.isNotEmpty) {
          _selectedState = MasterOption(id: sid, name: sname);
        }
      }

      if (userMap['profile'] is Map) {
        final pMap = Map<String, dynamic>.from(userMap['profile'] as Map);
        _startupName.text =
            pMap['startupName']?.toString() ?? pMap['startup']?.toString() ?? '';
        _pitch.text =
            pMap['pitch']?.toString() ?? pMap['oneLinePitch']?.toString() ?? '';
        _targetRaise.text = pMap['targetRaise']?.toString() ?? '';

        if (pMap['industryId'] is Map) {
          final indMap = Map<String, dynamic>.from(pMap['industryId'] as Map);
          final iId = (indMap['id'] ?? indMap['_id'])?.toString() ?? '';
          final iName = (indMap['name'] ?? indMap['label'])?.toString() ?? iId;
          if (iId.isNotEmpty) {
            _selectedIndustry = MasterOption(id: iId, name: iName);
            _industryDisplayController.text = iName;
          }
        } else if (pMap['industryId'] is String) {
          final iStr = pMap['industryId'].toString();
          if (iStr.isNotEmpty) {
            _selectedIndustry = MasterOption(id: iStr, name: iStr);
            _industryDisplayController.text = iStr;
          }
        }

        if (pMap['stageId'] is Map) {
          final stMap = Map<String, dynamic>.from(pMap['stageId'] as Map);
          final sId = (stMap['id'] ?? stMap['_id'])?.toString() ?? '';
          final sName = (stMap['name'] ?? stMap['label'])?.toString() ?? sId;
          if (sId.isNotEmpty) {
            _selectedStage = MasterOption(id: sId, name: sName);
          }
        } else if (pMap['stageId'] is String) {
          final sStr = pMap['stageId'].toString();
          if (sStr.isNotEmpty) {
            _selectedStage = MasterOption(id: sStr, name: sStr);
          }
        }

        if (pMap['founderRoleId'] is Map) {
          final frMap = Map<String, dynamic>.from(pMap['founderRoleId'] as Map);
          final frId = (frMap['id'] ?? frMap['_id'])?.toString() ?? '';
          final frName = (frMap['name'] ?? frMap['label'])?.toString() ?? frId;
          if (frId.isNotEmpty) {
            _selectedRole = MasterOption(id: frId, name: frName);
          }
        } else if (pMap['founderRoleId'] is String) {
          final frStr = pMap['founderRoleId'].toString();
          if (frStr.isNotEmpty) {
            _selectedRole = MasterOption(id: frStr, name: frStr);
          }
        }

        if (pMap['teamSizeId'] is Map) {
          final tsMap = Map<String, dynamic>.from(pMap['teamSizeId'] as Map);
          final tsId = (tsMap['id'] ?? tsMap['_id'])?.toString() ?? '';
          final tsName = (tsMap['name'] ?? tsMap['label'])?.toString() ?? tsId;
          if (tsId.isNotEmpty) {
            _selectedTeamSize = MasterOption(id: tsId, name: tsName);
          }
        } else if (pMap['teamSizeId'] != null) {
          final tsStr = pMap['teamSizeId'].toString();
          if (tsStr.isNotEmpty) {
            _selectedTeamSize = MasterOption(id: tsStr, name: tsStr);
          }
        }

        if (pMap['primaryGoalId'] is List) {
          final pgList = pMap['primaryGoalId'] as List;
          final names = <String>[];
          _selectedFounderGoalIds.clear();
          for (final goal in pgList) {
            if (goal is Map) {
              final gid = (goal['id'] ?? goal['_id'])?.toString();
              final gname = (goal['name'] ?? goal['label'])?.toString();
              if (gid != null && gid.isNotEmpty) _selectedFounderGoalIds.add(gid);
              if (gname != null && gname.isNotEmpty) names.add(gname);
            } else if (goal is String && goal.isNotEmpty) {
              _selectedFounderGoalIds.add(goal);
              names.add(goal);
            }
          }
          if (names.isNotEmpty) {
            _primaryGoalDisplayController.text = names.join(', ');
          }
        } else if (pMap['primaryGoalId'] is Map) {
          final pgMap = Map<String, dynamic>.from(pMap['primaryGoalId'] as Map);
          final pgId = (pgMap['id'] ?? pgMap['_id'])?.toString() ?? '';
          final pgName = (pgMap['name'] ?? pgMap['label'])?.toString() ?? pgId;
          if (pgId.isNotEmpty) {
            _selectedFounderGoalIds.add(pgId);
            _primaryGoalDisplayController.text = pgName;
          }
        } else if (pMap['primaryGoalId'] is String &&
            (pMap['primaryGoalId'] as String).isNotEmpty) {
          final pgStr = pMap['primaryGoalId'].toString();
          _selectedFounderGoalIds.add(pgStr);
          _primaryGoalDisplayController.text = pgStr;
        }
      }
    }

    _matchAllDropdowns();
    setState(() => _loading = false);
  }

  MasterOption? _matchOption(MasterOption? current, List<MasterOption> list) {
    if (current == null || list.isEmpty) return current;
    for (final opt in list) {
      if (opt.id == current.id) return opt;
      if (opt.name.toLowerCase() == current.name.toLowerCase()) return opt;
    }
    return current;
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
      if (_industries.isNotEmpty) {
        _selectedIndustry = _matchOption(_selectedIndustry, _industries);
      }
      if (_stages.isNotEmpty) {
        _selectedStage = _matchOption(_selectedStage, _stages);
      }
      if (_roles.isNotEmpty) {
        _selectedRole = _matchOption(_selectedRole, _roles);
      }
      if (_teamSizes.isNotEmpty) {
        _selectedTeamSize = _matchOption(_selectedTeamSize, _teamSizes);
      }
      if (_founderGoals.isNotEmpty) {
        _selectedPrimaryGoal =
            _matchOption(_selectedPrimaryGoal, _founderGoals);
      }
    });
  }

  void _updateFounderGoalsDisplayText() {
    final names = <String>[];
    for (final opt in _founderGoals) {
      if (_selectedFounderGoalIds.contains(opt.id)) {
        names.add(opt.name);
      }
    }
    if (names.isNotEmpty) {
      _primaryGoalDisplayController.text = names.join(', ');
    } else if (_selectedFounderGoalIds.isEmpty) {
      _primaryGoalDisplayController.clear();
    }
  }

  Future<void> _loadStatesForCountry(String countryIdOrCode) async {
    final res =
        await sl<MasterDataRepository>().getStatesOptions(countryIdOrCode);
    if (!mounted) return;
    _states = res.valueOrNull ?? [];
    _matchAllDropdowns();
  }

  void _showIndustryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _industrySearchController.text.trim().toLowerCase();
            final filtered = search.isEmpty
                ? _industries
                : _industries
                    .where((c) => c.name.toLowerCase().contains(search))
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
                      Text(
                        'Select Industry',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSizes.vGapSm,
                      AppTextField(
                        controller: _industrySearchController,
                        hint: 'Search industry...',
                        prefixIcon: Icons.search,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      AppSizes.vGapMd,
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No industries found'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected =
                                      _selectedIndustry?.id == item.id;
                                  return ListTile(
                                    title: Text(item.name),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle,
                                            color: AppColors.primary)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedIndustry = item;
                                        _industryDisplayController.text =
                                            item.name;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              ),
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

  void _showPrimaryGoalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _goalSearchController.text.trim().toLowerCase();
            final filtered = search.isEmpty
                ? _founderGoals
                : _founderGoals
                    .where((c) => c.name.toLowerCase().contains(search))
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
                            'Select Primary Goal (${_selectedFounderGoalIds.length})',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _updateFounderGoalsDisplayText();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Done',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      AppSizes.vGapSm,
                      AppTextField(
                        controller: _goalSearchController,
                        hint: 'Search primary goal...',
                        prefixIcon: Icons.search,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      AppSizes.vGapMd,
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No goals found'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected =
                                      _selectedFounderGoalIds.contains(item.id);
                                  return CheckboxListTile(
                                    title: Text(item.name),
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    onChanged: (_) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedFounderGoalIds.remove(item.id);
                                        } else {
                                          _selectedFounderGoalIds.add(item.id);
                                        }
                                      });
                                      setSheetState(() {});
                                      _updateFounderGoalsDisplayText();
                                    },
                                  );
                                },
                              ),
                      ),
                      AppSizes.vGapMd,
                      AppPrimaryButton(
                        label:
                            'Done (${_selectedFounderGoalIds.length} selected)',
                        onPressed: () {
                          _updateFounderGoalsDisplayText();
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

  Future<void> _save() async {
    final fullName = _fullName.text.trim();
    if (fullName.isEmpty) {
      context.showSnack('Name is required', isError: true);
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'fullName': fullName,
      'city': _city.text.trim(),
      if (_bio.text.trim().isNotEmpty) 'bio': _bio.text.trim(),
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      if (_selectedState != null) 'stateId': _selectedState!.id,
      'startupName': _startupName.text.trim(),
      if (_pitch.text.trim().isNotEmpty) 'pitch': _pitch.text.trim(),
      if (_selectedIndustry != null) 'industryId': _selectedIndustry!.id,
      if (_selectedStage != null) 'stageId': _selectedStage!.id,
      if (_selectedRole != null) 'founderRoleId': _selectedRole!.id,
      if (_selectedTeamSize != null) 'teamSizeId': _selectedTeamSize!.id,
      if (_selectedFounderGoalIds.isNotEmpty)
        'primaryGoalId': _selectedFounderGoalIds.toList(),
      if (_targetRaise.text.trim().isNotEmpty)
        'targetRaise': double.tryParse(_targetRaise.text.trim()) ??
            _targetRaise.text.trim(),
      if (_localAvatarPath != null || _avatarUrl != null)
        'logo': _localAvatarPath ?? _avatarUrl,
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
      final msg = res.valueOrNull?['message']?.toString() ??
          'Founder profile updated successfully';
      context.showSnack(msg);
      final currentUser = context.read<AuthBloc>().state.user;
      if (currentUser != null) {
        context.read<AuthBloc>().add(
              AuthUserUpdated(
                currentUser.copyWith(
                  fullName: fullName,
                  location: _city.text.trim(),
                ),
              ),
            );
      }
      Navigator.of(context).pop();
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
      endpoint: ApiEndpoints.updateMe,
      method: 'put',
      fileField: 'file',
    );
    if (!mounted) return;
    result.fold(
      (failure) => context.showSnack(failure.message, isError: true),
      (url) {
        setState(() {
          _avatarUrl = url;
          _localAvatarPath = null;
        });
        context.read<AuthBloc>().add(const AuthRefreshUser());
      },
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        appBar: AppBar(
          leading:
              IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
          title: const Text('Founder Profile'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  Center(
                    child: ProfileAvatarEditor(
                      localPath: _localAvatarPath,
                      networkUrl: _avatarUrl,
                      onPathPicked: _uploadAvatar,
                    ),
                  ),
                  AppSizes.vGapXl,
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'Email Address',
                          readOnly: true,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _fullName,
                          label: 'Name *',
                          hint: 'Enter your name',
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _startupName,
                          label: 'Startup / Company Name *',
                          hint: 'e.g. LogiTech AI',
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _industryDisplayController,
                          label: 'Industry *',
                          hint: 'Select Industry',
                          readOnly: true,
                          suffixIcon:
                              const Icon(Icons.keyboard_arrow_down_rounded),
                          onTap: _showIndustryBottomSheet,
                        ),
                        AppSizes.vGapMd,
                        AppDropdown<MasterOption>(
                          label: 'Current Stage *',
                          hint: 'Select Current Stage',
                          value: _selectedStage,
                          items: _stages,
                          itemLabel: (item) => item.name,
                          onChanged: (opt) =>
                              setState(() => _selectedStage = opt),
                        ),
                        AppSizes.vGapMd,
                        AppDropdown<MasterOption>(
                          label: 'Role in Startup *',
                          hint: 'Select Role in Startup',
                          value: _selectedRole,
                          items: _roles,
                          itemLabel: (item) => item.name,
                          onChanged: (opt) =>
                              setState(() => _selectedRole = opt),
                        ),
                        AppSizes.vGapMd,
                        AppDropdown<MasterOption>(
                          label: 'Team Size *',
                          hint: 'Select Team Size',
                          value: _selectedTeamSize,
                          items: _teamSizes,
                          itemLabel: (item) => item.name,
                          onChanged: (opt) =>
                              setState(() => _selectedTeamSize = opt),
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _primaryGoalDisplayController,
                          label: _selectedFounderGoalIds.isEmpty
                              ? 'Primary Goal on Platform'
                              : 'Primary Goal on Platform (${_selectedFounderGoalIds.length})',
                          hint: 'Select Primary Goal',
                          readOnly: true,
                          suffixIcon:
                              const Icon(Icons.keyboard_arrow_down_rounded),
                          onTap: _showPrimaryGoalBottomSheet,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _targetRaise,
                          label: 'Target Raise (\$)',
                          hint: 'e.g. 750000',
                          keyboardType: TextInputType.number,
                        ),
                        AppSizes.vGapMd,
                        AppLocationField(
                          controller: _city,
                          label: 'City / Location *',
                          hint: 'Select location',
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
                        if (_selectedCountry != null) ...[
                          AppSizes.vGapMd,
                          AppDropdown<MasterOption>(
                            label: 'State *',
                            hint: 'Select State',
                            value: _selectedState,
                            items: _states,
                            itemLabel: (item) => item.name,
                            onChanged: (opt) =>
                                setState(() => _selectedState = opt),
                          ),
                        ],
                  ],
                ),
              ),
              AppSizes.vGapLg,
              _buildSectionTitle('Founder Bio'),
              AppCard(
                child: AppTextField(
                  controller: _bio,
                  label: 'Bio',
                  hint: 'Tell people about your background and vision',
                  maxLines: 4,
                ),
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
  );

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class FounderFundingLivePage extends StatefulWidget {
  const FounderFundingLivePage({super.key});
  @override
  State<FounderFundingLivePage> createState() => _FounderFundingLivePageState();
}

class _FounderFundingLivePageState extends State<FounderFundingLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rounds = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.founderFunding,
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
    _rounds = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _createRound() async {
    final res = await sl<ApiClientHelper>().post<Map<String, dynamic>>(
      ApiEndpoints.founderFunding,
      body: {'title': 'New Round', 'targetAmount': 0},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
      allowNullData: false,
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Funding round created'),
    );
    await _load();
  }

  Future<void> _updateStatus(String id, String status) async {
    final res = await sl<ApiClientHelper>().patchAction(
      ApiEndpoints.founderFundingStatus(id),
      body: {'status': status},
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Status updated'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Funding'),
      actions: [TextButton(onPressed: _createRound, child: const Text('New'))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (_rounds.isEmpty)
                  const AppCard(child: Text('No funding rounds yet')),
                for (final r in _rounds)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: ListTile(
                      title: Text(r['title']?.toString() ?? 'Funding round'),
                      subtitle: Text('Status: ${r['status'] ?? 'draft'}'),
                      trailing: IconButton(
                        onPressed: () =>
                            _updateStatus(r['id']?.toString() ?? '', 'active'),
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class _FounderPitchDeckLivePageState extends State<FounderPitchDeckLivePage> {
  final _summary = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().get<Map<String, dynamic>>(
      ApiEndpoints.founderPitchDeck,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (!mounted) return;
    _summary.text = res.valueOrNull?['summary']?.toString() ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final api = sl<ApiClientHelper>();
    var res = await api.put<Map<String, dynamic>>(
      ApiEndpoints.founderPitchDeck,
      body: {'summary': _summary.text.trim()},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (res.isFailure) {
      res = await api.post<Map<String, dynamic>>(
        ApiEndpoints.founderPitchDeck,
        body: {'summary': _summary.text.trim()},
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
        allowNullData: false,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Pitch deck saved'),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Pitch Deck')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              AppTextField(
                controller: _summary,
                label: 'Deck Summary',
                hint: 'Enter deck summary',
                maxLines: 8,
              ),
              AppSizes.vGapMd,
              AppPrimaryButton(
                label: 'Save',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
  );
}

class FounderBusinessPlanLivePage extends StatefulWidget {
  const FounderBusinessPlanLivePage({super.key});
  @override
  State<FounderBusinessPlanLivePage> createState() =>
      _FounderBusinessPlanLivePageState();
}

class _FounderBusinessPlanLivePageState
    extends State<FounderBusinessPlanLivePage> {
  final _summary = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>().get<Map<String, dynamic>>(
      ApiEndpoints.founderBusinessPlan,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (!mounted) return;
    _summary.text = res.valueOrNull?['summary']?.toString() ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final api = sl<ApiClientHelper>();
    var res = await api.put<Map<String, dynamic>>(
      ApiEndpoints.founderBusinessPlan,
      body: {'summary': _summary.text.trim()},
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    if (res.isFailure) {
      res = await api.post<Map<String, dynamic>>(
        ApiEndpoints.founderBusinessPlan,
        body: {'summary': _summary.text.trim()},
        parser: (raw) => Map<String, dynamic>.from(raw as Map),
        allowNullData: false,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Business plan saved'),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Business Plan')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              AppTextField(
                controller: _summary,
                label: 'Plan Summary',
                hint: 'Enter plan summary',
                maxLines: 10,
              ),
              AppSizes.vGapMd,
              AppPrimaryButton(
                label: 'Save',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
  );
}

class FounderTeamLivePage extends StatefulWidget {
  const FounderTeamLivePage({super.key});

  @override
  State<FounderTeamLivePage> createState() => _FounderTeamLivePageState();
}

class _FounderTeamLivePageState extends State<FounderTeamLivePage> {
  bool _loading = true;
  List<Map<String, dynamic>> _team = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.founderTeam,
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
    _team = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final role = TextEditingController();
    await showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Add team member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: name, hint: 'Name'),
            AppTextField(controller: role, hint: 'Role'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final res = await sl<ApiClientHelper>().postAction(
                ApiEndpoints.founderTeam,
                body: {'name': name.text.trim(), 'role': role.text.trim()},
              );
              if (!mounted) return;
              res.fold(
                (f) => context.showSnack(f.message),
                (_) => context.showSnack('Member added'),
              );
              if (dCtx.mounted) Navigator.pop(dCtx);
              await _load();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Team'),
      actions: [TextButton(onPressed: _add, child: const Text('Add'))],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (_team.isEmpty)
                  const AppCard(child: Text('No team members yet')),
                for (final m in _team)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: ListTile(
                      title: Text(m['name']?.toString() ?? 'Member'),
                      subtitle: Text(m['role']?.toString() ?? ''),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class FounderMediaLivePage extends StatefulWidget {
  const FounderMediaLivePage({super.key});
  @override
  State<FounderMediaLivePage> createState() => _FounderMediaLivePageState();
}

class _FounderMediaLivePageState extends State<FounderMediaLivePage> {
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
          ApiEndpoints.founderDocuments,
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
      endpoint: ApiEndpoints.founderDocumentsUpload,
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
      fields: {'category': 'founder_document'},
    );
    if (!mounted) return;
    fallback.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Uploaded via files API'),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: const Text('Media & Documents'),
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
                  const AppCard(child: Text('No documents uploaded')),
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

class FounderAnalyticsLivePage extends StatefulWidget {
  const FounderAnalyticsLivePage({super.key});
  @override
  State<FounderAnalyticsLivePage> createState() =>
      _FounderAnalyticsLivePageState();
}

class _FounderAnalyticsLivePageState extends State<FounderAnalyticsLivePage> {
  bool _loading = true;
  Map<String, dynamic> _analytics = const {};
  List<Map<String, dynamic>> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final a = await api.get<Map<String, dynamic>>(
      ApiEndpoints.founderAnalytics,
      parser: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    final r = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.founderReports,
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
    _analytics = a.valueOrNull ?? const {};
    _reports = r.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: const Text('Founder Analytics')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                _metric('Funding Raised', _analytics['fundingRaised']),
                _metric('Investor Interests', _analytics['investorInterests']),
                _metric('Meetings', _analytics['meetings']),
                _metric('Pitch Deck Views', _analytics['pitchDeckViews']),
                _metric('Wallet', _analytics['walletBalance']),
                _metric('Subscription', _analytics['subscriptionPlan']),
                for (final rep in _reports)
                  AppCard(
                    margin: const EdgeInsets.only(top: AppSizes.sm),
                    child: Text(rep['title']?.toString() ?? 'Report'),
                  ),
              ],
            ),
          ),
  );

  Widget _metric(String label, dynamic value) => AppCard(
    child: Row(
      children: [Text(label), const Spacer(), Text(value?.toString() ?? '—')],
    ),
  );
}
