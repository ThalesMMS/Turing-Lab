import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/common/simulation_speed_control.dart';

void main() {
  testWidgets('updates displayed and announced speed when locale changes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    double? selectedSpeed;

    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SimulationSpeedControl(
            currentSpeed: 0.25,
            onSpeedChanged: (speed) => selectedSpeed = speed,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const Locale('en')));

    expect(find.text('0.25x'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(SimulationSpeedControl)).value,
      'Slow 0.25x',
    );

    await tester.pumpWidget(app(const Locale('pt', 'BR')));
    await tester.pump();

    expect(find.text('0,25x'), findsOneWidget);
    expect(find.text('0.25x'), findsNothing);
    expect(
      tester.getSemantics(find.byType(SimulationSpeedControl)).value,
      'Lenta 0,25x',
    );
    await tester.tap(find.text('0,5x'));
    expect(selectedSpeed, 0.5);
    semantics.dispose();
  });
}
