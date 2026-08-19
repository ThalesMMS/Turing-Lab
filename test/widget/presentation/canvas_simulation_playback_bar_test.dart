import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';

void main() {
  testWidgets('navigates, plays to the end, and closes', (tester) async {
    final selected = <int>[];
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CanvasSimulationPlaybackBar(
              stepCount: 3,
              stepDuration: const Duration(milliseconds: 100),
              onStepChanged: selected.add,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(selected, [0]);

    await tester.tap(find.byTooltip('Next Step'));
    await tester.pump();
    expect(selected, [0, 1]);

    await tester.tap(find.byTooltip('Previous Step'));
    await tester.pump();
    expect(selected, [0, 1, 0]);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(selected, [0, 1, 0, 1, 2]);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('Step 3 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('renders the input word and advances its consumption', (
    tester,
  ) async {
    const words = <CanvasSimulationWord>[
      [
        CanvasSimulationWordSymbol('a', CanvasWordSymbolStatus.current),
        CanvasSimulationWordSymbol('b', CanvasWordSymbolStatus.pending),
      ],
      [
        CanvasSimulationWordSymbol('a', CanvasWordSymbolStatus.consumed),
        CanvasSimulationWordSymbol('b', CanvasWordSymbolStatus.current),
      ],
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CanvasSimulationPlaybackBar(
              stepCount: 2,
              words: words,
              onStepChanged: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Text wordText() => tester.widget<Text>(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.textSpan != null,
          ),
        );

    var spans = (wordText().textSpan! as TextSpan).children!;
    expect(spans, hasLength(2));
    expect((spans[0] as TextSpan).text, 'a');
    expect((spans[0] as TextSpan).style?.decoration, TextDecoration.underline);
    expect(
      (spans[1] as TextSpan).style?.decoration,
      isNot(TextDecoration.underline),
    );

    await tester.tap(find.byTooltip('Next Step'));
    await tester.pump();

    spans = (wordText().textSpan! as TextSpan).children!;
    expect(
      (spans[0] as TextSpan).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect((spans[1] as TextSpan).style?.decoration, TextDecoration.underline);
  });

  testWidgets('renders epsilon for an empty input word', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CanvasSimulationPlaybackBar(
              stepCount: 1,
              words: const <CanvasSimulationWord>[[]],
              onStepChanged: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ε'), findsOneWidget);
  });
}
