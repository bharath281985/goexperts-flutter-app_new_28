import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  static const _faqs = [
    [
      'How do I withdraw my earnings?',
      'Go to Wallet → Withdraw and choose your bank account. Payouts take 1–3 business days.',
    ],
    [
      'How does escrow work?',
      'Funds are held securely and released to freelancers when milestones are approved.',
    ],
    [
      'How do I verify my profile?',
      'Complete your profile and submit documents under Security Center → Verification.',
    ],
    [
      'Can I switch roles?',
      'Yes, you can add more roles from Settings → Account at any time.',
    ],
  ];

  bool _loading = true;
  List<Map<String, dynamic>> _tickets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ApiClientHelper>()
        .getEnvelope<List<Map<String, dynamic>>>(
          ApiEndpoints.supportTickets,
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
    _tickets = res.valueOrNull ?? const [];
    setState(() => _loading = false);
  }

  Future<void> _createTicket() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTicketSheet(
        onReload: () async {
          await _load();
        },
      ),
    );
  }

  Future<void> _viewTicket(Map<String, dynamic> ticketInfo) async {
    final ticketId =
        ticketInfo['id']?.toString() ?? ticketInfo['_id']?.toString() ?? '';
    if (ticketId.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ViewTicketSheet(
        ticketInfo: ticketInfo,
        onReload: () async {
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket,
        backgroundColor: const Color(0xFFFFDDDD),
        elevation: 0,
        label: const Text(
          'Create Ticket',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        icon: const Icon(Icons.add, color: Colors.black87, size: 20),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          Row(
            children: [
              Expanded(
                child: _contact(
                  context,
                  Icons.chat_bubble_outline_rounded,
                  'Live Chat',
                  const Color(0xFFC8102E),
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: _contact(
                  context,
                  Icons.email_outlined,
                  'Email Us',
                  Colors.blue,
                ),
              ),
              AppSizes.hGapMd,
              Expanded(
                child: _contact(
                  context,
                  Icons.call_outlined,
                  'Call',
                  Colors.green,
                ),
              ),
            ],
          ),
          AppSizes.vGapLg,
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          AppSizes.vGapSm,
          for (final f in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  f[0],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                iconColor: Colors.black87,
                collapsedIconColor: Colors.black87,
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  0,
                  AppSizes.lg,
                  AppSizes.lg,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      f[1],
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AppSizes.vGapLg,
          const Text(
            'My Tickets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          AppSizes.vGapSm,
          _loading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : (_tickets.isEmpty)
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.support_agent, color: Colors.grey, size: 40),
                      SizedBox(height: 12),
                      Text(
                        'No support tickets yet',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final t in _tickets)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.sm),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () => _viewTicket(t),
                          title: Text(
                            t['subject']?.toString() ?? 'Ticket',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Status: ${t['status'] ?? 'open'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _contact(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) => InkWell(
    onTap: () => context.showSnack('$label…'),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _CreateTicketSheet extends StatefulWidget {
  final VoidCallback onReload;
  const _CreateTicketSheet({required this.onReload});

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final subCtrl = TextEditingController();
  String category = 'Account Verification';
  String priority = 'High';
  bool _saving = false;

  @override
  void dispose() {
    subCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Support Ticket',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subject',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: subCtrl,
                      maxLines: 4,
                      minLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe your issue',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      items:
                          [
                                "Account Verification",
                                "Payment / Invoicing",
                                "Technical Issue / Bug",
                                "General Inquiry",
                                "Feedback / Suggestions",
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => category = v!),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: Colors.black54,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      items: ["Low", "Medium", "High"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => priority = v!),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.error_outline,
                          color: Colors.black54,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _saving
                            ? null
                            : () async {
                                if (subCtrl.text.trim().isEmpty) {
                                  context.showSnack('Subject is required');
                                  return;
                                }
                                setState(() => _saving = true);
                                final res = await sl<ApiClientHelper>()
                                    .postAction(
                                      ApiEndpoints.supportTickets,
                                      body: {
                                        'subject': subCtrl.text.trim(),
                                        'category': category,
                                        'priority': priority,
                                      },
                                    );
                                if (!mounted) return;
                                res.fold(
                                  (f) {
                                    context.showSnack(f.message);
                                    setState(() => _saving = false);
                                  },
                                  (_) {
                                    context.showSnack(
                                      'Ticket created successfully',
                                    );
                                    Navigator.pop(context);
                                    widget.onReload();
                                  },
                                );
                              },
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewTicketSheet extends StatefulWidget {
  final Map<String, dynamic> ticketInfo;
  final VoidCallback onReload;
  const _ViewTicketSheet({required this.ticketInfo, required this.onReload});

  @override
  State<_ViewTicketSheet> createState() => _ViewTicketSheetState();
}

class _ViewTicketSheetState extends State<_ViewTicketSheet> {
  bool _isLoading = true;
  bool _sending = false;
  Map<String, dynamic>? _ticketDetails;
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    final ticketId =
        widget.ticketInfo['id']?.toString() ??
        widget.ticketInfo['_id']?.toString() ??
        '';
    final res = await sl<ApiClientHelper>().getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.supportTicket(ticketId),
      parser: (e) => (e.data as Map?)?.cast<String, dynamic>() ?? {},
    );
    if (!mounted) return;
    res.fold(
      (f) {
        setState(() => _isLoading = false);
        context.showSnack(f.message);
      },
      (data) => setState(() {
        _ticketDetails = data;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status =
        _ticketDetails?['status']?.toString() ??
        widget.ticketInfo['status']?.toString() ??
        'unknown';
    final isClosed = status.toLowerCase() == 'closed';
    final categoryStr =
        _ticketDetails?['category']?.toString() ??
        widget.ticketInfo['category']?.toString() ??
        'N/A';
    final priorityStr =
        _ticketDetails?['priority']?.toString() ??
        widget.ticketInfo['priority']?.toString() ??
        'N/A';
    final msgsStr = _ticketDetails?['messages'];
    final messages = (msgsStr is List)
        ? msgsStr.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final title =
        _ticketDetails?['subject']?.toString() ??
        widget.ticketInfo['subject']?.toString() ??
        'Ticket Details';
    final ticketId =
        widget.ticketInfo['id']?.toString() ??
        widget.ticketInfo['_id']?.toString() ??
        '';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Status color
    Color statusColor = Colors.green;
    if (status.toLowerCase() == 'open') statusColor = Colors.orange;
    if (status.toLowerCase() == 'closed') statusColor = Colors.grey;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * (bottomInset > 0 ? 0.95 : 0.85),
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSizes.vGapMd,
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: [
                            Chip(
                              label: Text(
                                'Status: ${status.toUpperCase()}',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: statusColor.withAlpha(30),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                            ),
                            Chip(
                              label: Text(
                                categoryStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Colors.blue.withAlpha(30),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                            ),
                            Chip(
                              label: Text(
                                'Priority: $priorityStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Colors.red.withAlpha(30),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        AppSizes.vGapLg,
                        if (messages.isNotEmpty) ...[
                          const Text(
                            'Conversation History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          AppSizes.vGapSm,
                          for (var m in messages)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['createdAt']?.toString() ?? 'Just now',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    m['message']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          AppSizes.vGapLg,
                        ],
                        if (!isClosed) ...[
                          const Text(
                            'Leave a Reply',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          AppSizes.vGapSm,
                          AppTextField(
                            controller: _replyCtrl,
                            hint: 'Type your reply here...',
                            maxLines: 4,
                          ),
                          AppSizes.vGapLg,
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_sending && !isClosed) ...[
                              TextButton(
                                onPressed: () async {
                                  setState(() => _sending = true);
                                  final res = await sl<ApiClientHelper>()
                                      .patchAction(
                                        ApiEndpoints.supportTicketClose(
                                          ticketId,
                                        ),
                                      );
                                  if (!mounted) return;
                                  res.fold(
                                    (f) {
                                      context.showSnack(f.message);
                                      setState(() => _sending = false);
                                    },
                                    (_) {
                                      context.showSnack(
                                        'Ticket successfully closed',
                                      );
                                      Navigator.pop(context);
                                      widget.onReload();
                                    },
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Close Ticket',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              AppSizes.hGapMd,
                            ],
                            if (!isClosed)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _sending
                                      ? null
                                      : () async {
                                          if (_replyCtrl.text.trim().isEmpty) {
                                            return;
                                          }
                                          setState(() => _sending = true);
                                          final res = await sl<ApiClientHelper>()
                                              .postAction(
                                                ApiEndpoints.supportTicketReply(
                                                  ticketId,
                                                ),
                                                body: {
                                                  'message': _replyCtrl.text
                                                      .trim(),
                                                },
                                              );
                                          if (!mounted) return;
                                          res.fold(
                                            (f) {
                                              context.showSnack(f.message);
                                              setState(() => _sending = false);
                                            },
                                            (_) {
                                              context.showSnack(
                                                'Reply sent successfully',
                                              );
                                              Navigator.pop(context);
                                              widget.onReload();
                                            },
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: _sending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 18,
                                        ),
                                  label: const Text(
                                    'Send Reply',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            if (isClosed)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Close Preview',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: bottomInset > 0 ? 0 : AppSizes.lg),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
