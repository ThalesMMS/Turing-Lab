import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/data/services/active_session_persistence_service.dart';
import 'package:turing_lab/presentation/providers/active_session_provider.dart';
import 'package:turing_lab/presentation/providers/document_annotations_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/settings_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/providers/formal_extension_editor_providers.dart';
import 'package:turing_lab/presentation/transducers/mealy_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/moore_workspace_definition.dart';

void main() {
  group('activeSessionPersistenceProvider', () {
    test('restores persisted workspace state when autosave is enabled',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: HomeNavigationNotifier.regexIndex,
          savedAt: DateTime.utc(2026),
          fsa: _fsa(),
          grammar: _grammar(),
          regex: const RegexSessionSnapshot(
            currentRegex: 'ab*',
            testString: 'abb',
            simplifyOutput: false,
            alphabet: 'ab01 ',
            documentId: 'saved-regex',
            documentName: 'Saved regex',
          ),
          annotations: {
            DefaultFormalSystemIds.fsa: DocumentAnnotationCollection(
              documentId: 'fsa-1',
              documentRevision: '1',
              annotations: [
                DocumentAnnotation(
                  id: 'note-1',
                  documentId: 'fsa-1',
                  documentRevision: '1',
                  text: 'Restored note',
                  x: 8,
                  y: 12,
                  createdAt: DateTime.utc(2026),
                  updatedAt: DateTime.utc(2026),
                ),
              ],
            ),
          },
        ),
      );

      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      expect(
        container.read(automatonStateProvider).currentAutomaton?.id,
        'fsa-1',
      );
      expect(container.read(grammarProvider).productions.single.id, 'p1');
      expect(container.read(regexEditorProvider).currentRegex, 'ab*');
      expect(container.read(regexEditorProvider).testString, 'abb');
      expect(container.read(regexEditorProvider).simplifyOutput, isFalse);
      expect(container.read(regexEditorProvider).alphabet, 'ab01 ');
      expect(container.read(regexEditorProvider).documentId, 'saved-regex');
      expect(container.read(regexEditorProvider).documentName, 'Saved regex');
      expect(
        container
            .read(documentAnnotationsProvider)[DefaultFormalSystemIds.fsa]
            ?.annotations
            .single
            .text,
        'Restored note',
      );
      expect(
        container.read(homeNavigationProvider),
        HomeNavigationNotifier.regexIndex,
      );
    });

    test('does not restore persisted workspace state when autosave is disabled',
        () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.autoSaveKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: HomeNavigationNotifier.regexIndex,
          savedAt: DateTime.utc(2026),
          fsa: _fsa(),
        ),
      );

      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      expect(container.read(automatonStateProvider).currentAutomaton, isNull);
      expect(
        container.read(homeNavigationProvider),
        HomeNavigationNotifier.fsaIndex,
      );
      expect(await service.loadSession(), isNull);
    });

    test('flush persists the current editor state when autosave is enabled',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      container.read(automatonStateProvider.notifier).updateAutomaton(_fsa());
      container.read(homeNavigationProvider.notifier).setIndex(
            HomeNavigationNotifier.fsaIndex,
          );

      await container.read(activeSessionPersistenceProvider.notifier).flush();

      final restored = await service.loadSession();
      expect(restored?.fsa?.id, 'fsa-1');
      expect(
        restored?.activeWorkspaceIndex,
        HomeNavigationNotifier.fsaIndex,
      );
    });

    test('flush clears persisted state when autosave is disabled', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: HomeNavigationNotifier.fsaIndex,
          savedAt: DateTime.utc(2026),
          fsa: _fsa(),
        ),
      );
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;
      await container.read(settingsProvider.notifier).refreshFromModel(
            const SettingsModel(autoSave: false),
          );

      await container.read(activeSessionPersistenceProvider.notifier).flush();

      expect(await service.loadSession(), isNull);
    });

    test('container disposal flushes a pending debounced snapshot', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final firstContainer = _containerWithPrefs(prefs);

      await firstContainer
          .read(activeSessionPersistenceProvider)
          .restoreComplete;
      firstContainer
          .read(automatonStateProvider.notifier)
          .updateAutomaton(_fsa());
      firstContainer.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final restoredContainer = _containerWithPrefs(prefs);
      addTearDown(restoredContainer.dispose);
      await restoredContainer
          .read(activeSessionPersistenceProvider)
          .restoreComplete;

      expect(
        restoredContainer.read(automatonStateProvider).currentAutomaton?.id,
        'fsa-1',
      );
    });

    test('flush propagates persistence failures', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final container = _containerWithPrefs(
        prefs,
        overrides: [
          activeSessionPersistenceServiceProvider.overrideWithValue(
            _FailingActiveSessionPersistenceService(prefs),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeSessionPersistenceProvider).restoreComplete;
      container.read(automatonStateProvider.notifier).updateAutomaton(_fsa());

      await expectLater(
        container.read(activeSessionPersistenceProvider.notifier).flush(),
        throwsA(isA<StateError>()),
      );
    });

    test('serializes saves so an older snapshot cannot overwrite a newer one',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = _ControlledActiveSessionPersistenceService(prefs);
      final container = _containerWithPrefs(
        prefs,
        overrides: [
          activeSessionPersistenceServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeSessionPersistenceProvider).restoreComplete;
      container
          .read(homeNavigationProvider.notifier)
          .setIndex(HomeNavigationNotifier.regexIndex);
      await service.waitForOperationCount(1);

      container
          .read(homeNavigationProvider.notifier)
          .setIndex(HomeNavigationNotifier.grammarIndex);
      final flush =
          container.read(activeSessionPersistenceProvider.notifier).flush();
      await Future<void>.delayed(Duration.zero);

      expect(service.operations, ['save:4']);
      service.completeNextOperation();
      await service.waitForOperationCount(2);
      expect(service.operations, ['save:4', 'save:1']);
      service.completeNextOperation();
      await flush;

      expect(service.persisted?.activeWorkspaceIndex, 1);
    });

    test('queues clear behind an in-flight save when autosave is disabled',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = _ControlledActiveSessionPersistenceService(prefs);
      final container = _containerWithPrefs(
        prefs,
        overrides: [
          activeSessionPersistenceServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeSessionPersistenceProvider).restoreComplete;
      container
          .read(homeNavigationProvider.notifier)
          .setIndex(HomeNavigationNotifier.regexIndex);
      await service.waitForOperationCount(1);

      await container.read(settingsProvider.notifier).refreshFromModel(
            const SettingsModel(autoSave: false),
          );
      final flush =
          container.read(activeSessionPersistenceProvider.notifier).flush();
      await Future<void>.delayed(Duration.zero);

      expect(service.operations, ['save:4']);
      service.completeNextOperation();
      await service.waitForOperationCount(2);
      expect(service.operations, ['save:4', 'clear']);
      service.completeNextOperation();
      await flush;

      expect(service.persisted, isNull);
    });

    test('restore handles malformed autosave setting', () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.autoSaveKey: 'not-a-bool',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);

      await persistenceState.restoreComplete;

      expect(container.read(automatonStateProvider).currentAutomaton, isNull);
    });

    test('does not persist grammar transient conversion state', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      await container.read(grammarProvider.notifier).convertToPda();
      await Future<void>.delayed(
        activeSessionSaveDebounceDuration + const Duration(milliseconds: 50),
      );

      expect(await service.loadSession(), isNull);
    });

    test('does not persist regex transient UI state', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      container.read(regexEditorProvider.notifier).toggleSimplificationSteps();
      await Future<void>.delayed(
        activeSessionSaveDebounceDuration + const Duration(milliseconds: 50),
      );

      expect(await service.loadSession(), isNull);
    });

    test('does not persist PDA derived metadata state', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final pdaNotifier = _TestPDAEditorNotifier();
      final container = _containerWithPrefs(
        prefs,
        overrides: [
          pdaEditorProvider.overrideWith((ref) => pdaNotifier),
        ],
      );
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      pdaNotifier.emit(
        const PDAEditorState(
          nondeterministicTransitionIds: {'t0'},
          lambdaTransitionIds: {'t0'},
        ),
      );
      await Future<void>.delayed(
        activeSessionSaveDebounceDuration + const Duration(milliseconds: 50),
      );

      expect(await service.loadSession(), isNull);
    });

    test('does not persist TM derived metadata state', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final tmNotifier = _TestTMEditorNotifier();
      final container = _containerWithPrefs(
        prefs,
        overrides: [
          tmEditorProvider.overrideWith((ref) => tmNotifier),
        ],
      );
      addTearDown(container.dispose);

      final persistenceState = container.read(activeSessionPersistenceProvider);
      await persistenceState.restoreComplete;

      tmNotifier.emit(
        const TMEditorState(
          tapeSymbols: {'a'},
          moveDirections: {'right'},
          nondeterministicTransitionIds: {'t0'},
        ),
      );
      await Future<void>.delayed(
        activeSessionSaveDebounceDuration + const Duration(milliseconds: 50),
      );

      expect(await service.loadSession(), isNull);
    });

    test('provider round trips Mealy and Moore documents and workspace key',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final first = _containerWithPrefs(prefs);
      await first.read(activeSessionPersistenceProvider).restoreComplete;

      first.read(mealyEditorProvider.notifier).replaceDocument(_mealy());
      first.read(mooreEditorProvider.notifier).replaceDocument(_moore());
      final mooreIndex = first
          .read(workspacePresentationRegistryProvider)
          .indexOfKey(TransducerFormalSystemIds.moore)!;
      first.read(homeNavigationProvider.notifier).setIndex(mooreIndex);
      await first.read(activeSessionPersistenceProvider.notifier).flush();
      first.dispose();

      final restored = _containerWithPrefs(prefs);
      addTearDown(restored.dispose);
      await restored.read(activeSessionPersistenceProvider).restoreComplete;

      final mealy = restored.read(mealyEditorProvider).document;
      final moore = restored.read(mooreEditorProvider).document;
      expect(mealy.id.value, 'saved-mealy');
      expect(mealy.revision.value, 7);
      expect(mealy.transitions.single.output.values, ['edge-output']);
      expect(moore.id.value, 'saved-moore');
      expect(moore.revision.value, 9);
      expect(moore.states.single.output.values, ['state-output', 'ready']);
      expect(
        restored.read(activeWorkspaceKeyProvider),
        TransducerFormalSystemIds.moore,
      );
    });

    test('provider round trips unrestricted grammar and L-system documents',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final first = _containerWithPrefs(prefs);
      await first.read(activeSessionPersistenceProvider).restoreComplete;

      final grammarController = first.read(unrestrictedGrammarEditorProvider);
      grammarController.replaceGrammar(
        grammarController.grammar.copyWith(name: 'Saved unrestricted'),
      );
      final lSystemController = first.read(lSystemEditorProvider);
      lSystemController.replaceDocument(
        lSystemController.document.copyWith(
          name: 'Saved L-system',
          revision: 17,
          iterations: 2,
        ),
      );
      final lSystemIndex = first
          .read(workspacePresentationRegistryProvider)
          .indexOfKey(LSystemFormalSystemIds.key)!;
      first.read(homeNavigationProvider.notifier).setIndex(lSystemIndex);
      await first.read(activeSessionPersistenceProvider.notifier).flush();
      first.dispose();

      final restored = _containerWithPrefs(prefs);
      addTearDown(restored.dispose);
      await restored.read(activeSessionPersistenceProvider).restoreComplete;

      expect(
        restored.read(unrestrictedGrammarEditorProvider).grammar.name,
        'Saved unrestricted',
      );
      expect(
        restored.read(lSystemEditorProvider).document.name,
        'Saved L-system',
      );
      expect(restored.read(lSystemEditorProvider).document.revision, 17);
      expect(
        restored.read(activeWorkspaceKeyProvider),
        LSystemFormalSystemIds.key,
      );
    });
  });
}

