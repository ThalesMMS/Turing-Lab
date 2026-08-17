import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_resolver.dart';

/// Shared responsive actions used by all automaton transition editors.
class TransitionEditorActions extends StatelessWidget {
  const TransitionEditorActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.onDelete,
    this.cancelLabel,
    this.deleteLabel,
    this.saveLabel,
    this.baseFocusOrder = 0,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final String? cancelLabel;
  final String? deleteLabel;
  final String? saveLabel;
  final double baseFocusOrder;

  Widget _ordered(double order, Widget child) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(baseFocusOrder + order),
      child: child,
    );
  }

  Widget _cancelButton(String label) {
    return _ordered(
      0,
      OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _deleteButton(BuildContext context, String label) {
    return _ordered(
      1,
      OutlinedButton(
        onPressed: onDelete,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _saveButton(String label) {
    return _ordered(
      onDelete == null ? 1 : 2,
      FilledButton(
        onPressed: onSave,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = <Widget>[
          _cancelButton(cancelLabel ?? l10n.transitionEditorCancel),
          if (onDelete != null)
            _deleteButton(
              context,
              deleteLabel ?? l10n.transitionEditorDelete,
            ),
          _saveButton(saveLabel ?? l10n.transitionEditorSave),
        ];
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                actions[index],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(child: actions[index]),
            ],
          ],
        );
      },
    );
  }
}
