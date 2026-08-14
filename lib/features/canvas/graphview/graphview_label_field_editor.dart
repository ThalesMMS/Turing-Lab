//
//  graphview_label_field_editor.dart
//  Turing Lab
//
//  Widget de overlay que permite editar rótulos de transições diretamente no
//  GraphView, coordenando foco, confirmação e cancelamento com o canvas. A
//  implementação lida com ciclo de vida dos FocusNodes e invoca o formulário de
//  edição compartilhado para padronizar a experiência.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../presentation/widgets/transition_editors/transition_label_editor.dart';

/// Overlay editor used by the GraphView canvas to update transition labels.
class GraphViewLabelFieldEditor extends StatefulWidget {
  const GraphViewLabelFieldEditor({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  State<GraphViewLabelFieldEditor> createState() =>
      _GraphViewLabelFieldEditorState();
}

class _GraphViewLabelFieldEditorState extends State<GraphViewLabelFieldEditor> {
  late final FocusScopeNode _focusScopeNode;
  late final FocusNode _focusNode;
  bool _ignoreFocusLoss = false;

  @override
  void initState() {
    super.initState();
    _focusScopeNode = FocusScopeNode();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusScopeNode.requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    if (!focused && !_ignoreFocusLoss) {
      widget.onCancel();
    }
  }

  void _unfocusWithoutCancel() {
    _ignoreFocusLoss = true;
    _focusScopeNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final touchOptimized = MediaQuery.sizeOf(context).shortestSide < 900;
    return FocusScope(
      node: _focusScopeNode,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: _handleFocusChange,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TransitionLabelEditorForm(
                initialValue: widget.initialValue,
                onSubmit: (value) {
                  widget.onSubmit(value);
                  _unfocusWithoutCancel();
                },
                onCancel: () {
                  widget.onCancel();
                  _unfocusWithoutCancel();
                },
                onDelete: widget.onDelete == null
                    ? null
                    : () {
                        widget.onDelete!();
                        _unfocusWithoutCancel();
                      },
                autofocus: true,
                touchOptimized: touchOptimized,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