ProviderContainer _containerWithPrefs(
  SharedPreferences prefs, {
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
  );
}

class _TestPDAEditorNotifier extends PDAEditorNotifier {
  void emit(PDAEditorState nextState) {
    state = nextState;
  }
}

class _TestTMEditorNotifier extends TMEditorNotifier {
  void emit(TMEditorState nextState) {
    state = nextState;
  }
}

class _FailingActiveSessionPersistenceService
    extends ActiveSessionPersistenceService {
  _FailingActiveSessionPersistenceService(super.prefs);

  var _hasFailed = false;

  @override
  Future<void> saveSession(ActiveSessionSnapshot session) {
    if (!_hasFailed) {
      _hasFailed = true;
      return Future<void>.error(StateError('write failed'));
    }
    return super.saveSession(session);
  }
}

class _ControlledActiveSessionPersistenceService
    extends ActiveSessionPersistenceService {
  _ControlledActiveSessionPersistenceService(super.prefs);

  final List<String> operations = [];
  final List<Completer<void>> _operationGates = [];
  ActiveSessionSnapshot? persisted;

  @override
  Future<ActiveSessionSnapshot?> loadSession() async => persisted;

  @override
  Future<void> saveSession(ActiveSessionSnapshot session) async {
    operations.add('save:${session.activeWorkspaceIndex}');
    final gate = Completer<void>();
    _operationGates.add(gate);
    await gate.future;
    persisted = session;
  }

  @override
  Future<void> clearSession() async {
    operations.add('clear');
    final gate = Completer<void>();
    _operationGates.add(gate);
    await gate.future;
    persisted = null;
  }

  Future<void> waitForOperationCount(int count) async {
    while (operations.length < count) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void completeNextOperation() {
    _operationGates.firstWhere((gate) => !gate.isCompleted).complete();
  }
}

FSA _fsa() {
  final state = _state('q0', isInitial: true, isAccepting: true);
  return FSA(
    id: 'fsa-1',
    name: 'Saved FSA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

Grammar _grammar() {
  return Grammar(
    id: 'grammar-1',
    name: 'Saved Grammar',
    terminals: const {'a'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: {
      const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.regular,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );
}

MealyMachine _mealy() => MealyMachine(
      id: const TransducerMachineId('saved-mealy'),
      name: 'Saved Mealy',
      revision: const TransducerRevision(7),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('edge-output')},
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'q0',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        MealyTransition(
          id: const TransducerTransitionId('loop'),
          from: const TransducerStateId('q0'),
          to: const TransducerStateId('q0'),
          input: const TransducerInputSymbol('a'),
          output: TransducerOutputWord.fromValues(const ['edge-output']),
        ),
      ],
    );

MooreMachine _moore() => MooreMachine(
      id: const TransducerMachineId('saved-moore'),
      name: 'Saved Moore',
      revision: const TransducerRevision(9),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {
        const TransducerOutputSymbol('state-output'),
        const TransducerOutputSymbol('ready'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'q0',
          position: const TransducerPoint(0, 0),
          output: TransducerOutputWord.fromValues(
            const ['state-output', 'ready'],
          ),
          isInitial: true,
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('loop'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );

automaton_state.State _state(
  String id, {
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}
