//
//  apple_release_smoke_test.dart
//  Turing Lab
//
//  Level L1 of the Apple release validation matrix: deterministic
//  widget/platform smoke over the iPhone, iPad and macOS form factors. Every
//  case is parameterized from the shared harness, needs no simulator, signing
//  identity or hardware, and never touches archive or App Store Connect work.
//
//  Run with:
//    flutter test test/integration/apple_release_smoke_test.dart --concurrency=1
//

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/regex_preset.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/repositories/examples_repository.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel_scaffold.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_failure_dialog.dart';
import 'package:turing_lab/presentation/widgets/error_banner.dart';
import 'package:turing_lab/presentation/widgets/file_operations_panel.dart';
import 'package:turing_lab/presentation/widgets/grammar_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/grammar_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/pda_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

import '../support/apple_release_harness.dart';
import '../support/apple_release_module.dart';
import '../support/apple_release_shell.dart';
import '../support/apple_release_target.dart';
import '../support/apple_release_test_level.dart';

const AppleReleaseTestLevel _level = AppleReleaseTestLevel.widgetPlatformSmoke;

class _OfflineFilePicker extends FilePicker {
  _OfflineFilePicker({this.injectFailures = true});

  final bool injectFailures;
  int pickCount = 0;
  int saveCount = 0;

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
  }) async {
    pickCount++;
    if (!injectFailures) {
      return null;
    }
    return FilePickerResult([
      PlatformFile(
        name: 'invalid-apple-smoke.json',
        size: 2,
        bytes: Uint8List.fromList(const [123, 125]),
      ),
    ]);
  }

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
    saveCount++;
    if (!injectFailures) {
      return null;
    }
    throw PlatformException(
      code: 'apple-smoke-save-failure',
      message: 'Offline save dialog fixture rejected the destination.',
    );
  }
}

class _MemoizedExamplesRepository implements ExamplesRepository {
  _MemoizedExamplesRepository(this._delegate);

  final ExamplesRepository _delegate;
  final Map<String, Result<AssetExample<FSA>>> _fsa = {};
  final Map<String, Result<AssetExample<Grammar>>> _grammar = {};
  final Map<String, Result<AssetExample<PDA>>> _pda = {};
  final Map<String, Result<AssetExample<TM>>> _tm = {};
  final Map<String, Result<AssetExample<RegexPreset>>> _regex = {};

  ListResult<AssetExample<FSA>>? _allFsa;
  ListResult<AssetExample<Grammar>>? _allGrammar;
  ListResult<AssetExample<PDA>>? _allPda;
  ListResult<AssetExample<TM>>? _allTm;
  ListResult<AssetExample<RegexPreset>>? _allRegex;

  Future<void> preloadReleaseFixtures() async {
    await loadAllTypedFsaExamples();
    await loadAllTypedCfgExamples();
    await loadAllTypedPdaExamples();
    await loadAllTypedTmExamples();
    await loadAllTypedRegexExamples();
    await loadTypedFsaExample('AFD - Contém AB');
    await loadTypedCfgExample('GLC - a^n b^n');
    await loadTypedPdaExample('APD - a^n b^n');
    await loadTypedTmExample('MT - a^n b^n');
    await loadTypedRegexExample('Regex - Termina com AB');
  }

  @override
  Future<ListResult<AssetExample<FSA>>> loadAllTypedFsaExamples() async =>
      _allFsa ??= await _delegate.loadAllTypedFsaExamples();

  @override
  Future<ListResult<AssetExample<Grammar>>> loadAllTypedCfgExamples() async =>
      _allGrammar ??= await _delegate.loadAllTypedCfgExamples();

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() async =>
      _allPda ??= await _delegate.loadAllTypedPdaExamples();

  @override
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() async =>
      _allTm ??= await _delegate.loadAllTypedTmExamples();

  @override
  Future<ListResult<AssetExample<RegexPreset>>>
  loadAllTypedRegexExamples() async =>
      _allRegex ??= await _delegate.loadAllTypedRegexExamples();

  @override
  Future<Result<AssetExample<FSA>>> loadTypedFsaExample(String name) async =>
      _fsa[name] ??= await _delegate.loadTypedFsaExample(name);

