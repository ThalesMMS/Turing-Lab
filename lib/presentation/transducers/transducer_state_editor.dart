import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/transducers/transducers.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../l10n/app_localizations_resolver.dart';

final class TransducerStateEdit {
  TransducerStateEdit({
    required this.label,
    required this.isInitial,
    Iterable<String>? outputTokens,
  }) : outputTokens = outputTokens == null
            ? null
            : List<String>.unmodifiable(outputTokens);

  final String label;
  final bool isInitial;
  final List<String>? outputTokens;
}

typedef TransducerStateOutputValidator = String? Function(List<String> output);

Future<TransducerStateEdit?> showTransducerStateEditor(
  BuildContext context, {
  required GraphViewCanvasNode node,
  required TransducerEmissionRule emissionRule,
  required TransducerOutputWord? stateOutput,
  VoidCallback? onDelete,
  TransducerStateOutputValidator? outputValidator,
}) =>
    showDialog<TransducerStateEdit>(
      context: context,
      builder: (dialogContext) => _TransducerStateEditorDialog(
        node: node,
        emissionRule: emissionRule,
        stateOutput: stateOutput,
        onDelete: onDelete,
        outputValidator: outputValidator,
      ),
    );

final class _TransducerStateEditorDialog extends StatefulWidget {
  const _TransducerStateEditorDialog({
    required this.node,
    required this.emissionRule,
    required this.stateOutput,
    required this.onDelete,
    required this.outputValidator,
  });

  final GraphViewCanvasNode node;
  final TransducerEmissionRule emissionRule;
  final TransducerOutputWord? stateOutput;
  final VoidCallback? onDelete;
  final TransducerStateOutputValidator? outputValidator;

  @override
  State<_TransducerStateEditorDialog> createState() =>
      _TransducerStateEditorDialogState();
}

final class _TransducerStateEditorDialogState
    extends State<_TransducerStateEditorDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _outputController;
  late final FocusNode _outputFocus;
  late bool _isInitial;
  String? _outputError;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.node.label);
    _outputController = TextEditingController(
      text: widget.stateOutput?.values.join('\n') ?? '',
    );
    _outputFocus = FocusNode();
    _isInitial = widget.node.isInitial;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _outputController.dispose();
    _outputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: AlertDialog(
          scrollable: true,
          title: Text(l10n.transducerEditState),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('transducer-state-label'),
                    autofocus: true,
                    controller: _labelController,
                    decoration: InputDecoration(
                      labelText: l10n.transducerStateName,
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isInitial,
                    onChanged: (value) {
                      setState(() => _isInitial = value ?? false);
                    },
                    title: Text(l10n.transducerInitialState),
                  ),
                  if (widget.emissionRule is MooreEmissionRule)
                    TextField(
                      key: const Key('transducer-state-output'),
                      controller: _outputController,
                      focusNode: _outputFocus,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.transducerOutputTokens,
                        helperText: l10n.transducerOutputTokensHint,
                        errorText: _outputError,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (widget.onDelete != null)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDelete!();
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.transducerDeleteState),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                final output = _outputController.text
                    .split('\n')
                    .where((token) => token.isNotEmpty)
                    .toList(growable: false);
                final error = widget.emissionRule is MooreEmissionRule
                    ? widget.outputValidator?.call(output)
                    : null;
                if (error != null) {
                  setState(() => _outputError = error);
                  _outputFocus.requestFocus();
                  return;
                }
                Navigator.of(context).pop(
                  TransducerStateEdit(
                    label: _labelController.text,
                    isInitial: _isInitial,
                    outputTokens: widget.emissionRule is MooreEmissionRule
                        ? output
                        : null,
                  ),
                );
              },
              child: Text(l10n.transducerSave),
            ),
          ],
        ),
      ),
    );
  }
}
