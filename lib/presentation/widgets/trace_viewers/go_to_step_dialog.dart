//
//  go_to_step_dialog.dart
//  Turing Lab
//
//  Dialog used by BaseTraceViewer to jump to a 1-based simulation step
//  number. Validation is a pure function so it can be tested without UI.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../localization/locale_value_formatter.dart';

/// Reasons a go-to-step value is rejected.
enum GoToStepError { empty, notInteger, outOfRange }

/// Result of [parseGoToStep]: either a zero-based index or an error.
typedef GoToStepParse = ({int? index, GoToStepError? error});

/// Parses a user-entered 1-based step number against a trace of
/// [totalSteps] steps and returns the zero-based index or the error.
GoToStepParse parseGoToStep(String raw, int totalSteps) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (index: null, error: GoToStepError.empty);
  }
  final value = int.tryParse(trimmed);
  if (value == null) {
    return (index: null, error: GoToStepError.notInteger);
  }
  if (value < 1 || value > totalSteps) {
    return (index: null, error: GoToStepError.outOfRange);
  }
  return (index: value - 1, error: null);
}

String localizeGoToStepError(
  AppLocalizations l10n,
  GoToStepError error,
  int totalSteps,
) {
  return switch (error) {
    GoToStepError.empty => l10n.goToStepEmptyError,
    GoToStepError.notInteger => l10n.goToStepNotIntegerError,
    GoToStepError.outOfRange => l10n.goToStepOutOfRangeError(totalSteps),
  };
}

/// Shows the go-to-step dialog and returns the chosen zero-based index, or
/// null when the dialog is cancelled or dismissed.
Future<int?> showGoToStepDialog(
  BuildContext context, {
  required int totalSteps,
  required int currentIndex,
  void Function(BuildContext dialogContext)? onDialogContext,
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      onDialogContext?.call(dialogContext);
      return GoToStepDialog(totalSteps: totalSteps, currentIndex: currentIndex);
    },
  );
}

class GoToStepDialog extends StatefulWidget {
  const GoToStepDialog({
    super.key,
    required this.totalSteps,
    required this.currentIndex,
  });

  static const Key fieldKey = ValueKey('trace_go_to_step_field');
  static const Key confirmKey = ValueKey('trace_go_to_step_confirm');
  static const Key cancelKey = ValueKey('trace_go_to_step_cancel');

  final int totalSteps;
  final int currentIndex;

  @override
  State<GoToStepDialog> createState() => _GoToStepDialogState();
}

class _GoToStepDialogState extends State<GoToStepDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.currentIndex + 1}',
  );
  GoToStepError? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = parseGoToStep(_controller.text, widget.totalSteps);
    if (parsed.error != null) {
      setState(() => _error = parsed.error);
      return;
    }
    Navigator.of(context).pop(parsed.index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final error = _error;
    return AlertDialog(
      title: Text(l10n.goToStep),
      content: TextField(
        key: GoToStepDialog.fieldKey,
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        decoration: InputDecoration(
          labelText: formatter.integersInLocalizedText(
            l10n.goToStepFieldLabel(widget.totalSteps),
            [widget.totalSteps],
          ),
          errorText: error == null
              ? null
              : formatter.integersInLocalizedText(
                  localizeGoToStepError(l10n, error, widget.totalSteps),
                  [widget.totalSteps],
                ),
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          key: GoToStepDialog.cancelKey,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: GoToStepDialog.confirmKey,
          onPressed: _submit,
          child: Text(l10n.goToStepConfirm),
        ),
      ],
    );
  }
}
