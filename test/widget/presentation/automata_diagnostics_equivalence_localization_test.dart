import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/language_comparator.dart';
import 'package:turing_lab/core/models/computation_branch.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/fsa_computation_branch_adapter.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/language_comparison_outcome.dart';
import 'package:turing_lab/core/models/nfa_computation_tree.dart';
import 'package:turing_lab/core/models/nfa_path_node.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_model;
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_resolver.dart';
import 'package:turing_lab/l10n/automata_diagnostics_localizations.dart';
import 'package:turing_lab/presentation/widgets/automaton_diagnostic_highlight_bar.dart';
import 'package:turing_lab/presentation/widgets/base_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/computation_branch_inspector.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_semantics.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';
import 'package:turing_lab/presentation/widgets/read_only_fsa_graphview_canvas.dart';

// feature-localization-contract: automata-diagnostics-and-equivalence
// feature-localization-surface: localized-computation-tree
// feature-localization-surface: localized-nondeterminism-highlight
// feature-localization-surface: localized-epsilon-highlight
// feature-localization-surface: localized-dfa-equivalence
// feature-localization-surface: localized-error
// feature-localization-surface: localized-bounded-result
// feature-localization-surface: locale-switch-state-preservation
// feature-localization-surface: formal-content-preservation
// feature-localization-surface: responsive-accessibility
// feature-localization-surface: selection-highlight-result-viewport-preservation

