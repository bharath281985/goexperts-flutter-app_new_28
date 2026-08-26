import 'package:flutter/material.dart';

import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import '../services/google_places_service.dart';
import '../utils/field_hint_utils.dart';
import 'location_search_sheet.dart';

/// Location field with Google Places search and selection.
class AppLocationField extends StatelessWidget {
  const AppLocationField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.country,
    this.validator,
    this.onPlaceSelected,
    this.placesService,
    this.onAutoDetect,
    this.autoDetectTooltip = 'Use current location',
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? country;
  final String? Function(String?)? validator;
  final ValueChanged<SelectedPlace>? onPlaceSelected;
  final GooglePlacesService? placesService;
  final Future<void> Function()? onAutoDetect;
  final String autoDetectTooltip;

  Future<void> _openSearch(BuildContext context) async {
    final selected = await LocationSearchSheet.show(
      context,
      initialQuery: controller.text,
      country: country,
      placesService: placesService,
    );
    if (selected == null) return;

    controller.text = selected.formattedAddress;
    onPlaceSelected?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = label?.trim();
    final generatedHint = normalizedLabel == null || normalizedLabel.isEmpty
        ? (hint ?? 'Select Location')
        : selectHintForLabel(normalizedLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: context.text.titleSmall),
          AppSizes.vGapSm,
        ],
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _openSearch(context),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint ?? generatedHint,
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              size: AppSizes.iconMd,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onAutoDetect != null)
                  IconButton(
                    tooltip: autoDetectTooltip,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    onPressed: () async => onAutoDetect?.call(),
                    icon: const Icon(Icons.my_location_outlined),
                  ),
                IconButton(
                  tooltip: 'Search location',
                  onPressed: () => _openSearch(context),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
