import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/step_navigation_controls.dart';

void main() {
  testWidgets('localizes the visible and announced playback speed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StepNavigationControls(
            currentStepIndex: 0,
            totalSteps: 2,
            isPlaying: false,
            playbackSpeed: 2.5,
            onSpeedChanged: (_) {},
          ),
        ),
      ),
    );

    final slider = find.semantics
        .byLabel('Selecione a velocidade de reprodução')
        .evaluate()
        .single
        .getSemanticsData();
    semantics.dispose();
    expect(slider.label, contains('Selecione a velocidade de reprodução'));
    expect(slider.value, '2,50x');
    expect(slider.increasedValue, '2,75x');
    expect(slider.decreasedValue, '2,25x');
    expect(slider.flagsCollection.isSlider, isTrue);
    expect(find.text('2,50x'), findsOneWidget);
  });
}
