import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/dependency_injection/service_locator.dart';
import '../../features/master_data/domain/entities/skill_category.dart';
import '../../features/master_data/domain/entities/skill_option.dart';
import '../../features/master_data/domain/repositories/master_data_repository.dart';
import '../extensions/context_extensions.dart';

/// Loads industries/categories/skills from the catalog API.
class CategorySkillsPicker extends StatefulWidget {
  const CategorySkillsPicker({
    super.key,
    this.selectedIndustryId,
    required this.selectedCategoryId,
    required this.selectedSkillIds,
    this.onIndustryChanged,
    required this.onCategoryChanged,
    required this.onSkillsChanged,
    this.onSkillOptionsLoaded,
    this.industryLabel = 'Industry',
    this.industrySubtitle,
    this.categoryLabel = 'Category',
    this.categorySubtitle,
    this.skillsLabel = 'Skills',
    this.skillsSubtitle,
    this.initialSkillsVisible = 10,
    this.clearSkillsOnCategoryChange = true,
    this.industryError,
    this.categoryError,
    this.skillsError,
  });

  final String? selectedIndustryId;
  final String? selectedCategoryId;
  final Set<String> selectedSkillIds;

  final void Function(String? industryId, String industryName)?
  onIndustryChanged;
  final void Function(String? categoryId, String categoryName)
  onCategoryChanged;
  final ValueChanged<Set<String>> onSkillsChanged;
  final void Function(List<SkillOption> skills)? onSkillOptionsLoaded;

  final String industryLabel;
  final String? industrySubtitle;
  final String categoryLabel;
  final String? categorySubtitle;
  final String skillsLabel;
  final String? skillsSubtitle;
  final int initialSkillsVisible;
  final bool clearSkillsOnCategoryChange;
  final String? industryError;
  final String? categoryError;
  final String? skillsError;

  @override
  State<CategorySkillsPicker> createState() => _CategorySkillsPickerState();
}

class _CategorySkillsPickerState extends State<CategorySkillsPicker> {
  final Map<String, List<SkillCategory>> _categoriesByIndustryId = {};
  final Map<String, List<SkillOption>> _skillsByCategoryId = {};

  bool _loadingIndustries = true;
  bool _loadingCategories = false;
  bool _loadingSkills = false;
  bool _skillsExpanded = false;

  String? _industryLoadError;
  String? _categoryLoadError;
  String? _skillsLoadError;

  List<SkillCategory> _industries = [];
  List<SkillCategory> _visibleCategories = [];
  List<SkillOption> _visibleSkills = [];

  String? _currentIndustryId;
  String? _currentCategoryId;

  @override
  void initState() {
    super.initState();
    _currentIndustryId = widget.selectedIndustryId;
    _currentCategoryId = widget.selectedCategoryId;
    _loadIndustries();
  }

