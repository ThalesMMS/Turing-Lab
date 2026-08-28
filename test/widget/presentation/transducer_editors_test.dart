import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/transducers/transducer_state_editor.dart';
import 'package:turing_lab/presentation/transducers/transducer_transition_editor.dart';

void main() {
  testWidgets('transition errors preserve draft and focus the invalid field',
      (tester) async {
    await tester.pumpWidget(
      _App(
        child: TransducerTransitionEditor(
          initialInput: 'outside',
          initialOutput: const ['x'],
          onSubmit: (_, __) => fail('invalid draft must not submit'),
          onCancel: () {},
          validator: (_, __) => (
            inputError: 'Choose an input symbol from the alphabet.',
            outputError: null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('outside'), findsOneWidget);
    expect(
      find.text('Choose an input symbol from the alphabet.'),
      findsOneWidget,
    );
    final input = tester.widget<TextField>(
      find.byKey(const Key('transducer-transition-input')),
    );
    expect(input.focusNode!.hasFocus, isTrue);
  });

  testWidgets('Mealy state edit never validates an absent state output',
      (tester) async {
    TransducerStateEdit? result;
    var validationCalls = 0;
    await tester.pumpWidget(
      _App(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showTransducerStateEditor(
                context,
                node: const GraphViewCanvasNode(
                  id: 'q0',
                  label: 'Old',
                  x: 0,
                  y: 0,
                  isInitial: false,
                  isAccepting: false,
                ),
                emissionRule: const MealyEmissionRule(),
                stateOutput: null,
                outputValidator: (_) {
                  validationCalls++;
                  return 'must not run';
                },
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transducer-state-label')),
      'Renamed',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(validationCalls, 0);
    expect(result?.label, 'Renamed');
    expect(result?.outputTokens, isNull);
  });

  testWidgets('Moore output error keeps the dialog and focuses output',
      (tester) async {
    await tester.pumpWidget(
      _App(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showTransducerStateEditor(
              context,
              node: const GraphViewCanvasNode(
                id: 'q0',
                label: 'q0',
                x: 0,
                y: 0,
                isInitial: true,
                isAccepting: false,
              ),
              emissionRule: const MooreEmissionRule(),
              stateOutput: TransducerOutputWord.empty,
              outputValidator: (_) => 'Unknown output symbol.',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transducer-state-output')),
      'unknown',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Unknown output symbol.'), findsOneWidget);
    final output = tester.widget<TextField>(
      find.byKey(const Key('transducer-state-output')),
    );
    expect(output.focusNode!.hasFocus, isTrue);
    expect(find.text('unknown'), findsOneWidget);
  });
}

final class _App extends StatelessWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );
}
