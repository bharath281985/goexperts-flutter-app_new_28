import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class ContractFormPage extends StatefulWidget {
  const ContractFormPage({
    super.key,
    this.contract,
    this.initialProposalId,
    this.initialProjectId,
    this.initialFreelancerName,
  });

  final Contract? contract;
  final String? initialProposalId;
  final String? initialProjectId;
  final String? initialFreelancerName;

  @override
  State<ContractFormPage> createState() => _ContractFormPageState();
}

class _ContractFormPageState extends State<ContractFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _projectCtrl;
  late final TextEditingController _counterpartyCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _termsCtrl;

  DateTime? _startDate;
  DateTime? _endDate;
  final List<Map<String, dynamic>> _milestones = [];
  bool _saving = false;

  bool get _isEditing => widget.contract != null;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    _titleCtrl = TextEditingController(
      text: c?.projectTitle ?? 'Project Contract',
    );
    _projectCtrl = TextEditingController(
      text: c?.projectTitle ?? widget.initialProjectId ?? 'Linked Project',
    );
    _counterpartyCtrl = TextEditingController(
      text: c?.counterpartyName ?? widget.initialFreelancerName ?? 'Freelancer',
    );
    _amountCtrl = TextEditingController(
      text: c != null ? c.amount.toStringAsFixed(0) : '',
    );
    _termsCtrl = TextEditingController(
      text: 'Standard legal terms and milestones apply to this contract.',
    );

    if (c != null) {
      _startDate = c.startDate;
      for (final m in c.milestones) {
        _milestones.add({
          'title': m.title,
          'amount': m.amount,
          'dueDate': m.dueDate,
        });
      }
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _projectCtrl.dispose();
    _counterpartyCtrl.dispose();
    _amountCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add({
        'title': 'Milestone ${_milestones.length + 1}',
        'amount': 5000.0,
        'dueDate': DateTime.now().add(
          Duration(days: (_milestones.length + 1) * 7),
        ),
      });
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final payload = {
      'title': _titleCtrl.text.trim(),
      'projectTitle': _projectCtrl.text.trim(),
      'counterpartyName': _counterpartyCtrl.text.trim(),
      'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'terms': _termsCtrl.text.trim(),
      'proposalId': widget.initialProposalId,
      'milestones': _milestones
          .map(
            (m) => {
              'title': m['title'],
              'amount': m['amount'],
              'dueDate': (m['dueDate'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
    };

    final repo = sl<ProjectRepository>();
    final result = _isEditing
        ? await repo.updateContract(widget.contract!.id, payload)
        : await repo.createContract(payload);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => context.showSnack(failure.message, isError: true),
      (contract) {
        context.showSnack(_isEditing ? 'Contract updated' : 'Contract created');
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contract' : 'Create Contract'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          decoration: BoxDecoration(
            color: context.theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: AppPrimaryButton(
            label: _isEditing ? 'Save Contract' : 'Create Contract',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            // Section 1: Overview
            _SectionHeader(
              title: 'Contract Overview',
              icon: Icons.description_outlined,
            ),
            AppSizes.vGapSm,
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    controller: _titleCtrl,
                    label: 'Contract Title',
                    hint: 'e.g. Mobile App Development Contract',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _projectCtrl,
                    label: 'Linked Project',
                    hint: 'Project name or ID',
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _counterpartyCtrl,
                    label: 'Counterparty / Freelancer',
                    hint: 'Party name',
                  ),
                ],
              ),
            ),
            AppSizes.vGapLg,

            // Section 2: Pricing & Dates
            _SectionHeader(
              title: 'Financials & Schedule',
              icon: Icons.payments_outlined,
            ),
            AppSizes.vGapSm,
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    controller: _amountCtrl,
                    label: 'Total Contract Value (₹)',
                    hint: 'e.g. 50000',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if ((double.tryParse(v.trim()) ?? 0) <= 0)
                        return 'Must be > 0';
                      return null;
                    },
                  ),
                  AppSizes.vGapMd,
                  Row(
                    children: [
                      Expanded(
                        child: AppDatePicker(
                          label: 'Start Date',
                          value: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(hours: 12)),
                          onChanged: (d) => setState(() {
                            _startDate = d;
                            if (_endDate != null &&
                                (_endDate!.isBefore(d) || _endDate!.isAtSameMomentAs(d))) {
                              _endDate = null;
                            }
                          }),
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: AppDatePicker(
                          label: 'End Date',
                          value: _endDate,
                          firstDate: _startDate != null
                              ? _startDate!.add(const Duration(days: 1))
                              : DateTime.now().add(const Duration(days: 1)),
                          onChanged: (d) => setState(() => _endDate = d),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSizes.vGapLg,

            // Section 3: Milestones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: 'Milestones', icon: Icons.flag_outlined),
                TextButton.icon(
                  onPressed: _addMilestone,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Milestone'),
                ),
              ],
            ),
            AppSizes.vGapSm,
            if (_milestones.isEmpty)
              const AppCard(
                child: Center(
                  child: Text(
                    'No milestones added yet.',
                    style: TextStyle(color: AppColors.mutedText),
                  ),
                ),
              ),
            for (var i = 0; i < _milestones.length; i++)
              AppCard(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      color: AppColors.mutedText,
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _milestones[i]['title'] as String,
                            style: context.text.titleSmall,
                          ),
                          Text(
                            '${Formatters.compactCurrency(_milestones[i]['amount'] as double)} · Due ${Formatters.date(_milestones[i]['dueDate'] as DateTime)}',
                            style: context.text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      onPressed: () => _removeMilestone(i),
                    ),
                  ],
                ),
              ),
            AppSizes.vGapLg,

            // Section 4: Terms
            _SectionHeader(
              title: 'Terms & Conditions',
              icon: Icons.gavel_outlined,
            ),
            AppSizes.vGapSm,
            AppCard(
              child: AppTextField(
                controller: _termsCtrl,
                label: 'Contract Terms',
                hint: 'Enter terms and scope details...',
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        AppSizes.hGapSm,
        Text(
          title,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
