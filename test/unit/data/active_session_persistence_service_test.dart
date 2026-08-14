import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/data/services/active_session_persistence_service.dart';

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
          ),
        ),
      );

      final restored = await service.loadSession();

      expect(restored, isNotNull);
      expect(restored!.activeWorkspaceIndex, 4);
      expect(restored.fsa?.id, 'fsa-1');
      expect(restored.grammar?.productions.single.id, 'p1');
      expect(restored.pda?.id, 'pda-1');
      expect(restored.tm?.id, 'tm-1');
      expect(restored.regex?.currentRegex, 'a*b');
      expect(restored.regex?.testString, 'aaab');
      expect(restored.regex?.simplifyOutput, isFalse);
      expect(restored.regex?.alphabet, 'ab01 ');
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
      final legacyJson = ActiveSessionSnapshot(
        activeWorkspaceIndex: 2,
        savedAt: DateTime.utc(2026, 1, 2),
        fsa: _fsa(),
      ).toJson()
        ..['version'] = 0;
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: jsonEncode(legacyJson),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      final restored = await service.loadSession();

      expect(restored?.activeWorkspaceIndex, 2);
      expect(restored?.fsa?.id, 'fsa-1');
      final rewritten = jsonDecode(
        prefs.getString(ActiveSessionPersistenceService.sessionKey)!,
      ) as Map<String, dynamic>;
      expect(rewritten['version'], ActiveSessionSnapshot.currentVersion);
    });

    test('surfaces a failed rewrite while migrating a session', () async {
      final legacyJson = ActiveSessionSnapshot(
        activeWorkspaceIndex: 2,
        savedAt: DateTime.utc(2026, 1, 2),
      ).toJson()
        ..['version'] = 0;
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
    initialStackSymbol: 'Z',
  );
}

TM _tm() {
  final state = _state('t0', isInitial: true, isAccepting: true);
  return TM(
    id: 'tm-1',
    name: 'Saved TM',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'B'},
    blankSymbol: 'B',
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
