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

import '../../../presentation/widgets/transition_editors/transition_editor_shell.dart';
import '../../../presentation/widgets/transition_editors/transition_label_editor.dart';

/// Overlay editor used by the GraphView canvas to update transition labels.
class GraphViewLabelFieldEditor extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TransitionEditorShell(
      child: TransitionLabelEditorForm(
        initialValue: initialValue,
        onSubmit: onSubmit,
        onCancel: onCancel,
        onDelete: onDelete,
        autofocus: true,
        touchOptimized: true,
      ),
    );
  }
}
