//
//  tm_transition_operations_editor.dart
//  Turing Lab
//
//  Fornece formulário compacto para editar leituras, escritas e direção de transições de Máquina de Turing. Mantém estado mínimo dos campos, valida submissões e entrega o resultado por callback para integração com editores contextuais.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/tm_transition.dart';
import '../tm/direction_icon.dart';

class TmTransitionOperationsEditor extends StatefulWidget {
  const TmTransitionOperationsEditor({
    super.key,
    required this.initialRead,
    required this.initialWrite,
    required this.initialDirection,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialRead;
  final String initialWrite;
  final TapeDirection initialDirection;
  final void Function({
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
  }) onSubmit;
  final VoidCallback onCancel;

  @override
  State<TmTransitionOperationsEditor> createState() =>
      _TmTransitionOperationsEditorState();
}

class _TmTransitionOperationsEditorState
    extends State<TmTransitionOperationsEditor> {
  late final TextEditingController _readController = TextEditingController(
    text: widget.initialRead,
  );
  late final TextEditingController _writeController = TextEditingController(
    text: widget.initialWrite,
  );
  late TapeDirection _direction = widget.initialDirection;

  @override
  void dispose() {
    _readController.dispose();
    _writeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit(
      readSymbol: _readController.text.trim(),
      writeSymbol: _writeController.text.trim(),
      direction: _direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _SubmitIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _SubmitIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
      },
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
            constraints: const BoxConstraints(minWidth: 260),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                        decoration: const InputDecoration(
                          labelText: 'Read symbol',
                          border: OutlineInputBorder(),
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1.0),
                      child: TextField(
                        controller: _writeController,
                        decoration: const InputDecoration(
                          labelText: 'Write symbol',
                          border: OutlineInputBorder(),
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(2.0),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Direction',
                          border: OutlineInputBorder(),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<TapeDirection>(
                                value: _direction,
                                items: TapeDirection.values
                                    .map(
                                      (direction) => DropdownMenuItem(
                                        value: direction,
                                        child: TMDirectionIndicator(
                                          direction: direction,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _direction = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            TMDirectionSelector(
                              selected: _direction,
                              onChanged: (value) {
                                setState(() {
                                  _direction = value;
                                });
                              },
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(3.0),
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
                            order: const NumericFocusOrder(4.0),
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