  @override
  Future<Result<AssetExample<Grammar>>> loadTypedCfgExample(
    String name,
  ) async => _grammar[name] ??= await _delegate.loadTypedCfgExample(name);

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) async =>
      _pda[name] ??= await _delegate.loadTypedPdaExample(name);

  @override
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) async =>
      _tm[name] ??= await _delegate.loadTypedTmExample(name);

  @override
  Future<Result<AssetExample<RegexPreset>>> loadTypedRegexExample(
    String name,
  ) async => _regex[name] ??= await _delegate.loadTypedRegexExample(name);
}

Finder _textFieldInside(Type panelType) => find.descendant(
  of: find.byType(panelType),
  matching: find.byType(TextField),
);

Future<void> _loadOfflineExample(
  AppleReleaseHarness harness, {
  required WorkspaceTab workspaceTab,
  required Finder panel,
  required String canonicalName,
  required bool Function() isLoaded,
  String mobileTooltip = 'Algorithms & Examples',
}) async {
  await harness.openWorkspacePanel(
    workspaceTab: workspaceTab,
    panelId: AutomatonWorkspaceScaffold.algorithmPanelId,
    mobileTooltip: mobileTooltip,
    panel: panel,
    description: 'the Algorithms panel for $canonicalName',
  );
  final visibleName = harness.localizations.localizedExampleName(canonicalName);
  final example = find.descendant(
    of: panel,
    matching: find.byKey(ValueKey<String>('algorithm-example-$canonicalName')),
  );
  final loading = find.descendant(
    of: panel,
    matching: find.text(
      harness.localizations.localizeWorkflowText('Loading examples...'),
    ),
  );
  await harness.waitUntilAsync(
    () => example.evaluate().isNotEmpty || loading.evaluate().isEmpty,
    description: 'the offline example "$visibleName" to load',
  );
  if (example.evaluate().isEmpty) {
    final renderedText = find
        .descendant(of: panel, matching: find.byType(Text))
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .whereType<String>()
        .join(' | ');
    throw TestFailure(
      'The offline example "$visibleName" did not load. '
      'Rendered panel text: $renderedText',
    );
  }
  await harness.tap(example, description: 'the offline example "$visibleName"');
  await harness.waitUntilAsync(
    isLoaded,
    description: 'the offline example "$canonicalName" to update its editor',
  );
}

Future<void> _closeAlgorithms(AppleReleaseHarness harness, Finder panel) {
  return harness.closeWorkspacePanel(
    panelId: AutomatonWorkspaceScaffold.algorithmPanelId,
    panel: panel,
    description: 'the Algorithms panel',
  );
}

Future<void> _openSimulation(
  AppleReleaseHarness harness, {
  required WorkspaceTab workspaceTab,
  required Finder panel,
  String mobileTooltip = 'Simulate',
}) {
  return harness.openWorkspacePanel(
    workspaceTab: workspaceTab,
    panelId: AutomatonWorkspaceScaffold.simulationPanelId,
    mobileTooltip: mobileTooltip,
    panel: panel,
    description: 'the $mobileTooltip panel',
  );
}

