import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/cyk_step.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
import 'package:turing_lab/core/models/typed_algorithm_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_renderer_registry.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_viewer.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('localizes algorithm step data at narrow high text scale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final step = AlgorithmStep(
      id: 'localized-step-data',
      stepNumber: 0,
      title: 'Step title',
      explanation: 'Step explanation',
      type: AlgorithmType.cykParsing,
      properties: {
        'currentStates': ['q0'],
        'isAcceptingState': true,
        'hasTransitions': false,
      },
    );
    await tester.pumpWidget(_localizedViewer(step));
    await tester.pumpAndSettle();

    expect(find.text('Dados da etapa'), findsOneWidget);
    expect(find.text('Estados atuais'), findsOneWidget);
    expect(find.text('É estado de aceitação'), findsOneWidget);
    expect(find.text('Sim'), findsOneWidget);
    expect(find.text('Não'), findsOneWidget);
    expect(find.text('Análise CYK'), findsOneWidget);
    expect(find.text('Step Data'), findsNothing);
    expect(find.text('CYK Parse'), findsNothing);
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  testWidgets('localizes typed CYK step data and values', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final cykStep = CYKStep.fillBaseCase(
      id: 'localized-cyk-step',
      stepNumber: 0,
      position: 0,
      terminal: 'a',
      derivingVariables: {'A'},
    );
    await tester.pumpWidget(
      _localizedViewer(
        cykStep.baseStep.copyWith(properties: {kCykStepKey: cykStep}),
        rendererRegistry: AlgorithmStepRendererRegistry.withDefaults(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados da etapa CYK'), findsOneWidget);
    expect(find.text('Preencher caso base'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('CYK Step Data'), findsNothing);
    expect(find.text('Fill Base Case'), findsNothing);
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  testWidgets('localizes booleans without translating formal Yes text', (
    tester,
  ) async {
    final baseStep = AlgorithmStep(
      id: 'regex-step',
      stepNumber: 0,
      title: 'title',
      explanation: 'explanation',
      type: AlgorithmType.regexToNfa,
    );
    final payload = RegexToNFAStep(
      baseStep: baseStep,
      stepType: RegexToNFAStepType.basicSymbol,
      regexFragment: 'Yes',
      isFinalNFA: true,
    );

    await tester.pumpWidget(
      _localizedViewer(
        baseStep.copyWith(properties: {kRegexToNfaStepKey: payload}),
        rendererRegistry: AlgorithmStepRendererRegistry.withDefaults(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Sim'), findsOneWidget);
  });

  testWidgets('hides every structured title and explanation property', (
    tester,
  ) async {
    final message = StructuredMessage(
      namespace: 'test',
      code: 'metadata',
      category: StructuredMessageCategory.unknown,
      severity: StructuredMessageSeverity.unknown,
    );
    final step = AlgorithmStep(
      id: 'metadata-step',
      stepNumber: 0,
      title: 'Step title',
      explanation: 'Step explanation',
      type: AlgorithmType.nfaToDfa,
      properties: {
        'faToRegexTitleMessage': message,
        'faToRegexExplanationMessage': message,
        'regexToNfaTitleMessage': message,
        'regexToNfaExplanationMessage': message,
        'fsaKleeneStarTitleMessage': message,
        'fsaKleeneStarExplanationMessage': message,
        'fsaReversalTitleMessage': message,
        'fsaReversalExplanationMessage': message,
        'fsaConcatenationTitleMessage': message,
        'fsaConcatenationExplanationMessage': message,
        'dfaMinimizationTitleMessage': message,
        'dfaMinimizationExplanationMessage': message,
        'nfaToDfaTitleMessage': message,
        'nfaToDfaExplanationMessage': message,
        'cykStepTitleMessage': message,
        'cykStepExplanationMessage': message,
        'visibleValue': 'q0',
      },
    );

    await tester.pumpWidget(_localizedViewer(step));
    await tester.pumpAndSettle();

    expect(find.text('q0'), findsOneWidget);
    expect(find.textContaining('Title Message'), findsNothing);
    expect(find.textContaining('Explanation Message'), findsNothing);
  });
}

Widget _localizedViewer(
  AlgorithmStep step, {
  AlgorithmStepRendererRegistry? rendererRegistry,
}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: AlgorithmStepViewer(
          step: step,
          rendererRegistry: rendererRegistry,
        ),
      ),
    ),
  );
}
