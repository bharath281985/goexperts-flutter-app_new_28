import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../startup_ideas/domain/entities/startup.dart';
import '../../../startup_ideas/domain/repositories/startup_repository.dart';
import '../widgets/edit_idea_bottom_sheet.dart';
import '../../domain/repositories/founder_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import 'package:url_launcher/url_launcher.dart';

/// Founder's own startup management view (embeddable tab).
class MyStartupView extends StatefulWidget {
  const MyStartupView({super.key});

  @override
  State<MyStartupView> createState() => _MyStartupViewState();
}

class _MyStartupViewState extends State<MyStartupView> {
  bool _loading = true;
  Map<String, dynamic> _startup = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    var res = await api.get<dynamic>(
      ApiEndpoints.clientMyStartups,
      parser: (raw) => raw,
    );

    if (res.isFailure || res.valueOrNull == null) {
      res = await api.get<dynamic>(
        ApiEndpoints.clientIdeas,
        parser: (raw) => raw,
      );
    }

    if (!mounted) return;

    Map<String, dynamic> startupData = const {};
    final rawData = res.valueOrNull;

    if (rawData is List && rawData.isNotEmpty) {
      startupData = Map<String, dynamic>.from(rawData.first as Map);
    } else if (rawData is Map) {
      startupData = Map<String, dynamic>.from(rawData);
    }

