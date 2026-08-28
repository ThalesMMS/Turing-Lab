import 'package:flutter/material.dart';

import '../../core/models/pda_acceptance_mode.dart';
import '../../l10n/app_localizations_resolver.dart';

/// Edits the acceptance rule stored in the active PDA document.
class PdaAcceptanceModeControl extends StatelessWidget {
  const PdaAcceptanceModeControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const narrowBreakpoint = 520.0;

  final PDAAcceptanceMode value;
  final ValueChanged<PDAAcceptanceMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Semantics(
      key: const ValueKey('pda-acceptance-mode-semantics'),
      container: true,
      label: l10n.acceptanceModeLabel(
        pdaAcceptanceModeLabel(context, value),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < narrowBreakpoint) {
            return _buildNarrow(context);
          }
          return _buildWide(context);
        },
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('pda-acceptance-layout-narrow'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PDAAcceptanceMode>(
              key: const ValueKey('pda-acceptance-mode-dropdown'),
              value: value,
              isDense: true,
              isExpanded: true,
              selectedItemBuilder: (context) => [
                for (final mode in PDAAcceptanceMode.values)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      appLocalizationsOf(context).acceptanceModeLabel(
                        pdaAcceptanceModeLabel(context, mode),
                      ),
                    ),
                  ),
              ],
              onChanged: enabled
                  ? (mode) {
                      if (mode != null && mode != value) onChanged(mode);
                    }
                  : null,
              items: [
                for (final mode in PDAAcceptanceMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(pdaAcceptanceModeLabel(context, mode)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _ExplanationText(
          text: pdaAcceptanceModeCompactExplanation(context, value),
        ),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    final tiles = PDAAcceptanceMode.values
        .map(
          (mode) => _AcceptanceModeTile(
            mode: mode,
            selected: mode == value,
            enabled: enabled,
          ),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).pdaAcceptanceModeTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        RadioGroup<PDAAcceptanceMode>(
          groupValue: value,
          onChanged: (mode) {
            if (enabled && mode != null && mode != value) onChanged(mode);
          },
          child: Row(
            key: const ValueKey('pda-acceptance-layout-wide'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                Expanded(child: tiles[index]),
                if (index != tiles.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _ExplanationText(
          text: pdaAcceptanceModeExplanation(context, value),
        ),
      ],
    );
  }
}

class _ExplanationText extends StatelessWidget {
  const _ExplanationText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('pda-acceptance-mode-explanation'),
      container: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _AcceptanceModeTile extends StatelessWidget {
  const _AcceptanceModeTile({
    required this.mode,
    required this.selected,
    required this.enabled,
  });

  final PDAAcceptanceMode mode;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color:
          selected ? colors.secondaryContainer : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<PDAAcceptanceMode>(
        key: ValueKey('pda-acceptance-mode-${mode.name}'),
        value: mode,
        enabled: enabled,
        selected: selected,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(pdaAcceptanceModeLabel(context, mode)),
      ),
    );
  }
}

String pdaAcceptanceModeLabel(
  BuildContext context,
  PDAAcceptanceMode mode,
) {
  final l10n = appLocalizationsOf(context);
  return switch (mode) {
    PDAAcceptanceMode.finalState => l10n.pdaAcceptanceFinalState,
    PDAAcceptanceMode.emptyStack => l10n.pdaAcceptanceEmptyStack,
    PDAAcceptanceMode.both => l10n.pdaAcceptanceBoth,
  };
}

String pdaAcceptanceModeExplanation(
  BuildContext context,
  PDAAcceptanceMode mode,
) {
  final l10n = appLocalizationsOf(context);
  return switch (mode) {
    PDAAcceptanceMode.finalState => l10n.pdaAcceptanceFinalStateExplanation,
    PDAAcceptanceMode.emptyStack => l10n.pdaAcceptanceEmptyStackExplanation,
    PDAAcceptanceMode.both => l10n.pdaAcceptanceBothExplanation,
  };
}

String pdaAcceptanceModeCompactExplanation(
  BuildContext context,
  PDAAcceptanceMode mode,
) {
  final l10n = appLocalizationsOf(context);
  return switch (mode) {
    PDAAcceptanceMode.finalState =>
      l10n.pdaAcceptanceFinalStateCompactExplanation,
    PDAAcceptanceMode.emptyStack =>
      l10n.pdaAcceptanceEmptyStackCompactExplanation,
    PDAAcceptanceMode.both => l10n.pdaAcceptanceBothCompactExplanation,
  };
}