  @override
  void didUpdateWidget(CategorySkillsPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndustryId != oldWidget.selectedIndustryId) {
      _currentIndustryId = widget.selectedIndustryId;
    }
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      _currentCategoryId = widget.selectedCategoryId;
      if (_currentCategoryId != null && _currentCategoryId!.isNotEmpty) {
        _loadSkillsForCategory(_currentCategoryId!, notifyCategory: false);
      }
    }
  }

  Future<void> _loadIndustries() async {
    setState(() {
      _loadingIndustries = true;
      _industryLoadError = null;
    });

    final repo = sl<MasterDataRepository>();
    final result = await repo.getIndustries();

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _loadingIndustries = false;
        _industryLoadError =
            result.failureOrNull?.message ?? 'Failed to load industries';
      });
      return;
    }

    final industries = result.valueOrNull ?? [];
    setState(() {
      _industries = industries;
      _loadingIndustries = false;
      if (industries.isEmpty) {
        _industryLoadError = 'No industries available';
      }
    });

    if (_currentIndustryId != null &&
        industries.any((i) => i.id == _currentIndustryId)) {
      await _loadCategoriesForIndustry(
        _currentIndustryId!,
        notifyIndustry: false,
      );
    } else if (_currentCategoryId != null && _currentCategoryId!.isNotEmpty) {
      final catsRes = await repo.getSkillCategories(
        page: 1,
        pageSize: 1000,
        search: '',
      );
      if (catsRes.isSuccess && mounted) {
        final cats = catsRes.valueOrNull ?? [];
        final matched = cats.cast<SkillCategory?>().firstWhere(
          (c) => c?.id == _currentCategoryId,
          orElse: () => null,
        );
        if (matched != null && matched.industryId != null) {
          _currentIndustryId = matched.industryId;
          await _loadCategoriesForIndustry(
            _currentIndustryId!,
            notifyIndustry: true,
          );
        }
      }
    }
  }

  Future<void> _loadCategoriesForIndustry(
    String industryId, {
    bool notifyIndustry = true,
  }) async {
    if (_categoriesByIndustryId.containsKey(industryId)) {
      setState(() {
        _visibleCategories = _categoriesByIndustryId[industryId] ?? [];
        _visibleSkills = [];
      });
      if (notifyIndustry) {
        final name = _industryName(industryId);
        widget.onIndustryChanged?.call(industryId, name);
      }
      return;
    }

    setState(() {
      _loadingCategories = true;
      _categoryLoadError = null;
      _currentCategoryId = null;
      _visibleSkills = [];
    });

    if (notifyIndustry) {
      final name = _industryName(industryId);
      widget.onIndustryChanged?.call(industryId, name);
    }

    final repo = sl<MasterDataRepository>();
    final result = await repo.getSkillCategories(
      industryId: industryId,
      page: 1,
      pageSize: 200,
      search: '',
    );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _loadingCategories = false;
        _categoryLoadError =
            result.failureOrNull?.message ?? 'Failed to load categories';
      });
      return;
    }

    final categories = result.valueOrNull ?? [];
    setState(() {
      _categoriesByIndustryId[industryId] = categories;
      _visibleCategories = categories;
      _loadingCategories = false;
    });
  }

  Future<void> _loadSkillsForCategory(
    String categoryId, {
    bool notifyCategory = true,
  }) async {
    if (_skillsByCategoryId.containsKey(categoryId)) {
      setState(() {
        _visibleSkills = _skillsByCategoryId[categoryId] ?? [];
        _skillsExpanded = false;
      });
      if (notifyCategory) {
        final name = _categoryName(categoryId);
        widget.onCategoryChanged(categoryId, name);
      }
      return;
    }

    setState(() {
      _loadingSkills = true;
      _skillsLoadError = null;
      _skillsExpanded = false;
    });

    if (notifyCategory) {
      widget.onCategoryChanged(categoryId, _categoryName(categoryId));
    }

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
          _skillsLoadError =
              result.failureOrNull?.message ?? 'Failed to load skills';
        });
        return;
      }

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

    widget.onSkillOptionsLoaded?.call(allSkills);

    setState(() {
      _skillsByCategoryId[categoryId] = allSkills;
      _visibleSkills = allSkills;
      _loadingSkills = false;
    });
  }

  String _industryName(String id) {
    for (final industry in _industries) {
      if (industry.id == id) return industry.name;
    }
    return '';
  }

  String _categoryName(String categoryId) {
    for (final category in _visibleCategories) {
      if (category.id == categoryId) return category.name;
    }
    return '';
  }

  void _onIndustrySelected(String id) {
    if (id == _currentIndustryId) return;
    setState(() {
      _currentIndustryId = id;
    });

    if (widget.clearSkillsOnCategoryChange) {
      widget.onCategoryChanged('', '');
      widget.onSkillsChanged({});
    }

    _loadCategoriesForIndustry(id);
  }

  void _onCategorySelected(String categoryId) {
    if (categoryId == _currentCategoryId) return;
    setState(() {
      _currentCategoryId = categoryId;
    });

    if (widget.clearSkillsOnCategoryChange) {
      widget.onSkillsChanged({});
    }

    _loadSkillsForCategory(categoryId);
  }

  void _toggleSkill(String skillId) {
    final next = Set<String>.from(widget.selectedSkillIds);
    if (next.contains(skillId)) {
      next.remove(skillId);
    } else {
      next.add(skillId);
    }
    widget.onSkillsChanged(next);
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr(title), style: context.text.titleSmall),
        if (subtitle != null) ...[
          AppSizes.vGapXs,
          Text(context.tr(subtitle), style: context.text.bodySmall),
        ],
      ],
    );
  }

  Widget _buildIndustrySection() {
    if (_loadingIndustries) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_industryLoadError != null && _industries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(widget.industryLabel),
          AppSizes.vGapSm,
          Text(
            _industryLoadError!,
            style: context.text.bodyMedium?.copyWith(color: AppColors.danger),
          ),
          TextButton(
            onPressed: _loadIndustries,
            child: Text(context.tr('Retry')),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          widget.industryLabel,
          subtitle: widget.industrySubtitle,
        ),
        AppSizes.vGapMd,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final industry in _industries)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm),
                  child: ChoiceChip(
                    label: Text(industry.name),
                    selected: industry.id == _currentIndustryId,
                    showCheckmark: false,
                    onSelected: (_) => _onIndustrySelected(industry.id),
                  ),
                ),
            ],
          ),
        ),
        if (widget.industryError != null) ...[
          AppSizes.vGapXs,
          Text(
            widget.industryError!,
            style: context.text.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_loadingIndustries) return const SizedBox.shrink();
    if (_currentIndustryId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSizes.vGapLg,
          _buildSectionTitle(
            widget.categoryLabel,
            subtitle: 'Choose an industry first',
          ),
        ],
      );
    }

    if (_loadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categoryLoadError != null && _visibleCategories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSizes.vGapLg,
          _buildSectionTitle(widget.categoryLabel),
          AppSizes.vGapSm,
          Text(
            _categoryLoadError!,
            style: context.text.bodyMedium?.copyWith(color: AppColors.danger),
          ),
          TextButton(
            onPressed: () => _loadCategoriesForIndustry(_currentIndustryId!),
            child: Text(context.tr('Retry')),
          ),
        ],
      );
    }

    if (_visibleCategories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSizes.vGapLg,
          _buildSectionTitle(widget.categoryLabel),
          AppSizes.vGapSm,
          Text('No categories available', style: context.text.bodyMedium),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSizes.vGapLg,
        _buildSectionTitle(
          widget.categoryLabel,
          subtitle: widget.categorySubtitle,
        ),
        AppSizes.vGapMd,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in _visibleCategories)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: category.id == _currentCategoryId,
                    showCheckmark: false,
                    onSelected: (_) => _onCategorySelected(category.id),
                  ),
                ),
            ],
          ),
        ),
        if (widget.categoryError != null) ...[
          AppSizes.vGapXs,
          Text(
            widget.categoryError!,
            style: context.text.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _buildSkillChip(SkillOption skill) {
    final isSelected = widget.selectedSkillIds.contains(skill.id);
    return FilterChip(
      label: Text(skill.name),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => _toggleSkill(skill.id),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: isSelected ? AppColors.primary : context.theme.dividerColor,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : context.text.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildSkillsSection() {
    if (_loadingCategories) return const SizedBox.shrink();

    if (_currentCategoryId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSizes.vGapLg,
          _buildSectionTitle(
            widget.skillsLabel,
            subtitle: widget.skillsSubtitle ?? 'Choose a category first',
          ),
        ],
      );
    }

    final categoryName = _categoryName(_currentCategoryId!) == ''
        ? 'this category'
        : _categoryName(_currentCategoryId!);
    final shouldLimit =
        _visibleSkills.length > widget.initialSkillsVisible && !_skillsExpanded;
    final skillsToShow = shouldLimit
        ? _visibleSkills.take(widget.initialSkillsVisible).toList()
        : _visibleSkills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSizes.vGapLg,
        _buildSectionTitle(widget.skillsLabel, subtitle: widget.skillsSubtitle),
        if (widget.selectedSkillIds.isNotEmpty) ...[
          AppSizes.vGapSm,
          Text(
            context
                .tr('{count} selected')
                .replaceFirst('{count}', '${widget.selectedSkillIds.length}'),
            style: context.text.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ],
        if (widget.skillsError != null) ...[
          AppSizes.vGapSm,
          Text(
            widget.skillsError!,
            style: context.text.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ],
        AppSizes.vGapMd,
        if (_loadingSkills)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.md),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (_skillsLoadError != null && _visibleSkills.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _skillsLoadError!,
                style: context.text.bodyMedium?.copyWith(
                  color: AppColors.danger,
                ),
              ),
              TextButton(
                onPressed: () => _loadSkillsForCategory(_currentCategoryId!),
                child: Text(context.tr('Retry')),
              ),
            ],
          )
        else if (_visibleSkills.isEmpty)
          Text(
            context
                .tr('No skills found for {category}')
                .replaceFirst('{category}', categoryName),
            style: context.text.bodyMedium,
          )
        else ...[
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              for (final skill in skillsToShow) _buildSkillChip(skill),
            ],
          ),
          if (_visibleSkills.length > widget.initialSkillsVisible) ...[
            AppSizes.vGapSm,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    setState(() => _skillsExpanded = !_skillsExpanded),
                child: Text(_skillsExpanded ? 'Show less' : 'Show more'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIndustrySection(),
        _buildCategorySection(),
        _buildSkillsSection(),
      ],
    );
  }
}
