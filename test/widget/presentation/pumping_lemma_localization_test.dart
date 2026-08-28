import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/pumping_lemma_localizations.dart';
import 'package:turing_lab/presentation/content/pumping_lemma_problem_content_copy.dart';
import 'package:turing_lab/presentation/providers/pumping_lemma_progress_provider.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma_workspace.dart';

// feature-localization-contract: pumping-lemma-workspaces
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: localized-error
// feature-localization-surface: localized-valid-simulation
// feature-localization-surface: localized-import-export
// feature-localization-surface: localized-example-metadata
// feature-localization-surface: locale-switch-state-preservation
// feature-localization-surface: formal-content-preservation
// feature-localization-surface: responsive-accessibility
void main() {
  for (final theorem in PumpingLemmaTheorem.values) {
    testWidgets('${theorem.name} keeps the guided pumping workflow bilingual', (
      tester,
    ) async {
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      final container = await _pumpWorkspace(
        tester,
        theorem: theorem,
        locale: locale,
      );
      final en = AppLocalizationsEn();
      final pt = AppLocalizationsPt();
      final problem = _problemsFor(theorem).first;
      final problemCopy = PumpingLemmaProblemContentCopies.resolve(
        id: problem.id,
        languageCode: 'en',
        fallbackTitle: problem.customTitle,
      );

      expect(find.text(en.pumpingTheorem(theorem)), findsWidgets);
      expect(find.text(problemCopy.title), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('pumping-language-description')),
            )
            .label,
        en.languageLabelValue(problem.languageDescription),
      );

      final pumpingLength = find.byKey(const ValueKey('pumping-length-input'));
      final witness = find.byKey(const ValueKey('pumping-witness-input'));
      await tester.ensureVisible(pumpingLength);
      expect(
        tester.widget<TextField>(pumpingLength).decoration?.labelText,
        en.pumpingLemmaText(PumpingLemmaText.lengthLabel),
      );

      await tester.enterText(pumpingLength, '0');
      await _tapKey(tester, 'choose-pumping-length');
      expect(find.text(en.pumpingMessagePumpingLengthPositive), findsOneWidget);

      await tester.enterText(
        pumpingLength,
        '${problem.suggestedPumpingLength}',
      );
      await _tapKey(tester, 'choose-pumping-length');

      await tester.enterText(witness, 'not-json');
      await _tapKey(tester, 'choose-witness');
      expect(find.text(en.pumpingMessageInvalidTokenArray), findsOneWidget);

      final witnessValue = jsonEncode(problem.suggestedWitness);
      await tester.enterText(witness, witnessValue);
      locale.value = const Locale('pt');
      await tester.pumpAndSettle();
      expect(find.text(pt.pumpingTheorem(theorem)), findsWidgets);
      expect(find.text(en.pumpingTheorem(theorem)), findsNothing);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('pumping-language-description')),
            )
            .label,
        pt.languageLabelValue(problem.languageDescription),
      );
      expect(tester.widget<TextField>(witness).controller?.text, witnessValue);
      expect(
        tester.widget<TextField>(witness).decoration?.labelText,
        pt.pumpingLemmaText(PumpingLemmaText.witnessArray),
      );
      await _tapKey(tester, 'choose-witness');
      expect(
        find.text(en.pumpingStage(PumpingLemmaStage.awaitingDecomposition)),
        findsNothing,
      );
      expect(
        find.text(pt.pumpingStage(PumpingLemmaStage.awaitingDecomposition)),
        findsOneWidget,
      );
      await _tapKey(tester, 'choose-decomposition');
      await _tapKey(tester, 'choose-exponent');
      await _tapKey(tester, 'record-pumping-evidence');

      expect(find.text(pt.pumpingRoundComplete(1)), findsOneWidget);
      expect(find.text(en.pumpingRoundComplete(1)), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Decomposição\.')), findsOneWidget);
      final progress = container.read(
        theorem == PumpingLemmaTheorem.regular
            ? regularPumpingLemmaProgressProvider
            : contextFreePumpingLemmaProgressProvider,
      );
      expect(progress.completedChallengeIds, contains(problem.id));

      final formalLanguage = problem.languageDescription;
      expect(find.text(formalLanguage), findsOneWidget);
      expect(find.text(problemCopy.title), findsNothing);
      expect(
        find.text(
          PumpingLemmaProblemContentCopies.resolve(
            id: problem.id,
            languageCode: 'pt-BR',
            fallbackTitle: problem.customTitle,
          ).title,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final theorem in PumpingLemmaTheorem.values) {
    testWidgets(
      '${theorem.name} exports in English and imports in Portuguese',
      (tester) async {
        final picker = _FakeFilePicker();
        FilePicker.platform = picker;

        final locale = ValueNotifier(const Locale('en'));
        addTearDown(locale.dispose);
        await _pumpWorkspace(tester, theorem: theorem, locale: locale);

        final export = find.byKey(
          const ValueKey('interoperability_export_turing-lab-json'),
        );
        await tester.ensureVisible(export);
        await tester.tap(export);
        await tester.pumpAndSettle();
        expect(
          find.byType(DocumentInteroperabilityReviewDialog),
          findsOneWidget,
        );
        expect(
          find.text(AppLocalizationsEn().interoperabilityExportReviewTitle),
          findsOneWidget,
        );

        picker.enqueueSaveResult('pumping-session.json');
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            AppLocalizationsEn().interoperabilityExportDocument,
          ),
        );
        await tester.pumpAndSettle();
        expect(picker.lastSaveBytes, isNotNull);
        expect(picker.lastSaveBytes, isNotEmpty);
        expect(
          find.text(AppLocalizationsEn().interoperabilityExportSucceeded),
          findsOneWidget,
        );

        final exported = picker.lastSaveBytes!;
        locale.value = const Locale('pt');
        await tester.pumpAndSettle();
        picker.enqueuePickResult(
          FilePickerResult([
            PlatformFile(
              name: 'sessao-bombeamento.json',
              size: exported.length,
              bytes: exported,
            ),
          ]),
        );
        final import = find.byKey(
          const ValueKey('interoperability_import_document'),
        );
        await tester.ensureVisible(import);
        await tester.tap(import);
        await tester.pumpAndSettle();
        expect(
          find.byType(DocumentInteroperabilityReviewDialog),
          findsOneWidget,
        );
        expect(
          find.text(AppLocalizationsPt().interoperabilityImportReviewTitle),
          findsOneWidget,
        );
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            AppLocalizationsPt().interoperabilityReplaceDocument,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(AppLocalizationsPt().interoperabilityImportSucceeded),
          findsOneWidget,
        );
        expect(
          find.text(AppLocalizationsEn().interoperabilityImportSucceeded),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester, {
  required PumpingLemmaTheorem theorem,
  required ValueNotifier<Locale> locale,
}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      formalSystemRegistryProvider.overrideWithValue(
        FormalSystemRegistry.defaultRegistry,
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(body: PumpingLemmaWorkspace(theorem: theorem)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

List<PumpingLemmaProblem> _problemsFor(PumpingLemmaTheorem theorem) =>
    theorem == PumpingLemmaTheorem.regular
    ? PumpingLemmaProblemCatalog.regular
    : PumpingLemmaProblemCatalog.contextFree;

final class _FakeFilePicker extends FilePicker {
  final Queue<FilePickerResult?> _pickResults = Queue<FilePickerResult?>();
  final Queue<String?> _saveResults = Queue<String?>();
  Uint8List? lastSaveBytes;

  void enqueuePickResult(FilePickerResult? result) => _pickResults.add(result);

  void enqueueSaveResult(String? result) => _saveResults.add(result);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => _pickResults.isEmpty ? null : _pickResults.removeFirst();

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    lastSaveBytes = bytes;
    return _saveResults.isEmpty ? null : _saveResults.removeFirst();
  }
}
