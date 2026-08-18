import 'package:flutter/material.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import '../utils/field_hint_utils.dart';

/// Labeled dropdown field.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.value,
    this.label,
    this.hint,
    this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final String? label;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = label?.trim();
    final generatedHint = normalizedLabel == null || normalizedLabel.isEmpty
        ? hint
        : selectHintForLabel(normalizedLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(context.tr(label!), style: context.text.titleSmall),
          AppSizes.vGapSm,
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          style: context.text.bodyMedium,
          validator: validator,
          decoration: InputDecoration(
            hintText: generatedHint == null ? null : context.tr(generatedHint),
            hintStyle: context.theme.inputDecorationTheme.hintStyle,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: AppSizes.iconMd)
                : null,
          ),
          items: [
            if (value != null && !items.contains(value))
              DropdownMenuItem<T>(
                value: value,
                child: Text(
                  context.tr(itemLabel(value as T)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ...items.map(
              (e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  context.tr(itemLabel(e)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
