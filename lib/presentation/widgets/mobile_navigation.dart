//
//  mobile_navigation.dart
//  Turing Lab
//
//  Provides a mobile-optimized bottom navigation bar with configurable
//  items, icons, labels, and descriptions to support multiple app modules
//  on compact screens.
//  Applies Material 3 styling with SafeArea, subtle shadows, and an
//  active-item highlight, keeping the menu accessible and easy to extend.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_help.dart';
import 'navigation_item.dart';

export 'navigation_item.dart';

/// Mobile-optimized bottom navigation widget
class MobileNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;

  const MobileNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (items.isEmpty) return const SizedBox.shrink();
                final entries = items.asMap().entries;
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : items.length * 44;
                final availableColumns = (width / 44).floor().clamp(
                  1,
                  items.length,
                );
                if (items.length <= 5 && availableColumns == items.length) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in entries)
                        Expanded(child: _buildItem(context, entry)),
                    ],
                  );
                }

                final columns = availableColumns.clamp(1, 4);
                final itemWidth = width / columns;
                return Wrap(
                  children: [
                    for (final entry in entries)
                      SizedBox(
                        width: itemWidth,
                        child: _buildItem(context, entry),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, MapEntry<int, NavigationItem> entry) {
    final index = entry.key;
    return _buildNavigationItem(
      context,
      entry.value,
      currentIndex == index,
      () => onTap(index),
      key: ValueKey('mobile_navigation_item_$index'),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap, {
    required Key key,
  }) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = jflapLocalizationsOf(context);
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return Semantics(
      label: l10n.navigateTo(item.label),
      hint: item.description,
      button: true,
      enabled: true,
      selected: isSelected,
      excludeSemantics: true,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(item.icon, color: color),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
