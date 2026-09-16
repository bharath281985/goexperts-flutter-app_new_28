import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  List<Map<String, dynamic>> _faqs = [];
  String _supportEmail = 'servicedesk@goexperts.in';
  String _supportPhone = '+919441457677';
  bool _loading = true;
  List<Map<String, dynamic>> _tickets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = sl<ApiClientHelper>();
    
    // Fetch Support Tickets
    final resTickets = await client.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.supportTickets,
      parser: (e) {
        final list = e.data as List?;
        if (list == null) return const [];
        return list.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
      },
    );

    // Fetch FAQs
    final resFaqs = await client.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.publicFaqs,
      parser: (e) {
        final list = e.data as List?;
        if (list == null) return const [];
        return list.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
      },
    );

    // Fetch App Config
    final resConfig = await client.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.appConfig,
      parser: (e) => (e.data as Map?)?.cast<String, dynamic>() ?? {},
    );

    if (!mounted) return;
    
    _tickets = resTickets.valueOrNull ?? const [];
    _faqs = resFaqs.valueOrNull ?? [];
    
    final config = resConfig.valueOrNull;
    if (config != null) {
      _supportEmail = config['supportEmail']?.toString() ?? _supportEmail;
      _supportPhone = config['supportPhone']?.toString() ?? _supportPhone;
    }

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
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Help & Support'),
      ),
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
          AppSizes.vGapXxl,
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
                  f['question']?.toString() ?? '',
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
                      f['answer']?.toString() ?? '',
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  Future<void> _handleSupportContact(String text) async {
    if (text == "Call") {
      final Uri phoneUri = Uri(
        scheme: 'tel',
        path: _supportPhone,
      );
      try {
        final launched = await launchUrl(phoneUri);
        if (!launched && context.mounted) {
          context.showSnack('Could not open dial pad', isError: true);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnack('Could not open dial pad', isError: true);
        }
      }
    } else if (text == "Email Us") {
      try {
        final launched = await launchUrl(
          Uri.parse("mailto:$_supportEmail"),
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          context.showSnack('Could not open email app', isError: true);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnack('Could not open email app', isError: true);
        }
      }
    } else if (text == "Live Chat") {
      // Look for an existing open Live Chat ticket
      final existingChat = _tickets.where((t) {
        final subject = (t['subject']?.toString() ?? '').toLowerCase();
        final status = (t['status']?.toString() ?? '').toLowerCase();
        return subject.contains('live chat') && status != 'closed' && status != 'resolved';
      }).firstOrNull;

      if (existingChat != null) {
        _viewTicket(existingChat);
      } else {
        context.showSnack('Starting Live Chat...');
        final res = await sl<ApiClientHelper>().postEnvelope<Map<String, dynamic>>(
          ApiEndpoints.supportTickets,
          body: {
            'subject': 'Live Chat Request',
            'category': 'General Inquiry',
            'priority': 'High',
          },
          parser: (e) => (e.data as Map?)?.cast<String, dynamic>() ?? {},
        );
        
        if (context.mounted) {
          res.fold(
            (l) => context.showSnack(l.message, isError: true),
            (ticket) {
              _load(); // Reload the list
              _viewTicket(ticket);
            },
          );
        }
      }
    } else {
      context.showSnack("Coming soon");
    }
  }

  Widget _contact(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) => InkWell(
    onTap: () =>_handleSupportContact(label),
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
                          borderSide:  BorderSide(
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
  bool _showAllMessages = false;
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
        _ticketDetails?['categoryId']?.toString() ??
        'N/A';
    final priorityStr =
        _ticketDetails?['priority']?.toString() ??
        widget.ticketInfo['priority']?.toString() ??
        'N/A';
    final ticketNumber =
        _ticketDetails?['ticketNumber']?.toString() ??
        widget.ticketInfo['ticketNumber']?.toString() ??
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (!isClosed)
                              TextButton(
                                onPressed: () async {
                                  setState(() => _sending = true);
                                  final res = await sl<ApiClientHelper>()
                                      .patchAction(ApiEndpoints.supportTicketClose(ticketId));
                                  if (!mounted) return;
                                  res.fold(
                                    (f) {
                                      context.showSnack(f.message);
                                      setState(() => _sending = false);
                                    },
                                    (_) {
                                      context.showSnack('Ticket successfully closed');
                                      Navigator.pop(context);
                                      widget.onReload();
                                    },
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Close Ticket',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
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
                        AppSizes.vGapSm,
                        Row(
                          children: [
                            Text('Ticket Number:',style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),),
                            Expanded(child: Text(' $ticketNumber')),
                          ],
                        ),
                        AppSizes.vGapSm,
                        Row(
                          children: [
                            Text('Subject:',style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),),
                            Expanded(child: Text(' ${_ticketDetails?['subject']?.toString() ?? ''}')),
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
                          AppSizes.vGapLg,
                          const Divider(),
                          AppSizes.vGapSm,
                          if (messages.length > 3 && !_showAllMessages)
                            Center(
                              child: TextButton(
                                onPressed: () => setState(() => _showAllMessages = true),
                                child: Text('View previous messages (${messages.length - 3})'),
                              ),
                            ),
                          for (var i = 0; i < messages.length; i++)
                            Builder(
                              builder: (context) {
                                if (!_showAllMessages && i < messages.length - 3) return const SizedBox.shrink();
                                final m = messages[i];
                                final isAdmin = m['senderRole'] == 'admin';
                                String timeStr = m['createdAt']?.toString() ?? '';
                                try {
                                  if (timeStr.isNotEmpty) {
                                    final dt = DateTime.parse(timeStr).toLocal();
                                    timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                                  }
                                } catch (_) {}

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isAdmin) const SizedBox(width: 40),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isAdmin ? Colors.grey.shade200 : AppColors.primary,
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(16),
                                              topRight: const Radius.circular(16),
                                              bottomLeft: Radius.circular(isAdmin ? 0 : 16),
                                              bottomRight: Radius.circular(isAdmin ? 16 : 0),
                                            ),
                                          ),
                                          child: Wrap(
                                            alignment: isAdmin ? WrapAlignment.start : WrapAlignment.end,
                                            crossAxisAlignment: WrapCrossAlignment.end,
                                            children: [
                                              Text(
                                                m['message']?.toString() ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                  color: isAdmin ? Colors.black87 : Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: Text(
                                                  timeStr,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: isAdmin ? Colors.black54 : Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isAdmin) const SizedBox(width: 40),
                                    ],
                                  ),
                                );
                                }
                            ),
                          AppSizes.vGapLg,
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isClosed) ...[
                  const Divider(),
                  AppSizes.vGapSm,
                  Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _replyCtrl,
                                  hint: 'Type a reply...',
                                  maxLines: 1,
                                ),
                              ),
                              AppSizes.hGapSm,
                              _sending
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () async {
                                          if (_replyCtrl.text.trim().isEmpty) return;
                                          setState(() => _sending = true);
                                          final res = await sl<ApiClientHelper>()
                                              .postAction(
                                                ApiEndpoints.supportTicketReply(ticketId),
                                                body: {'message': _replyCtrl.text.trim()},
                                              );
                                          if (!mounted) return;
                                          res.fold(
                                            (f) {
                                              context.showSnack(f.message);
                                              setState(() => _sending = false);
                                            },
                                            (_) {
                                              context.showSnack('Reply sent successfully');
                                              _replyCtrl.clear();
                                              _loadTicket();
                                              setState(() => _sending = false);
                                              widget.onReload();
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.send, size: 20),
                                        color: Colors.white,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                        if (isClosed)
                          Row(
                            children: [
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
    );
  }
}
