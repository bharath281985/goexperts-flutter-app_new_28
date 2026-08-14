import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/signup_multi_select_sheet.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerProfessionalDetailsPage extends StatefulWidget {
  const FreelancerProfessionalDetailsPage({super.key});

  @override
  State<FreelancerProfessionalDetailsPage> createState() =>
      _FreelancerProfessionalDetailsPageState();
}

class _FreelancerProfessionalDetailsPageState
    extends State<FreelancerProfessionalDetailsPage> {
  static const _defaultAvailabilityOptions = [
    'Available for work',
    'Part-time availability',
    'Booked this month',
    'Not available',
  ];

  final _formKey = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _location = TextEditingController();

  String? _detailId;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedExperienceId;
  String? _selectedAvailabilityId;

  List<SkillCategory> _categories = [];
  List<String> _experienceLevels = [];
  final List<String> _availabilityOptions = _defaultAvailabilityOptions;

  List<String> _availableSkillNames = [];
  List<String> _selectedSkillNames = [];
  final Map<String, SkillOption> _skillsMap = {};

  bool _loading = true;
  bool _loadingCategories = true;
  bool _loadingSkills = false;
  bool _saving = false;

  FreelancerProfileRepository get _repo => sl<FreelancerProfileRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _hourlyRate.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // 1. Fetch categories & experience levels master data
    try {
      final catRes = await sl<MasterDataRepository>().getIndustries();
      catRes.fold((f) {}, (list) => _categories = list);

      final expRes = await sl<MasterDataRepository>().getExperienceLevels();
      expRes.fold((f) {}, (list) {
        if (list.isNotEmpty) _experienceLevels = list;
      });
      if (_experienceLevels.isEmpty) {
        _experienceLevels = ['Entry Level', 'Intermediate', 'Expert'];
      }
    } catch (_) {}
    setState(() => _loadingCategories = false);

    // 2. Fetch professional details
    final res = await _repo.getProfessionalDetails();
    if (!mounted) return;

    res.fold((f) => _loadFallbackProfile(), (data) {
      if (data.isNotEmpty) {
        _detailId = data['id']?.toString() ?? data['_id']?.toString();
        _selectedCategoryId =
            data['categoryId']?.toString() ?? data['category_id']?.toString();
        _selectedCategoryName =
            data['categoryName']?.toString() ?? data['category']?.toString();
        _headline.text =
            data['heading']?.toString() ??
            data['headline']?.toString() ??
            data['title']?.toString() ??
            '';
        _bio.text =
            data['bio']?.toString() ?? data['description']?.toString() ?? '';
        final rateVal = data['hourlyRate'] ?? data['hourly_rate'];
        _hourlyRate.text = rateVal != null ? rateVal.toString() : '';
        _selectedExperienceId =
            data['experienceId']?.toString() ??
            data['experience_id']?.toString() ??
            data['experienceLevel']?.toString();
        _selectedAvailabilityId =
            data['availabilityId']?.toString() ??
            data['availability_id']?.toString() ??
            data['availability']?.toString();
        _location.text =
            data['location']?.toString() ?? data['city']?.toString() ?? '';

        dynamic rawSkills =
            data['skillsId'] ?? data['skills'] ?? data['skillIds'];
        if (rawSkills is List) {
          _selectedSkillNames = rawSkills
              .map((e) {
                if (e is Map) {
                  final name =
                      e['name']?.toString() ??
                      e['value']?.toString() ??
                      e['id']?.toString() ??
                      '';
                  final id = e['id']?.toString() ?? '';
                  if (name.isNotEmpty) {
                    _skillsMap[name] = SkillOption(id: id, name: name);
                  }
                  return name;
                }
                return e.toString();
              })
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else {
        _loadFallbackProfile();
      }
    });

    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      await _fetchSkillsForCategory(_selectedCategoryId!);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFallbackProfile() async {
    final authUser = context.read<AuthBloc>().state.user;
    if (_headline.text.isEmpty) _headline.text = authUser?.headline ?? '';
    if (_location.text.isEmpty) _location.text = authUser?.location ?? '';

    final profileRes = await _repo.getProfile();
    if (!mounted) return;
    profileRes.fold((f) {}, (profile) {
      if (_bio.text.isEmpty) _bio.text = profile.bio;
      if (_hourlyRate.text.isEmpty && profile.hourlyRate > 0) {
        _hourlyRate.text = profile.hourlyRate.toStringAsFixed(2);
      }
      if (_selectedSkillNames.isEmpty) {
        _selectedSkillNames = List<String>.from(profile.skills);
      }
    });
  }

  Future<void> _fetchSkillsForCategory(String categoryId) async {
    setState(() => _loadingSkills = true);
    try {
      final res = await sl<ApiClientHelper>().getEnvelope<List<SkillOption>>(
        ApiEndpoints.publicSkills,
        query: {
          'categoryId': categoryId,
          'industryId': categoryId,
          'page': 1,
          'limit': 50,
        },
        parser: (env) {
          dynamic list = env.data;
          if (list is Map) {
            final map = Map<String, dynamic>.from(list);
            list = map['data'] ?? map['items'] ?? map['skills'] ?? const [];
          }
          if (list is! List) return <SkillOption>[];
          return list
              .map(
                (e) =>
                    SkillOption.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        },
      );
      if (!mounted) return;
      if (res.isSuccess && res.valueOrNull != null) {
        final skills = res.valueOrNull!;
        setState(() {
          for (final s in skills) {
            _skillsMap[s.name] = s;
          }
          _availableSkillNames = skills.map((s) => s.name).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSkills = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      context.showSnack('Please select a category', isError: true);
      return;
    }

    final skillIds = _selectedSkillNames
        .map((name) => _skillsMap[name]?.id ?? name)
        .where((id) => id.isNotEmpty)
        .toList();

    final payload = {
      'categoryId': _selectedCategoryId,
      'heading': _headline.text.trim(),
      'bio': _bio.text.trim(),
      'hourlyRate': double.tryParse(_hourlyRate.text.trim()) ?? 0,
      'availabilityId': _selectedAvailabilityId ?? _availabilityOptions.first,
      'experienceId': _selectedExperienceId ?? _experienceLevels.first,
      'skillsId': skillIds,
      'location': _location.text.trim(),
    };

    setState(() => _saving = true);

    final res = await _repo.updateProfessionalDetails(payload, id: _detailId);

    if (!mounted) return;
    setState(() => _saving = false);

    res.fold((f) => context.showSnack(f.message, isError: true), (success) {
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Professional details saved');
    });
  }

  int _completion() {
    final checks = [
      _selectedCategoryId != null && _selectedCategoryId!.isNotEmpty,
      _selectedExperienceId != null && _selectedExperienceId!.isNotEmpty,
      _headline.text.trim().isNotEmpty,
      _bio.text.trim().isNotEmpty,
      _hourlyRate.text.trim().isNotEmpty,
      _selectedAvailabilityId != null && _selectedAvailabilityId!.isNotEmpty,
      _location.text.trim().isNotEmpty,
      _selectedSkillNames.isNotEmpty,
    ];
    return ((checks.where((check) => check).length / checks.length) * 100)
        .round();
  }

  double get _rate => double.tryParse(_hourlyRate.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      constrainWidth: false,
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Professional details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: AppPrimaryButton(
              label: 'Save changes',
              icon: Icons.save_outlined,
              isLoading: _saving,
              expanded: false,
              height: 38,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  _HeaderCard(completion: _completion()),
                  AppSizes.vGapMd,
                  AppCard(
                    radius: AppSizes.radiusMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category & focus',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Where you show up in the marketplace',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        AppSizes.vGapMd,
                        if (_loadingCategories)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          AppDropdown<SkillCategory>(
                            label: 'Category *',
                            hint: 'Select value',
                            value:
                                _selectedCategoryId == null ||
                                    _selectedCategoryId!.isEmpty
                                ? null
                                : _categories.firstWhere(
                                    (x) => x.id == _selectedCategoryId,
                                    orElse: () => SkillCategory(
                                      id: _selectedCategoryId!,
                                      name: _selectedCategoryName ?? '',
                                    ),
                                  ),
                            items: _categories,
                            itemLabel: (cat) => cat.name,
                            prefixIcon: Icons.layers_outlined,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _selectedCategoryId = val.id;
                                _selectedCategoryName = val.name;
                                _selectedSkillNames.clear();
                                _availableSkillNames.clear();
                                _skillsMap.clear();
                              });
                              _fetchSkillsForCategory(val.id);
                            },
                          ),
                        AppSizes.vGapMd,
                        AppDropdown<String>(
                          label: 'Experience level',
                          hint: 'Select value',
                          value:
                              _selectedExperienceId == null ||
                                  !_experienceLevels.contains(
                                    _selectedExperienceId,
                                  )
                              ? null
                              : _selectedExperienceId!,
                          items: _experienceLevels,
                          itemLabel: (item) => item,
                          prefixIcon: Icons.badge_outlined,
                          onChanged: (val) =>
                              setState(() => _selectedExperienceId = val),
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _headline,
                          label: 'Headline',
                          hint: 'Short pitch clients see first',
                          prefixIcon: Icons.auto_awesome_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value?.trim().isEmpty == true ? 'Required' : null,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _bio,
                          label: 'About / bio',
                          hint:
                              'Describe your expertise, industries, and delivery style',
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          validator: (value) =>
                              value?.trim().isEmpty == true ? 'Required' : null,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: _hourlyRate,
                          label: 'Hourly rate',
                          hint: '250.00',
                          prefixIcon: Icons.attach_money_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final rate = double.tryParse(value?.trim() ?? '');
                            if (rate == null || rate <= 0) {
                              return 'Enter a valid rate';
                            }
                            return null;
                          },
                        ),
                        AppSizes.vGapMd,
                        AppDropdown<String>(
                          label: 'Availability',
                          hint: 'Select value',
                          value:
                              _selectedAvailabilityId == null ||
                                  !_availabilityOptions.contains(
                                    _selectedAvailabilityId,
                                  )
                              ? null
                              : _selectedAvailabilityId!,
                          items: _availabilityOptions,
                          itemLabel: (item) => item,
                          prefixIcon: Icons.schedule_outlined,
                          onChanged: (val) =>
                              setState(() => _selectedAvailabilityId = val),
                        ),
                        AppSizes.vGapMd,
                        AppLocationField(
                          controller: _location,
                          label: 'Location',
                          hint: 'Search and select location',
                          validator: (value) =>
                              value?.trim().isEmpty == true ? 'Required' : null,
                        ),
                        AppSizes.vGapMd,
                        if (_loadingSkills)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          SignupMultiSelectSheet(
                            label: 'Skills',
                            minSelection: 0,
                            selectedItems: _selectedSkillNames,
                            availableOptions: _availableSkillNames,
                            onChanged: (items) {
                              setState(() => _selectedSkillNames = items);
                            },
                          ),
                      ],
                    ),
                  ),
                  AppSizes.vGapMd,
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      final snapshot = _SnapshotCard(
                        completion: _completion(),
                        rating: 4.33,
                        reviews: 0,
                        location: _location.text.trim(),
                        rate: _rate,
                        saving: _saving,
                        onSave: _save,
                      );
                      final distribution = _SkillDistributionCard(
                        skills: _selectedSkillNames,
                      );
                      if (!wide) {
                        return Column(
                          children: [distribution, AppSizes.vGapMd, snapshot],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: distribution),
                          AppSizes.hGapMd,
                          Expanded(flex: 3, child: snapshot),
                        ],
                      );
                    },
                  ),
                  AppSizes.vGapXl,
                ],
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.completion});

  final int completion;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return AppCard(
      radius: AppSizes.radiusMd,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          AppAvatar(
            name: user?.fullName ?? 'Freelancer',
            imageUrl: user?.avatarUrl,
            size: 48,
            showOnline: true,
            isOnline: true,
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marketplace profile',
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Professional details',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'These fields power how clients find and hire you.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$completion%',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppSizes.vGapXs,
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    minHeight: 8,
                    backgroundColor: context.theme.dividerColor,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillDistributionCard extends StatelessWidget {
  const _SkillDistributionCard({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final displaySkills = skills.isEmpty
        ? const ['Profile setup']
        : skills.take(4).toList();

    return AppCard(
      radius: AppSizes.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specialization breakdown',
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Estimated marketplace fit based on active skills',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSizes.vGapMd,
          for (final skill in displaySkills) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(skill, style: context.text.bodyMedium),
                Text(
                  'Primary',
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            AppSizes.vGapXs,
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(
                value: 0.85,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            AppSizes.vGapSm,
          ],
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.completion,
    required this.rating,
    required this.reviews,
    required this.location,
    required this.rate,
    required this.saving,
    required this.onSave,
  });

  final int completion;
  final double rating;
  final int reviews;
  final String location;
  final double rate;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppSizes.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile snapshot',
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppSizes.vGapMd,
          _MetricRow(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Profile completion',
            value: '$completion%',
          ),
          _MetricRow(
            icon: Icons.star_rounded,
            label: 'Client rating',
            value: '$rating ($reviews)',
          ),
          _MetricRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: location.isEmpty ? 'Not set' : location,
          ),
          _MetricRow(
            icon: Icons.attach_money_rounded,
            label: 'Hourly rate',
            value: rate > 0 ? '\$${rate.toStringAsFixed(2)}/hr' : 'Not set',
          ),
          AppSizes.vGapMd,
          AppPrimaryButton(
            label: 'Save changes',
            isLoading: saving,
            onPressed: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          AppSizes.hGapSm,
          Expanded(child: Text(label, style: context.text.bodyMedium)),
          Text(
            value,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
