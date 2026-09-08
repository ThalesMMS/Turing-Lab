import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/common/example_load_flow.dart';

void main() {
  Widget host(void Function(BuildContext) onTap) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onTap(context),
            child: const Text('load'),
          ),
        ),
      ),
    );
  }

  testWidgets('applies the payload and reports success with the example name', (
    tester,
  ) async {
    final loadingStates = <bool>[];
    String? applied;
    await tester.pumpWidget(
      host((context) {
        loadExampleWithFeedback<String>(
          context,
          load: () async => Success(
            AssetExample<String>(
              id: 'fsa.example',
              name: 'Even zeros',
              description: 'Accepts an even number of zeros',
              category: ExampleCategory.dfa,
              difficultyLevel: DifficultyLevel.easy,
              complexityLevel: ExampleComplexityLevel.low,
              tags: const ['dfa'],
              payload: 'payload',
            ),
          ),
          apply: (example) => applied = example.payload,
          setLoading: loadingStates.add,
        );
      }),
    );
    await tester.tap(find.text('load'));
    await tester.pump();
    await tester.pump();

    expect(applied, 'payload');
    expect(loadingStates, [true, false]);
    expect(find.text('Example loaded: Even zeros'), findsOneWidget);
  });

  testWidgets('reports repository failures and thrown errors', (tester) async {
    var applied = false;
    var attempt = 0;
    await tester.pumpWidget(
      host((context) {
        attempt++;
        loadExampleWithFeedback<String>(
          context,
          load: () async {
            if (attempt == 1) return const Failure('missing asset');
            throw StateError('boom');
          },
          apply: (_) => applied = true,
          setLoading: (_) {},
        );
      }),
    );
    await tester.tap(find.text('load'));
    await tester.pump();
    await tester.pump();
    expect(applied, isFalse);
    expect(
      find.textContaining('Failed to load example: missing asset'),
      findsOneWidget,
    );

    await tester.tap(find.text('load'));
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('Failed to load example: Bad state: boom'),
      findsOneWidget,
    );
  });
}
