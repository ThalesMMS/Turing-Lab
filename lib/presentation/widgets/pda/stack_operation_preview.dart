//
//  stack_operation_preview.dart
//  Turing Lab
//
//  Stack operation preview widget to show on hover/touch
//  in PDA transitions. Visually demonstrates the input,pop→push effect on the stack.
//
//  Created for Phase 3 - Transition Operation Preview
//

import 'package:flutter/material.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';

/// Stack operation preview widget
///
/// Shows a visual preview of what a PDA transition will do with the stack,
/// including the input symbol, symbol to be removed (pop) and
/// symbol to be added (push).
class StackOperationPreview extends StatelessWidget {
  final String inputSymbol;
  final String popSymbol;
  final String pushSymbol;
  final StackState currentStack;

  const StackOperationPreview({
    super.key,
    required this.inputSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    required this.currentStack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operation Preview',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          _buildOperationRow(
            theme,
            'Input',
            inputSymbol,
            Icons.input,
            theme.colorScheme.primary,
          ),
          _buildOperationRow(
            theme,
            'Pop',
            popSymbol,
            Icons.arrow_downward,
            theme.colorScheme.error,
          ),
          _buildOperationRow(
            theme,
            'Push',
            pushSymbol,
            Icons.arrow_upward,
            Colors.green,
          ),
          const Divider(),
          Text(
            'Result',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStackPreview(theme),
        ],
      ),
    );
  }

  Widget _buildOperationRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isLambda = value == 'λ' || value == 'ε' || value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          Text(
            isLambda ? 'λ' : value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLambda ? theme.colorScheme.outline : color,
              fontStyle: isLambda ? FontStyle.italic : FontStyle.normal,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackPreview(ThemeData theme) {
    // Simulate the operation
    var resultStack = currentStack;

    // Pop unless the symbol is lambda
    if (popSymbol != 'λ' && popSymbol != 'ε' && popSymbol.isNotEmpty) {
      resultStack = resultStack.pop();
    }

    // Push unless the symbol is lambda
    if (pushSymbol != 'λ' && pushSymbol != 'ε' && pushSymbol.isNotEmpty) {
      // Push may be multiple symbols (e.g. "ABC")
      // Push right-to-left to keep the correct order
      for (var i = pushSymbol.length - 1; i >= 0; i--) {
        resultStack = resultStack.push(pushSymbol[i]);
      }
    }

    if (resultStack.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '(empty stack)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: resultStack.symbols.reversed.take(5).map((symbol) {
          final isTop = symbol == resultStack.symbols.last;
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTop
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isTop
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: isTop ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              symbol,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }
}
