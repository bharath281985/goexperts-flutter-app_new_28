import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';

/// Bottom sheet for viewing, editing, or updating the status of an investment offer.
Future<bool?> showInvestmentEditSheet(
  BuildContext context, {
  required Deal deal,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => InvestmentEditSheet(deal: deal),
  );
}

class InvestmentEditSheet extends StatefulWidget {
  const InvestmentEditSheet({super.key, required this.deal});
  final Deal deal;

  @override
  State<InvestmentEditSheet> createState() => _InvestmentEditSheetState();
}

class _InvestmentEditSheetState extends State<InvestmentEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _equityCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.deal.amount.toStringAsFixed(0),
    );
    _equityCtrl = TextEditingController(
      text: widget.deal.equity.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _equityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = sl<InvestorRepository>();
    final payload = {
      'offer': double.tryParse(_amountCtrl.text.trim()) ?? widget.deal.amount,
      'equity': double.tryParse(_equityCtrl.text.trim()) ?? widget.deal.equity,
    };

    final result = await repo.updateInvestment(widget.deal.id, payload);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack('Investment offer updated');
        Navigator.pop(context, true);
      },
    );
  }

  Future<void> _cancelOffer() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Withdraw Offer?',
      message: 'Are you sure you want to withdraw this investment offer?',
      confirmLabel: 'Withdraw Offer',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    final repo = sl<InvestorRepository>();
    final result = await repo.updateInvestmentStatus(widget.deal.id, 'cancelled');

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack('Investment offer withdrawn');
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.md,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              AppSizes.vGapMd,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Investment Offer',
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.deal.startupName,
                          style: context.text.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              AppSizes.vGapLg,
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Offer Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    AppSizes.vGapMd,
                    TextFormField(
                      controller: _equityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Equity Percentage (%)',
                        prefixIcon: Icon(Icons.pie_chart_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final d = double.tryParse(v.trim());
                        if (d == null || d <= 0 || d > 100) return '0–100';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              AppSizes.vGapLg,
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Withdraw Offer',
                      icon: Icons.cancel_outlined,
                      onPressed: _saving ? null : _cancelOffer,
                    ),
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Save Changes',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
