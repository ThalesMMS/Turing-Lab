import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations_resolver.dart';

typedef TransducerTransitionValidator = ({
  String? inputError,
  String? outputError,
})
    Function(String input, List<String> output);

final class TransducerTransitionEditor extends StatefulWidget {
  const TransducerTransitionEditor({
    super.key,
    required this.initialInput,
    required this.initialOutput,
    required this.onSubmit,
    required this.onCancel,
    this.showOutput = true,
    this.validator,
    this.onDelete,
  });

  final String initialInput;
  final List<String> initialOutput;
  final void Function(String input, List<String> output) onSubmit;
  final VoidCallback onCancel;
  final bool showOutput;
  final TransducerTransitionValidator? validator;
  final VoidCallback? onDelete;

  @override
  State<TransducerTransitionEditor> createState() =>
      _TransducerTransitionEditorState();
}

final class _TransducerTransitionEditorState
    extends State<TransducerTransitionEditor> {
  late final TextEditingController _inputController;
  late final TextEditingController _outputController;
  late final FocusNode _inputFocus;
  late final FocusNode _outputFocus;
  String? _inputError;
  String? _outputError;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initialInput);
    _outputController = TextEditingController(
      text: widget.initialOutput.join('\n'),
    );
    _inputFocus = FocusNode();
    _outputFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _inputFocus.dispose();
    _outputFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _inputController.text;
    if (input.isEmpty) {
      setState(() =>
          _inputError = appLocalizationsOf(context).transducerInputRequired);
      _inputFocus.requestFocus();
      return;
    }
    setState(() => _inputError = null);
    final output = _outputController.text
        .split('\n')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final validation = widget.validator?.call(input, output);
    if (validation != null &&
        (validation.inputError != null || validation.outputError != null)) {
      setState(() {
        _inputError = validation.inputError;
        _outputError = validation.outputError;
      });
      if (validation.inputError != null) {
        _inputFocus.requestFocus();
      } else {
        _outputFocus.requestFocus();
      }
      return;
    }
    widget.onSubmit(input, output);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).vertical -
              24,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) {
                    widget.onCancel();
                    return null;
                  },
                ),
              },
              child: FocusTraversalGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.transducerEditTransition,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('transducer-transition-input'),
                      controller: _inputController,
                      focusNode: _inputFocus,
                      decoration: InputDecoration(
                        labelText: l10n.transducerInputSymbol,
                        errorText: _inputError,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    if (widget.showOutput) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('transducer-transition-output'),
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
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.onDelete case final onDelete?)
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.transducerDeleteTransition),
                          ),
                        TextButton(
                          onPressed: widget.onCancel,
                          child: Text(MaterialLocalizations.of(context)
                              .cancelButtonLabel),
                        ),
                        FilledButton(
                          onPressed: _submit,
                          child: Text(l10n.transducerSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
