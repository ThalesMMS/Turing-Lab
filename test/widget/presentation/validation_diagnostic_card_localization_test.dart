import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/models/validation_diagnostic.dart';
import 'package:turing_lab/core/validators/validation_messages.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/validation_diagnostic_card.dart';

void main() {
  testWidgets(
    'localizes diagnostic labels at narrow width and high text scale',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final diagnostic = ValidationDiagnostic(
        code: 'FSA_NO_INITIAL',
        summary: 'Initial state required',
        suggestedFixes: [
          SuggestedFix(
            label: 'Mark a start state',
            details: 'Select a state and set it as the initial/start state.',
          ),
        ],
        structuredMessage: ValidationMessages.forCode('FSA_NO_INITIAL'),
      );

      Widget app(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SingleChildScrollView(
              child: ValidationDiagnosticCard(diagnostic: diagnostic),
            ),
          ),
        ),
      );

      await tester.pumpWidget(app(const Locale('en')));

      expect(find.text('Suggested fixes'), findsOneWidget);
      expect(find.text('The automaton has no initial state.'), findsOneWidget);
      expect(find.text('Mark a start state'), findsOneWidget);
      expect(
        find.text('Select a state and set it as the initial/start state.'),
        findsOneWidget,
      );
      expect(find.text('Diagnostic code: FSA_NO_INITIAL'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Suggested fixes')).label,
        contains('Suggested fixes'),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(app(const Locale('pt', 'BR')));
      await tester.pump();

      expect(find.text('Correções sugeridas'), findsOneWidget);
      expect(find.text('O autômato não tem estado inicial.'), findsOneWidget);
      expect(find.text('Marque um estado inicial'), findsOneWidget);
      expect(
        find.text('Selecione um estado e defina-o como estado inicial.'),
        findsOneWidget,
      );
      expect(find.text('Mark a start state'), findsNothing);
      expect(
        find.text('Código de diagnóstico: FSA_NO_INITIAL'),
        findsOneWidget,
      );
      expect(find.text('Suggested fixes'), findsNothing);
      expect(
        tester.getSemantics(find.text('Correções sugeridas')).label,
        contains('Correções sugeridas'),
      );
      expect(tester.takeException(), isNull);

      semantics.dispose();
    },
  );
}
