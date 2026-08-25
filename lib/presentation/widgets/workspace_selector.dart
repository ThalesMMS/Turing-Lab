//
//  workspace_selector.dart
//  Turing Lab
//
//  Compact workspace switcher shown at the leading edge of the global app
//  bar on wide viewports. Replaces the permanent navigation rail so the
//  canvas keeps the full width of the window.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_help.dart';
import 'mobile_navigation.dart';

/// Drop-down that switches between the FSA, Grammar, PDA, TM, Regex and
/// Pumping workspaces from a single app-bar control.
class WorkspaceSelector extends StatelessWidget {
  const WorkspaceSelector({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  /// Width the app bar must reserve for the selector.
  static const double leadingWidth = 176;

  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = jflapLocalizationsOf(context);
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final current = items[safeIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        menuChildren: [
          for (final entry in items.asMap().entries)
            MenuItemButton(
              onPressed: () => onSelected(entry.key),
              leadingIcon: Icon(
                entry.value.icon,
                color: entry.key == safeIndex
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              trailingIcon: entry.key == safeIndex
                  ? Icon(Icons.check, size: 18, color: colorScheme.primary)
                  : null,
              child: Semantics(
                label: l10n.navigateTo(entry.value.label),
                hint: entry.value.description,
                button: true,
                enabled: true,
                selected: entry.key == safeIndex,
                excludeSemantics: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: entry.key == safeIndex
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: entry.key == safeIndex
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        entry.value.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        builder: (context, controller, _) {
          return Semantics(
            label: l10n.workspaceSelectorLabel(current.label),
            hint: l10n.workspaceSelectorHint,
            button: true,
            enabled: true,
            excludeSemantics: true,
            child: Tooltip(
              message: l10n.workspaceSelectorHint,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(current.icon, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          current.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
