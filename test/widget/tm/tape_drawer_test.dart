//
//  tm_tape_drawer_test.dart
//  Turing Lab
//
//  Widget test suite verifying the TMTapePanel widget, ensuring correct
//  rendering of tape state, head position highlighting, read/write operation
//  indicators, scroll behavior, and cell editing functionality. Tests validate
//  both empty and populated tape states, with proper interaction handling
//  during simulation and edit modes.
//
//  Created for Phase 4 integration testing - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';

class _CellEditCallback {
  final List<Map<String, dynamic>> editedCells = [];

  void call(int cellIndex, String newValue) {
    editedCells.add({'index': cellIndex, 'value': newValue});
  }
}

Future<void> _pumpTapePanel(
  WidgetTester tester, {
  required TapeState tapeState,
  Set<String> tapeAlphabet = const {'0', '1'},
  bool isSimulating = false,
  VoidCallback? onClear,
  void Function(int, String)? onCellEdit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TMTapePanel(
          tapeState: tapeState,
          tapeAlphabet: tapeAlphabet,
          isSimulating: isSimulating,
          onClear: onClear,
          onCellEdit: onCellEdit,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TapeState', () {
    test('creates initial empty tape state', () {
      final state = TapeState.initial();

      expect(state.isEmpty, isTrue);
      expect(state.cells, isEmpty);
      expect(state.headPosition, 0);
      expect(state.blankSymbol, '□');
      expect(state.currentCell, '□');
      expect(state.wasRead, isFalse);
      expect(state.wasWritten, isFalse);
    });

    test('creates tape state with custom blank symbol', () {
      final state = TapeState.initial(blankSymbol: '_');

      expect(state.blankSymbol, '_');
      expect(state.currentCell, '_');
    });

    test('returns current cell at head position', () {
      const state = TapeState(cells: ['a', 'b', 'c'], headPosition: 1);

      expect(state.currentCell, 'b');
    });

    test('returns blank symbol when head is out of bounds', () {
      const state = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 5,
        blankSymbol: '□',
      );

      expect(state.currentCell, '□');
    });

    test('detects read operation', () {
      const state = TapeState(
        cells: ['a', 'b'],
        headPosition: 0,
        lastReadSymbol: 'a',
      );

      expect(state.wasRead, isTrue);
      expect(state.wasWritten, isFalse);
    });

    test('detects write operation', () {
      const state = TapeState(
        cells: ['a', 'b'],
        headPosition: 0,
        lastWriteSymbol: 'x',
      );

      expect(state.wasRead, isFalse);
      expect(state.wasWritten, isTrue);
    });

    test('returns visible cells with padding', () {
      const state = TapeState(
        cells: ['a', 'b', 'c', 'd', 'e'],
        headPosition: 2,
        blankSymbol: '□',
      );

      final visible = state.getVisibleCells(padding: 2);

      // With padding=2, should show [a, b, c, d, e] centered around c
      expect(visible.length, 5);
      expect(visible, ['a', 'b', 'c', 'd', 'e']);
    });

    test('pads visible cells with blanks when near edges', () {
      const state = TapeState(
        cells: ['a', 'b'],
        headPosition: 0,
        blankSymbol: '□',
      );

      final visible = state.getVisibleCells(padding: 2);

      // Should have blanks on left, then cells
      expect(visible.length, 5);
      expect(visible[0], '□');
      expect(visible[1], '□');
      expect(visible[2], 'a');
      expect(visible[3], 'b');
      expect(visible[4], '□');
    });

    test('returns correct head index in visible cells', () {
      const state = TapeState(cells: ['a', 'b', 'c'], headPosition: 1);

      final headIndex = state.getHeadIndexInVisible(padding: 3);

      expect(headIndex, 3);
    });
  });

  group('TMTapePanel', () {
    testWidgets('renders empty tape state', (tester) async {
      final tapeState = TapeState.initial();

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.text('Tape (Head: 0)'), findsOneWidget);
      expect(find.textContaining('Empty (□: □)'), findsOneWidget);
      expect(find.byIcon(Icons.horizontal_rule), findsOneWidget);
    });

    testWidgets('renders tape with cells', (tester) async {
      const tapeState = TapeState(
        cells: ['0', '1', '0', '1'],
        headPosition: 2,
      );

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.text('Tape (Head: 2)'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('highlights head position with arrow', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
      );

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows read operation indicator', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
        lastReadSymbol: 'b',
      );

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('shows write operation indicator', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
        lastWriteSymbol: 'x',
      );

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows both read and write indicators', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
        lastReadSymbol: 'b',
        lastWriteSymbol: 'x',
      );

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays clear button when onClear provided', (tester) async {
      const tapeState = TapeState(cells: ['a', 'b'], headPosition: 0);
      var clearCalled = false;

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onClear: () => clearCalled = true,
      );

      expect(find.text('Clear'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(clearCalled, isTrue);
    });

    testWidgets('hides clear button when onClear not provided', (tester) async {
      const tapeState = TapeState(cells: ['a', 'b'], headPosition: 0);

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('allows cell editing when not simulating', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
      );
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        isSimulating: false,
        onCellEdit: editCallback.call,
      );

      // Find and tap a tape cell (they are wrapped in InkWell)
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsWidgets);

      // Tap the first visible cell
      await tester.tap(inkWellFinder.first);
      await tester.pumpAndSettle();

      // Verify edit dialog appears
      expect(find.text('Symbol'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('disables cell editing when simulating', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
      );
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        isSimulating: true,
        onCellEdit: editCallback.call,
      );

      // Cells should not be wrapped in InkWell when simulating
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsNothing);
    });

    testWidgets('shows tape alphabet buttons in edit dialog', (tester) async {
      const tapeState = TapeState(cells: ['0', '1'], headPosition: 0);
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        tapeAlphabet: {'0', '1', 'X'},
        onCellEdit: editCallback.call,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Should show tape alphabet section
      expect(find.text('Tape Alphabet:'), findsOneWidget);

      // Should show alphabet buttons (including blank symbol)
      final outlinedButtons = find.byType(OutlinedButton);
      expect(outlinedButtons, findsWidgets);
    });

    testWidgets('cell edit dialog allows manual symbol entry', (tester) async {
      const tapeState = TapeState(cells: ['a', 'b'], headPosition: 0);
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onCellEdit: editCallback.call,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Find the text field and enter a symbol
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'X');
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify callback was called with new value
      expect(editCallback.editedCells.length, 1);
      expect(editCallback.editedCells[0]['value'], 'X');
    });

    testWidgets('cell edit dialog can be cancelled', (tester) async {
      const tapeState = TapeState(cells: ['a', 'b'], headPosition: 0);
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onCellEdit: editCallback.call,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify callback was not called
      expect(editCallback.editedCells, isEmpty);
    });

    testWidgets('uses blank symbol when text field is empty', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b'],
        headPosition: 0,
        blankSymbol: '□',
      );
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onCellEdit: editCallback.call,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Clear the text field
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify callback was called with blank symbol
      expect(editCallback.editedCells.length, 1);
      expect(editCallback.editedCells[0]['value'], '□');
    });

    testWidgets('updates when tape state changes', (tester) async {
      const initialState = TapeState(cells: ['a', 'b'], headPosition: 0);

      await _pumpTapePanel(tester, tapeState: initialState);
      expect(find.text('Tape (Head: 0)'), findsOneWidget);

      // Update with new tape state
      const newState = TapeState(cells: ['x', 'y', 'z'], headPosition: 2);

      await _pumpTapePanel(tester, tapeState: newState);
      expect(find.text('Tape (Head: 2)'), findsOneWidget);
    });

    testWidgets('renders within Card with proper styling', (tester) async {
      const tapeState = TapeState(cells: ['a'], headPosition: 0);

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.byType(Card), findsOneWidget);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 4);
    });

    testWidgets('keeps the head cell centered while the tape slides', (
      tester,
    ) async {
      Widget buildPanel(TapeState tapeState) {
        return MaterialApp(
          home: Scaffold(
            body: TMTapePanel(
              tapeState: tapeState,
              tapeAlphabet: const {'a', 'b', 'c', 'd', 'e'},
            ),
          ),
        );
      }

      await tester.pumpWidget(
        buildPanel(
          const TapeState(cells: ['a', 'b', 'c', 'd', 'e'], headPosition: 1),
        ),
      );
      await tester.pumpAndSettle();

      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(
        tester.getCenter(find.text('b')).dx,
        closeTo(viewport.center.dx, 1.0),
      );

      await tester.pumpWidget(
        buildPanel(
          const TapeState(cells: ['a', 'b', 'c', 'd', 'e'], headPosition: 3),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      final midFlightDx = tester.getCenter(find.text('d')).dx;
      expect(midFlightDx, isNot(closeTo(viewport.center.dx, 1.0)));

      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.text('d')).dx,
        closeTo(viewport.center.dx, 1.0),
      );
    });

    testWidgets('displays visible cells with horizontal scroll', (
      tester,
    ) async {
      final tapeState = TapeState(
        cells: List.generate(20, (i) => i.toString()),
        headPosition: 10,
      );

      await _pumpTapePanel(tester, tapeState: tapeState);

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.scrollDirection, Axis.horizontal);
    });

    testWidgets('cell clear button in edit dialog clears text', (tester) async {
      const tapeState = TapeState(cells: ['a', 'b'], headPosition: 0);
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onCellEdit: editCallback.call,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Enter text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'X');
      await tester.pumpAndSettle();

      // Tap the clear button (suffix icon)
      final clearButton = find.descendant(
        of: textField,
        matching: find.byIcon(Icons.clear),
      );
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify text is cleared
      final textController = tester.widget<TextField>(textField).controller;
      expect(textController?.text, isEmpty);
    });

    testWidgets('edit dialog title shows cell index', (tester) async {
      const tapeState = TapeState(
        cells: ['a', 'b', 'c'],
        headPosition: 1,
      );
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onCellEdit: editCallback.call,
      );

      // Tap a cell to open edit dialog
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Verify dialog title contains cell index
      expect(find.textContaining('Edit Cell'), findsOneWidget);
    });

    testWidgets('limits text field input to 1 character', (tester) async {
      const tapeState = TapeState(cells: ['a'], headPosition: 0);
      final editCallback = _CellEditCallback();

      await _pumpTapePanel(
        tester,
        tapeState: tapeState,
        onCellEdit: editCallback.call,
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, 1);
    });
  });
}
