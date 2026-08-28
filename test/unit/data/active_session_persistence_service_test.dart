import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/data/services/active_session_persistence_service.dart';
import 'package:turing_lab/data/services/active_session_module_registry.dart';

void main() {
  group('ActiveSessionPersistenceService', () {
    test('saves and restores all workspace snapshots', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: 4,
          savedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
          fsa: _fsa(),
          grammar: _grammar(),
          pda: _pda(),
          tm: _tm(),
          regex: const RegexSessionSnapshot(
            currentRegex: 'a*b',
            testString: 'aaab',
            simplifyOutput: false,
            alphabet: 'ab01 ',
            documentId: 'regex-1',
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
                  text: 'Saved note',
                  x: 10,
                  y: 20,
                  createdAt: DateTime.utc(2026, 1, 2),
                  updatedAt: DateTime.utc(2026, 1, 2),
                ),
              ],
            ),
          },
        ),
      );

      final restored = await service.loadSession();

      expect(restored, isNotNull);
      expect(restored!.activeWorkspaceIndex, 4);
      expect(restored.activeWorkspaceKey, DefaultFormalSystemIds.regex);
      expect(restored.fsa?.id, 'fsa-1');
      expect(restored.grammar?.productions.single.id, 'p1');
      expect(restored.pda?.id, 'pda-1');
      expect(restored.pda?.acceptanceMode, PDAAcceptanceMode.emptyStack);
      expect(restored.tm?.id, 'tm-1');
      expect(restored.tm?.tapeCount, 2);
      expect(restored.tm?.acceptancePolicy, TMAcceptancePolicy.halting);
      expect(restored.tm?.tmTransitions.single.readSymbols, ['a', 'B']);
      expect(restored.tm?.tmTransitions.single.writeSymbols, ['a', 'a']);
      expect(restored.tm?.blockDefinitions.keys, {'saved-block'});
      expect(
        restored.tm?.blockInvocations.single.reference.blockId,
        'saved-block',
      );
      expect(restored.regex?.currentRegex, 'a*b');
      expect(restored.regex?.testString, 'aaab');
      expect(restored.regex?.simplifyOutput, isFalse);
      expect(restored.regex?.alphabet, 'ab01 ');
      expect(restored.regex?.documentId, 'regex-1');
      expect(restored.regex?.documentName, 'Saved regex');
      expect(
        restored
            .annotations[DefaultFormalSystemIds.fsa]?.annotations.single.text,
        'Saved note',
      );

      final stored = jsonDecode(
        prefs.getString(ActiveSessionPersistenceService.sessionKey)!,
      ) as Map<String, dynamic>;
      expect(stored['activeWorkspace'], DefaultFormalSystemIds.regex.value);
      expect(stored, isNot(contains('activeWorkspaceIndex')));
      expect(
        stored['annotations'],
        contains(DefaultFormalSystemIds.fsa.value),
      );
      final documents = stored['documents'] as Map<String, dynamic>;
      expect(
        documents[DefaultFormalSystemIds.fsa.value],
        containsPair(
          'schema',
          {'id': 'turing-lab.fsa', 'version': 1},
        ),
      );
    });

    test('returns null and clears malformed session payloads', () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: 'not json',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      final restored = await service.loadSession();

      expect(restored, isNull);
      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        isNull,
      );
    });

    test('migrates a version 0 session and rewrites the current envelope',
        () async {
      final legacyJson = _legacyJson(version: 0, workspaceIndex: 2)
        ..['fsa'] = _fsa().toJson();
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: jsonEncode(legacyJson),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      final restored = await service.loadSession();

      expect(restored?.activeWorkspaceIndex, 2);
      expect(restored?.activeWorkspaceKey, DefaultFormalSystemIds.pda);
      expect(restored?.fsa?.id, 'fsa-1');
      final rewritten = jsonDecode(
        prefs.getString(ActiveSessionPersistenceService.sessionKey)!,
      ) as Map<String, dynamic>;
      expect(rewritten['version'], ActiveSessionSnapshot.currentVersion);
    });

    test('surfaces a failed rewrite while migrating a session', () async {
      final legacyJson = _legacyJson(version: 1, workspaceIndex: 2);
      final payload = jsonEncode(legacyJson);
      final prefs = await _preferencesWithFailingWrites(
        initialValues: {
          'flutter.${ActiveSessionPersistenceService.sessionKey}': payload,
        },
      );
      final service = ActiveSessionPersistenceService(prefs);

      await expectLater(
        service.loadSession(),
        throwsA(
          isA<ActiveSessionPersistenceException>().having(
            (error) => error.operation,
            'operation',
            'save',
          ),
        ),
      );
      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        isNotNull,
      );
    });

    test('backs up and surfaces an unsupported future session version',
        () async {
      const futureVersion = ActiveSessionSnapshot.currentVersion + 1;
      final payload = jsonEncode(<String, dynamic>{
        'version': futureVersion,
        'savedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
        'activeWorkspaceIndex': 3,
      });
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: payload,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      await expectLater(
        service.loadSession(),
        throwsA(
          isA<UnsupportedActiveSessionVersionException>()
              .having((error) => error.version, 'version', futureVersion),
        ),
      );

      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        payload,
      );
      expect(
        prefs.getString(
          ActiveSessionPersistenceService.unsupportedSessionBackupKey(
            futureVersion,
          ),
        ),
        payload,
      );
    });

    test('reads the persisted autosave setting', () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.autoSaveKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      expect(service.autoSaveEnabled, isFalse);
    });

    test('preserves and backs up a future document schema envelope', () async {
      final payload = jsonEncode({
        'version': ActiveSessionSnapshot.currentVersion,
        'savedAt': DateTime.utc(2026).toIso8601String(),
        'activeWorkspace': DefaultFormalSystemIds.fsa.value,
        'documents': {
          DefaultFormalSystemIds.fsa.value: {
            'schema': {'id': 'turing-lab.fsa', 'version': 99},
            'data': _fsa().toJson(),
          },
        },
      });
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: payload,
      });
      final prefs = await SharedPreferences.getInstance();

      final service = ActiveSessionPersistenceService(prefs);

      await expectLater(
        service.loadSession(),
        throwsA(
          isA<UnsupportedActiveSessionSchemaVersionException>()
              .having(
                  (error) => error.systemKey, 'key', DefaultFormalSystemIds.fsa)
              .having((error) => error.version, 'version', 99),
        ),
      );
      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        payload,
      );
      expect(
        prefs.getString(
          ActiveSessionPersistenceService.unsupportedSchemaBackupKey(
            DefaultFormalSystemIds.fsa,
            99,
          ),
        ),
        payload,
      );
    });

    test('clears a document with a corrupt schema identity', () async {
      final payload = jsonEncode({
        'version': ActiveSessionSnapshot.currentVersion,
        'savedAt': DateTime.utc(2026).toIso8601String(),
        'activeWorkspace': DefaultFormalSystemIds.fsa.value,
        'documents': {
          DefaultFormalSystemIds.fsa.value: {
            'schema': {'id': 'wrong.fsa', 'version': 1},
            'data': _fsa().toJson(),
          },
        },
      });
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: payload,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
          await ActiveSessionPersistenceService(prefs).loadSession(), isNull);
      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        isNull,
      );
    });

    test('does not invent persisted data for Pumping Lemma', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      await expectLater(
        service.saveSession(
          ActiveSessionSnapshot(
            activeWorkspaceKey: DefaultFormalSystemIds.pumping,
            savedAt: DateTime.utc(2026),
            documents: {DefaultFormalSystemIds.pumping: 'fake'},
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        isNull,
      );
    });

    test('round trips regular and context-free pumping sessions', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final regularProblem = PumpingLemmaProblemCatalog.regular.first;
      final contextFreeProblem = PumpingLemmaProblemCatalog.contextFree.first;
      final regular = RegularPumpingLemmaDocument(
        problem: regularProblem,
        session: PumpingLemmaSession<RegularPumpingDecomposition>(
          sessionId: 'regular-session',
          challengeId: regularProblem.id,
          sourceRevision: regularProblem.sourceRevision,
          theorem: PumpingLemmaTheorem.regular,
          mode: PumpingLemmaMode.challenge,
          role: PumpingLemmaRole.learner,
          targetLanguage: regularProblem.languageDescription,
        ),
        progress: PumpingLemmaEnvironmentProgress(
          challengeScores: {'regular.equal-blocks': 1},
        ),
      );
      final contextFree = ContextFreePumpingLemmaDocument(
        problem: contextFreeProblem,
        session: PumpingLemmaSession<ContextFreePumpingDecomposition>(
          sessionId: 'context-free-session',
          challengeId: contextFreeProblem.id,
          sourceRevision: contextFreeProblem.sourceRevision,
          theorem: PumpingLemmaTheorem.contextFree,
          mode: PumpingLemmaMode.guidedPractice,
          role: PumpingLemmaRole.learner,
          targetLanguage: contextFreeProblem.languageDescription,
        ),
        progress: PumpingLemmaEnvironmentProgress(
          challengeScores: {'cfl.equal-three-blocks': 2},
        ),
      );

      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceKey: DefaultFormalSystemIds.contextFreePumping,
          savedAt: DateTime.utc(2026, 8, 25),
          documents: {
            DefaultFormalSystemIds.regularPumping: regular,
            DefaultFormalSystemIds.contextFreePumping: contextFree,
          },
        ),
      );

      final restored = await service.loadSession();
      expect(
        restored?.activeWorkspaceKey,
        DefaultFormalSystemIds.contextFreePumping,
      );
      expect(
        restored?.documentFor<PumpingLemmaDocument>(
          DefaultFormalSystemIds.regularPumping,
        ),
        isA<RegularPumpingLemmaDocument>(),
      );
      expect(
        restored?.documentFor<PumpingLemmaDocument>(
          DefaultFormalSystemIds.contextFreePumping,
        ),
        isA<ContextFreePumpingLemmaDocument>(),
      );
    });

    test('round trips a test-only registered session module', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final registry = FormalSystemRegistry(
        modules: const [_SampleModule()],
        formats: const [],
      );
      final composed =
          ActiveSessionModuleRegistry.withBuiltInSessions(registry);
      expect(composed.moduleFor(_sampleKey)?.session,
          isA<_SampleSessionCapability>());
      final service = ActiveSessionPersistenceService(
        prefs,
        registry: composed,
      );

      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceKey: _sampleKey,
          savedAt: DateTime.utc(2026),
          documents: {_sampleKey: 'sample payload'},
        ),
      );

      final restored = await service.loadSession();
      expect(restored?.activeWorkspaceKey, _sampleKey);
      expect(restored?.documentFor<String>(_sampleKey), 'sample payload');
    });

    test('surfaces a backend save failure', () async {
      final prefs = await _preferencesWithFailingWrites();
      final service = ActiveSessionPersistenceService(prefs);

      await expectLater(
        service.saveSession(
          ActiveSessionSnapshot(
            activeWorkspaceIndex: 0,
            savedAt: DateTime.utc(2026),
          ),
        ),
        throwsA(
          isA<ActiveSessionPersistenceException>().having(
            (error) => error.operation,
            'operation',
            'save',
          ),
        ),
      );
    });

    test('surfaces a backend clear failure', () async {
      final prefs = await _preferencesWithFailingWrites();
      final service = ActiveSessionPersistenceService(prefs);

      await expectLater(
        service.clearSession(),
        throwsA(
          isA<ActiveSessionPersistenceException>().having(
            (error) => error.operation,
            'operation',
            'clear',
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _legacyJson({
  required int version,
  required int workspaceIndex,
}) {
  return {
    'version': version,
    'savedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
    'activeWorkspaceIndex': workspaceIndex,
  };
}

const _sampleKey = FormalSystemKey(
  type: FormalSystemTypeId('test-sample'),
  variant: FormalSystemVariantId('standard'),
);

class _SampleModule implements FormalSystemModule<Object> {
  const _SampleModule();

  @override
  FormalSystemDescriptor get descriptor => FormalSystemDescriptor(
        key: _sampleKey,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('test.sample'),
          version: DocumentSchemaVersion(1),
        ),
        route: const WorkspaceRouteId('/test-sample'),
        category: FormalSystemCategory.learning,
        localizationNamespace: const CapabilityNamespaceId('test.sample'),
        semanticsNamespace:
            const CapabilityNamespaceId('semantics.test.sample'),
        capabilities: const FormalSystemCapabilities(
          session: SupportedCapability(),
        ),
      );

  @override
  List<DocumentCodecCapability<Object>> get codecs => const [];

  @override
  List<ConversionCapability<Object, Object>> get conversions => const [];

  @override
  ExampleCatalogCapability<Object>? get examples => null;

  @override
  SessionCapability<Object> get session => const _SampleSessionCapability();
}

class _SampleSessionCapability implements SessionCapability<Object> {
  const _SampleSessionCapability();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('session.test.sample');

  @override
  Object decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) =>
      encoded['value'] as String;

  @override
  Map<String, Object?> encodeSession(Object document) => {'value': document};
}

Future<SharedPreferences> _preferencesWithFailingWrites({
  Map<String, Object> initialValues = const {},
}) async {
  final originalStore = SharedPreferencesStorePlatform.instance;
  SharedPreferencesStorePlatform.instance = _FailingWritesStore(initialValues);
  SharedPreferences.resetStatic();
  addTearDown(() {
    SharedPreferencesStorePlatform.instance = originalStore;
    SharedPreferences.resetStatic();
  });
  return SharedPreferences.getInstance();
}

class _FailingWritesStore extends InMemorySharedPreferencesStore {
  _FailingWritesStore(super.initialValues) : super.withData();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    return false;
  }

  @override
  Future<bool> remove(String key) async {
    return false;
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

PDA _pda() {
  final state = _state('p0', isInitial: true, isAccepting: true);
  return PDA(
    id: 'pda-1',
    name: 'Saved PDA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
    acceptanceMode: PDAAcceptanceMode.emptyStack,
    initialStackSymbol: 'Z',
  );
}

TM _tm() {
  final initial = _state('t0', isInitial: true);
  final accepting = _state('t1', isAccepting: true);
  final blockInitial = _state('b0', isInitial: true);
  final blockMachine = TM(
    id: 'saved-block',
    name: 'Saved block machine',
    states: {blockInitial},
    transitions: const {},
    alphabet: const {'a'},
    initialState: blockInitial,
    acceptingStates: const {},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
    tapeCount: 2,
  );
  final transition = TMTransition(
    id: 'tm-transition',
    fromState: initial,
    toState: accepting,
    label: 'T1: a/aR | T2: B/aS',
    type: TransitionType.deterministic,
    readSymbols: const ['a', 'B'],
    writeSymbols: const ['a', 'a'],
    directions: const [TapeDirection.right, TapeDirection.stay],
  );
  return TM(
    id: 'tm-1',
    name: 'Saved TM',
    states: {initial, accepting},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: initial,
    acceptingStates: {accepting},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
    tapeCount: 2,
    acceptancePolicy: TMAcceptancePolicy.halting,
    blockDefinitions: {
      'saved-block': TMBlockDefinition(
        id: 'saved-block',
        name: 'Saved block',
        revision: 3,
        machine: blockMachine,
      ),
    },
    blockInvocations: const [
      TMBlockInvocationNode(
        id: 'saved-call',
        stateId: 't0',
        reference: TMBlockReference(blockId: 'saved-block', revision: 3),
      ),
    ],
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
