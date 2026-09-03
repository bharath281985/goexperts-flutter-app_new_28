import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import 'gradient_icon.dart';

/// A tab definition for [AppBottomNavigation].
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeCount = 0,
    this.badgeText,
    this.badgeWidget,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;
  final String? badgeText;
  final Widget? badgeWidget;
}

/// Branded bottom navigation bar shared by every role shell.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border(top: BorderSide(color: context.theme.dividerColor)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavCell(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : context.text.bodySmall?.color;
    final iconWidget = selected
        ? GradientIcon(
            icon: item.activeIcon,
            size: 24,
            colors: [context.colors.primary, context.colors.secondary],
          )
        : Icon(
            item.icon,
            color: color,
            size: 24,
          );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.badgeWidget != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  Positioned(
                    top: -1,
                    right: -4,
                    child: item.badgeWidget!,
                  ),
                ],
              )
            else
              Badge(
                isLabelVisible: item.badgeText != null
                    ? item.badgeText!.isNotEmpty
                    : item.badgeCount > 0,
                label: Text(item.badgeText ?? '${item.badgeCount}'),
                child: iconWidget,
              ),
            const SizedBox(height: 3),
            Text(
              context.tr(item.label),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
