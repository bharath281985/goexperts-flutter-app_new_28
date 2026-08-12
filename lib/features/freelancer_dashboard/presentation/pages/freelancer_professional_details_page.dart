import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerProfessionalDetailsPage extends StatefulWidget {
  const FreelancerProfessionalDetailsPage({super.key});

  @override
  State<FreelancerProfessionalDetailsPage> createState() =>
      _FreelancerProfessionalDetailsPageState();
}

class _FreelancerProfessionalDetailsPageState
    extends State<FreelancerProfessionalDetailsPage> {
  static const _experienceLevels = ['Entry Level', 'Intermediate', 'Expert'];

  static const _availabilityOptions = [
    'Available for work',
    'Part-time availability',
    'Booked this month',
    'Not available',
  ];

  final _formKey = GlobalKey<FormState>();
  final _category = TextEditingController(text: 'Cyber Security');
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _location = TextEditingController();
  final _skills = TextEditingController();

  String _experienceLevel = _experienceLevels.first;
  String _availability = _availabilityOptions.first;
  SelectedPlace? _selectedPlace;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _skills.addListener(_refreshSkillPreview);
    _load();
  }

  @override
  void dispose() {
    _category.dispose();
    _headline.dispose();
    _bio.dispose();
    _hourlyRate.dispose();
    _location.dispose();
    _skills
      ..removeListener(_refreshSkillPreview)
      ..dispose();
    super.dispose();
  }

  void _refreshSkillPreview() => setState(() {});

  Future<void> _load() async {
    final authUser = context.read<AuthBloc>().state.user;
    _headline.text = authUser?.headline ?? '';
    _location.text = authUser?.location ?? '';

    final res = await sl<FreelancerProfileRepository>().getProfile();
    if (!mounted) return;

    res.fold((f) => context.showSnack(f.message, isError: true), (profile) {
      _bio.text = profile.bio;
      _hourlyRate.text = profile.hourlyRate > 0
          ? profile.hourlyRate.toStringAsFixed(2)
          : '';
      _skills.text = profile.skills.join(', ');
      _availability = _availabilityFromApi(profile.availability);
    });

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final skills = _skillList();
    final locationText = _location.text.trim();
    final payload = {
      'category': _category.text.trim(),
      'primaryCategory': _category.text.trim(),
      'headline': _headline.text.trim(),
      'bio': _bio.text.trim(),
      'hourlyRate': double.tryParse(_hourlyRate.text.trim()) ?? 0,
      'experienceLevel': _experienceLevel,
      'availability': _availabilityToApi(_availability),
      'location': locationText,
      'city': locationText,
      'skills': skills,
      if (_selectedPlace != null) ...{
        'googlePlaceId': _selectedPlace!.placeId,
        'latitude': _selectedPlace!.latitude,
        'longitude': _selectedPlace!.longitude,
      },
    };

    final res = await sl<FreelancerProfileRepository>().updateProfile(payload);
    if (!mounted) return;

    setState(() => _saving = false);
    res.fold((f) => context.showSnack(f.message, isError: true), (profile) {
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Professional details saved');
      setState(() {});
    });
  }

  String _availabilityFromApi(String value) {
    switch (value) {
      case 'available':
        return 'Available for work';
      case 'part-time':
        return 'Part-time availability';
      case 'booked':
        return 'Booked this month';
      case 'not-available':
        return 'Not available';
      default:
        return _availabilityOptions.first;
    }
  }

  String _availabilityToApi(String value) {
    switch (value) {
      case 'Available for work':
        return 'available';
      case 'Part-time availability':
        return 'part-time';
      case 'Booked this month':
        return 'booked';
      case 'Not available':
        return 'not-available';
      default:
        return 'available';
    }
  }

  List<String> _skillList() => _skills.text
      .split(',')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

  int _completion() {
    final checks = [
      _category.text.trim().isNotEmpty,
      _experienceLevel.isNotEmpty,
      _headline.text.trim().isNotEmpty,
      _bio.text.trim().isNotEmpty,
      _hourlyRate.text.trim().isNotEmpty,
      _availability.isNotEmpty,
      _location.text.trim().isNotEmpty,
      _skillList().isNotEmpty,
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
        leading: IconTapWidget(
          onTap: () => Navigator.of(context).maybePop(),
        ),
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
                    child: _CategoryFocusForm(
                      category: _category,
                      headline: _headline,
                      bio: _bio,
                      hourlyRate: _hourlyRate,
                      location: _location,
                      skills: _skills,
                      experienceLevel: _experienceLevel,
                      availability: _availability,
                      experienceLevels: _experienceLevels,
                      availabilityOptions: _availabilityOptions,
                      onExperienceChanged: (value) =>
                          setState(() => _experienceLevel = value!),
                      onAvailabilityChanged: (value) =>
                          setState(() => _availability = value!),
                      onPlaceSelected: (place) =>
                          setState(() => _selectedPlace = place),
                      onRateChanged: (_) => setState(() {}),
                      skillList: _skillList(),
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
                        skills: _skillList(),
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

class _CategoryFocusForm extends StatelessWidget {
  const _CategoryFocusForm({
    required this.category,
    required this.headline,
    required this.bio,
    required this.hourlyRate,
    required this.location,
    required this.skills,
    required this.experienceLevel,
    required this.availability,
    required this.experienceLevels,
    required this.availabilityOptions,
    required this.onExperienceChanged,
    required this.onAvailabilityChanged,
    required this.onPlaceSelected,
    required this.onRateChanged,
    required this.skillList,
  });

  final TextEditingController category;
  final TextEditingController headline;
  final TextEditingController bio;
  final TextEditingController hourlyRate;
  final TextEditingController location;
  final TextEditingController skills;
  final String experienceLevel;
  final String availability;
  final List<String> experienceLevels;
  final List<String> availabilityOptions;
  final ValueChanged<String?> onExperienceChanged;
  final ValueChanged<String?> onAvailabilityChanged;
  final ValueChanged<SelectedPlace> onPlaceSelected;
  final ValueChanged<String> onRateChanged;
  final List<String> skillList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category & focus',
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          'Where you show up in the marketplace',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        AppSizes.vGapMd,
        AppTextField(
          controller: category,
          label: 'Primary category / title',
          hint: 'e.g. Cyber Security',
          prefixIcon: Icons.layers_outlined,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Required' : null,
        ),
        AppDropdown<String>(
          label: 'Experience level',
          value: experienceLevel,
          items: experienceLevels,
          itemLabel: (item) => item,
          prefixIcon: Icons.badge_outlined,
          onChanged: onExperienceChanged,
        ),
        AppSizes.vGapMd,
        AppTextField(
          controller: headline,
          label: 'Headline',
          hint: 'Short pitch clients see first',
          prefixIcon: Icons.auto_awesome_outlined,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Required' : null,
        ),
        AppSizes.vGapMd,
        AppTextField(
          controller: bio,
          label: 'About / bio',
          hint: 'Describe your expertise, industries, and delivery style',
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Required' : null,
        ),
        AppSizes.vGapMd,
        AppTextField(
          controller: hourlyRate,
          label: 'Hourly rate',
          hint: '7235.48',
          prefixIcon: Icons.attach_money_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textInputAction: TextInputAction.next,
          onChanged: onRateChanged,
          validator: (value) {
            final rate = double.tryParse(value?.trim() ?? '');
            if (rate == null || rate <= 0) return 'Enter a valid rate';
            return null;
          },
        ),
        AppDropdown<String>(
          label: 'Availability',
          value: availability,
          items: availabilityOptions,
          itemLabel: (item) => item,
          prefixIcon: Icons.schedule_outlined,
          onChanged: onAvailabilityChanged,
        ),
        AppSizes.vGapMd,
        AppLocationField(
          controller: location,
          label: 'Location',
          hint: 'City, Country',
          onPlaceSelected: onPlaceSelected,
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Required' : null,
        ),
        AppSizes.vGapMd,
        AppTextField(
          controller: skills,
          label: 'Skills (comma-separated)',
          hint: 'NodeJs, Figma, Flutter, Java',
          maxLines: 3,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Add at least one skill' : null,
        ),
        if (skillList.isNotEmpty) ...[
          AppSizes.vGapSm,
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xs,
            children: [
              for (final skill in skillList)
                Chip(
                  label: Text(skill),
                  labelStyle: context.text.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ],
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
        : skills.take(5).toList();
    return AppCard(
      radius: AppSizes.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill distribution',
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Preview based on your saved skills',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSizes.vGapMd,
          for (var i = 0; i < displaySkills.length; i++) ...[
            _SkillBar(
              label: displaySkills[i],
              value: skills.isEmpty ? 0.12 : (0.25 - (i * 0.02)).clamp(0.1, 1),
            ),
            if (i != displaySkills.length - 1) AppSizes.vGapSm,
          ],
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('$percent%', style: context.text.labelSmall),
          ],
        ),
        AppSizes.vGapXs,
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: context.theme.dividerColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
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
            'Snapshot',
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppSizes.vGapMd,
          _SnapshotRow(label: 'Profile completion', value: '$completion%'),
          _SnapshotRow(label: 'Job success', value: '$completion%'),
          _SnapshotRow(label: 'Rating', value: rating.toStringAsFixed(2)),
          _SnapshotRow(label: 'Reviews', value: '$reviews'),
          _SnapshotRow(
            label: 'Location',
            value: location.isEmpty ? '-' : location,
          ),
          _SnapshotRow(
            label: 'Rate',
            value: rate <= 0 ? '-' : '\$${rate.toStringAsFixed(2)}/hr',
          ),
          AppSizes.vGapMd,
          AppPrimaryButton(
            label: 'Save changes',
            icon: Icons.save_outlined,
            isLoading: saving,
            onPressed: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          AppSizes.hGapMd,
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
