//
//  suggested_simulation_input_test.dart
//  Turing Lab
//
//  Covers the "Use input" action of example suggestions: request publishing
//  from the FSA algorithm panel, application by the simulation panels,
//  workspace isolation, the keep/replace prompt for edited fields, transducer
//  token conversion, and the compact-layout chip rendering.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/simulation_input_request_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/common/simulation_input_request_binding.dart';
import 'package:turing_lab/presentation/widgets/example_suggested_simulations_text.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/transducers/transducer_simulation_panel.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.isNotEmpty)
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $texts');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Loaded once outside the fake-async zone so both panel tests resolve the
  // bundled examples from the in-memory cache.
  final examples = ExamplesAssetDataSource();
  late final String containsAbPayloadId;
  setUpAll(() async {
    final all = (await examples.loadAllTypedFsaExamples()).data!;
    containsAbPayloadId = all
        .firstWhere((example) => example.id == 'asset/afd_contains_ab')
        .payload
        .id;
  });

  group('SimulationInputRequestNotifier', () {
    test('publishes increasing ids and consumes only the matching one', () {
      final notifier = SimulationInputRequestNotifier();
      final first = notifier.publish(
        workspace: DefaultFormalSystemIds.fsa,
        exampleId: 'asset/afd_contains_ab',
        input: 'aab',
      );
      final second = notifier.publish(
        workspace: DefaultFormalSystemIds.fsa,
        exampleId: 'asset/afd_contains_ab',
        input: 'ab',
      );
      expect(second.id, greaterThan(first.id));
      notifier.consume(first.id);
      expect(notifier.state, second);
      notifier.consume(second.id);
      expect(notifier.state, isNull);
    });
  });

  test('transducer suggestions become one token per line', () {
    expect(transducerSuggestionToInputLines('0101'), '0\n1\n0\n1');
    expect(transducerSuggestionToInputLines('coin vend'), 'coin\nvend');
    expect(transducerSuggestionToInputLines('ab'), 'a\nb');
  });

  group('AlgorithmPanel use-input action', () {
    testWidgets('loads the example, publishes the request and confirms', (
      tester,
    ) async {
      final notifier = AutomatonStateNotifier();
      final container = ProviderContainer(
        overrides: [automatonStateProvider.overrideWith((ref) => notifier)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(
            AlgorithmPanel(
              currentAutomaton: null,
              showExamples: true,
              examplesDataSource: examples,
              fileService: FileOperationsService(),
            ),
          ),
        ),
      );
      final chip = find.byKey(
        ExampleSuggestedSimulationsText.useInputKey(
          'aab',
          'asset/afd_contains_ab',
        ),
      );
      await _waitFor(tester, chip);
      expect(find.byTooltip('Use input'), findsWidgets);

      await tester.ensureVisible(chip);
      await tester.tap(chip);
      for (
        var attempt = 0;
        attempt < 100 && container.read(simulationInputRequestProvider) == null;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 500));

      final request = container.read(simulationInputRequestProvider);
      expect(request, isNotNull);
      expect(request!.workspace, DefaultFormalSystemIds.fsa);
      expect(request.exampleId, 'asset/afd_contains_ab');
      expect(request.input, 'aab');
      expect(notifier.state.currentAutomaton?.id, containsAbPayloadId);
      expect(
        find.text('Input “aab” sent to the simulation field.'),
        findsOneWidget,
      );
    });

    testWidgets('closes the compact sheet and opens the simulate action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      var simulateCalls = 0;
      container
          .read(
            workspaceQuickActionsProvider(DefaultFormalSystemIds.fsa).notifier,
          )
          .state = WorkspaceQuickActions(
        onSimulate: () => simulateCalls++,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const ValueKey('open-sheet'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SizedBox(
                      height: 600,
                      child: SingleChildScrollView(
                        child: AlgorithmPanel(
                          currentAutomaton: null,
                          showExamples: true,
                          examplesDataSource: examples,
                          fileService: FileOperationsService(),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open-sheet')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlgorithmPanel), findsOneWidget);
      final chip = find.byKey(
        ExampleSuggestedSimulationsText.useInputKey(
          'aab',
          'asset/afd_contains_ab',
        ),
      );
      await _waitFor(tester, chip);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      for (var attempt = 0; attempt < 100 && simulateCalls == 0; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 1));

      expect(simulateCalls, 1);
      expect(find.byType(AlgorithmPanel), findsNothing);
      expect(container.read(simulationInputRequestProvider)?.input, 'aab');
    });
  });

  group('SimulationPanel request consumption', () {
    Future<ProviderContainer> pumpPanel(
      WidgetTester tester, {
      SimulationInputRequest? pending,
    }) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      if (pending != null) {
        container
            .read(simulationInputRequestProvider.notifier)
            .publish(
              workspace: pending.workspace,
              exampleId: pending.exampleId,
              input: pending.input,
            );
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(SimulationPanel(onSimulate: (_) async {})),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    SimulationInputRequest request(FormalSystemKey workspace, String input) =>
        SimulationInputRequest(
          id: 0,
          workspace: workspace,
          exampleId: 'example',
          input: input,
        );

    TextField inputField(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).first);

    testWidgets('applies a pending request for its workspace on mount', (
      tester,
    ) async {
      final container = await pumpPanel(
        tester,
        pending: request(DefaultFormalSystemIds.fsa, 'a b'),
      );
      expect(inputField(tester).controller!.text, 'a b');
      expect(container.read(simulationInputRequestProvider), isNull);
    });

    testWidgets('ignores requests addressed to another workspace', (
      tester,
    ) async {
      final container = await pumpPanel(
        tester,
        pending: request(DefaultFormalSystemIds.pda, 'aabb'),
      );
      expect(inputField(tester).controller!.text, isEmpty);
      expect(container.read(simulationInputRequestProvider), isNotNull);
    });

    testWidgets('applies a live request into an empty field', (tester) async {
      final container = await pumpPanel(tester);
      container
          .read(simulationInputRequestProvider.notifier)
          .publish(
            workspace: DefaultFormalSystemIds.fsa,
            exampleId: 'example',
            input: '110',
          );
      await tester.pumpAndSettle();
      expect(inputField(tester).controller!.text, '110');
      expect(container.read(simulationInputRequestProvider), isNull);
    });

    for (final beforeFrame in [true, false]) {
      testWidgets(
        'new requests replace confirmations (before frame: $beforeFrame)',
        (tester) async {
          final container = await pumpPanel(tester);
          await tester.enterText(find.byType(TextField).first, 'typed');
          final notifier = container.read(
            simulationInputRequestProvider.notifier,
          );
          void publish(String input) => notifier.publish(
            workspace: DefaultFormalSystemIds.fsa,
            exampleId: 'example',
            input: input,
          );
          publish('old');
          if (!beforeFrame) await tester.pumpAndSettle();
          publish('new');
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
          await tester.tap(
            find.byKey(SimulationInputRequestBinding.replaceKey),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
          expect(inputField(tester).controller!.text, 'new');
          expect(container.read(simulationInputRequestProvider), isNull);
        },
      );
    }

    testWidgets(
      'a request for another workspace dismisses the old confirmation',
      (tester) async {
        final container = await pumpPanel(tester);
        await tester.enterText(find.byType(TextField).first, 'typed');
        final notifier = container.read(
          simulationInputRequestProvider.notifier,
        );
        notifier.publish(
          workspace: DefaultFormalSystemIds.fsa,
          exampleId: 'example',
          input: 'old',
        );
        await tester.pumpAndSettle();
        notifier.publish(
          workspace: DefaultFormalSystemIds.pda,
          exampleId: 'other',
          input: 'new',
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
        expect(inputField(tester).controller!.text, 'typed');
        expect(container.read(simulationInputRequestProvider)?.input, 'new');
      },
    );

    testWidgets('asks before replacing an edited field and can keep it', (
      tester,
    ) async {
      final container = await pumpPanel(tester);
      await tester.enterText(find.byType(TextField).first, 'typed');
      container
          .read(simulationInputRequestProvider.notifier)
          .publish(
            workspace: DefaultFormalSystemIds.fsa,
            exampleId: 'example',
            input: 'aab',
          );
      await tester.pumpAndSettle();
      expect(find.text('Replace current input?'), findsOneWidget);
      expect(
        find.text(
          'The simulation field contains “typed”. Replace it with “aab”?',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(SimulationInputRequestBinding.keepKey));
      await tester.pumpAndSettle();
      expect(inputField(tester).controller!.text, 'typed');
      expect(container.read(simulationInputRequestProvider), isNull);

      container
          .read(simulationInputRequestProvider.notifier)
          .publish(
            workspace: DefaultFormalSystemIds.fsa,
            exampleId: 'example',
            input: 'ba',
          );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SimulationInputRequestBinding.replaceKey));
      await tester.pumpAndSettle();
      expect(inputField(tester).controller!.text, 'ba');
      expect(container.read(simulationInputRequestProvider), isNull);

      // A field still holding the applied suggestion is replaced silently.
      container
          .read(simulationInputRequestProvider.notifier)
          .publish(
            workspace: DefaultFormalSystemIds.fsa,
            exampleId: 'example',
            input: 'aabb',
          );
      await tester.pumpAndSettle();
      expect(find.text('Replace current input?'), findsNothing);
      expect(inputField(tester).controller!.text, 'aabb');
    });

    testWidgets('opens only the newest prompt when requests race a frame', (
      tester,
    ) async {
      final container = await pumpPanel(tester);
      await tester.enterText(find.byType(TextField).first, 'typed');
      final notifier = container.read(simulationInputRequestProvider.notifier);
      notifier.publish(
        workspace: DefaultFormalSystemIds.fsa,
        exampleId: 'example',
        input: 'aab',
      );
      notifier.publish(
        workspace: DefaultFormalSystemIds.fsa,
        exampleId: 'example',
        input: 'ba',
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          'The simulation field contains “typed”. Replace it with “ba”?',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(SimulationInputRequestBinding.replaceKey));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(inputField(tester).controller!.text, 'ba');
      expect(container.read(simulationInputRequestProvider), isNull);
    });

    testWidgets('localizes the replace prompt in Portuguese', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(
            SimulationPanel(onSimulate: (_) async {}),
            locale: const Locale('pt'),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'x');
      container
          .read(simulationInputRequestProvider.notifier)
          .publish(
            workspace: DefaultFormalSystemIds.fsa,
            exampleId: 'example',
            input: 'aab',
          );
      await tester.pumpAndSettle();
      expect(find.text('Substituir a entrada atual?'), findsOneWidget);
      expect(find.text('Manter atual'), findsOneWidget);
      expect(find.text('Substituir'), findsOneWidget);
    });
  });
}
