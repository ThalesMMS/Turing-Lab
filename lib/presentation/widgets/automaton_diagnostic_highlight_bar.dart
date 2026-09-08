import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import 'collapsible_canvas_panel.dart';
import 'movable_canvas_panel_host.dart';

enum AutomatonDiagnosticHighlightKind { conflicts, epsilon }

/// Standalone canvas actions for inspecting transition diagnostics.
class AutomatonDiagnosticHighlightBar extends StatelessWidget {
  const AutomatonDiagnosticHighlightBar({
    super.key,
    required this.activeKind,
    required this.conflictCount,
    required this.onConflictSelected,
    this.floating = false,
    this.epsilonCount,
    this.onEpsilonSelected,
  });

  final bool floating;
  final AutomatonDiagnosticHighlightKind? activeKind;
  final int conflictCount;
  final ValueChanged<bool>? onConflictSelected;
  final int? epsilonCount;
  final ValueChanged<bool>? onEpsilonSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final content = Semantics(
      container: true,
      label: l10n.automataDiagnosticsCanvas,
      child: Material(
        key: const ValueKey('automaton-diagnostic-highlight-bar'),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _DiagnosticChip(
                key: const ValueKey('highlight-conflicting-transitions'),
                label: l10n.automataDiagnosticsConflicts(conflictCount),
                semanticLabel: l10n.automataDiagnosticsConflictAction(
                  (activeKind == AutomatonDiagnosticHighlightKind.conflicts)
                      .toString(),
                  conflictCount,
                ),
                hint: l10n.automataDiagnosticsConflictHint,
                icon: Icons.warning_amber_rounded,
                selected:
                    activeKind == AutomatonDiagnosticHighlightKind.conflicts,
                onSelected: conflictCount == 0 ? null : onConflictSelected,
              ),
              if (epsilonCount case final count?)
                _DiagnosticChip(
                  key: const ValueKey('highlight-epsilon-transitions'),
                  label: l10n.automataDiagnosticsEpsilon(count),
                  semanticLabel: l10n.automataDiagnosticsEpsilonAction(
                    (activeKind == AutomatonDiagnosticHighlightKind.epsilon)
                        .toString(),
                    count,
                  ),
                  hint: l10n.automataDiagnosticsEpsilonHint,
                  icon: Icons.alt_route,
                  selected:
                      activeKind == AutomatonDiagnosticHighlightKind.epsilon,
                  onSelected: count == 0 ? null : onEpsilonSelected,
                ),
            ],
          ),
        ),
      ),
    );
    if (!floating) return content;
    return MovableCanvasPanelHost(
      anchor: Alignment.topLeft,
      builder: (context, {required onDragDelta, required onPanelSizeChanged}) =>
          CollapsibleCanvasPanel(
            label: l10n.automataDiagnosticsCanvas,
            icon: Icons.rule,
            showCollapseButton: true,
            onDragDelta: onDragDelta,
            onPanelSizeChanged: onPanelSizeChanged,
            child: content,
          ),
    );
  }
}

class _DiagnosticChip extends StatelessWidget {
  const _DiagnosticChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String semanticLabel;
  final String hint;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        toggled: selected,
        label: semanticLabel,
        hint: hint,
        child: Tooltip(
          message: hint,
          excludeFromSemantics: true,
          child: FilterChip(
            selected: selected,
            avatar: Icon(selected ? Icons.visibility_off : icon, size: 18),
            label: Text(label),
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }
}