final AppLocalizations _en = AppLocalizationsEn();
final AppLocalizations _pt = AppLocalizationsPt();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'production diagnostics and equivalence stay localized after locale switch',
    (tester) async {
      await _usePhoneAtTwoHundredPercent(tester);
      final machineA = _machine('machine-a', 'Máquina Ω', acceptsA: true);
      final machineB = _machine('machine-b', 'Máquina λ', acceptsA: false);
      final comparison = LanguageComparator.compareLanguages(
        machineA,
        machineB,
      );
      expect(comparison.isSuccess, isTrue);
      final result = comparison.data!;
      expect(result.isEquivalent, isFalse);
      final machineSnapshot = jsonEncode(machineA.toJson());
      final highlightService = SimulationHighlightService();
      final hostKey = GlobalKey<_DiagnosticsContractHostState>();

      await tester.pumpWidget(
        _DiagnosticsContractHost(
          key: hostKey,
          machineA: machineA,
          comparisonResult: result,
          highlightService: highlightService,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_en.automataDiagnosticsConflicts(2)), findsOneWidget);
      expect(find.text(_en.automataDiagnosticsEpsilon(1)), findsOneWidget);
      expect(find.text(_en.notEquivalent), findsOneWidget);

      final input = tester.widget<TextField>(find.byType(TextField).first);
      input.controller!.text = 'λcustom';
      await tester.pump();

      final branchSelector = find.byKey(
        const ValueKey('computation-branch-selector'),
      );
      await tester.ensureVisible(branchSelector);
      await tester.tap(branchSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('qΩ').last);
      await tester.pumpAndSettle();

      final detailsDisclosure = find.text(
        _en.computationBranchesConfigurationDetails,
      );
      await tester.ensureVisible(detailsDisclosure);
      await tester.tap(detailsDisclosure);
      await tester.pumpAndSettle();

      final branchHighlight = find.byKey(
        const ValueKey('computation-branch-highlight'),
      );
      await tester.ensureVisible(branchHighlight);
      await tester.tap(branchHighlight);
      await tester.pumpAndSettle();
      expect(highlightService.lastHighlight?.stateIds, {'q0-id', 'q-omega-id'});

      final conflictAction = find.byKey(
        const ValueKey('highlight-conflicting-transitions'),
      );
      await tester.ensureVisible(conflictAction);
      await tester.tap(conflictAction);
      await tester.pumpAndSettle();
      expect(
        hostKey.currentState!.activeDiagnostic,
        AutomatonDiagnosticHighlightKind.conflicts,
      );

      final nextStep = find.byKey(
        const ValueKey<String>(LanguageComparisonSemantics.nextStep),
      );
      await tester.ensureVisible(nextStep);
      await tester.tap(nextStep);
      await tester.pumpAndSettle();
      expect(
        find.byKey(LanguageComparisonSemantics.stepKey(1)),
        findsOneWidget,
      );
      final canvasStateBefore = tester.state(
        find.byType(ReadOnlyFsaGraphViewCanvas).first,
      );

      hostKey.currentState!.setLocale(const Locale('pt'));
      await tester.pumpAndSettle();

      expect(find.text(_pt.automataDiagnosticsConflicts(2)), findsOneWidget);
      expect(find.text(_pt.automataDiagnosticsEpsilon(1)), findsOneWidget);
      expect(find.text(_pt.computationBranchesTitle), findsOneWidget);
      expect(find.text(_pt.notEquivalent), findsOneWidget);
      expect(
        find.text(_pt.languageComparisonStepAlphabetNormalization),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'λcustom',
      );
      expect(
        hostKey.currentState!.activeDiagnostic,
        AutomatonDiagnosticHighlightKind.conflicts,
      );
      expect(highlightService.lastHighlight?.stateIds, {'q0-id', 'q-omega-id'});
      expect(
        find.byKey(LanguageComparisonSemantics.stepKey(1)),
        findsOneWidget,
      );
      expect(
        tester.state(find.byType(ReadOnlyFsaGraphViewCanvas).first),
        same(canvasStateBefore),
      );
      expect(
        find.byKey(
          LanguageComparisonSemantics.statusKey(
            LanguageComparisonStatus.notEquivalent,
          ),
        ),
        findsOneWidget,
      );
      expect(jsonEncode(machineA.toJson()), machineSnapshot);
      expect(find.textContaining('Máquina Ω'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bounded and invalid outcomes have complete bilingual semantics',
    (tester) async {
      await _usePhoneAtTwoHundredPercent(tester);
      final hostKey = GlobalKey<_FailureContractHostState>();
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(_FailureContractHost(key: hostKey));
      await tester.pumpAndSettle();

      expect(find.text(_en.languageComparisonLimitReached), findsOneWidget);
      expect(
        find.text(_en.languageComparisonFailureStateLimitExplanation),
        findsOneWidget,
      );
      expect(find.text(_en.languageComparisonInvalidInput), findsOneWidget);
      expect(
        find.text(_en.languageComparisonFailureMalformedExplanation),
        findsOneWidget,
      );

      hostKey.currentState!.setLocale(const Locale('pt'));
      await tester.pumpAndSettle();

      expect(find.text(_pt.languageComparisonLimitReached), findsOneWidget);
      expect(
        find.text(_pt.languageComparisonFailureStateLimitExplanation),
        findsOneWidget,
      );
      expect(find.text(_pt.languageComparisonInvalidInput), findsOneWidget);
      expect(
        find.text(_pt.languageComparisonFailureMalformedExplanation),
        findsOneWidget,
      );
      final errorLabels = tester
          .widgetList<Semantics>(
            find.bySemanticsIdentifier(LanguageComparisonSemantics.error),
          )
          .map((widget) => widget.properties.label)
          .whereType<String>();
      expect(errorLabels, everyElement(isNot(contains('machine'))));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

class _DiagnosticsContractHost extends StatefulWidget {
  const _DiagnosticsContractHost({
    super.key,
    required this.machineA,
    required this.comparisonResult,
    required this.highlightService,
  });

  final FSA machineA;
  final EquivalenceComparisonResult comparisonResult;
  final SimulationHighlightService highlightService;

  @override
  State<_DiagnosticsContractHost> createState() =>
      _DiagnosticsContractHostState();
}

class _DiagnosticsContractHostState extends State<_DiagnosticsContractHost> {
  Locale locale = const Locale('en');
  AutomatonDiagnosticHighlightKind? activeDiagnostic;
  ComputationBranchId? selectedBranchId;
  ComputationBranchNodeId? selectedNodeId;
  final TextEditingController inputController = TextEditingController();

  void setLocale(Locale value) => setState(() => locale = value);

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = appLocalizationsOf(context);
            final adapted = FsaComputationBranchAdapter.adapt(
              _branchingResult(),
              isDeterministic: false,
              stateLabels: const {
                'q0-id': 'q0',
                'q-accept-id': 'qAccept',
                'q-omega-id': 'qΩ',
              },
            );
            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AutomatonDiagnosticHighlightBar(
                      activeKind: activeDiagnostic,
                      conflictCount: 2,
                      epsilonCount: 1,
                      onConflictSelected: (selected) => setState(() {
                        activeDiagnostic = selected
                            ? AutomatonDiagnosticHighlightKind.conflicts
                            : null;
                      }),
                      onEpsilonSelected: (selected) => setState(() {
                        activeDiagnostic = selected
                            ? AutomatonDiagnosticHighlightKind.epsilon
                            : null;
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SimulationTextField(
                        controller: inputController,
                        labelText: l10n.inputString,
                        hintText: l10n.simulationInputHint,
                      ),
                    ),
                    ComputationBranchInspector(
                      availability: adapted.availability,
                      selectedBranchId: selectedBranchId,
                      selectedNodeId: selectedNodeId,
                      onBranchSelected: (branchId) {
                        final availability = adapted.availability;
                        final selection =
                            availability is ComputationBranchesAvailable
                            ? availability.graph.resolveSelection(
                                branchId: branchId,
                              )
                            : const ComputationBranchSelection();
                        setState(() {
                          selectedBranchId = selection.branchId;
                          selectedNodeId = selection.nodeId;
                        });
                      },
                      onNodeSelected: (nodeId) =>
                          setState(() => selectedNodeId = nodeId),
                      onBranchHighlightRequested: (branchId) => widget
                          .highlightService
                          .dispatch(adapted.highlightForBranch(branchId)),
                      labels: l10n.computationBranchInspectorLabels,
                    ),
                    LanguageComparisonViewer(
                      comparisonResult: widget.comparisonResult,
                      showSteps: true,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FailureContractHost extends StatefulWidget {
  const _FailureContractHost({super.key});

  @override
  State<_FailureContractHost> createState() => _FailureContractHostState();
}

class _FailureContractHostState extends State<_FailureContractHost> {
  Locale locale = const Locale('en');

  void setLocale(Locale value) => setState(() => locale = value);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                LanguageComparisonViewer.unavailable(
                  failure: LanguageComparisonFailure(
                    reason: LanguageComparisonFailureReason.stateLimit,
                    message: 'product state budget exhausted',
                  ),
                ),
                LanguageComparisonViewer.unavailable(
                  failure: LanguageComparisonFailure(
                    reason: LanguageComparisonFailureReason.malformedInput,
                    message: 'machine qΩ has no initial state',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _usePhoneAtTwoHundredPercent(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

SimulationResult _branchingResult() {
  const accepted = NFAPathNode(
    currentState: 'q-accept-id',
    remainingInput: '',
    inputSymbol: 'λ',
    transitionUsed: 'δ(q0, λ) → qAccept',
    transitionIds: ['accept-edge'],
    stepNumber: 1,
    isAccepting: true,
  );
  const dead = NFAPathNode(
    currentState: 'q-omega-id',
    remainingInput: '',
    inputSymbol: 'λ',
    transitionUsed: 'δ(q0, λ) → qΩ',
    transitionIds: ['dead-edge'],
    stepNumber: 1,
    isDeadEnd: true,
  );
  const root = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'λ',
    stepNumber: 0,
    children: [accepted, dead],
  );
  return SimulationResult.success(
    inputString: 'λ',
    steps: const [],
    executionTime: Duration.zero,
    computationTree: NFAComputationTree.accepted(
      root: root,
      inputString: 'λ',
      totalSteps: 1,
    ),
  );
}

FSA _machine(String id, String name, {required bool acceptsA}) {
  final q0 = automaton_model.State(
    id: '$id-q0',
    label: 'q0-$name',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: acceptsA,
  );
  final q1 = automaton_model.State(
    id: '$id-q1',
    label: 'q1-$name',
    position: Vector2(120, 0),
    isAccepting: !acceptsA,
  );
  return FSA(
    id: id,
    name: name,
    states: {q0, q1},
    transitions: {
      FSATransition.deterministic(
        id: '$id-transition',
        fromState: q0,
        toState: q1,
        symbol: 'σ',
      ),
    },
    alphabet: const {'σ'},
    initialState: q0,
    acceptingStates: acceptsA ? {q0} : {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 240, 160),
  );
}
