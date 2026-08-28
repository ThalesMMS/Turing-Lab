import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/algorithm_step_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_navigator.dart';

AlgorithmStepNotifier _steps(Ref ref) {
  final notifier = AlgorithmStepNotifier(ref);
  notifier.initializeSteps([
    AlgorithmStep(
      id: 'step-0',
      stepNumber: 0,
      title: 'Initialize',
      explanation: 'Initialize the algorithm.',
      type: AlgorithmType.nfaToDfa,
    ),
    AlgorithmStep(
      id: 'step-1',
      stepNumber: 1,
      title: 'Continue',
      explanation: 'Continue the algorithm.',
      type: AlgorithmType.nfaToDfa,
    ),
    AlgorithmStep(
      id: 'step-2',
      stepNumber: 2,
      title: 'Finish',
      explanation: 'Finish the algorithm.',
      type: AlgorithmType.nfaToDfa,
    ),
  ]);
  return notifier;
}

Future<void> _pumpNavigator(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [algorithmStepProvider.overrideWith(_steps)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AlgorithmStepNavigator()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('step scrubber exposes a localized name, value, and hint', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();

    await _pumpNavigator(tester, const Locale('en'));
    final english = tester.getSemantics(find.byType(Slider));
    final englishData = english.getSemanticsData();
    expect(englishData.label, 'Timeline scrubber');
    expect(englishData.value, 'Step 1 of 3');
    expect(englishData.hint, 'Drag to navigate through simulation steps');
    expect(englishData.flagsCollection.isSlider, isTrue);

    await _pumpNavigator(tester, const Locale('pt', 'BR'));
    final portuguese = tester.getSemantics(find.byType(Slider));
    final portugueseData = portuguese.getSemanticsData();
    expect(portugueseData.label, 'Controle da linha do tempo');
    expect(portugueseData.value, 'Passo 1 de 3');
    expect(
      portugueseData.hint,
      'Arraste para navegar pelos passos da simulação',
    );
    expect(portugueseData.flagsCollection.isSlider, isTrue);

    semanticsHandle.dispose();
  });
}
