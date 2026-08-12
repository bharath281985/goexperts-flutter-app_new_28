import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/profile_avatar_editor.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/freelancer_profile.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerEditProfilePage extends StatefulWidget {
  const FreelancerEditProfilePage({super.key});

  @override
  State<FreelancerEditProfilePage> createState() =>
      _FreelancerEditProfilePageState();
}

class _FreelancerEditProfilePageState extends State<FreelancerEditProfilePage> {
  // Controllers
  final _bio = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _skillsRaw = TextEditingController(); // "skill1, skill2"
  final _experience = TextEditingController();
  final _education = TextEditingController();
  final _languages = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _phoneCode = TextEditingController(text: '+91');
  final _countryCode = TextEditingController(text: 'IN');
  final _experienceYears = TextEditingController();
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();
  final _github = TextEditingController();
  final _portfolio = TextEditingController();
  final _linkedin = TextEditingController();
  final _website = TextEditingController();
  final _panNumber = TextEditingController();
  final _aadhaarNumber = TextEditingController();

  // Availability options
  static const _availabilityOptions = [
    'available',
    'part-time',
    'not-available',
  ];
  String _availability = 'available';

  // State
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  FreelancerProfile? _profile;
  String? _localAvatarPath;
  String? _currentAvatarUrl;
  String? _currentResumeUrl;
  String? _pendingResumePath; // staged resume, uploaded on Save

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bio.dispose();
    _hourlyRate.dispose();
    _skillsRaw.dispose();
    _experience.dispose();
    _education.dispose();
    _languages.dispose();
    _fullName.dispose();
    _phone.dispose();
    _phoneCode.dispose();
    _countryCode.dispose();
    _experienceYears.dispose();
    _title.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _github.dispose();
    _portfolio.dispose();
    _linkedin.dispose();
    _website.dispose();
    _panNumber.dispose();
    _aadhaarNumber.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final res = await sl<FreelancerProfileRepository>().getProfile();
    if (!mounted) return;
    res.fold((f) => context.showSnack(f.message), (p) {
      _profile = p;
      _currentAvatarUrl = p.avatarUrl;
      _currentResumeUrl = p.resumeUrl;
      _bio.text = p.bio;
      _hourlyRate.text = p.hourlyRate > 0
          ? p.hourlyRate.toStringAsFixed(0)
          : '';
      _skillsRaw.text = p.skills.join(', ');
      _experience.text = p.experience;
      _education.text = p.education;
      _languages.text = p.languages.join(', ');

      _fullName.text = p.fullName;
      _phone.text = p.phone;
      _phoneCode.text = p.phoneCode.isEmpty ? '+91' : p.phoneCode;
      _countryCode.text = p.countryCode.isEmpty ? 'IN' : p.countryCode;
      _experienceYears.text = p.experienceYears > 0
          ? p.experienceYears.toString()
          : p.experience;
      _title.text = p.title;
      _city.text = p.city;
      _state.text = p.state;
      _country.text = p.country;
      _github.text = p.githubUrl;
      _portfolio.text = p.portfolioUrl;
      _linkedin.text = p.linkedin;
      _website.text = p.website;
      _panNumber.text = p.panNumber;
      _aadhaarNumber.text = p.aadhaarNumber;

      if (_availabilityOptions.contains(p.availability)) {
        _availability = p.availability;
      }
    });
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_fullName.text.trim().isEmpty) {
      context.showSnack('Full name is required', isError: true);
      return;
    }
    setState(() => _saving = true);

    // Upload pending resume first
    if (_pendingResumePath != null) {
      final uploadRes = await sl<FreelancerProfileRepository>().uploadResume(
        _pendingResumePath!,
      );
      if (!mounted) return;
      uploadRes.fold(
        (f) => context.showSnack(
          'Resume upload failed: ${f.message}',
          isError: true,
        ),
        (url) {
          _pendingResumePath = null;
          _currentResumeUrl = url;
        },
      );
    }

    // Notice we do NOT send _localAvatarPath here if it was a File path.
    // The avatar URL is exclusively from _currentAvatarUrl after it uploads.
    final payload = {
      // ── Personal ──────────────────────────────────────────────────────────
      'fullName': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'phoneCode': _phoneCode.text.trim(),
      'countryCode': _countryCode.text.trim(),
      'bio': _bio.text.trim(),
      'title': _title.text.trim(),
      // ── Location ──────────────────────────────────────────────────────────
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'country': _country.text.trim(),
      // ── Work ──────────────────────────────────────────────────────────────
      'availability': _availability,
      'hourlyRate': double.tryParse(_hourlyRate.text.trim()) ?? 0.0,
      'skills': _skillsRaw.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'languages': _languages.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'education': _education.text.trim(),
      'experience': _experienceYears.text.trim(),
      // ── Social & Links ────────────────────────────────────────────────────
      'githubUrl': _github.text.trim(),
      'portfolioUrl': _portfolio.text.trim(),
      'linkedin': _linkedin.text.trim(),
      'website': _website.text.trim(),
      // ── KYC ───────────────────────────────────────────────────────────────
      'panNumber': _panNumber.text.trim(),
      'aadhaarNumber': _aadhaarNumber.text.trim(),
      // ── Avatar & Resume ───────────────────────────────────────────────────
      if (_currentAvatarUrl != null) 'avatarUrl': _currentAvatarUrl,
      if (_currentAvatarUrl != null) 'avatar': _currentAvatarUrl,
      if (_currentResumeUrl != null) 'resumeUrl': _currentResumeUrl,
      if (_currentResumeUrl != null) 'resume': _currentResumeUrl,
    };

    final res = await sl<FreelancerProfileRepository>().updateProfile(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold((f) => context.showSnack(f.message), (_) {
      context.showSnack('Profile updated successfully!');
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
    res.fold((f) => context.showSnack(f.message), (url) async {
      setState(() {
        _localAvatarPath = null;
        _currentAvatarUrl = url;
      });
      context.read<AuthBloc>().add(const AuthRefreshUser());
      context.showSnack('Avatar updated!');
      await _load();
    });
  }

  Future<void> _pickResume() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _pendingResumePath = path);
    context.showSnack('Resume selected — tap Save to upload.');
  }

  Future<void> _openResumeUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) context.showSnack('Unable to open resume', isError: true);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  int _completionPercent() {
    final checks = [
      _bio.text.trim().isNotEmpty,
      _hourlyRate.text.trim().isNotEmpty,
      _skillsRaw.text.trim().isNotEmpty,
      _experience.text.trim().isNotEmpty,
      _education.text.trim().isNotEmpty,
      _languages.text.trim().isNotEmpty,
      _fullName.text.trim().isNotEmpty,
      _title.text.trim().isNotEmpty,
      _city.text.trim().isNotEmpty,
      _panNumber.text.trim().isNotEmpty,
      _aadhaarNumber.text.trim().isNotEmpty,
      (_localAvatarPath ?? _profile?.avatarUrl ?? '').isNotEmpty,
      (_profile?.resumeUrl?.isNotEmpty == true || _pendingResumePath != null),
    ];
    final filled = checks.where((c) => c).length;
    return ((filled / checks.length) * 100).round();
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(
          onTap: () => Navigator.of(context).maybePop(),
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Completion banner ───────────────────────────────────────
                  _CompletionCard(percent: _completionPercent()),
                  AppSizes.vGapLg,

                  // ── Avatar ─────────────────────────────────────────────────
                  _SectionLabel('Profile Photo'),
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
                            decoration: BoxDecoration(
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

                  _SectionLabel('About You'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _fullName,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _title,
                    label: 'Professional Title',
                    hint: 'e.g. Senior Flutter Developer',
                  ),
                  AppSizes.vGapMd,
                  Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: AppTextField(
                          controller: _phoneCode,
                          label: 'Code',
                          hint: '+91',
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: AppTextField(
                          controller: _phone,
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  AppSizes.vGapLg,

                  _SectionLabel('Location'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _city,
                    label: 'City',
                    hint: 'e.g. Hyderabad',
                  ),
                  AppSizes.vGapMd,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: AppTextField(
                          controller: _countryCode,
                          label: 'Country Code',
                          hint: 'IN',
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: AppTextField(
                          controller: _country,
                          label: 'Country',
                          hint: 'India',
                        ),
                      ),
                    ],
                  ),
                  AppSizes.vGapLg,

                  // ── Bio ────────────────────────────────────────────────────
                  _SectionLabel('Professional Bio'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _bio,
                    label: 'Bio',
                    hint:
                        'Tell clients about yourself, your expertise, and what makes you unique…',
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                  ),
                  AppSizes.vGapLg,

                  // ── Availability & Rate ─────────────────────────────────────
                  _SectionLabel('Work Preferences'),
                  AppSizes.vGapSm,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _hourlyRate,
                          label: 'Hourly Rate (₹)',
                          hint: 'e.g. 1500',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Availability',
                              style: context.text.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AppSizes.vGapXs,
                            AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                              ),
                              child: DropdownButton<String>(
                                value: _availability,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'available',
                                    child: Text('Available'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'part-time',
                                    child: Text('Part-Time'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'not-available',
                                    child: Text('Not Available'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _availability = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSizes.vGapLg,

                  // ── Skills ─────────────────────────────────────────────────
                  _SectionLabel('Skills'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _skillsRaw,
                    label: 'Skills',
                    hint: 'Flutter, Python, UI/UX, Node.js…',
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  AppSizes.vGapXs,
                  Text(
                    'Separate skills with commas',
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (_skillsRaw.text.trim().isNotEmpty) ...[
                    AppSizes.vGapSm,
                    _ChipsPreview(raw: _skillsRaw.text),
                  ],
                  AppSizes.vGapLg,

                  // ── Languages ──────────────────────────────────────────────
                  _SectionLabel('Languages'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _languages,
                    label: 'Languages',
                    hint: 'English, Hindi, Tamil…',
                    textInputAction: TextInputAction.next,
                  ),
                  AppSizes.vGapXs,
                  Text(
                    'Separate with commas',
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSizes.vGapLg,

                  // ── Experience ─────────────────────────────────────────────
                  _SectionLabel('Experience'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _experienceYears,
                    label: 'Years of experience',
                    hint: 'Senior Dev at TechCorp, Freelance Flutter Dev…',
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                  ),
                  AppSizes.vGapXs,
                  Text(
                    'Separate entries with commas',
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSizes.vGapLg,

                  // ── Education ──────────────────────────────────────────────
                  _SectionLabel('Education'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _education,
                    label: 'Education',
                    hint: 'B.Tech Computer Science - NIT…',
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                  ),
                  AppSizes.vGapXs,
                  Text(
                    'Separate entries with commas',
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSizes.vGapLg,

                  // ── Resume ─────────────────────────────────────────────────
                  _SectionLabel('Resume / CV'),
                  AppSizes.vGapSm,
                  _ResumeCard(
                    networkUrl: _currentResumeUrl,
                    pendingPath: _pendingResumePath,
                    onPick: _pickResume,
                    onOpenUrl: _openResumeUrl,
                    onRemovePending: () =>
                        setState(() => _pendingResumePath = null),
                  ),
                  AppSizes.vGapLg,
                  _SectionLabel('Social & Links'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _github,
                    label: 'GitHub URL',
                    hint: 'https://github.com/...',
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _portfolio,
                    label: 'Portfolio URL',
                    hint: 'https://...',
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _linkedin,
                    label: 'LinkedIn Profile',
                    hint: 'LinkedIn URL',
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _website,
                    label: 'Website',
                    hint: 'Personal website URL',
                  ),
                  AppSizes.vGapLg,

                  _SectionLabel('KYC Documents'),
                  AppSizes.vGapSm,
                  AppTextField(
                    controller: _panNumber,
                    label: 'PAN Number',
                    maxLength: 10,
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _aadhaarNumber,
                    label: 'Aadhaar Number',
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                  ),
                  AppSizes.vGapXl,

                  // ── Save button ────────────────────────────────────────────
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

class _ChipsPreview extends StatelessWidget {
  const _ChipsPreview({required this.raw});
  final String raw;

  @override
  Widget build(BuildContext context) {
    final items = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSizes.xs,
      runSpacing: AppSizes.xs,
      children: [
        for (final item in items)
          Chip(
            label: Text(item),
            labelStyle: context.text.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.networkUrl,
    required this.pendingPath,
    required this.onPick,
    required this.onOpenUrl,
    required this.onRemovePending,
  });

  final String? networkUrl;
  final String? pendingPath;
  final VoidCallback onPick;
  final void Function(String url) onOpenUrl;
  final VoidCallback onRemovePending;

  String get _pendingFileName {
    if (pendingPath == null) return '';
    return pendingPath!.split(RegExp(r'[\\/]')).last;
  }

  String get _networkFileName {
    if (networkUrl == null || networkUrl!.isEmpty) return '';
    final raw = networkUrl!.split('?').first;
    return raw.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasNetwork = networkUrl != null && networkUrl!.isNotEmpty;
    final hasPending = pendingPath != null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: hasNetwork || hasPending
                      ? AppColors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending
                          ? 'New resume selected'
                          : hasNetwork
                          ? 'Resume uploaded'
                          : 'No resume uploaded yet',
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasPending)
                      Text(
                        _pendingFileName,
                        style: context.text.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (hasNetwork)
                      GestureDetector(
                        onTap: () => onOpenUrl(networkUrl!),
                        child: Text(
                          _networkFileName.isNotEmpty
                              ? _networkFileName
                              : 'View Resume',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        'PDF, DOC, DOCX accepted',
                        style: context.text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              AppSizes.hGapSm,
              if (hasPending)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.danger,
                  tooltip: 'Remove selection',
                  onPressed: onRemovePending,
                ),
              AppPrimaryButton(
                label: hasPending
                    ? 'Change'
                    : (hasNetwork ? 'Replace' : 'Upload'),
                icon: Icons.upload_rounded,
                onPressed: onPick,
                expanded: false,
              ),
            ],
          ),
          if (hasPending) ...[
            AppSizes.vGapXs,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This resume will be uploaded when you tap "Save Profile"',
                      style: context.text.labelSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
