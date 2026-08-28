//
//  pda_transition_editor.dart
//  Turing Lab
//
//  Provides a PDA-focused transition editor with read, pop, and push
//  fields plus ε toggles. Clears and validates input, firing structured
//  callbacks so the host screen can apply changes safely.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_operation_preview.dart';

import '../../../core/utils/epsilon_utils.dart';
import '../../../l10n/app_localizations_resolver.dart';
import 'transition_editor_actions.dart';
import 'transition_editor_shell.dart';

class PdaTransitionEditor extends StatefulWidget {
  const PdaTransitionEditor({
    super.key,
    required this.initialRead,
    required this.initialPop,
    required this.initialPush,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
    this.currentStack,
  });

  final String initialRead;
  final String initialPop;
  final String initialPush;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;
  final StackState? currentStack;
  final void Function({
    required String readSymbol,
    required String popSymbol,
    required String pushSymbol,
    required bool lambdaInput,
    required bool lambdaPop,
    required bool lambdaPush,
  }) onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  State<PdaTransitionEditor> createState() => _PdaTransitionEditorState();
}

class _PdaTransitionEditorState extends State<PdaTransitionEditor> {
  late final TextEditingController _readController = TextEditingController(
    text: widget.initialRead,
  );
  late final TextEditingController _popController = TextEditingController(
    text: widget.initialPop,
  );
  late final TextEditingController _pushController = TextEditingController(
    text: widget.initialPush,
  );
  late bool _lambdaInput = widget.isLambdaInput;
  late bool _lambdaPop = widget.isLambdaPop;
  late bool _lambdaPush = widget.isLambdaPush;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to update preview on text change
    _readController.addListener(() => setState(() {}));
    _popController.addListener(() => setState(() {}));
    _pushController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _readController.dispose();
    _popController.dispose();
    _pushController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final readSymbol = _readController.text.trim();
    final popSymbol = _popController.text.trim();
    final pushSymbol = _pushController.text.trim();
    if ((!_lambdaInput && readSymbol.isEmpty) ||
        (!_lambdaPop && popSymbol.isEmpty) ||
        (!_lambdaPush && pushSymbol.isEmpty)) {
      setState(() {
        _showValidationErrors = true;
      });
      return;
    }
    widget.onSubmit(
      readSymbol: readSymbol,
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      lambdaInput: _lambdaInput,
      lambdaPop: _lambdaPop,
      lambdaPush: _lambdaPush,
    );
  }

  Widget _buildLambdaSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (next) {
        setState(() {
          onChanged(next);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    const shortcuts = <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.enter): _SubmitIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter): _SubmitIntent(),
      SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(
            onInvoke: (intent) {
              _handleSubmit();
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (intent) {
              widget.onCancel();
              return null;
            },
          ),
        },
        child: TransitionEditorShell(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(0.0),
                  child: TextField(
                    controller: _readController,
                    enabled: !_lambdaInput,
                    decoration: InputDecoration(
                      labelText: l10n.pdaInputSymbol,
                      border: const OutlineInputBorder(),
                      errorText: _showValidationErrors &&
                              !_lambdaInput &&
                              _readController.text.trim().isEmpty
                          ? l10n.pdaInputSymbolRequired
                          : null,
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    autofocus: true,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1.0),
                  child: _buildLambdaSwitch(
                    label: l10n.pdaLambdaInput,
                    value: _lambdaInput,
                    onChanged: (value) {
                      _lambdaInput = value;
                      if (value) {
                        _readController.text = '';
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2.0),
                  child: TextField(
                    controller: _popController,
                    enabled: !_lambdaPop,
                    decoration: InputDecoration(
                      labelText: l10n.pdaPopSymbol,
                      border: const OutlineInputBorder(),
                      errorText: _showValidationErrors &&
                              !_lambdaPop &&
                              _popController.text.trim().isEmpty
                          ? l10n.pdaPopSymbolRequired
                          : null,
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3.0),
                  child: _buildLambdaSwitch(
                    label: l10n.pdaLambdaPop,
                    value: _lambdaPop,
                    onChanged: (value) {
                      _lambdaPop = value;
                      if (value) {
                        _popController.text = '';
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4.0),
                  child: TextField(
                    controller: _pushController,
                    enabled: !_lambdaPush,
                    decoration: InputDecoration(
                      labelText: l10n.pdaPushSymbol,
                      border: const OutlineInputBorder(),
                      errorText: _showValidationErrors &&
                              !_lambdaPush &&
                              _pushController.text.trim().isEmpty
                          ? l10n.pdaPushSymbolRequired
                          : null,
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5.0),
                  child: _buildLambdaSwitch(
                    label: l10n.pdaLambdaPush,
                    value: _lambdaPush,
                    onChanged: (value) {
                      _lambdaPush = value;
                      if (value) {
                        _pushController.text = '';
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.currentStack != null) ...[
                  StackOperationPreview(
                    inputSymbol:
                        _lambdaInput ? kEpsilonSymbol : _readController.text,
                    popSymbol:
                        _lambdaPop ? kEpsilonSymbol : _popController.text,
                    pushSymbol:
                        _lambdaPush ? kEpsilonSymbol : _pushController.text,
                    currentStack: widget.currentStack!,
                  ),
                  const SizedBox(height: 16),
                ],
                TransitionEditorActions(
                  onCancel: widget.onCancel,
                  onDelete: widget.onDelete,
                  onSave: _handleSubmit,
                  baseFocusOrder: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
