import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/data/services/active_session_persistence_service.dart';
import 'package:turing_lab/presentation/providers/active_session_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/settings_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

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
          ),
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
