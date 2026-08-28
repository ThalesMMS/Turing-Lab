//
//  workspace_selector.dart
//  Turing Lab
//
//  Workspace switcher shared by compact and wide app-bar layouts.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_help.dart';
import 'navigation_item.dart';

/// Drop-down that switches between every registered workspace.
class WorkspaceSelector extends StatelessWidget {
  const WorkspaceSelector({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.compact = false,
  });

  /// Width the app bar must reserve for the selector.
  static const double leadingWidth = 176;

  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Whether the selector is rendered in the compact app-bar title slot.
  final bool compact;

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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 8,
        vertical: compact ? 4 : 6,
      ),
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
                        maxLines: 2,
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
            expanded: controller.isOpen,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            excludeSemantics: true,
            child: Tooltip(
              message: l10n.workspaceSelectorHint,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 4 : 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      Icon(current.icon, size: 20, color: colorScheme.primary),
                      SizedBox(width: compact ? 4 : 8),
                      Flexible(
                        child: Text(
                          current.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        semanticLabel: l10n.workspaceSelectorHint,
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
