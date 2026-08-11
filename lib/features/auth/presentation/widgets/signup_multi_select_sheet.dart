import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Searchable chip selection bottom sheet for Skills and Master Goals
class SignupMultiSelectSheet extends StatelessWidget {
  final String label;
  final List<String> selectedItems;
  final List<String> availableOptions;
  final ValueChanged<List<String>> onChanged;
  final int minSelection;
  final Future<List<String>> Function(String query)? onSearchApi;
  final String? errorText;

  const SignupMultiSelectSheet({
    super.key,
    required this.label,
    required this.selectedItems,
    required this.availableOptions,
    required this.onChanged,
    this.minSelection = 1,
    this.onSearchApi,
    this.errorText,
  });

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: _MultiSelectContent(
              title: label,
              selectedItems: selectedItems,
              initialOptions: availableOptions,
              minSelection: minSelection,
              onSearchApi: onSearchApi,
              onConfirm: (items) {
                onChanged(items);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              '${selectedItems.length} Selected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selectedItems.length < minSelection
                    ? Colors.red
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        AppTextField(
          key: ValueKey(selectedItems.join('|')),
          initialValue: selectedItems.join(', '),
          hint: 'Tap to search & select $label...',
          readOnly: true,
          onTap: () => _showSheet(context),
          suffixIcon: const Icon(Icons.search),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _MultiSelectContent extends StatefulWidget {
  final String title;
  final List<String> selectedItems;
  final List<String> initialOptions;
  final int minSelection;
  final Future<List<String>> Function(String query)? onSearchApi;
  final ValueChanged<List<String>> onConfirm;

  const _MultiSelectContent({
    required this.title,
    required this.selectedItems,
    required this.initialOptions,
    required this.minSelection,
    this.onSearchApi,
    required this.onConfirm,
  });

  @override
  State<_MultiSelectContent> createState() => _MultiSelectContentState();
}

class _MultiSelectContentState extends State<_MultiSelectContent> {
  late List<String> _currentSelected;
  List<String> _options = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentSelected = List.from(widget.selectedItems);
    _options = List.from(widget.initialOptions);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (widget.onSearchApi != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (query.trim().isEmpty) {
          setState(() {
            _options = widget.initialOptions;
          });
          return;
        }

        setState(() => _isLoading = true);
        try {
          final results = await widget.onSearchApi!(query.trim());
          setState(() {
            _options = results;
            _isLoading = false;
          });
        } catch (_) {
          setState(() => _isLoading = false);
        }
      });
    } else {
      setState(() {
        if (query.isEmpty) {
          _options = widget.initialOptions;
        } else {
          _options = widget.initialOptions
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      });
    }
  }

  void _toggleItem(String item) {
    setState(() {
      if (_currentSelected.contains(item)) {
        _currentSelected.remove(item);
      } else {
        _currentSelected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select ${widget.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${_currentSelected.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field with Debounce
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search ${widget.title}...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Options List
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = _options[index];
                final isSelected = _currentSelected.contains(item);

                return CheckboxListTile(
                  title: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  activeColor: AppColors.primary,
                  value: isSelected,
                  onChanged: (_) => _toggleItem(item),
                );
              },
            ),
          ),

          // Confirm Button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(_currentSelected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply (${_currentSelected.length} Selected)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
