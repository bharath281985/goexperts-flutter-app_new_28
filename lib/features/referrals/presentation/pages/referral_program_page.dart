import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/share_sheet.dart';
import '../../data/referral_repository.dart';
import '../../domain/referral_details.dart';

class ReferralProgramPage extends StatefulWidget {
  const ReferralProgramPage({super.key, this.repository});
  final ReferralRepository? repository;

  @override
  State<ReferralProgramPage> createState() => _ReferralProgramPageState();
}

class _ReferralProgramPageState extends State<ReferralProgramPage> {
  late final ReferralRepository _repository =
      widget.repository ?? sl<ReferralRepository>();
  ReferralDetails? _details;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await _repository.getReferrals();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _error = failure.message; _loading = false; }),
      (value) => setState(() { _details = value; _loading = false; }),
    );
  }

  void _copy(String value, String label) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    context.showSnack('$label copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Referral Program'),
      ),
      body: _loading
          ? const _LoadingView()
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(onRefresh: _load, child: _Content(
                  details: _details!,
                  onCopy: _copy,
                  onShare: () {
                    final link = _details!.referralLink;
                    if (link.isEmpty) return;
                    ShareSheet.show(context, title: 'GoExperts invitation', link: link,
                      subtitle: 'Join me on GoExperts and grow with a trusted community.');
                  },
                )),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.details, required this.onCopy, required this.onShare});
  final ReferralDetails details;
  final void Function(String, String) onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final stats = details.stats;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 16, wide ? 32 : 16, 32),
        children: [
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960), child: Column(children: [
            _Hero(details: details, onCopy: onCopy, onShare: onShare),
            const SizedBox(height: 18),
            _ShareCard(details: details, onCopy: onCopy),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: wide ? 4 : 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: wide ? 1.6 : 1.35,
              children: [
                _Stat('Total referrals', '${stats.total}', Icons.people_alt_outlined, AppColors.info),
                _Stat('Pending', '${stats.pending}', Icons.schedule_rounded, AppColors.warning),
                _Stat('Rewarded', '${stats.rewarded}', Icons.verified_rounded, AppColors.success),
                _Stat('Total rewards', _formatReward(stats.totalReward), Icons.stars_rounded, const Color(0xFFD89A16)),
              ],
            ),
            const SizedBox(height: 24),
            const _HowItWorks(),
            const SizedBox(height: 24),
            _History(items: details.history),
          ])),
        ],
      );
    });
  }

  static String _formatReward(num value) => value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
}

class _Hero extends StatelessWidget {
  const _Hero({required this.details, required this.onCopy, required this.onShare});
  final ReferralDetails details; final void Function(String, String) onCopy; final VoidCallback onShare;
  @override Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 10))]),
    child: Stack(children: [
      Positioned(right: -10, top: -18, child: Icon(Icons.card_giftcard_rounded, size: 124, color: Colors.white.withValues(alpha: .10))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.redeem_rounded, color: Color(0xFFFFD66B), size: 32), const SizedBox(height: 22),
        Text('Invite. Earn. Grow together.', style: context.text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), Text('Share your pass with people who belong here.', style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .82))),
        const SizedBox(height: 22), Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          InkWell(onTap: () => onCopy(details.referralCode, 'Referral code'), borderRadius: BorderRadius.circular(12), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(details.referralCode.isEmpty ? 'Code unavailable' : details.referralCode,
              style: const TextStyle(color: Color(0xFF55101A), fontWeight: FontWeight.w800, letterSpacing: 1.2)), const SizedBox(width: 10), const Icon(Icons.copy_rounded, size: 17, color: AppColors.primary)]))),
          FilledButton.icon(onPressed: details.referralLink.isEmpty ? null : onShare, icon: const Icon(Icons.ios_share_rounded), label: const Text('Share invite'),
        )])
      ])
    ]),
  );
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.details, required this.onCopy}); final ReferralDetails details; final void Function(String, String) onCopy;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 116, height: 116, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: details.qrCode.isEmpty ? const _QrFallback() : Image.network(details.qrCode, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _QrFallback(), loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
    const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Scan or share', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 5),
      Text('Scan this QR code or copy your personal invitation link.', style: context.text.bodySmall), const SizedBox(height: 12),
      Container(padding: const EdgeInsets.only(left: 12), decoration: BoxDecoration(border: Border.all(color: context.theme.dividerColor), borderRadius: BorderRadius.circular(10)), child: Row(children: [
        Expanded(child: Text(details.referralLink.isEmpty ? 'Link unavailable' : details.referralLink, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall)),
        IconButton(tooltip: 'Copy referral link', onPressed: details.referralLink.isEmpty ? null : () => onCopy(details.referralLink, 'Referral link'), icon: const Icon(Icons.copy_rounded, size: 19))]))
    ]))
  ])));
}

class _QrFallback extends StatelessWidget { const _QrFallback(); @override Widget build(BuildContext context) => const Center(child: Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.mutedText)); }

class _Stat extends StatelessWidget { const _Stat(this.label, this.value, this.icon, this.color); final String label, value; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Icon(icon, color: color, size: 22), Text(value, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelMedium)
  ]))); }

class _HowItWorks extends StatelessWidget { const _HowItWorks(); @override Widget build(BuildContext context) { const steps = [('1','Share invite',Icons.send_rounded),('2','Friend joins',Icons.person_add_alt_1_rounded),('3','Earn reward',Icons.workspace_premium_rounded)]; return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('How it works', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 16), Row(children: [for (var i=0;i<steps.length;i++) ...[Expanded(child: Column(children: [CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .1), foregroundColor: AppColors.primary, child: Icon(steps[i].$3, size: 20)), const SizedBox(height: 8), Text(steps[i].$2, textAlign: TextAlign.center, style: context.text.labelMedium)])), if(i<2) Expanded(child: Divider(color: AppColors.primary.withValues(alpha: .25)))]] )]))); } }

class _History extends StatelessWidget { const _History({required this.items}); final List<Map<String,dynamic>> items;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Referral history', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
    if(items.isEmpty) Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20), child: Center(child: Column(children: [Icon(Icons.group_add_outlined, size: 44, color: context.theme.colorScheme.primary), const SizedBox(height: 12), Text('Your first invite starts here', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('Share your referral link. New referrals and rewards will appear here.', textAlign: TextAlign.center, style: context.text.bodySmall)]))))
    else ...items.map((item) { final title = item['name'] ?? item['email'] ?? item['referralCode'] ?? 'Referral'; final status = item['status'] ?? 'Invited'; final subtitle = item['createdAt'] ?? item['date'] ?? item['reward']; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)), title: Text(title.toString()), subtitle: subtitle == null ? null : Text(subtitle.toString()), trailing: Text(status.toString(), style: TextStyle(color: context.theme.colorScheme.primary, fontWeight: FontWeight.w700)))); })
  ]); }

class _LoadingView extends StatelessWidget { const _LoadingView(); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [Container(height: 250, decoration: BoxDecoration(color: context.theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24))), const SizedBox(height: 18), for(var i=0;i<3;i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(height: 100, decoration: BoxDecoration(color: context.theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16))))]); }
class _ErrorView extends StatelessWidget { const _ErrorView({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.primary), const SizedBox(height: 16), Text('Couldn’t load referrals', style: context.text.titleLarge), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center), const SizedBox(height: 20), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))]))); }
