import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/data/tm/tm_block_example_catalog.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/tm_block_example_content_copy.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_block_example_button.dart';

// feature-localization-contract: advanced-tm-workspaces
// feature-localization-surface: localized-building-block-workspace
final class _TMBlockExamplesDataSource extends ExamplesAssetDataSource {
  @override
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() async =>
      Success(await const TMBlockExampleCatalog().loadExamples());

  @override
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) async {
    final example = (await const TMBlockExampleCatalog().loadExamples()).single;
    return Success(example);
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required Locale locale,
  required TMEditorNotifier notifier,
  required _TMBlockExamplesDataSource examples,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: TMAlgorithmPanel(
            useExpanded: false,
            examplesDataSource: examples,
          ),
        ),
      ),
    ),
  );
  for (var attempt = 0; attempt < 80; attempt++) {
    if (find.byType(TMBlockExampleButton).evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 25));
  }
  fail('Timed out waiting for the TM building-block example.');
}

void main() {
  testWidgets(
    'localizes the building-block example at 320px and 200 percent without changing its formal project',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = TMEditorNotifier();
      final examples = _TMBlockExamplesDataSource();
      final en = TMBlockExampleContentCopies.resolve(
        id: TMBlockExampleContentCopies.id,
        languageCode: 'en',
      );
      final pt = TMBlockExampleContentCopies.resolve(
        id: TMBlockExampleContentCopies.id,
        languageCode: 'pt-BR',
      );

      await _pumpPanel(
        tester,
        locale: const Locale('en'),
        notifier: notifier,
        examples: examples,
      );

      expect(find.text(en.title), findsOneWidget);
      expect(find.textContaining(en.summary), findsOneWidget);
      expect(find.text('Suggested simulation: 111'), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(TMBlockExampleButton));
      expect(semantics.label, contains(en.accessibleDescription));
      expect(semantics.label, contains('Suggested simulation: 111.'));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byType(TMBlockExampleButton));
      await tester.tap(find.byType(TMBlockExampleButton));
      for (
        var attempt = 0;
        attempt < 80 && notifier.state.tm == null;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 25));
      }
      final loaded = notifier.state.tm;
      expect(loaded, isNotNull);
      final formalProject = loaded!.toJson();
      final stateIds = loaded.states.map((state) => state.id).toSet();
      final blockIds = loaded.blockDefinitions.keys.toSet();
      final invocationIds = loaded.blockInvocations
          .map((invocation) => invocation.id)
          .toList();

      await _pumpPanel(
        tester,
        locale: const Locale('pt', 'BR'),
        notifier: notifier,
        examples: examples,
      );

      expect(find.text(pt.title), findsOneWidget);
      expect(find.text(en.title), findsNothing);
      expect(find.textContaining(pt.summary), findsOneWidget);
      expect(find.text('Simulação sugerida: 111'), findsOneWidget);
      final portugueseSemantics = tester.getSemantics(
        find.byType(TMBlockExampleButton),
      );
      expect(portugueseSemantics.label, contains(pt.accessibleDescription));
      expect(portugueseSemantics.label, contains('Simulação sugerida: 111.'));
      expect(notifier.state.tm?.toJson(), formalProject);
      expect(
        notifier.state.tm?.states.map((state) => state.id).toSet(),
        stateIds,
      );
      expect(notifier.state.tm?.blockDefinitions.keys.toSet(), blockIds);
      expect(
        notifier.state.tm?.blockInvocations
            .map((invocation) => invocation.id)
            .toList(),
        invocationIds,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
