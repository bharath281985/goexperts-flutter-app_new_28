import 'package:flutter/material.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import '../utils/formatters.dart';

/// Tappable date field wrapping the Material date picker.
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint = 'Select date',
    this.firstDate,
    this.lastDate,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final String hint;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveFirst = firstDate != null
        ? DateTime(firstDate!.year, firstDate!.month, firstDate!.day)
        : DateTime(now.year - 10);
    final effectiveLast = lastDate != null
        ? DateTime(lastDate!.year, lastDate!.month, lastDate!.day)
        : DateTime(now.year + 10);

    DateTime initial = value != null
        ? DateTime(value!.year, value!.month, value!.day)
        : today;

    if (initial.isBefore(effectiveFirst)) {
      initial = effectiveFirst;
    }
    if (initial.isAfter(effectiveLast)) {
      initial = effectiveLast;
    }

    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: effectiveFirst,
        lastDate: effectiveLast,
      );
      if (picked != null) onChanged(picked);
    } catch (e) {
      debugPrint('AppDatePicker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.text.titleSmall),
          AppSizes.vGapSm,
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _pick(context),
          child: AbsorbPointer(
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  size: AppSizes.iconSm,
                ),
              ),
              child: Text(
                value != null ? Formatters.date(value!) : hint,
                style: value != null
                    ? context.text.bodyMedium
                    : context.text.bodyMedium?.copyWith(
                        color: context.text.bodySmall?.color,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
