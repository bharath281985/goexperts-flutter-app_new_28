import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/router/route_names.dart';
import '../extensions/context_extensions.dart';

class RecommendationTabConfig {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  final String? viewAllRoute;

  const RecommendationTabConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.accent,
    this.viewAllRoute,
  });
}

class DashboardRecommendationsSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<RecommendationTabConfig> tabs;
  final Map<String, List<Map<String, dynamic>>> items;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const DashboardRecommendationsSection({
    super.key,
    this.title = 'Recommended For You',
    this.subtitle = 'Curated opportunities tailored to your profile',
    required this.tabs,
    required this.items,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<DashboardRecommendationsSection> createState() =>
      _DashboardRecommendationsSectionState();
}

class _DashboardRecommendationsSectionState
    extends State<DashboardRecommendationsSection> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();

    final activeTab =
        widget.tabs[_activeTabIndex.clamp(0, widget.tabs.length - 1)];
    final tabItems = widget.items[activeTab.key] ?? const [];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildHeader(context, activeTab),
          const SizedBox(height: 12),

          // Segmented Pill Tabs
          _buildPillTabs(context),
          const SizedBox(height: 14),

          // Content List / Shimmer / Empty State
          if (widget.isLoading)
            _buildShimmerList(context, activeTab)
          else if (tabItems.isEmpty)
            _buildEmptyState(context, activeTab)
          else
            _buildItemsList(context, activeTab, tabItems),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RecommendationTabConfig activeTab,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: activeTab.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: activeTab.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color:
                          context.isDark ? Colors.white : AppColors.darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (activeTab.viewAllRoute != null)
          InkWell(
            onTap: () => context.push(activeTab.viewAllRoute!),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: activeTab.accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: activeTab.accent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPillTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.darkCard.withValues(alpha: 0.6)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDark
                ? AppColors.darkBorder
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: List.generate(widget.tabs.length, (index) {
            final tab = widget.tabs[index];
            final isSelected = _activeTabIndex == index;
            final count = (widget.items[tab.key] ?? []).length;

            return GestureDetector(
              onTap: () {
                if (_activeTabIndex != index) {
                  setState(() => _activeTabIndex = index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (context.isDark ? AppColors.darkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: tab.accent.withValues(alpha: 0.25),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: context.isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isSelected ? tab.accent : AppColors.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (context.isDark
                                ? Colors.white
                                : AppColors.darkText)
                            : AppColors.mutedText,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tab.accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? tab.accent : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    RecommendationTabConfig tab,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      children: items.take(5).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCard(context, tab, item),
        );
      }).toList(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    RecommendationTabConfig tab,
    Map<String, dynamic> item,
  ) {
    var title = (item['title']?.toString() ?? '').trim();
    final rawSubtitle = (item['subtitle']?.toString() ?? '').trim();
    final rawDescription = (item['description']?.toString() ?? '').trim();
    final subtitle = _sanitizeTag(rawSubtitle, _fallbackRole(tab.key));
    final description = _sanitizeDescription(rawDescription);

    if (title.isEmpty ||
        title.toLowerCase() == 'untitled' ||
        title.toLowerCase() == 'untitled project' ||
        title.toLowerCase() == 'project' ||
        title.toLowerCase() == 'startup idea') {
      if (tab.key == 'projects') {
        title = subtitle.isNotEmpty && subtitle != 'Project'
            ? '$subtitle Platform'
            : 'Web & Mobile App Project';
      } else if (tab.key == 'startups') {
        title = subtitle.isNotEmpty && subtitle != 'Startup'
            ? '$subtitle Venture'
            : 'Emerging Tech Startup';
      } else {
        title = _fallbackRole(tab.key);
      }
    }

    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'G';
    final isDark = context.isDark;

    // Optional metric pill (Budget or Funding)
    final budget = item['budget'];
    final funding = item['funding'];
    String? metricText;
    if (budget != null && budget is num && budget > 0) {
      metricText = '₹${budget >= 100000 ? (budget / 100000).toStringAsFixed(1) + 'L' : budget >= 1000 ? (budget / 1000).toStringAsFixed(0) + 'k' : budget.toString()}';
    } else if (funding != null && funding is num && funding > 0) {
      metricText = '₹${funding >= 10000000 ? (funding / 10000000).toStringAsFixed(1) + 'Cr' : funding >= 100000 ? (funding / 100000).toStringAsFixed(1) + 'L' : funding.toString()}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleItemTap(context, tab.key, item),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.border.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.25 : 0.03,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Rounded Gradient Avatar with Icon or Monogram
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tab.accent.withValues(alpha: 0.18),
                      tab.accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tab.accent.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: tab.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Middle: Title, Badges & Secondary info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + Verified Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.darkText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Subtitle Tag Pill + Optional Metric + Description
                    Row(
                      children: [
                        if (subtitle.isNotEmpty) ...[
                          Container(
                            constraints: const BoxConstraints(maxWidth: 110),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tab.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: tab.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (metricText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              metricText,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : AppColors.darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (description.isNotEmpty)
                          Expanded(
                            child: Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right: Compact Action Pill Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tab.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tab.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tab.accent,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: tab.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  static String _fallbackRole(String key) {
    switch (key) {
      case 'freelancers':
        return 'Freelancer';
      case 'startups':
        return 'Startup';
      case 'founders':
        return 'Founder';
      case 'investors':
        return 'Investor';
      case 'clients':
        return 'Client';
      case 'projects':
        return 'Project';
      default:
        return 'Recommended';
    }
  }

  static String _sanitizeTag(String raw, String fallback) {
    if (raw.isEmpty) return fallback;
    // Check if raw looks like a UUID or ID list (contains dashes and hex / length > 20 without spaces)
    if (_isUuidLike(raw)) return fallback;
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && !_isUuidLike(s)).toList();
    if (parts.isEmpty) return fallback;
    return parts.first;
  }

  static String _sanitizeDescription(String raw) {
    if (raw.isEmpty) return '';
    if (_isUuidLike(raw)) return '';
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && !_isUuidLike(s)).toList();
    return parts.join(', ');
  }

  static bool _isUuidLike(String s) {
    final trimmed = s.trim();
    if (trimmed.length >= 24 && !trimmed.contains(' ')) return true;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(trimmed);
  }

  void _handleItemTap(
    BuildContext context,
    String tabKey,
    Map<String, dynamic> item,
  ) {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    switch (tabKey) {
      case 'startups':
        context.push('${Routes.startupDetails}/$id');
        break;
      case 'projects':
        context.push('${Routes.projectDetails}/$id');
        break;
      case 'freelancers':
        context.push('${Routes.publicFreelancer}/$id');
        break;
      case 'founders':
        context.push('${Routes.publicFounder}/$id');
        break;
      case 'investors':
        context.push('${Routes.publicInvestor}/$id');
        break;
      case 'clients':
        context.push('${Routes.publicCompany}/$id');
        break;
      default:
        break;
    }
  }

  Widget _buildEmptyState(
    BuildContext context,
    RecommendationTabConfig tab,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tab.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(tab.icon, size: 22, color: tab.accent),
          ),
          const SizedBox(height: 10),
          Text(
            'No ${tab.label.toLowerCase()} found yet',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: context.isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'New matches will appear here based on network activity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.mutedText,
            ),
          ),
          if (widget.onRefresh != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: widget.onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tab.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Refresh Recommendations',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: tab.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerList(
    BuildContext context,
    RecommendationTabConfig tab,
  ) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tab.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
