import 'package:flutter/material.dart';

import '../../l10n/app_localizations_help.dart';
import 'mobile_navigation.dart';

/// Desktop-optimized navigation rail mirroring the mobile navigation items.
class DesktopNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> items;
  final bool extended;

  const DesktopNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Derived from the theme's label style so the rail keeps the app's
    // typography; a bare TextStyle here would drop the typeface.
    final labelStyle = theme.textTheme.labelMedium ?? const TextStyle();
    final l10n = jflapLocalizationsOf(context);

    return NavigationRail(
      selectedIndex: currentIndex,
      groupAlignment: -1,
      scrollable: true,
      extended: extended,
      minWidth: 80,
      labelType:
          extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
      selectedLabelTextStyle: labelStyle.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: labelStyle.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        fontSize: 12,
      ),
      destinations: [
        for (final item in items.asMap().entries)
          NavigationRailDestination(
            icon: Tooltip(
              waitDuration: const Duration(milliseconds: 250),
              message: item.value.description,
              child: ExcludeSemantics(child: Icon(item.value.icon)),
            ),
            selectedIcon: Tooltip(
              waitDuration: const Duration(milliseconds: 150),
              message: item.value.description,
              child: ExcludeSemantics(child: Icon(item.value.icon)),
            ),
            label: Semantics(
              label: l10n.navigateTo(item.value.label),
              hint: item.value.description,
              button: true,
              enabled: true,
              selected: currentIndex == item.key,
              excludeSemantics: true,
              child: Text(item.value.label),
            ),
          ),
      ],
      onDestinationSelected: onDestinationSelected,
    );
  }
}
