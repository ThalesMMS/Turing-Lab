import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_operation_preview.dart';

void main() {
  testWidgets('atomic stack preview preserves complete symbols', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StackOperationPreview(
            inputSymbol: 'a',
            popSymbol: 'Z',
            pushSymbol: 'S_0Z_0',
            pushSymbols: ['S_0', 'Z_0'],
            currentStack: StackState(symbols: ['Z']),
          ),
        ),
      ),
    );
    expect(find.text('S_0'), findsOneWidget);
    expect(find.text('Z_0'), findsOneWidget);
    expect(find.text('_'), findsNothing);
  });
}
