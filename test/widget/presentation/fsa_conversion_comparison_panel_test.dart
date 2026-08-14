import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/conversion_step_history.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/before_after_comparison.dart';
import 'package:turing_lab/presentation/widgets/fsa_conversion_comparison_panel.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    originalDebugPrint = debugPrint;
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  testWidgets(
    'renders shrink when comparison inputs are incomplete',
    (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: FSAConversionComparisonPanel(
            history: null,
            currentAutomaton: null,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(0.0));
      expect(sizedBox.height, equals(0.0));
      expect(find.byType(BeforeAfterComparison), findsNothing);
    },
  );

  testWidgets(
    'renders BeforeAfterComparison for valid conversion snapshots',
    (tester) async {
      final automaton = _fsa();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FSAConversionComparisonPanel(
              history: ConversionHistory(
                id: 'history',
                algorithmType: AlgorithmType.nfaToDfa,
                initialSnapshot: automaton.toJson(),
                finalSnapshot: automaton.toJson(),
              ),
              currentAutomaton: automaton,
            ),
          ),
        ),
      );

      expect(find.byType(BeforeAfterComparison), findsOneWidget);
      expect(find.text('Conversion result'), findsOneWidget);
    },
  );

  testWidgets(
    'logs and shows fallback when conversion snapshots cannot deserialize',
    (tester) async {
      final logs = <String>[];
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FSAConversionComparisonPanel(
              history: ConversionHistory(
                id: 'history',
                algorithmType: AlgorithmType.nfaToDfa,
                initialSnapshot: const {'id': 'broken'},
                finalSnapshot: _fsa().toJson(),
              ),
              currentAutomaton: _fsa(),
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Conversion comparison unavailable'),
        findsOneWidget,
      );
      expect(
        logs.join('\n'),
        contains('Failed to deserialize conversion comparison history history'),
      );
    },
  );
}

FSA _fsa() {
  final now = DateTime(2026, 1, 1);
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );

  return FSA(
    id: 'fsa',
    name: 'FSA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
  );
}
