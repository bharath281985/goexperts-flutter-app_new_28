import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../domain/entities/resume_template.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerResumeTemplatesPage extends StatefulWidget {
  const FreelancerResumeTemplatesPage({super.key});

  @override
  State<FreelancerResumeTemplatesPage> createState() =>
      _FreelancerResumeTemplatesPageState();
}

class _FreelancerResumeTemplatesPageState
    extends State<FreelancerResumeTemplatesPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _loading = true;
  List<ResumeTemplate> _templates = [];

  FreelancerProfileRepository get _repo =>
      sl<FreelancerProfileRepository>();

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _fetchTemplates(query);
    });
  }

  Future<void> _fetchTemplates([String? query]) async {
    setState(() => _loading = true);
    final search = query ?? _searchController.text.trim();
    final res = await _repo.getResumeTemplates(search: search);
    if (!mounted) return;

    res.fold(
      (f) {
        context.showSnack(f.message, isError: true);
        setState(() {
          _templates = [];
          _loading = false;
        });
      },
      (data) {
        setState(() {
          _templates = data;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Resume Templates'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.sm,
              AppSizes.screenPadding,
              AppSizes.sm,
            ),
            child: AppTextField(
              controller: _searchController,
              hint: 'Search templates...',
              prefixIcon: Icons.search_rounded,
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _templates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.find_in_page_outlined,
                              size: 64,
                              color: AppColors.mutedText,
                            ),
                            AppSizes.vGapMd,
                            Text(
                              'No templates found',
                              style: context.text.titleMedium?.copyWith(
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchTemplates(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSizes.screenPadding),
                          itemCount: _templates.length,
                          separatorBuilder: (_, __) => AppSizes.vGapLg,
                          itemBuilder: (ctx, idx) {
                            final template = _templates[idx];
                            return _TemplateCard(template: template);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final ResumeTemplate template;

  @override
  Widget build(BuildContext context) {
    final hasThumbnail =
        template.thumbnail != null && template.thumbnail!.trim().isNotEmpty;

    return AppCard(
      radius: AppSizes.radiusLg,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Container
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Center(
              child: hasThumbnail
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: Image.network(
                        template.thumbnail!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                      ),
                    )
                  : _buildFallbackIcon(),
            ),
          ),
          AppSizes.vGapMd,

          // ATS Friendly Badge
          if (template.atsFriendly) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ATS Friendly',
                style: context.text.labelSmall?.copyWith(
                  color: const Color(0xFF0F9755),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppSizes.vGapSm,
          ],

          // Name
          Text(
            template.name,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppSizes.vGapXs,

          // Description
          Text(
            template.description,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          AppSizes.vGapLg,

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.showSnack('Previewing ${template.name}');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: const Text('Preview'),
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.showSnack('Selected template: ${template.name}');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: const Text('Use Template'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.description_outlined,
          color: AppColors.danger,
          size: 54,
        ),
      ),
    );
  }
}