Future<void> _closeSimulation(AppleReleaseHarness harness, Finder panel) {
  return harness.closeWorkspacePanel(
    panelId: AutomatonWorkspaceScaffold.simulationPanelId,
    panel: panel,
    description: 'the simulation panel',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final examplesRepository = _MemoizedExamplesRepository(
    ExamplesAssetDataSource(),
  );
  setUpAll(
    () => examplesRepository.preloadReleaseFixtures().timeout(
      AppleReleaseHarness.defaultTimeout,
    ),
  );

  for (final target in AppleReleaseTarget.all) {
    group('${_level.id} Apple smoke - ${target.label}', () {
      testWidgets(
        'first launch renders the ${target.expectedShell.name} shell and '
        'reaches every release module',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          body: (harness) async {
            expect(
              harness.shell,
              target.expectedShell,
              reason:
                  'HomePage must pick the ${target.expectedShell.name} '
                  'shell at ${target.logicalSize.width}px.\n'
                  '${harness.describeState()}',
            );
            expect(harness.shellFinder, findsOneWidget);

            harness.expectNoUntrackedException(
              'rendering the first launch workspace',
            );

            final l10n = harness.localizations;
            for (final module in AppleReleaseModule.values) {
              await harness.openModule(module);
              expect(
                harness.appBarText(
                  harness.shell == AppleReleaseShell.mobile
                      ? module.label(l10n)
                      : module.description(l10n),
                ),
                findsOneWidget,
                reason:
                    'The ${module.name} workspace heading must be the only '
                    'one in the app bar.',
              );
              harness.expectNoUntrackedException(
                'opening the ${module.name} workspace',
              );
            }

            await harness.openModule(AppleReleaseModule.fsa);
            harness.expectNoUntrackedException(
              'returning to the FSA workspace',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'settings round trip switches locale, saves the dark theme and '
        'returns to the workspace',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          body: (harness) async {
            await harness.openSettings();
            final english = harness.localizationsFor('en');
            expect(
              harness.appBarText(english.settingsPageTitle),
              findsOneWidget,
            );
            expect(find.text(english.settingsThemeModeTitle), findsOneWidget);
            expect(find.text(english.settingsLanguageTitle), findsOneWidget);

            await harness.selectLocale('pt');
            final portuguese = harness.localizationsFor('pt');
            expect(
              harness.appBarText(portuguese.settingsPageTitle),
              findsOneWidget,
              reason:
                  'Selecting Portuguese must retranslate the settings page.',
            );

            await harness.selectLocale('en');
            expect(
              harness.appBarText(english.settingsPageTitle),
              findsOneWidget,
            );

            await harness.tap(
              find.byKey(const ValueKey('settings_theme_dark')),
              description: 'the dark theme chip',
            );
            await harness.waitUntil(
              () => tester
                  .widget<FilterChip>(
                    find.byKey(const ValueKey('settings_theme_dark')),
                  )
                  .selected,
              description: 'the dark theme chip to report itself selected',
            );

            await harness.tapAndWaitFor(
              find.byKey(const ValueKey('settings_save_button')),
              find.text(english.settingsSaveSuccess),
              description: 'the settings saved confirmation',
            );

            await harness.back(
              expected: harness.shellFinder,
              description: 'the workspace shell',
            );
            expect(
              harness.shellBrightness,
              Brightness.dark,
              reason:
                  'The saved dark theme must survive the pop back to the '
                  'workspace.',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'offline fixtures cover FSA editing and simulation plus Grammar, '
        'PDA, TM and Regex flows',
        (tester) async {
          await AppleReleaseHarness.run(
            tester,
            target: target,
            level: _level,
            examplesRepository: examplesRepository,
            body: (harness) async {
              final fsaAlgorithms = find.byType(AlgorithmPanel);
              await _loadOfflineExample(
                harness,
                workspaceTab: WorkspaceTab.fsa,
                panel: fsaAlgorithms,
                canonicalName: 'AFD - Contém AB',
                isLoaded: () =>
                    harness.container
                        .read(automatonStateProvider)
                        .currentAutomaton
                        ?.name ==
                    'AFD - Contém AB',
              );
              await _closeAlgorithms(harness, fsaAlgorithms);

              final canvas = tester.widget<AutomatonGraphViewCanvas>(
                find.byType(AutomatonGraphViewCanvas),
              );
              final stateCount = harness.container
                  .read(automatonStateProvider)
                  .currentAutomaton!
                  .states
                  .length;
              canvas.controller!.addStateAt(const Offset(260, 220));
              await harness.waitUntil(
                () =>
                    harness.container
                        .read(automatonStateProvider)
                        .currentAutomaton!
                        .states
                        .length ==
                    stateCount + 1,
                description: 'the FSA canvas edit to reach the domain model',
              );

              final fsaSimulation = find.byType(SimulationPanel);
              await _openSimulation(
                harness,
                workspaceTab: WorkspaceTab.fsa,
                panel: fsaSimulation,
              );
              await harness.enterText(
                _textFieldInside(SimulationPanel).first,
                'ab',
                description: 'the FSA simulation input',
              );
              await harness.tap(
                find.descendant(
                  of: fsaSimulation,
                  matching: find.text(harness.localizations.simulate),
                ),
                description: 'the FSA Simulate button',
              );
              await harness.waitUntilAsync(
                () =>
                    harness.container
                        .read(automatonSimulationProvider)
                        .simulationResult
                        ?.isAccepted ==
                    true,
                description: 'the loaded FSA to accept "ab"',
              );
              await _closeSimulation(harness, fsaSimulation);
              harness.expectNoUntrackedException('completing the FSA journey');

              await harness.openModule(AppleReleaseModule.grammar);
              final grammarAlgorithms = find.byType(GrammarAlgorithmPanel);
              await _loadOfflineExample(
                harness,
                workspaceTab: WorkspaceTab.grammar,
                panel: grammarAlgorithms,
                canonicalName: 'GLC - a^n b^n',
                isLoaded: () =>
                    harness.container.read(grammarProvider).name ==
                    'GLC - a^n b^n',
              );
              await _closeAlgorithms(harness, grammarAlgorithms);
              final grammarSimulation = find.byType(GrammarSimulationPanel);
              await _openSimulation(
                harness,
                workspaceTab: WorkspaceTab.grammar,
                panel: grammarSimulation,
                mobileTooltip: 'Parser',
              );
              await harness.enterText(
                _textFieldInside(GrammarSimulationPanel).first,
                'aabb',
                description: 'the Grammar parser input',
              );
              await harness.tap(
                find.descendant(
                  of: grammarSimulation,
                  matching: find.text(harness.localizations.parseString),
                ),
                description: 'the Grammar Parse String button',
              );
              await harness.waitUntilAsync(
                () => find
                    .descendant(
                      of: grammarSimulation,
                      matching: find.text(harness.localizations.accepted),
                    )
                    .evaluate()
                    .isNotEmpty,
                description: 'the Grammar parser acceptance result',
              );
              await _closeSimulation(harness, grammarSimulation);
              harness.expectNoUntrackedException(
                'completing the Grammar journey',
              );

              await harness.openModule(AppleReleaseModule.pda);
              final pdaAlgorithms = find.byType(PDAAlgorithmPanel);
              await _loadOfflineExample(
                harness,
                workspaceTab: WorkspaceTab.pda,
                panel: pdaAlgorithms,
                canonicalName: 'APD - a^n b^n',
                mobileTooltip: 'Algorithms',
                isLoaded: () =>
                    harness.container.read(pdaEditorProvider).pda?.name ==
                    'APD - a^n b^n',
              );
              await _closeAlgorithms(harness, pdaAlgorithms);
              final pdaSimulation = find.byType(PDASimulationPanel);
              await _openSimulation(
                harness,
                workspaceTab: WorkspaceTab.pda,
                panel: pdaSimulation,
              );
              await harness.enterText(
                _textFieldInside(PDASimulationPanel).first,
                'ab',
                description: 'the PDA simulation input',
              );
              await harness.tap(
                find.descendant(
                  of: pdaSimulation,
                  matching: find.text('Simulate PDA'),
                ),
                description: 'the Simulate PDA button',
              );
              await harness.waitUntilAsync(
                () => find
                    .descendant(
                      of: pdaSimulation,
                      matching: find.text(harness.localizations.accepted),
                    )
                    .evaluate()
                    .isNotEmpty,
                description: 'the PDA acceptance result',
              );
              await _closeSimulation(harness, pdaSimulation);
              harness.expectNoUntrackedException('completing the PDA journey');

              await harness.openModule(AppleReleaseModule.tm);
              final tmAlgorithms = find.byType(TMAlgorithmPanel);
              await _loadOfflineExample(
                harness,
                workspaceTab: WorkspaceTab.tm,
                panel: tmAlgorithms,
                canonicalName: 'MT - a^n b^n',
                isLoaded: () =>
                    harness.container.read(tmEditorProvider).tm?.name ==
                    'tm_anbn',
              );
              await _closeAlgorithms(harness, tmAlgorithms);
              final tmSimulation = find.byType(TMSimulationPanel);
              await _openSimulation(
                harness,
                workspaceTab: WorkspaceTab.tm,
                panel: tmSimulation,
              );
              await harness.enterText(
                _textFieldInside(TMSimulationPanel).first,
                'ab',
                description: 'the TM simulation input',
              );
              await harness.tap(
                find.descendant(
                  of: tmSimulation,
                  matching: find.text('Simulate TM'),
                ),
                description: 'the Simulate TM button',
              );
              await harness.waitUntilAsync(
                () => find
                    .descendant(
                      of: tmSimulation,
                      matching: find.text(harness.localizations.accepted),
                    )
                    .evaluate()
                    .isNotEmpty,
                description: 'the TM acceptance result',
              );
              await _closeSimulation(harness, tmSimulation);
              harness.expectNoUntrackedException('completing the TM journey');

              await harness.openModule(AppleReleaseModule.regex);
              final regexAlgorithms = find.byType(AlgorithmPanelScaffold);
              await _loadOfflineExample(
                harness,
                workspaceTab: WorkspaceTab.regex,
                panel: regexAlgorithms,
                canonicalName: 'Regex - Termina com AB',
                isLoaded: () =>
                    harness.container.read(regexEditorProvider).currentRegex ==
                    '(a|b)*ab',
              );
              await _closeAlgorithms(harness, regexAlgorithms);
              final regexSimulation = find.byKey(
                const Key('regex-simulation-section'),
              );
              await _openSimulation(
                harness,
                workspaceTab: WorkspaceTab.regex,
                panel: regexSimulation,
              );
              await harness.enterText(
                find.byKey(const ValueKey('regex_test_input_field')),
                'ab',
                description: 'the Regex test input',
              );
              await harness.tap(
                find.byTooltip(harness.localizations.testStringTooltip),
                description: 'the Regex test action',
              );
              await harness.waitUntilAsync(() {
                final state = harness.container.read(regexEditorProvider);
                return state.hasTested && state.matches;
              }, description: 'the Regex preset to match "ab"');
              await _closeSimulation(harness, regexSimulation);
              harness.expectNoUntrackedException(
                'completing the Regex journey',
              );
            },
          );
        },
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'offline file fixtures surface import and export errors without '
        'native system UI',
        (tester) async {
          final picker = _OfflineFilePicker();
          FilePicker.platform = picker;
          try {
            await AppleReleaseHarness.run(
              tester,
              target: target,
              level: _level,
              body: (harness) async {
                final algorithms = find.byType(AlgorithmPanel);
                await harness.openWorkspacePanel(
                  workspaceTab: WorkspaceTab.fsa,
                  panelId: AutomatonWorkspaceScaffold.algorithmPanelId,
                  mobileTooltip: 'Algorithms & Examples',
                  panel: algorithms,
                  description: 'the Algorithms panel for file operations',
                );

                await harness.tap(
                  find.byKey(
                    const ValueKey<String>('interoperability_import_document'),
                  ),
                  description: 'the generic document import action',
                );
                final importDialog = find.byWidgetPredicate(
                  (widget) => widget is DocumentInteroperabilityFailureDialog,
                  description: 'a document interoperability failure dialog',
                );
                await harness.waitUntilAsync(
                  () => importDialog.evaluate().isNotEmpty,
                  description: 'the invalid JSON import error dialog',
                );
                expect(picker.pickCount, 1);
                expect(
                  find.textContaining('invalid-apple-smoke.json'),
                  findsOneWidget,
                );
                await harness.dismissRoute(
                  importDialog,
                  description: 'the invalid JSON import error dialog',
                );

                harness.container
                    .read(automatonStateProvider.notifier)
                    .updateAutomaton(
                      FSA.empty(
                        id: 'apple-smoke-file-fixture',
                        name: 'Apple smoke file fixture',
                      ),
                    );
                await harness.waitUntilAsync(
                  () =>
                      harness.container
                          .read(automatonStateProvider)
                          .currentAutomaton
                          ?.id ==
                      'apple-smoke-file-fixture',
                  description: 'the offline FSA file fixture to load',
                );

                await harness.tap(
                  find.byKey(
                    const ValueKey<String>(
                      'interoperability_export_turing-lab-json',
                    ),
                  ),
                  description: 'the generic JSON export action',
                );
                await harness.tap(
                  find.text(
                    harness.localizations.interoperabilityExportDocument,
                  ),
                  description: 'the reviewed JSON export confirmation',
                );
                final filePanel = find.byType(FileOperationsPanel);
                await harness.waitUntilAsync(
                  () => find
                      .descendant(
                        of: filePanel,
                        matching: find.byType(ErrorBanner),
                      )
                      .evaluate()
                      .isNotEmpty,
                  description: 'the rejected JSON export error banner',
                );
                expect(picker.saveCount, 1);
                expect(
                  find.text(
                    harness.localizations.interoperabilityOperationFailed,
                  ),
                  findsOneWidget,
                );

                await _closeAlgorithms(harness, algorithms);
              },
            );
          } finally {
            FilePicker.platform = _OfflineFilePicker(injectFailures: false);
          }
        },
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'help opens from the workspace app bar, searches and returns',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          enableSemantics: true,
          body: (harness) async {
            final l10n = harness.localizations;

            await harness.openHelp();
            harness.expectNoUntrackedException('opening the help catalog');

            await harness.tapAndWaitFor(
              find.byKey(const ValueKey('help-search-action')),
              find.byKey(const ValueKey('help-search-field')),
              description: 'the help search field',
            );
            await tester.enterText(
              find.byKey(const ValueKey('help-search-field')),
              'grammar',
            );
            await harness.waitFor(
              find.byKey(const ValueKey('help-search-status')),
              description: 'the help search status region',
            );

            await harness.back(
              expected: harness.shellFinder,
              description: 'the workspace shell',
            );
            expect(
              harness.appBarText(
                harness.shell == AppleReleaseShell.mobile
                    ? AppleReleaseModule.fsa.label(l10n)
                    : AppleReleaseModule.fsa.description(l10n),
              ),
              findsOneWidget,
              reason:
                  'Closing help must restore the workspace it was opened '
                  'from.',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'launch restores the persisted locale and theme',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          preferences: const <String, Object>{
            'settings_locale_code': 'pt',
            'settings_theme_mode': 'dark',
          },
          body: (harness) async {
            final portuguese = harness.localizationsFor('pt');
            expect(
              harness.appBarText(
                harness.shell == AppleReleaseShell.mobile
                    ? AppleReleaseModule.fsa.label(portuguese)
                    : AppleReleaseModule.fsa.description(portuguese),
              ),
              findsOneWidget,
              reason:
                  'A relaunch must restore the persisted locale before the '
                  'workspace is usable.',
            );
            expect(
              harness.shellBrightness,
              Brightness.dark,
              reason: 'A relaunch must restore the persisted theme.',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      if (target.hasPointerAndKeyboard) {
        testWidgets(
          'pointer hover and keyboard traversal work without native system UI',
          (tester) => AppleReleaseHarness.run(
            tester,
            target: target,
            level: _level,
            body: (harness) async {
              expect(
                harness.shell,
                AppleReleaseShell.desktop,
                reason:
                    'Pointer and keyboard coverage targets the desktop '
                    'shell only.',
              );

              final l10n = harness.localizations;
              final selectorHint = l10n.workspaceSelectorHint;
              final selector = find
                  .descendant(
                    of: harness.shellFinder,
                    matching: find.byIcon(Icons.arrow_drop_down),
                  )
                  .first;

              final pointer = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await pointer.addPointer();
              addTearDown(pointer.removePointer);
              await pointer.moveTo(tester.getCenter(selector));

              await harness.waitFor(
                find.text(selectorHint),
                description: 'the workspace selector tooltip shown on hover',
              );

              await pointer.moveTo(Offset.zero);
              await harness.waitUntilGone(
                find.text(selectorHint),
                description: 'the workspace selector tooltip to be dismissed',
              );

              await harness.openHelp();
              await harness.tapAndWaitFor(
                find.byKey(const ValueKey('help-search-action')),
                find.byKey(const ValueKey('help-search-field')),
                description: 'the help search field',
              );
              await harness.waitUntil(
                () =>
                    tester.binding.focusManager.primaryFocus?.context != null &&
                    find
                        .descendant(
                          of: find.byKey(const ValueKey('help-search-field')),
                          matching: find.byType(EditableText),
                        )
                        .evaluate()
                        .isNotEmpty,
                description: 'the help search field to take keyboard focus',
              );

              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await harness.waitUntilGone(
                find.byKey(const ValueKey('help-search-field')),
                description: 'the help search field to close on Escape',
              );

              await harness.back(
                expected: harness.shellFinder,
                description: 'the workspace shell',
              );
            },
          ),
          variant: TargetPlatformVariant.only(target.platform),
        );
      }
    });
  }
}
