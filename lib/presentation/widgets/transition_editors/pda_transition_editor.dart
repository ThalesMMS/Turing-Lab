//
//  pda_transition_editor.dart
//  Turing Lab
//
//  Disponibiliza editor focado em transições de PDA com campos para leitura, pop e push e toggles para λ. Limpa e valida entradas, disparando callbacks estruturados para que a tela hospedeira aplique alterações com segurança.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_operation_preview.dart';

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
    widget.onSubmit(
      readSymbol: _readController.text.trim(),
      popSymbol: _popController.text.trim(),
      pushSymbol: _pushController.text.trim(),
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
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useStackedButtons = constraints.maxWidth < 320;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(0.0),
                          child: TextField(
                            controller: _readController,
                            enabled: !_lambdaInput,
                            decoration: const InputDecoration(
                              labelText: 'Input symbol',
                              border: OutlineInputBorder(),
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
                            label: 'λ-input',
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
                            decoration: const InputDecoration(
                              labelText: 'Pop symbol',
                              border: OutlineInputBorder(),
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
                            label: 'λ-pop',
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
                            decoration: const InputDecoration(
                              labelText: 'Push symbol',
                              border: OutlineInputBorder(),
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
                            label: 'λ-push',
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
                                _lambdaInput ? 'λ' : _readController.text,
                            popSymbol: _lambdaPop ? 'λ' : _popController.text,
                            pushSymbol:
                                _lambdaPush ? 'λ' : _pushController.text,
                            currentStack: widget.currentStack!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (useStackedButtons) ...[
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(6.0),
                            child: OutlinedButton(
                              onPressed: widget.onCancel,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(7.0),
                            child: FilledButton(
                              onPressed: _handleSubmit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(6.0),
                                  child: OutlinedButton(
                                    onPressed: widget.onCancel,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(7.0),
                                  child: FilledButton(
                                    onPressed: _handleSubmit,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    child: const Text('Save'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
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
