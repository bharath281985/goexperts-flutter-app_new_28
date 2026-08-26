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
    this.prefixWidget,
    this.onTap,
  });

  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final String? label;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = label?.trim();
    final generatedHint = normalizedLabel == null || normalizedLabel.isEmpty
        ? hint
        : selectHintForLabel(normalizedLabel);
    final uniqueItems = items.toSet().toList(growable: false);

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
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint ?? generatedHint,
            hintStyle: context.theme.inputDecorationTheme.hintStyle,
            prefixIcon: prefixWidget != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: prefixWidget,
                  )
                : prefixIcon != null
                    ? Icon(prefixIcon, size: AppSizes.iconMd)
                    : null,
            prefixIconConstraints: prefixWidget != null
                ? const BoxConstraints(minWidth: 40, minHeight: 24)
                : null,
          ),
          items: [
            if (value != null && !uniqueItems.contains(value))
              DropdownMenuItem<T>(
                value: value,
                child: Text(
                  context.tr(itemLabel(value as T)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ...uniqueItems.map(
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
