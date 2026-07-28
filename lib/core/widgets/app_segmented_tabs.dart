import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';

class AppSegmentedTabs extends StatefulWidget {
  final Map<String, Widget> tabs;
  const AppSegmentedTabs({super.key, required this.tabs});

  @override
  State<AppSegmentedTabs> createState() => _AppSegmentedTabsState();
}

class _AppSegmentedTabsState extends State<AppSegmentedTabs> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final keys = widget.tabs.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(keys.length, (index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlack.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      keys[index],
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.warning
                            : AppColors.projectSecondaryText,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: widget.tabs[keys[_currentIndex]]!,
        ),
      ],
    );
  }
}
