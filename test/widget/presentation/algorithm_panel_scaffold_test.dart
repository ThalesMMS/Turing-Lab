import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/models/asset_example.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel_scaffold.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button_config.dart';

void main() {
  testWidgets('AlgorithmPanelScaffold renders title and children in card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmPanelScaffold(
            title: 'Shared Algorithms',
            children: [
              Text('Panel body'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Shared Algorithms'), findsOneWidget);
    expect(find.text('Panel body'), findsOneWidget);
  });

  testWidgets('AlgorithmButtonList renders configs with spacing and callbacks',
      (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmButtonList(
            configs: [
              AlgorithmButtonConfig(
                title: 'Run analysis',
                description: 'Execute the shared list action',
                icon: Icons.analytics,
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Run analysis'), findsOneWidget);

    await tester.tap(find.text('Run analysis'));
    await tester.pumpAndSettle();

    expect(tapped, true);
  });

  testWidgets('AlgorithmPanelScaffold supports padding outside scroll view', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmPanelScaffold(
            title: 'Outer Padding',
            paddingInsideScroll: false,
            children: [
              Text('Panel body'),
            ],
          ),
        ),
      ),
    );

    final scroll = find.byType(SingleChildScrollView);
    final configuredPadding = find.byWidgetPredicate(
      (widget) =>
          widget is Padding && widget.padding == const EdgeInsets.all(16),
    );

    expect(configuredPadding, findsOneWidget);
    expect(
      find.descendant(of: configuredPadding, matching: scroll),
      findsOneWidget,
    );
  });

  testWidgets('AlgorithmResultsSection switches empty and result content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmResultsSection(
            hasResults: false,
            emptyBuilder: (_) => const Text('No results'),
            resultsBuilder: (_) => throw StateError('results should be lazy'),
          ),
        ),
      ),
    );

    expect(find.text('Analysis Results'), findsOneWidget);
    expect(find.text('No results'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmResultsSection(
            hasResults: true,
            emptyBuilder: (_) => throw StateError('empty should be lazy'),
            resultsBuilder: (_) => const Text('Results'),
          ),
        ),
      ),
    );

    expect(find.text('No results'), findsNothing);
    expect(find.text('Results'), findsOneWidget);
  });

  testWidgets('AlgorithmResultsCard renders child in result container', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlgorithmResultsCard(child: Text('Rendered result')),
        ),
      ),
    );

    expect(find.text('Rendered result'), findsOneWidget);
  });

  testWidgets('AlgorithmExamplesSection shows loading state', (tester) async {
    final examplesFuture = Future<ListResult<AssetExample<String>>>.value(
      const Success(<AssetExample<String>>[]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmExamplesSection<String>(
            examplesFuture: examplesFuture,
            loadingExampleName: null,
            onExampleSelected: (_) {},
            failureMessage: 'Could not load examples',
            emptyMessage: 'No examples',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    expect(find.text('Loading examples...'), findsOneWidget);
    await tester.pump();
  });

  testWidgets('AlgorithmExamplesSection shows failure state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmExamplesSection<String>(
            examplesFuture: Future.value(
              const Failure<List<AssetExample<String>>>('Example failure'),
            ),
            loadingExampleName: null,
            onExampleSelected: (_) {},
            failureMessage: 'Could not load examples',
            emptyMessage: 'No examples',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Example failure'), findsOneWidget);
  });

  testWidgets('AlgorithmExamplesSection shows empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmExamplesSection<String>(
            examplesFuture: Future.value(const Success(<AssetExample<String>>[])),
            loadingExampleName: null,
            onExampleSelected: (_) {},
            failureMessage: 'Could not load examples',
            emptyMessage: 'No examples',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No examples'), findsOneWidget);
  });

  testWidgets('AlgorithmExamplesSection shows examples and handles selection', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlgorithmExamplesSection<String>(
            examplesFuture: Future.value(
              Success([
                AssetExample<String>(
                  name: 'Example A',
                  description: 'Example description',
                  category: ExampleCategory.dfa,
                  difficultyLevel: DifficultyLevel.easy,
                  complexityLevel: ExampleComplexityLevel.low,
                  tags: const ['test'],
                  payload: 'payload',
                ),
              ]),
            ),
            loadingExampleName: null,
            onExampleSelected: (name) => selected = name,
            failureMessage: 'Could not load examples',
            emptyMessage: 'No examples',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Example A'), findsOneWidget);

    await tester.tap(find.text('Example A'));
    await tester.pumpAndSettle();

    expect(selected, 'Example A');
  });
}