    _startup = startupData;
    setState(() => _loading = false);
  }

  Future<void> _createStartup() async {
    const defaultStartup = Startup(
      id: '',
      name: '',
      tagline: '',
      industry: '',
      stage: '',
      founderName: '',
      fundingRequired: 0,
      equityOffered: 0,
      location: '',
    );

    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EditIdeaBottomSheet(startup: defaultStartup),
    );

    if (data == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = sl<StartupRepository>();
    final res = await repo.createIdea(data);

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading spinner

    res.fold((f) => context.showSnack(f.message, isError: true), (created) {
      context.showSnack('Startup idea created successfully!');
      _load();
    });
  }

  Future<void> _editStartup() async {
    if (_startup.isEmpty || _startup['id'] == null) {
      context.showSnack('No startup data to edit', isError: true);
      return;
    }

    final startup = Startup.fromApiJson(_startup);

    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          EditIdeaBottomSheet(startup: startup, rawStartup: _startup),
    );

    if (data == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final repo = sl<StartupRepository>();

    // Merge the bottom sheet data with the original API payload to preserve required fields
    final Map<String, dynamic> payload = Map<String, dynamic>.from(_startup);
    data.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        payload[key] = value;
      }
    });

    // Flatten user profile into root object based on required cURL API format
    if (_startup['user'] is Map) {
      final u = _startup['user'] as Map;
      payload['fullName'] = u['fullName'] ?? payload['fullName'];
      payload['bio'] = u['bio'] ?? payload['bio'];
      payload['country'] = u['country'] ?? payload['country'];
      payload['city'] = u['city'] ?? payload['city'];
      payload['avatarUrl'] = u['avatarUrl'] ?? payload['avatarUrl'];
      final phone = u['phone']?.toString() ?? '';
      if (phone.isNotEmpty) {
        payload['phoneNumber'] = phone;
      }
    }

    // Default assignments just to match endpoint structure
    payload['visibility'] = payload['visibility'] ?? 'Public';
    if (payload.containsKey('startup') && !payload.containsKey('startupName')) {
      payload['startupName'] = payload['startup'];
    }

    final res = await repo.updateIdea(startup.id, payload);

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading spinner

    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack('Startup updated successfully');
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final name = _startup['startupName']?.toString().trim().isNotEmpty == true
        ? _startup['startupName'].toString().trim()
        : (_startup['startup']?.toString().trim() ??
            _startup['name']?.toString().trim() ??
            '');

    final isPlaceholder = name.toLowerCase().endsWith("'s startup") ||
        name.toLowerCase().endsWith("’s startup");

    final hasValidStartup = _startup.isNotEmpty &&
        _startup['id'] != null &&
        _startup['id'].toString().isNotEmpty &&
        _startup['id'].toString() != 'null' &&
        name.isNotEmpty &&
        !isPlaceholder;

    // If there is no DB record or id is missing/null or placeholder, show No Startup Found
    if (!hasValidStartup) {
      return Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
          title: const Text('My Startup'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                AppSizes.vGapMd,
                Text(
                  'No Startup Found',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSizes.vGapSm,
                Text(
                  'You have not created any startup idea yet. Create your startup profile to attract investors, upload pitch decks, and raise capital.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.subtleText,
                  ),
                ),
                AppSizes.vGapLg,
                AppPrimaryButton(
                  label: 'Create Startup',
                  icon: Icons.add_rounded,
                  onPressed: _createStartup,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final tagline =
        _startup['title']?.toString() ??
        _startup['tagline']?.toString() ??
        '';
    final rawIndObj = _startup['industry'];
    final rawIndustry = (_startup['industryName'] ??
            (rawIndObj is Map ? (rawIndObj['name'] ?? rawIndObj['label'] ?? rawIndObj['value']) : rawIndObj))
        ?.toString()
        .trim() ??
        '';

    final rawStageObj = _startup['stage'];
    final rawStage = (_startup['stageName'] ??
            (rawStageObj is Map ? (rawStageObj['name'] ?? rawStageObj['label'] ?? rawStageObj['value']) : rawStageObj))
        ?.toString()
        .trim() ??
        '';

    final rawCatObj = _startup['category'];
    final rawCategory = (_startup['categoryName'] ??
            (rawCatObj is Map ? (rawCatObj['name'] ?? rawCatObj['label'] ?? rawCatObj['value']) : rawCatObj))
        ?.toString()
        .trim() ??
        '';

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    final industry = uuidRegex.hasMatch(rawIndustry) ? '' : rawIndustry;
    final stage = uuidRegex.hasMatch(rawStage) ? '' : rawStage;
    final category = uuidRegex.hasMatch(rawCategory) ? '' : rawCategory;
    final teamSize = _startup['teamSize']?.toString() ?? '';

    final logoUrl =
        _startup['logo']?.toString() ??
        _startup['logoUrl']?.toString() ??
        (_startup['user'] is Map
            ? (_startup['user'] as Map)['avatarUrl']?.toString()
            : null);

    final coverUrl = _startup['coverUrl']?.toString() ??
        _startup['cover']?.toString() ??
        _startup['coverImage']?.toString() ??
        _startup['coverimage']?.toString();

    final goal = (num.tryParse(_startup['funding']?.toString() ?? '0') ?? 0)
        .toDouble();
    final equity = (num.tryParse(_startup['equity']?.toString() ?? '0') ?? 0)
        .toDouble();

    final bidsList = _startup['bids'] as List? ?? [];
    final bids = bidsList
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    final raised = (num.tryParse(_startup['raised']?.toString() ?? '0') ?? 0)
        .toDouble();
    final interestedInvestors = _startup['interestedInvestors'] ?? bids.length;

    final tags = <String>[
      if (stage.isNotEmpty) stage,
      if (industry.isNotEmpty) industry,
      if (category.isNotEmpty && category != industry) category,
      if (teamSize.isNotEmpty && teamSize != '0') '$teamSize Team Members',
    ];

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editStartup,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Update Idea'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(
              context: context,
              coverUrl: coverUrl,
              logoUrl: logoUrl,
              name: name,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tagline,
                        style: context.text.bodyLarge?.copyWith(
                          color: AppColors.subtleText,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildTagsRow(context, tags),
                    ],
                    const SizedBox(height: 24),
                    _buildFundingSection(
                      context,
                      goal,
                      raised,
                      equity,
                      interestedInvestors.toString(),
                    ),
                    const SizedBox(height: 24),
                    _buildDocumentsSection(context),
                    const SizedBox(height: 24),
                    _buildInvestorRequests(context, bids),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar({
    required BuildContext context,
    required String? coverUrl,
    required String? logoUrl,
    required String name,
  }) {
    return SliverAppBar(
      leading: IconTapWidget(
        onTap: () => Navigator.of(context).maybePop(),
      ),
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              CustomCachedImage(imageUrl: coverUrl, fit: BoxFit.cover)
            else
              Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(
                    Icons.business,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: AppAvatar(name: name, imageUrl: logoUrl, size: 70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context, List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .where((t) => t.isNotEmpty)
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                t,
                style: context.text.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFundingSection(
    BuildContext context,
    double goal,
    double raised,
    double equity,
    String interested,
  ) {
    double progress = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Funding Round',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (goal > 0)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Raised',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: context.theme.dividerColor.withValues(
                alpha: 0.5,
              ),
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statBlock(
                  context,
                  'Goal Amount',
                  Formatters.compactCurrency(goal),
                ),
              ),
              Expanded(
                child: _statBlock(
                  context,
                  'Amount Raised',
                  Formatters.compactCurrency(raised),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statBlock(
                  context,
                  'Equity Offered',
                  '${equity.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _statBlock(context, 'Interested Investors', interested),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    final docs = _startup['documents'] as List? ?? [];

    final pitchDeckUrl =
        _startup['pitchDeckUrl']?.toString() ??
        _startup['pitchDeck']?.toString();
    final businessPlanUrl =
        _startup['businessPlanUrl']?.toString() ??
        _startup['businessPlan']?.toString();

    final List<Map<String, dynamic>> combinedDocs = [];
    if (docs.isNotEmpty) {
      combinedDocs.addAll(docs.cast<Map<String, dynamic>>());
    }

    if (pitchDeckUrl != null &&
        pitchDeckUrl.trim().isNotEmpty &&
        pitchDeckUrl.trim() != 'null' &&
        !combinedDocs.any((d) => d['name'] == 'Pitch Deck')) {
      combinedDocs.add({'name': 'Pitch Deck', 'url': pitchDeckUrl.trim()});
    }

    if (businessPlanUrl != null &&
        businessPlanUrl.trim().isNotEmpty &&
        businessPlanUrl.trim() != 'null' &&
        !combinedDocs.any((d) => d['name'] == 'Business Plan')) {
      combinedDocs.add({'name': 'Business Plan', 'url': businessPlanUrl.trim()});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Startup Assets'),
        const SizedBox(height: 12),
        if (combinedDocs.isEmpty)
          const AppCard(
            child: Text(
              'No assets uploaded yet.',
              style: TextStyle(color: AppColors.subtleText),
            ),
          ),
        for (final doc in combinedDocs)
          _asset(
            context,
            Icons.insert_drive_file_outlined,
            doc['name']?.toString() ?? 'Document',
            'Available',
            doc['url']?.toString(),
          ),
      ],
    );
  }

  Widget _buildInvestorRequests(
    BuildContext context,
    List<Map<String, dynamic>> bids,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: AppSectionHeader(title: 'Investor Requests')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${bids.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bids.isEmpty)
          const AppCard(
            child: Text(
              'No investor requests yet.',
              style: TextStyle(color: AppColors.subtleText),
            ),
          ),
        for (final r in bids)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            onTap: () async {
              final id = r['id']?.toString();
              if (id != null && id.isNotEmpty) {
                await context.push('${Routes.proposalDetails}/$id');
                _load();
              }
            },
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    final invId = r['investorId']?.toString();
                    if (invId != null && invId.isNotEmpty) {
                      context.push('${Routes.publicInvestor}/$invId');
                    }
                  },
                  child: AppAvatar(
                    name:
                        r['investorName']?.toString() ??
                        r['investorProfile']?['fullName']?.toString() ??
                        'Investor',
                    imageUrl:
                        r['avatarUrl']?.toString() ??
                        r['investorProfile']?['avatarUrl']?.toString(),
                    size: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['investorName']?.toString() ??
                            r['investorProfile']?['fullName']?.toString() ??
                            'Investor',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offers ${Formatters.compactCurrency(num.tryParse(r['offer']?.toString() ?? '0')?.toDouble() ?? 0)} for ${num.tryParse(r['equity']?.toString() ?? '0')?.toDouble().toStringAsFixed(1)}% equity',
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusOrActions(r),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statBlock(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.text.labelMedium?.copyWith(color: AppColors.subtleText),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildStatusOrActions(Map<String, dynamic> r) {
    final statusStr = r['status']?.toString().toLowerCase() ?? 'pending';
    if (statusStr == 'accepted' || statusStr == 'accept') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Accepted',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (statusStr == 'rejected' || statusStr == 'reject') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Rejected',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Schedule Meeting',
          onPressed: () => _scheduleMeeting(r['id']?.toString() ?? ''),
          icon: const Icon(
            Icons.calendar_month,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        IconButton(
          tooltip: 'Accept',
          onPressed: () => _respond(r['id']?.toString() ?? '', 'accept'),
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 28,
          ),
        ),
        IconButton(
          tooltip: 'Reject',
          onPressed: () => _respond(r['id']?.toString() ?? '', 'reject'),
          icon: const Icon(Icons.cancel, color: AppColors.danger, size: 28),
        ),
      ],
    );
  }

  Future<void> _scheduleMeeting(String id) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 30),
    );
    if (time == null || !mounted) return;

    final formattedDate =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final formattedTime =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    final res = await sl<StartupRepository>().scheduleOfferMeeting(
      id,
      date: formattedDate,
      time: formattedTime,
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) => context.showSnack('Meeting scheduled for $formattedDate at $formattedTime.'),
    );
    await _load();
  }

  Future<void> _respond(String id, String action) async {
    final res = await sl<FounderRepository>().respondToRequest(id, action);
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) => context.showSnack('Request successfully updated.'),
    );
    await _load();
  }

  Widget _asset(
    BuildContext context,
    IconData icon,
    String title,
    String meta,
    String? url,
  ) {
    final cleanUrl = url?.trim();
    final hasUrl = cleanUrl != null && cleanUrl.isNotEmpty && cleanUrl != 'null';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      onTap: () {
        if (hasUrl) {
          final ext = cleanUrl.split('.').last.split('?').first.toUpperCase();
          context.push(
            '${Routes.documentViewer}?url=${Uri.encodeComponent(cleanUrl)}&name=${Uri.encodeComponent(title)}&type=${Uri.encodeComponent(ext.isNotEmpty ? ext : 'PDF')}',
          );
        } else {
          context.showSnack('No file attached for $title', isError: true);
        }
      },
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: context.text.labelSmall?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.mutedText,
          size: 14,
        ),
      ],
    ),
  );
}
}
