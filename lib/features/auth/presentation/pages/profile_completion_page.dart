import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/entities/ticket_size_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../bloc/auth_bloc.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _headline = TextEditingController(); // Job Title / Headline
  final _company =
      TextEditingController(); // Client Company / Investor Firm Name
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _ticketMin = TextEditingController();
  final _ticketMax = TextEditingController();
  final _categoryDisplayController = TextEditingController();
  final _skillsDisplayController = TextEditingController();
  final _hiringGoalsDisplayController = TextEditingController();
  final _focusAreasDisplayController = TextEditingController();
  final _categorySearch = TextEditingController();
  final _skillSearch = TextEditingController();
  final _imagePicker = ImagePicker();

  final Set<String> _selectedSkillIds = {};
  final Set<String> _selectedHiringGoalIds = {};
  final Set<String> _selectedFocusAreaIds = {};
  final Map<String, List<SkillOption>> _skillsByCategoryId = {};

  MasterOption? _selectedCountry;
  MasterOption? _selectedState;
  MasterOption? _selectedExperience;
  MasterOption? _selectedAvailability;
  MasterOption? _selectedCompanySize;
  MasterOption? _selectedBudgetRange;
  MasterOption? _selectedInvestorType;
  MasterOption? _selectedPreferredStage;
  TicketSizeOption? _selectedTicketSize;
  MasterOption? _selectedFounderStage;
  MasterOption? _selectedFounderRole;
  MasterOption? _selectedTeamSize;
  MasterOption? _selectedPrimaryGoal;
  MasterOption? _selectedFounderIndustry;
  final Set<String> _selectedFounderGoalIds = {};

  num? _rawTicketMin;
  num? _rawTicketMax;

  final _pitch = TextEditingController();
  final _targetRaise = TextEditingController();
  final _founderIndustryDisplayController = TextEditingController();
  final _primaryGoalDisplayController = TextEditingController();

  List<MasterOption> _countries = [];
  List<MasterOption> _states = [];
  List<MasterOption> _experienceLevels = [];
  List<MasterOption> _availabilities = [];
  List<MasterOption> _companySizes = [];
  List<MasterOption> _budgetRanges = [];
  List<MasterOption> _hiringGoals = [];
  List<MasterOption> _investorTypes = [];
  List<MasterOption> _investorStages = [];
  List<TicketSizeOption> _ticketSizes = [];
  List<MasterOption> _focusAreaOptions = [];
  List<MasterOption> _startupStages = [];
  List<MasterOption> _startupRoles = [];
  List<MasterOption> _teamSizes = [];
  List<MasterOption> _founderGoals = [];
  final List<String> _prefilledFocusAreaNames = [];

  bool _loadingCategories = true;
  bool _loadingSkills = false;
  // ignore: unused_field
  String? _loadError;
  String? _categoryError;
  String? _avatarError;
  Uint8List? _avatarBytes;
  int _profileCompletion = 0;

  List<SkillCategory> _categories = [];
  String? _selectedCategoryId;
  List<SkillOption> _visibleSkills = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      _profileCompletion = user.profileCompletion;
      if (user.fullName.isNotEmpty) _fullName.text = user.fullName;
      if (user.categoryId != null && user.categoryId!.isNotEmpty) {
        _selectedCategoryId = user.categoryId;
      } else if (user.industryId != null && user.industryId!.isNotEmpty) {
        _selectedCategoryId = user.industryId;
      }
      if (user.skillIds.isNotEmpty) {
        _selectedSkillIds.addAll(user.skillIds);
      }
    }
    _loadMasterData();
    _loadCategories();
    _loadMeData();
  }

  Future<void> _loadMeData() async {
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

      if (!mounted || res.isFailure) return;
      final userMap = res.valueOrNull ?? {};
      if (userMap.isEmpty) return;

      final emailVal = userMap['email']?.toString();
      if (emailVal != null && emailVal.isNotEmpty) _email.text = emailVal;

      final compVal =
          userMap['profileCompletion'] ?? userMap['profile_completion'];
      if (compVal != null) {
        final parsed = int.tryParse(compVal.toString());
        if (parsed != null && parsed > 0) {
          setState(() => _profileCompletion = parsed);
        }
      }

      final fn =
          userMap['fullName']?.toString() ?? userMap['full_name']?.toString();
      if (fn != null && fn.isNotEmpty) _fullName.text = fn;

      final bioVal = userMap['bio']?.toString();
      if (bioVal != null && bioVal.isNotEmpty) _bio.text = bioVal;

      final locVal =
          userMap['city']?.toString() ?? userMap['location']?.toString();
      if (locVal != null && locVal.isNotEmpty) _location.text = locVal;

      // Extract country & state
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

      // Extract nested profile object
      if (userMap['profile'] is Map) {
        final pMap = Map<String, dynamic>.from(userMap['profile'] as Map);

        final compVal = (pMap['company'] ?? pMap['firm'] ?? pMap['startupName'])?.toString();
        if (compVal != null && compVal.isNotEmpty) {
          _company.text = compVal;
        }

        final pitchVal = pMap['pitch']?.toString();
        if (pitchVal != null && pitchVal.isNotEmpty) {
          _pitch.text = pitchVal;
        }

        final headlineVal =
            (pMap['jobTitle'] ??
                    pMap['titleHeadline'] ??
                    pMap['headline'] ??
                    pMap['title'])
                ?.toString();
        if (headlineVal != null && headlineVal.isNotEmpty) {
          _headline.text = headlineVal;
        }

        final rateVal = pMap['hourlyRate'] ?? pMap['hourly_rate'];
        if (rateVal != null) {
          _hourlyRate.text = rateVal.toString();
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

        final raiseVal = pMap['targetRaise'] ?? pMap['target_raise'];
        if (raiseVal != null) {
          _targetRaise.text = raiseVal.toString();
        }

        if (pMap['stageId'] is Map) {
          final sMap = Map<String, dynamic>.from(pMap['stageId'] as Map);
          final sId = (sMap['id'] ?? sMap['_id'])?.toString() ?? '';
          final sName = (sMap['name'] ?? sMap['label'])?.toString() ?? sId;
          if (sId.isNotEmpty && sName.isNotEmpty) {
            _selectedFounderStage = MasterOption(id: sId, name: sName);
          }
        } else if (pMap['stage'] is Map) {
          final sMap = Map<String, dynamic>.from(pMap['stage'] as Map);
          final sId = (sMap['id'] ?? sMap['_id'])?.toString() ?? '';
          final sName = (sMap['name'] ?? sMap['label'])?.toString() ?? sId;
          if (sId.isNotEmpty && sName.isNotEmpty) {
            _selectedFounderStage = MasterOption(id: sId, name: sName);
          }
        } else if (pMap['stageId'] is String && pMap['stageId'].toString().isNotEmpty) {
          final sId = pMap['stageId'].toString();
          _selectedFounderStage = MasterOption(id: sId, name: sId);
        } else if (pMap['stage'] is String && pMap['stage'].toString().isNotEmpty) {
          final sId = pMap['stage'].toString();
          _selectedFounderStage = MasterOption(id: sId, name: sId);
        }

        if (pMap['founderRoleId'] is Map) {
          final rMap = Map<String, dynamic>.from(pMap['founderRoleId'] as Map);
          final rId = (rMap['id'] ?? rMap['_id'])?.toString() ?? '';
          final rName = (rMap['name'] ?? rMap['label'])?.toString() ?? rId;
          if (rId.isNotEmpty && rName.isNotEmpty) {
            _selectedFounderRole = MasterOption(id: rId, name: rName);
          }
        } else if (pMap['founderRole'] is Map) {
          final rMap = Map<String, dynamic>.from(pMap['founderRole'] as Map);
          final rId = (rMap['id'] ?? rMap['_id'])?.toString() ?? '';
          final rName = (rMap['name'] ?? rMap['label'])?.toString() ?? rId;
          if (rId.isNotEmpty && rName.isNotEmpty) {
            _selectedFounderRole = MasterOption(id: rId, name: rName);
          }
        } else if (pMap['founderRoleId'] is String && pMap['founderRoleId'].toString().isNotEmpty) {
          final rId = pMap['founderRoleId'].toString();
          _selectedFounderRole = MasterOption(id: rId, name: rId);
        } else if (pMap['founderRole'] is String && pMap['founderRole'].toString().isNotEmpty) {
          final rId = pMap['founderRole'].toString();
          _selectedFounderRole = MasterOption(id: rId, name: rId);
        }

        if (pMap['teamSizeId'] is Map) {
          final tMap = Map<String, dynamic>.from(pMap['teamSizeId'] as Map);
          final tId = (tMap['id'] ?? tMap['_id'])?.toString() ?? '';
          final tName = (tMap['name'] ?? tMap['label'])?.toString() ?? tId;
          if (tId.isNotEmpty && tName.isNotEmpty) {
            _selectedTeamSize = MasterOption(id: tId, name: tName);
          }
        } else if (pMap['teamSize'] is Map) {
          final tMap = Map<String, dynamic>.from(pMap['teamSize'] as Map);
          final tId = (tMap['id'] ?? tMap['_id'])?.toString() ?? '';
          final tName = (tMap['name'] ?? tMap['label'])?.toString() ?? tId;
          if (tId.isNotEmpty && tName.isNotEmpty) {
            _selectedTeamSize = MasterOption(id: tId, name: tName);
          }
        } else if (pMap['teamSizeId'] is String && pMap['teamSizeId'].toString().isNotEmpty) {
          final tId = pMap['teamSizeId'].toString();
          _selectedTeamSize = MasterOption(id: tId, name: tId);
        } else if (pMap['teamSize'] is String && pMap['teamSize'].toString().isNotEmpty) {
          final tId = pMap['teamSize'].toString();
          _selectedTeamSize = MasterOption(id: tId, name: tId);
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

        if (pMap['focusAreasId'] is List) {
          final faList = pMap['focusAreasId'] as List;
          _prefilledFocusAreaNames.clear();
          for (final area in faList) {
            if (area is Map) {
              final fid = (area['id'] ?? area['_id'])?.toString();
              final fname = (area['name'] ?? area['label'])?.toString();
              if (fid != null && fid.isNotEmpty) _selectedFocusAreaIds.add(fid);
              if (fname != null && fname.isNotEmpty) {
                _prefilledFocusAreaNames.add(fname);
              }
            } else if (area is String && area.isNotEmpty) {
              _selectedFocusAreaIds.add(area);
              _prefilledFocusAreaNames.add(area);
            }
          }
          if (_prefilledFocusAreaNames.isNotEmpty) {
            _focusAreasDisplayController.text = _prefilledFocusAreaNames.join(
              ', ',
            );
          }
        }

        if (pMap['experienceId'] != null) {
          if (pMap['experienceId'] is Map) {
            final eMap = pMap['experienceId'] as Map;
            _selectedExperience = MasterOption(
              id: eMap['id']?.toString() ?? eMap['_id']?.toString() ?? '',
              name: eMap['name']?.toString() ?? eMap['label']?.toString() ?? '',
            );
          } else if (pMap['experienceId'] is String) {
            _selectedExperience = MasterOption(
              id: pMap['experienceId'].toString(),
              name: pMap['experienceId'].toString(),
            );
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

        if (pMap['industryId'] is Map) {
          final indMap = Map<String, dynamic>.from(pMap['industryId'] as Map);
          final indId = (indMap['id'] ?? indMap['_id'])?.toString();
          final indName = (indMap['name'] ?? indMap['label'])?.toString();
          if (indId != null && indId.isNotEmpty) {
            _selectedCategoryId = indId;
            if (indName != null && indName.isNotEmpty) {
              _categoryDisplayController.text = indName;
            }
            // Also populate founder industry field
            _selectedFounderIndustry = MasterOption(
              id: indId,
              name: indName ?? indId,
            );
            _founderIndustryDisplayController.text = indName ?? indId;
          }
        } else if (pMap['industry'] is List) {
          // industry stored as array
          final indList = pMap['industry'] as List;
          if (indList.isNotEmpty) {
            final first = indList.first;
            if (first is Map) {
              final indId = (first['id'] ?? first['_id'])?.toString() ?? '';
              final indName = (first['name'] ?? first['label'])?.toString() ?? indId;
              if (indId.isNotEmpty) {
                _selectedCategoryId = indId;
                _selectedFounderIndustry = MasterOption(id: indId, name: indName);
                _categoryDisplayController.text = indName;
                _founderIndustryDisplayController.text = indName;
              }
            } else if (first is String && first.isNotEmpty) {
              _selectedCategoryId = first;
              _selectedFounderIndustry = MasterOption(id: first, name: first);
              _founderIndustryDisplayController.text = first;
            }
          }
        } else if (pMap['industry'] is Map) {
          final indMap = Map<String, dynamic>.from(pMap['industry'] as Map);
          final indId = (indMap['id'] ?? indMap['_id'])?.toString() ?? '';
          final indName = (indMap['name'] ?? indMap['label'])?.toString() ?? indId;
          if (indId.isNotEmpty) {
            _selectedCategoryId = indId;
            _selectedFounderIndustry = MasterOption(id: indId, name: indName);
            _categoryDisplayController.text = indName;
            _founderIndustryDisplayController.text = indName;
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

        if (pMap['primaryGoalId'] is List) {
          final pgList = pMap['primaryGoalId'] as List;
          final names = <String>[];
          _selectedFounderGoalIds.clear();
          for (final goal in pgList) {
            if (goal is Map) {
              final gid = (goal['id'] ?? goal['_id'])?.toString();
              final gname = (goal['name'] ?? goal['label'])?.toString();
              if (gid != null && gid.isNotEmpty) {
                _selectedFounderGoalIds.add(gid);
              }
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

        if (pMap['hiringGoalId'] is List) {
          final hgList = pMap['hiringGoalId'] as List;
          final names = <String>[];
          _selectedHiringGoalIds.clear();
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
      _matchAllDropdowns();
    } catch (_) {}
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
      if (_startupStages.isNotEmpty) {
        _selectedFounderStage = _matchOption(
          _selectedFounderStage,
          _startupStages,
        );
      }
      if (_startupRoles.isNotEmpty) {
        _selectedFounderRole = _matchOption(
          _selectedFounderRole,
          _startupRoles,
        );
      }
      if (_teamSizes.isNotEmpty) {
        _selectedTeamSize = _matchOption(_selectedTeamSize, _teamSizes);
      }
      if (_founderGoals.isNotEmpty) {
        _selectedPrimaryGoal = _matchOption(
          _selectedPrimaryGoal,
          _founderGoals,
        );
      }
      if (_focusAreaOptions.isNotEmpty) {
        _selectedFounderIndustry = _matchOption(
          _selectedFounderIndustry,
          _focusAreaOptions,
        );
        if (_selectedFounderIndustry != null) {
          _founderIndustryDisplayController.text = _selectedFounderIndustry!.name;
        }
      }
    });
  }

  Future<void> _loadMasterData() async {
    final repo = sl<MasterDataRepository>();

    final cRes = await repo.getCountriesOptions();
    if (mounted && cRes.isSuccess) _countries = cRes.valueOrNull ?? [];

    final expRes = await repo.getExperienceLevelOptions();
    if (mounted && expRes.isSuccess) {
      _experienceLevels = expRes.valueOrNull ?? [];
    }

    final availRes = await repo.getAvailabilityOptions();
    if (mounted && availRes.isSuccess) {
      _availabilities = availRes.valueOrNull ?? [];
    }

    final csRes = await repo.getCompanySizeOptions();
    if (mounted && csRes.isSuccess) {
      _companySizes = csRes.valueOrNull ?? [];
    }

    final tmRes = await repo.getTeamSizeOptions();
    if (mounted && tmRes.isSuccess) {
      _teamSizes = tmRes.valueOrNull ?? [];
    }

    final bRes = await repo.getHiringBudgetOptions();
    if (mounted && bRes.isSuccess) _budgetRanges = bRes.valueOrNull ?? [];

    final hgRes = await repo.getHiringGoalOptions();
    if (mounted && hgRes.isSuccess) _hiringGoals = hgRes.valueOrNull ?? [];

    final itRes = await repo.getInvestorTypeOptions();
    if (mounted && itRes.isSuccess) _investorTypes = itRes.valueOrNull ?? [];

    final stRes = await repo.getInvestorStageOptions();
    if (mounted && stRes.isSuccess) _investorStages = stRes.valueOrNull ?? [];

    final tsRes = await repo.getTicketSizeOptions();
    if (mounted && tsRes.isSuccess) _ticketSizes = tsRes.valueOrNull ?? [];

    final indRes = await repo.getIndustryOptions();
    if (mounted && indRes.isSuccess) {
      _focusAreaOptions = indRes.valueOrNull ?? [];
    }

    final stgRes = await repo.getStartupStageOptions();
    if (mounted && stgRes.isSuccess) _startupStages = stgRes.valueOrNull ?? [];

    final rolRes = await repo.getStartupRoleOptions();
    if (mounted && rolRes.isSuccess) _startupRoles = rolRes.valueOrNull ?? [];

    final fgRes = await repo.getFounderGoalOptions();
    if (mounted && fgRes.isSuccess) _founderGoals = fgRes.valueOrNull ?? [];

    if (mounted) _updateFocusAreasDisplayText();

    _matchAllDropdowns();
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
    setState(() {
      _loadingCategories = true;
      _loadError = null;
    });

    final result = await sl<MasterDataRepository>().getIndustries();
    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _loadingCategories = false;
        _loadError =
            result.failureOrNull?.message ?? 'Failed to load categories';
      });
      return;
    }

    final categories = result.valueOrNull ?? [];
    if (categories.isEmpty) {
      setState(() {
        _loadingCategories = false;
        _loadError = 'No categories available';
      });
      return;
    }

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
    } else {
      _visibleSkills = [];
    }
  }

  Future<void> _loadSkillsForCategory(String categoryId) async {
    // The backend API returns all skills regardless of industryId.
    // Cache under a fixed key so we only fetch once.
    const cacheKey = '__all__';
    if (_skillsByCategoryId.containsKey(cacheKey) &&
        (_skillsByCategoryId[cacheKey] ?? []).isNotEmpty) {
      setState(() {
        _selectedCategoryId = categoryId;
        _visibleSkills = _skillsByCategoryId[cacheKey] ?? [];
        _categoryError = null;
      });
      _updateSkillsDisplayText();
      return;
    }

    setState(() {
      _selectedCategoryId = categoryId;
      _loadingSkills = true;
      _loadError = null;
      _categoryError = null;
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

      if (result.isFailure) {
        setState(() {
          _loadingSkills = false;
          _loadError = result.failureOrNull?.message ?? 'Failed to load skills';
        });
        return;
      }

      final batch = result.valueOrNull ?? [];
      if (batch.isEmpty) break;

      allSkills.addAll(batch.where((skill) => skill.name.isNotEmpty));

      if (page == 1) {
        final totalResult = await repo.getSkillsTotal(categoryId: categoryId);
        total = totalResult.valueOrNull ?? batch.length;
      }

      if (allSkills.length >= total || batch.length < pageSize) break;
      page++;
    }

    setState(() {
      _skillsByCategoryId[cacheKey] = allSkills;
      _visibleSkills = allSkills;
      _loadingSkills = false;
    });
    _updateSkillsDisplayText();
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

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
            final filtered = (search.isEmpty
                ? List<SkillCategory>.from(_categories)
                : _categories
                      .where((c) => c.name.toLowerCase().contains(search))
                      .toList())
              ..sort((a, b) {
                final aSel = a.id == _selectedCategoryId;
                final bSel = b.id == _selectedCategoryId;
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

  void _showFocusAreasBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
            final options = _focusAreaOptions.isNotEmpty
                ? _focusAreaOptions
                : _categories
                      .map((c) => MasterOption(id: c.id, name: c.name))
                      .toList();
            final filtered = search.isEmpty
                ? options
                : options
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

  void _showFounderIndustryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
            final filtered = search.isEmpty
                ? _focusAreaOptions
                : _focusAreaOptions
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
                        controller: _categorySearch,
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
                                      _selectedFounderIndustry?.id == item.id;
                                  return ListTile(
                                    title: Text(item.name),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedFounderIndustry = item;
                                        _founderIndustryDisplayController.text =
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

  void _showFounderGoalsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _categorySearch.text.trim().toLowerCase();
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
                                  final isSelected = _selectedFounderGoalIds
                                      .contains(item.id);
                                  return CheckboxListTile(
                                    title: Text(item.name),
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    onChanged: (_) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedFounderGoalIds.remove(
                                            item.id,
                                          );
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

  Future<void> _showSkillsBottomSheet() async {
    if (_selectedCategoryId == null) {
      context.showSnack('Please select a Category first', isError: true);
      return;
    }

    const cacheKey = '__all__';
    if (_skillsByCategoryId.containsKey(cacheKey) &&
        (_skillsByCategoryId[cacheKey] ?? []).isNotEmpty) {
      setState(() {
        _visibleSkills = _skillsByCategoryId[cacheKey]!;
      });
    } else {
      await _loadSkillsForCategory(_selectedCategoryId!);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final search = _skillSearch.text.trim().toLowerCase();
            final filtered = (search.isEmpty
                ? List<SkillOption>.from(_visibleSkills)
                : _visibleSkills
                      .where((s) => s.name.toLowerCase().contains(search))
                      .toList())
              ..sort((a, b) {
                final aSel = _selectedSkillIds.contains(a.id);
                final bSel = _selectedSkillIds.contains(b.id);
                if (aSel && !bSel) return -1;
                if (!aSel && bSel) return 1;
                return 0;
              });

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

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _headline.dispose();
    _company.dispose();
    _location.dispose();
    _bio.dispose();
    _hourlyRate.dispose();
    _ticketMin.dispose();
    _ticketMax.dispose();
    _categoryDisplayController.dispose();
    _skillsDisplayController.dispose();
    _hiringGoalsDisplayController.dispose();
    _focusAreasDisplayController.dispose();
    _pitch.dispose();
    _targetRaise.dispose();
    _founderIndustryDisplayController.dispose();
    _primaryGoalDisplayController.dispose();
    _categorySearch.dispose();
    _skillSearch.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final existingAvatar = context.read<AuthBloc>().state.user?.avatarUrl;
    final hasAvatar =
        _avatarBytes != null ||
        (existingAvatar != null && existingAvatar.isNotEmpty);
    if (!hasAvatar) {
      const message = 'Profile photo is required';
      setState(() => _avatarError = message);
      _showTopValidationMessage(message);
      return;
    }

    final role =
        context.read<AuthBloc>().state.user?.role ?? UserRole.freelancer;

    if (role != UserRole.client &&
        role != UserRole.investor &&
        role != UserRole.founder &&
        _selectedCategoryId == null) {
      setState(() => _categoryError = 'Category is required');
      context.showSnack('Category is required', isError: true);
      return;
    }

    setState(() {
      _avatarError = null;
      _categoryError = null;
    });

    final payload = <String, dynamic>{
      'fullName': _fullName.text.trim(),
      'titleHeadline': _headline.text.trim(),
      'headline': _headline.text.trim(),
      'city': _location.text.trim(),
      'bio': _bio.text.trim(),
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      if (_selectedState != null) 'stateId': _selectedState!.id,
      if (role == UserRole.client) ...{
        if (_company.text.trim().isNotEmpty) 'company': _company.text.trim(),
        if (_headline.text.trim().isNotEmpty) 'jobTitle': _headline.text.trim(),
        if (_selectedCategoryId != null) 'industryId': _selectedCategoryId,
        if (_selectedCompanySize != null)
          'companySizeId': _selectedCompanySize!.id,
        if (_selectedBudgetRange != null)
          'projectHireBudgetId': _selectedBudgetRange!.id,
        if (_selectedHiringGoalIds.isNotEmpty)
          'hiringGoalId': _selectedHiringGoalIds.toList(),
      } else if (role == UserRole.investor) ...{
        if (_company.text.trim().isNotEmpty) 'firm': _company.text.trim(),
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
                double.tryParse(_ticketMin.text.trim()) ??
                _ticketMin.text.trim(),
          if (_ticketMax.text.trim().isNotEmpty)
            'ticketMax':
                double.tryParse(_ticketMax.text.trim()) ??
                _ticketMax.text.trim(),
        },
      } else if (role == UserRole.founder) ...{
        if (_company.text.trim().isNotEmpty) ...{
          'startupName': _company.text.trim(),
          'companyName': _company.text.trim(),
        },
        if (_pitch.text.trim().isNotEmpty) 'pitch': _pitch.text.trim(),
        if (_selectedFounderIndustry != null) ...{
          'industryId': _selectedFounderIndustry!.id,
          'industry': [_selectedFounderIndustry!.id],
        },
        if (_selectedFounderStage != null) ...{
          'stageId': _selectedFounderStage!.id,
          'stage': _selectedFounderStage!.id,
        },
        if (_selectedFounderRole != null) ...{
          'founderRoleId': _selectedFounderRole!.id,
          'founderRole': _selectedFounderRole!.id,
        },
        if (_selectedTeamSize != null) ...{
          'teamSizeId': _selectedTeamSize!.id,
          'teamSize': _selectedTeamSize!.id,
        },
        if (_selectedFounderGoalIds.isNotEmpty) ...{
          'primaryGoalId': _selectedFounderGoalIds.toList(),
          'primaryGoal': _selectedFounderGoalIds.toList(),
        },
        if (_targetRaise.text.trim().isNotEmpty) ...{
          'targetRaise':
              double.tryParse(_targetRaise.text.trim()) ??
              _targetRaise.text.trim(),
        },
      } else ...{
        if (_selectedCategoryId != null) ...{
          'industryId': _selectedCategoryId,
          'industry': [_selectedCategoryId],
          'categoryId': _selectedCategoryId,
        },
        if (_selectedExperience != null) ...{
          'experienceLevelId': _selectedExperience!.id,
          'experienceId': _selectedExperience!.id,
        },
        if (_selectedAvailability != null)
          'availabilityId': _selectedAvailability!.id,
        if (_hourlyRate.text.trim().isNotEmpty)
          'hourlyRate':
              double.tryParse(_hourlyRate.text.trim()) ??
              _hourlyRate.text.trim(),
        if (_selectedSkillIds.isNotEmpty) ...{
          'skillIds': _selectedSkillIds.toList().join(','),
          'skills': _selectedSkillIds.toList(),
        },
      },
    };

    context.read<AuthBloc>().add(
      AuthProfileCompleted(payload, avatarBytes: _avatarBytes?.toList()),
    );
  }

  void _showTopValidationMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: context.colors.error,
        content: Text(
          message,
          style: context.text.bodyMedium?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: messenger.hideCurrentMaterialBanner,
          ),
        ],
      ),
    );

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      messenger.hideCurrentMaterialBanner();
    });
  }

  Future<void> _openAvatarPicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            if (_avatarBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _avatarBytes = null);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAvatar(source);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarError = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isCamera = source == ImageSource.camera;
      final denied = e.code.contains('denied') || e.code.contains('restricted');
      context.showSnack(
        denied
            ? '${isCamera ? 'Camera' : 'Gallery'} permission is required to select a profile photo.'
            : 'Could not select profile photo. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role =
        context.select((AuthBloc b) => b.state.user?.role) ??
        UserRole.freelancer;
    final isClient = role == UserRole.client;
    final isInvestor = role == UserRole.investor;

    return Scaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Complete your profile'),
      ),
      body: ResponsiveWrapper(
        maxWidth: 560,
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              (previous.errorMessage != current.errorMessage &&
                  current.errorMessage != null) ||
              (previous.successMessage != current.successMessage &&
                  current.successMessage != null),
          listener: (context, state) {
            if (state.errorMessage != null) {
              context.showSnack(state.errorMessage!, isError: true);
            }
            if (state.successMessage != null) {
              context.showSnack(state.successMessage!);
              final role = state.user?.role;
              final targetRoute = role == UserRole.client
                  ? Routes.clientDashboard
                  : role == UserRole.investor
                      ? Routes.investorDashboard
                      : role == UserRole.founder
                          ? Routes.founderDashboard
                          : Routes.freelancerDashboard;
              context.go(targetRoute);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: context.paddingWithBottomSafe(
                const EdgeInsets.all(AppSizes.xl),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.lg),
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: context.colors.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile Completion',
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(_profileCompletion > 0 ? _profileCompletion : (state.user?.profileCompletion ?? 0))}%',
                                style: context.text.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          AppSizes.vGapSm,
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  ((_profileCompletion > 0
                                          ? _profileCompletion
                                          : (state.user?.profileCompletion ??
                                                0))
                                      .clamp(0, 100)) /
                                  100.0,
                              minHeight: 8,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              AppAvatar(
                                name: state.user?.fullName ?? 'User',
                                imageUrl: state.user?.avatarUrl,
                                imageBytes: _avatarBytes,
                                size: 88,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: Material(
                                    color: AppColors.primary,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      tooltip: 'Add profile photo',
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 25,
                                            height: 25,
                                          ),
                                      padding: EdgeInsets.zero,
                                      onPressed: _openAvatarPicker,
                                      icon: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSizes.vGapSm,
                          Text(
                            'Profile photo *',
                            style: context.text.bodySmall,
                          ),
                          if (_avatarError != null) ...[
                            AppSizes.vGapXs,
                            Text(
                              _avatarError!,
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppSizes.vGapLg,
                    Text(
                      'Setting up your ${role.shortLabel} profile',
                      style: context.text.titleMedium,
                    ),
                    AppSizes.vGapLg,
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      hint: 'Enter Email',
                      readOnly: true,
                    ),
                    AppSizes.vGapLg,
                    AppTextField(
                      controller: _fullName,
                      label: 'Full Name *',
                      hint: 'Enter Full Name',
                      validator: (v) =>
                          Validators.minLength(v, 2, field: 'Full Name'),
                    ),
                    if (isInvestor) ...[
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _company,
                        label: 'Firm / Entity Name',
                        hint: 'Enter Firm / Entity Name',
                      ),
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'Investor Type *',
                        hint: 'Select Investor Type',
                        value: _selectedInvestorType,
                        items: _investorTypes,
                        itemLabel: (item) => item.name,
                        validator: (v) => Validators.required(
                          v?.name,
                          field: 'Investor Type',
                        ),
                        onChanged: (opt) =>
                            setState(() => _selectedInvestorType = opt),
                      ),
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'Preferred Investment Stage *',
                        hint: 'Select Preferred Investment Stage',
                        value: _selectedPreferredStage,
                        items: _investorStages,
                        itemLabel: (item) => item.name,
                        validator: (v) => Validators.required(
                          v?.name,
                          field: 'Preferred Investment Stage',
                        ),
                        onChanged: (opt) =>
                            setState(() => _selectedPreferredStage = opt),
                      ),
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _focusAreasDisplayController,
                        label: _selectedFocusAreaIds.isEmpty
                            ? 'Focus Areas / Sectors'
                            : 'Focus Areas / Sectors (${_selectedFocusAreaIds.length})',
                        hint: 'Select Focus Industries / Sector',
                        readOnly: true,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                        onTap: _showFocusAreasBottomSheet,
                      ),
                      AppSizes.vGapLg,
                      AppLocationField(
                        controller: _location,
                        label: 'Location *',
                        hint: 'Select Location',
                        country: _selectedCountry?.name,
                        validator: (v) =>
                            Validators.required(v, field: 'Location'),
                      ),
                      AppSizes.vGapLg,
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
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'State *',
                        hint: 'Select State',
                        value: _selectedState,
                        items: _states,
                        itemLabel: (item) => item.name,
                        validator: (v) =>
                            Validators.required(v?.name, field: 'State'),
                        onChanged: (opt) =>
                            setState(() => _selectedState = opt),
                      ),
                      AppSizes.vGapLg,
                      AppDropdown<TicketSizeOption>(
                        label: 'Ticket Size *',
                        hint: 'Select Ticket Size',
                        value: _selectedTicketSize,
                        items: _ticketSizes,
                        itemLabel: (item) => item.label,
                        validator: (v) =>
                            Validators.required(v?.label, field: 'Ticket Size'),
                        onChanged: (opt) =>
                            setState(() => _selectedTicketSize = opt),
                      ),
                    ] else if (role == UserRole.founder) ...[
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _company,
                        label: 'Startup / Company Name *',
                        hint: 'Enter Startup / Company Name',
                        validator: (v) =>
                            Validators.required(v, field: 'Startup Name'),
                      ),
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _founderIndustryDisplayController,
                        label: 'Industry *',
                        hint: 'Select Industry',
                        readOnly: true,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                        onTap: _showFounderIndustryBottomSheet,
                      ),
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'Current Stage *',
                        hint: 'Select Current Stage',
                        value: _selectedFounderStage,
                        items: _startupStages,
                        itemLabel: (item) => item.name,
                        validator: (v) => Validators.required(
                          v?.name,
                          field: 'Current Stage',
                        ),
                        onChanged: (opt) =>
                            setState(() => _selectedFounderStage = opt),
                      ),
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'Role in Startup *',
                        hint: 'Select Role in Startup',
                        value: _selectedFounderRole,
                        items: _startupRoles,
                        itemLabel: (item) => item.name,
                        validator: (v) => Validators.required(
                          v?.name,
                          field: 'Role in Startup',
                        ),
                        onChanged: (opt) =>
                            setState(() => _selectedFounderRole = opt),
                      ),
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'Team Size *',
                        hint: 'Select Team Size',
                        value: _selectedTeamSize,
                        items: _teamSizes,
                        itemLabel: (item) => item.name,
                        validator: (v) =>
                            Validators.required(v?.name, field: 'Team Size'),
                        onChanged: (opt) =>
                            setState(() => _selectedTeamSize = opt),
                      ),
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _primaryGoalDisplayController,
                        label: _selectedFounderGoalIds.isEmpty
                            ? 'Primary Goal on Platform'
                            : 'Primary Goal on Platform (${_selectedFounderGoalIds.length})',
                        hint: 'Select Primary Goal',
                        readOnly: true,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                        onTap: _showFounderGoalsBottomSheet,
                      ),
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _targetRaise,
                        label: 'Target Raise (₹)',
                        hint: 'Enter Target Raise',
                        keyboardType: TextInputType.number,
                      ),
                      AppSizes.vGapLg,
                      AppLocationField(
                        controller: _location,
                        label: 'Location *',
                        hint: 'Select Location',
                        country: _selectedCountry?.name,
                        validator: (v) =>
                            Validators.required(v, field: 'Location'),
                      ),
                      AppSizes.vGapLg,
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
                      if (_selectedCountry != null) ...[
                        AppSizes.vGapLg,
                        AppDropdown<MasterOption>(
                          label: 'State *',
                          hint: 'Select State',
                          value: _selectedState,
                          items: _states,
                          itemLabel: (item) => item.name,
                          validator: (v) =>
                              Validators.required(v?.name, field: 'State'),
                          onChanged: (opt) =>
                              setState(() => _selectedState = opt),
                        ),
                      ],
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _pitch,
                        label: 'One Line Pitch',
                        hint:
                            'Autonomous supply-chain optimization powered by machine learning.',
                        maxLines: 2,
                      ),
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _bio,
                        label: 'Professional Overview',
                        hint: 'Tell people about your background and vision',
                        maxLines: 4,
                      ),
                    ] else ...[
                      AppSizes.vGapLg,
                      // AppTextField(
                      //   controller: _headline,
                      //   label: isClient ? 'Job Title *' : 'Headline *',
                      //   hint: isClient
                      //       ? 'Enter Job Title'
                      //       : role == UserRole.founder
                      //       ? 'Enter your title'
                      //       : 'Enter your job title',
                      //   // validator: (v) => Validators.minLength(
                      //   //   v,
                      //   //   2,
                      //   //   field: isClient ? 'Job Title' : 'Headline',
                      //   // ),
                      // ),
                      if (isClient) ...[
                        AppSizes.vGapLg,
                        AppTextField(
                          controller: _company,
                          label: 'Company Name *',
                          hint: 'Enter Company Name',
                          validator: (v) =>
                              Validators.minLength(v, 2, field: 'Company Name'),
                        ),
                      ],
                      AppSizes.vGapLg,
                      AppLocationField(
                        controller: _location,
                        label: 'Location *',
                        hint: 'Select Location',
                        country: _selectedCountry?.name,
                        validator: (v) =>
                            Validators.required(v, field: 'Location'),
                      ),
                      AppSizes.vGapLg,
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
                      AppSizes.vGapLg,
                      AppDropdown<MasterOption>(
                        label: 'State *',
                        hint: 'Select State',
                        value: _selectedState,
                        items: _states,
                        itemLabel: (item) => item.name,
                        validator: (v) =>
                            Validators.required(v?.name, field: 'State'),
                        onChanged: (opt) =>
                            setState(() => _selectedState = opt),
                      ),
                      AppSizes.vGapLg,
                      AppTextField(
                        controller: _categoryDisplayController,
                        label: 'Category / Industry *',
                        hint: 'Select Category / Industry',
                        readOnly: true,
                        suffixIcon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                        onTap: _showCategoryBottomSheet,
                        validator: (v) => Validators.required(
                          v,
                          field: 'Category / Industry',
                        ),
                      ),
                      if (_categoryError != null) ...[
                        AppSizes.vGapXs,
                        Text(
                          _categoryError!,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      if (isClient) ...[
                        AppSizes.vGapLg,
                        AppDropdown<MasterOption>(
                          label: 'Company Size *',
                          hint: 'Select Company Size',
                          value: _selectedCompanySize,
                          items: _companySizes,
                          itemLabel: (item) => item.name,
                          validator: (v) => Validators.required(
                            v?.name,
                            field: 'Company Size',
                          ),
                          onChanged: (opt) =>
                              setState(() => _selectedCompanySize = opt),
                        ),
                        AppSizes.vGapLg,
                        AppDropdown<MasterOption>(
                          label: 'Project / Hiring Budget *',
                          hint: 'Select Project / Hiring Budget',
                          value: _selectedBudgetRange,
                          items: _budgetRanges,
                          itemLabel: (item) => item.name,
                          validator: (v) => Validators.required(
                            v?.name,
                            field: 'Project / Hiring Budget',
                          ),
                          onChanged: (opt) =>
                              setState(() => _selectedBudgetRange = opt),
                        ),
                        AppSizes.vGapLg,
                        AppTextField(
                          controller: _hiringGoalsDisplayController,
                          label: 'Hiring Goals',
                          hint: 'Select Hiring Goals',
                          readOnly: true,
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          ),
                          onTap: _showHiringGoalsBottomSheet,
                        ),
                      ] else ...[
                        AppSizes.vGapLg,
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
                        AppDropdown<MasterOption>(
                          label: 'Availability *',
                          hint: 'Select Availability',
                          value: _selectedAvailability,
                          items: _availabilities,
                          itemLabel: (item) => item.name,
                          validator: (v) => Validators.required(
                            v?.name,
                            field: 'Availability',
                          ),
                          onChanged: (opt) =>
                              setState(() => _selectedAvailability = opt),
                        ),
                        AppSizes.vGapLg,
                        AppTextField(
                          controller: _hourlyRate,
                          label: 'Hourly Rate (₹/hr) *',
                          hint: 'Enter Hourly Rate',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final reqErr = Validators.required(
                              v,
                              field: 'Hourly Rate',
                            );
                            if (reqErr != null) return reqErr;
                            final trimmed = v!.trim();
                            if (double.tryParse(trimmed) == null) {
                              return 'Please enter a valid amount (e.g. 230.99)';
                            }
                            return null;
                          },
                        ),
                        AppSizes.vGapLg,
                        AppTextField(
                          controller: _skillsDisplayController,
                          label: 'Skills (optional)',
                          hint: _selectedCategoryId == null
                              ? 'Select category first'
                              : 'Select skills',
                          readOnly: true,
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          ),
                          onTap: _showSkillsBottomSheet,
                        ),
                      ],
                    ],
                    AppSizes.vGapLg,
                    AppTextField(
                      controller: _bio,
                      label: 'About / Bio',
                      hint: 'Enter About / Bio',
                      maxLines: 4,
                    ),
                    AppSizes.vGapXl,
                    AppPrimaryButton(
                      label: 'Continue',
                      isLoading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                    AppSizes.vGapLg,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
