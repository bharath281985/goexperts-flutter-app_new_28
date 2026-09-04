import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';

/// Embeddable portfolio holding catalog with an executive dashboard look.
class PortfolioListView extends StatefulWidget {
  const PortfolioListView({
    super.key,
    this.investorId,
    this.investorName,
    this.isReadOnly = false,
  });

  final String? investorId;
  final String? investorName;
  final bool isReadOnly;

  @override
  State<PortfolioListView> createState() => _PortfolioListViewState();
}

class _PortfolioListViewState extends State<PortfolioListView> {
  int _refreshKey = 0;
  String _selectedStatusFilter = 'All';

  static const _statusFilters = [
    'All',
    'Ongoing',
    'Completed',
  ];

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final repo = sl<InvestorRepository>();
    final isReadOnly = widget.isReadOnly ||
        (widget.investorId != null && widget.investorId!.isNotEmpty);

    return Column(
      children: [
        // Modern Status Filter Pills
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
            vertical: AppSizes.xs,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final status = _statusFilters[index];
              final isSelected = _selectedStatusFilter == status;
              final icon = switch (status.toLowerCase()) {
                'ongoing' => Icons.trending_up_rounded,
                'completed' => Icons.check_circle_outline_rounded,
                _ => Icons.dashboard_outlined,
              };

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedStatusFilter = status;
                    _refreshKey++;
                  });
                },
                borderRadius: BorderRadius.circular(AppSizes.md),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: context.text.labelMedium?.copyWith(
                          color: isSelected ? Colors.white : AppColors.darkText,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: CatalogView<PortfolioItem>(
            key: ValueKey('$_refreshKey-$_selectedStatusFilter'),
            fetcher: (params) {
              final queryParams = _selectedStatusFilter != 'All'
                  ? params.copyWith(filters: {
                      ...params.filters,
                      'status': _selectedStatusFilter.toLowerCase(),
                    })
                  : params;
              return repo.getPortfolio(queryParams, investorId: widget.investorId);
            },
            searchHint: 'Search portfolio holdings, industry…',
            emptyTitle: 'No portfolio holdings found',
            emptyIcon: Icons.pie_chart_outline_rounded,
            skeletonHeight: 140,
            floatingActionButton: isReadOnly
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _openAdd(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Add Holding',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
            itemBuilder: (context, item, _) => _PortfolioCard(
              item: item,
              isReadOnly: isReadOnly,
              onEdit: isReadOnly ? null : () => _openEdit(context, item),
              onDelete: isReadOnly ? null : () => _deleteItem(context, item),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const InvestorPortfolioFormPage(),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _openEdit(BuildContext context, PortfolioItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvestorPortfolioFormPage(item: item),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _deleteItem(BuildContext context, PortfolioItem item) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete Portfolio Holding?',
      message:
          'Are you sure you want to remove ${item.startupName} from your portfolio?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    final repo = sl<InvestorRepository>();
    final res = await repo.deletePortfolioItem(item.id);
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (msg) {
        context.showSnack(msg);
        _reload();
      },
    );
  }
}

class PublicInvestorPortfolioPage extends StatelessWidget {
  const PublicInvestorPortfolioPage({
    super.key,
    required this.investorId,
    this.investorName = 'Investor',
    this.isReadOnly = true,
  });

  final String investorId;
  final String investorName;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(
          investorName.isNotEmpty
              ? '$investorName’s Portfolio'
              : 'Investor Portfolio',
        ),
      ),
      body: PortfolioListView(
        investorId: investorId,
        investorName: investorName,
        isReadOnly: isReadOnly,
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.item,
    this.isReadOnly = false,
    this.onEdit,
    this.onDelete,
  });

  final PortfolioItem item;
  final bool isReadOnly;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing' || 'active':
        return const Color(0xFF1E88E5);
      case 'completed' || 'exited':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'written off' || 'closed':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _launchUrl(BuildContext context, String urlStr) async {
    final uri = Uri.tryParse(urlStr.trim());
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          context.showSnack('Could not open link', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roi = item.roi;
    final isPositive = roi >= 0;
    final statusCol = _statusColor(item.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.radiusSm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.radiusSm + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Logo + Name + Status + More Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(
                  imageUrl: item.logoUrl,
                  name: item.startupName,
                  size: 48,
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.startupName,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusCol.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              border: Border.all(
                                color: statusCol.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusCol,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.status,
                                  style: context.text.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: statusCol,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.industry.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Text(
                                item.industry,
                                style: context.text.bodySmall?.copyWith(
                                  color: AppColors.mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              item.stage,
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isReadOnly) ...[
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (action) {
                      if (action == 'edit') onEdit?.call();
                      if (action == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Holding'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Live Project Link Chip
            if (item.projectUrl != null && item.projectUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _launchUrl(context, item.projectUrl!),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.projectUrl!,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            AppSizes.vGapMd,

            // Financial Metrics Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161A22)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invested',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.compactCurrency(item.investedAmount),
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Equity Stake',
                            style: context.text.labelSmall?.copyWith(
                              color: AppColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.equity.toStringAsFixed(1)}%',
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Valuation',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.compactCurrency(item.currentValue),
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            if (item.investedAmount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (isPositive ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${isPositive ? '+' : ''}${roi.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: isPositive ? AppColors.success : AppColors.danger,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Date Footer
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 5),
                Text(
                  'Invested on ${DateFormat('dd MMM yyyy').format(item.investedAt)}',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Executive form for creating and editing an Investor Portfolio holding with instant live validation.
class InvestorPortfolioFormPage extends StatefulWidget {
  const InvestorPortfolioFormPage({super.key, this.item});
  final PortfolioItem? item;

  @override
  State<InvestorPortfolioFormPage> createState() =>
      _InvestorPortfolioFormPageState();
}

class _InvestorPortfolioFormPageState extends State<InvestorPortfolioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  final _companyCardKey = GlobalKey();
  final _termsCardKey = GlobalKey();
  final _metricsCardKey = GlobalKey();

  final _startupNameFocus = FocusNode();
  final _projectUrlFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _equityFocus = FocusNode();
  final _valuationFocus = FocusNode();

  final TextEditingController _startupNameCtrl = TextEditingController();
  final TextEditingController _projectUrlCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _equityCtrl = TextEditingController();
  final TextEditingController _valuationCtrl = TextEditingController();
  final TextEditingController _logoUrlCtrl = TextEditingController();

  String? _selectedIndustry;
  String _selectedStage = 'Seed';
  String _selectedStatus = 'Ongoing';
  DateTime _investedDate = DateTime.now();

  bool _loadingIndustries = false;
  List<String> _industryOptions = const [];
  bool _saving = false;

  static const _stages = [
    'Pre-Seed',
    'Seed',
    'Series A',
    'Series B',
    'Growth',
    'Expansion',
    'Late Stage',
  ];

  static const _statuses = [
    'Ongoing',
    'Completed',
  ];

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _startupNameCtrl.text = item.startupName;
      _projectUrlCtrl.text = item.projectUrl ?? '';
      _amountCtrl.text = item.investedAmount > 0 ? item.investedAmount.toStringAsFixed(0) : '';
      _equityCtrl.text = item.equity > 0 ? item.equity.toString() : '';
      _valuationCtrl.text = item.currentValue > 0 ? item.currentValue.toStringAsFixed(0) : '';
      _logoUrlCtrl.text = item.logoUrl ?? '';
      _investedDate = item.investedAt;
      _selectedStatus = _statuses.contains(item.status) ? item.status : 'Ongoing';
      if (item.industry.isNotEmpty && item.industry != 'General') {
        _selectedIndustry = item.industry;
      }
      if (_stages.contains(item.stage)) {
        _selectedStage = item.stage;
      }
    }

    _amountCtrl.addListener(_onMetricChanged);
    _valuationCtrl.addListener(_onMetricChanged);
    _loadIndustries();
  }

  void _onMetricChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _startupNameFocus.dispose();
    _projectUrlFocus.dispose();
    _amountFocus.dispose();
    _equityFocus.dispose();
    _valuationFocus.dispose();
    _amountCtrl.removeListener(_onMetricChanged);
    _valuationCtrl.removeListener(_onMetricChanged);
    _startupNameCtrl.dispose();
    _projectUrlCtrl.dispose();
    _amountCtrl.dispose();
    _equityCtrl.dispose();
    _valuationCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  Future<void> _loadIndustries() async {
    setState(() => _loadingIndustries = true);
    try {
      final response = await Dio().get('${AppConfig.baseUrl}${ApiEndpoints.publicIndustries}');
      final raw = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : null;
      if (raw is List) {
        final list = raw
            .whereType<Map>()
            .map((item) => (item['name'] ?? item['label'] ?? item['title'])?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (mounted) {
          setState(() {
            _industryOptions = list;
            _loadingIndustries = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _industryOptions = const [
          'FinTech',
          'HealthTech',
          'EdTech',
          'AI / ML',
          'SaaS',
          'E-Commerce',
          'CleanTech',
          'AgriTech',
          'Manufacturing',
          'DeepTech',
          'Consumer',
        ];
        _loadingIndustries = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _investedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _investedDate = picked);
    }
  }

  Future<void> _save() async {
    // 1. Check Startup Name
    if (_startupNameCtrl.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollToKey(_companyCardKey);
      _startupNameFocus.requestFocus();
      context.showSnack('Please enter a Startup / Company Name *', isError: true);
      return;
    }

    // 2. Check Project URL
    final projectUrl = _projectUrlCtrl.text.trim();
    if (projectUrl.isEmpty) {
      _formKey.currentState?.validate();
      _scrollToKey(_companyCardKey);
      _projectUrlFocus.requestFocus();
      context.showSnack('Please enter a Project / Website URL *', isError: true);
      return;
    }
    if (!projectUrl.startsWith('http://') && !projectUrl.startsWith('https://')) {
      _formKey.currentState?.validate();
      _scrollToKey(_companyCardKey);
      _projectUrlFocus.requestFocus();
      context.showSnack('Project URL must start with http:// or https://', isError: true);
      return;
    }

    // 3. Check Industry
    if (_selectedIndustry == null || _selectedIndustry!.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollToKey(_companyCardKey);
      context.showSnack('Please select an Industry *', isError: true);
      return;
    }

    // 4. Check Invested Amount
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _formKey.currentState?.validate();
      _scrollToKey(_metricsCardKey);
      _amountFocus.requestFocus();
      context.showSnack('Please enter a valid Invested Amount (₹) *', isError: true);
      return;
    }

    // 5. Check Equity
    final equity = double.tryParse(_equityCtrl.text.trim());
    if (equity == null || equity <= 0 || equity > 100) {
      _formKey.currentState?.validate();
      _scrollToKey(_metricsCardKey);
      _equityFocus.requestFocus();
      context.showSnack('Please enter Equity between 0.1% and 100% *', isError: true);
      return;
    }

    // 6. Check Current Valuation
    final valuation = double.tryParse(_valuationCtrl.text.trim());
    if (valuation == null || valuation < 0) {
      _formKey.currentState?.validate();
      _scrollToKey(_metricsCardKey);
      _valuationFocus.requestFocus();
      context.showSnack('Please enter a valid Current Valuation (₹) *', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _scrollToKey(_companyCardKey);
      return;
    }

    final payload = {
      'startupName': _startupNameCtrl.text.trim(),
      'industry': _selectedIndustry!.trim(),
      'stage': _selectedStage,
      'status': _selectedStatus,
      'projectUrl': projectUrl,
      'investedAmount': amount,
      'equity': equity,
      'currentValue': valuation,
      'investedAt': _investedDate.toIso8601String(),
      'logoUrl': _logoUrlCtrl.text.trim(),
    };

    setState(() => _saving = true);
    final repo = sl<InvestorRepository>();
    final result = _isEdit
        ? await repo.updatePortfolioItem(widget.item!.id, payload)
        : await repo.addPortfolioItem(payload);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack(_isEdit ? 'Holding updated' : 'Holding added to portfolio');
        Navigator.of(context).pop(true);
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate live ROI preview
    final parsedInvested = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final parsedValuation = double.tryParse(_valuationCtrl.text.trim()) ?? 0;
    final hasMetrics = parsedInvested > 0 && parsedValuation >= 0;
    final gainLoss = parsedValuation - parsedInvested;
    final roiPercent = parsedInvested > 0 ? (gainLoss / parsedInvested) * 100 : 0.0;
    final multiple = parsedInvested > 0 ? (parsedValuation / parsedInvested) : 0.0;
    final isGain = gainLoss >= 0;

    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(_isEdit ? 'Edit Holding' : 'Add Portfolio Holding'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            // Top Header Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.gold.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Update Asset Holding' : 'New Portfolio Holding',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track startup equity, valuation, and capital returns.',
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            AppSizes.vGapMd,

            // Card 1: Company Profile
            AppCard(
              key: _companyCardKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.apartment_rounded,
                    title: 'Company Profile',
                    subtitle: 'Enter startup identity & official links',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _startupNameCtrl,
                    focusNode: _startupNameFocus,
                    label: 'Startup / Company Name *',
                    hint: 'e.g. Acme Technologies Inc.',
                    prefixIcon: Icons.business_rounded,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Company name is required'
                        : null,
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _projectUrlCtrl,
                    focusNode: _projectUrlFocus,
                    label: 'Project / Website URL *',
                    hint: 'https://acme.com',
                    prefixIcon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Project / Website URL is required';
                      }
                      final trimmed = val.trim();
                      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  AppSizes.vGapMd,
                  if (_loadingIndustries) ...[
                    Text('Industry *', style: context.text.titleSmall),
                    AppSizes.vGapSm,
                    const LinearProgressIndicator(minHeight: 3),
                  ] else
                    AppDropdown<String>(
                      label: 'Industry *',
                      hint: 'Select industry',
                      value: _selectedIndustry,
                      items: _industryOptions,
                      itemLabel: (s) => s,
                      onChanged: _saving
                          ? null
                          : (val) => setState(() => _selectedIndustry = val),
                    ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _logoUrlCtrl,
                    label: 'Company Logo URL (Optional)',
                    hint: 'https://example.com/logo.png',
                    prefixIcon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),

            AppSizes.vGapMd,

            // Card 2: Investment Terms & Status
            AppCard(
              key: _termsCardKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.handshake_outlined,
                    title: 'Investment Terms & Stage',
                    subtitle: 'Funding round and status classification',
                  ),
                  const SizedBox(height: 16),
                  AppDropdown<String>(
                    label: 'Investment Stage *',
                    hint: 'Select stage',
                    value: _selectedStage,
                    items: _stages,
                    itemLabel: (s) => s,
                    onChanged: _saving
                        ? null
                        : (val) {
                            if (val != null) setState(() => _selectedStage = val);
                          },
                  ),
                  AppSizes.vGapMd,
                  Text(
                    'Holding Status *',
                    style: context.text.titleSmall?.copyWith(fontSize: 14),
                  ),
                  AppSizes.vGapSm,
                  Row(
                    children: _statuses.map((st) {
                      final isSelected = _selectedStatus == st;
                      final isOngoing = st == 'Ongoing';
                      final activeColor = isOngoing
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFF10B981);

                      return Expanded(
                        child: InkWell(
                          onTap: _saving
                              ? null
                              : () => setState(() => _selectedStatus = st),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: st == _statuses.first ? 8 : 0,
                              left: st == _statuses.last ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor.withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF161A22) : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : AppColors.border.withValues(alpha: 0.7),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isOngoing
                                      ? Icons.trending_up_rounded
                                      : Icons.check_circle_rounded,
                                  size: 18,
                                  color: isSelected ? activeColor : AppColors.mutedText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  st,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? activeColor : AppColors.mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  AppSizes.vGapMd,
                  InkWell(
                    onTap: _saving ? null : _selectDate,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.md,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161A22) : Colors.grey.shade50,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Initial Investment Date *',
                                style: context.text.labelSmall?.copyWith(
                                  color: AppColors.mutedText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMMM yyyy').format(_investedDate),
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AppSizes.vGapMd,

            // Card 3: Financial Capital & Valuation
            AppCard(
              key: _metricsCardKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.monetization_on_outlined,
                    title: 'Financial Capital & Valuation',
                    subtitle: 'Track capital invested and current value',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _amountCtrl,
                    focusNode: _amountFocus,
                    label: 'Invested Capital (₹) *',
                    hint: 'e.g. 2500000',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Invested amount is required';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return 'Please enter a valid positive amount';
                      }
                      return null;
                    },
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _equityCtrl,
                    focusNode: _equityFocus,
                    label: 'Equity Ownership Stake (%) *',
                    hint: 'e.g. 7.5',
                    prefixIcon: Icons.pie_chart_outline_rounded,
                    suffixText: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Equity % is required';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0 || num > 100) {
                        return 'Please enter equity between 0.1% and 100%';
                      }
                      return null;
                    },
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _valuationCtrl,
                    focusNode: _valuationFocus,
                    label: 'Current Holding Valuation (₹) *',
                    hint: 'e.g. 3500000',
                    prefixIcon: Icons.trending_up_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Current valuation is required';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num < 0) {
                        return 'Please enter a valid valuation amount';
                      }
                      return null;
                    },
                  ),

                  // Live Calculated ROI & Multiple Card
                  if (hasMetrics) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: (isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isGain ? Icons.insights_rounded : Icons.trending_down_rounded,
                                size: 16,
                                color: isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE PERFORMANCE PREVIEW',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Net Gain / Loss',
                                    style: context.text.labelSmall?.copyWith(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${isGain ? '+' : ''}${Formatters.currency(gainLoss)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Return (ROI)',
                                    style: context.text.labelSmall?.copyWith(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${isGain ? '+' : ''}${roiPercent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Multiple (MOIC)',
                                    style: context.text.labelSmall?.copyWith(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${multiple.toStringAsFixed(2)}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            AppSizes.vGapXl,

            AppPrimaryButton(
              label: _isEdit ? 'Update Holding' : 'Add to Portfolio',
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
