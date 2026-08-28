import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/document_annotation_collection.dart';
import '../../core/models/automaton.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/production.dart';
import '../../core/models/settings_model.dart';
import '../../core/models/tm.dart';
import '../../core/transducers/transducers.dart';
import '../../core/l_systems/l_systems.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/repositories/active_session_repository.dart';
import '../../injection/data_providers.dart';
import 'automaton_state_provider.dart';
import 'document_annotations_provider.dart';
import 'grammar_provider.dart';
import 'home_navigation_provider.dart';
import 'pda_editor_provider.dart';
import 'regex_editor_provider.dart';
import 'settings_provider.dart';
import 'tm_editor_provider.dart';
import 'workspace_registry_provider.dart';
import 'formal_extension_editor_providers.dart';
import '../l_systems/l_system_editor_controller.dart';
import '../unrestricted_grammar/unrestricted_grammar_editor_controller.dart';
import '../transducers/mealy_workspace_definition.dart';
import '../transducers/moore_workspace_definition.dart';
import '../transducers/transducer_editor_state.dart';

final activeSessionPersistenceServiceProvider = activeSessionRepositoryProvider;

const activeSessionSaveDebounceDuration = Duration(milliseconds: 300);

final activeSessionPersistenceProvider = StateNotifierProvider<
    ActiveSessionPersistenceNotifier, ActiveSessionPersistenceState>((ref) {
  final service = ref.watch(activeSessionPersistenceServiceProvider);
  return ActiveSessionPersistenceNotifier(ref, service);
});

class ActiveSessionPersistenceState {
  const ActiveSessionPersistenceState({
    required this.restoreComplete,
    this.isRestoring = false,
  });

  final Future<void> restoreComplete;
  final bool isRestoring;

  ActiveSessionPersistenceState copyWith({
    Future<void>? restoreComplete,
    bool? isRestoring,
  }) {
    return ActiveSessionPersistenceState(
      restoreComplete: restoreComplete ?? this.restoreComplete,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class ActiveSessionPersistenceNotifier
    extends StateNotifier<ActiveSessionPersistenceState> {
  ActiveSessionPersistenceNotifier(this._ref, this._service)
      : super(
          ActiveSessionPersistenceState(
            restoreComplete: Future<void>.value(),
          ),
        ) {
    _attachListeners();
    final restoreComplete = _restore();
    state = state.copyWith(restoreComplete: restoreComplete);
  }

  final Ref _ref;
  final ActiveSessionRepository _service;
  Timer? _saveDebounce;
  Future<void>? _activeWrite;
  ActiveSessionSnapshot? _pendingSnapshot;
  bool _pendingAutoSave = true;
  bool _hasPendingChange = false;
  bool _isRestoring = false;
  bool _disposed = false;
  late FormalSystemKey _latestWorkspaceKey;
  FSA? _latestFsa;
  Grammar? _latestGrammar;
  PDA? _latestPda;
  TM? _latestTm;
  RegexSessionSnapshot? _latestRegex;
  late MealyMachine _latestMealy;
  late MooreMachine _latestMoore;
  late UnrestrictedGrammar _latestUnrestrictedGrammar;
  late LSystemDocument _latestLSystem;
  Map<FormalSystemKey, DocumentAnnotationCollection> _latestAnnotations =
      const {};

  Future<void> flush() async {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _capturePendingSnapshotIfNeeded();
    await _persistPendingChange();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _capturePendingSnapshotIfNeeded();
    unawaited(
      _persistPendingChange().catchError((Object error, StackTrace stackTrace) {
        _logSaveFailure(error, stackTrace);
      }),
    );
    _disposed = true;
    super.dispose();
  }

  void _attachListeners() {
    _latestWorkspaceKey = _ref.read(activeWorkspaceKeyProvider);
    _latestFsa = _ref.read(automatonStateProvider).currentAutomaton;
    _latestGrammar = _buildGrammarSnapshot(_ref.read(grammarProvider));
    _latestPda = _ref.read(pdaEditorProvider).pda;
    _latestTm = _ref.read(tmEditorProvider).tm;
    _latestRegex = _buildRegexSnapshot(_ref.read(regexEditorProvider));
    _latestMealy = _ref.read(mealyEditorProvider).document;
    _latestMoore = _ref.read(mooreEditorProvider).document;
    _latestUnrestrictedGrammar =
        _ref.read(unrestrictedGrammarEditorProvider).grammar;
    _latestLSystem = _ref.read(lSystemEditorProvider).document;
    _latestAnnotations = _ref.read(documentAnnotationsProvider);

    _ref.listen<SettingsModel>(settingsProvider, _handleSettingsChanged);
    _ref.listen<FormalSystemKey>(activeWorkspaceKeyProvider, (_, next) {
      _latestWorkspaceKey = next;
      _scheduleSave();
    });
    _ref.listen<AutomatonStateProviderState>(
      automatonStateProvider,
      (_, next) {
        _latestFsa = next.currentAutomaton;
        _scheduleSave();
      },
    );
    _ref.listen<_PersistedGrammarState>(
      grammarProvider.select(_PersistedGrammarState.fromState),
      (_, __) {
        _latestGrammar = _buildGrammarSnapshot(_ref.read(grammarProvider));
        _scheduleSave();
      },
    );
    _ref.listen<_PersistedPdaState>(
      pdaEditorProvider.select(_PersistedPdaState.fromState),
      (_, next) {
        _latestPda = next.pda;
        _scheduleSave();
      },
    );
    _ref.listen<_PersistedTmState>(
      tmEditorProvider.select(_PersistedTmState.fromState),
      (_, next) {
        _latestTm = next.tm;
        _scheduleSave();
      },
    );
    _ref.listen<_PersistedRegexState>(
      regexEditorProvider.select(_PersistedRegexState.fromState),
      (_, next) {
        _latestRegex = next.toSnapshot();
        _scheduleSave();
      },
    );
    _ref.listen<TransducerEditorState<MealyMachine>>(
      mealyEditorProvider,
      (_, next) {
        _latestMealy = next.document;
        _scheduleSave();
      },
    );
    _ref.listen<TransducerEditorState<MooreMachine>>(
      mooreEditorProvider,
      (_, next) {
        _latestMoore = next.document;
        _scheduleSave();
      },
    );
    _ref.listen<UnrestrictedGrammarEditorController>(
      unrestrictedGrammarEditorProvider,
      (_, next) {
        _latestUnrestrictedGrammar = next.grammar;
        _scheduleSave();
      },
    );
    _ref.listen<LSystemEditorController>(
      lSystemEditorProvider,
      (_, next) {
        _latestLSystem = next.document;
        _scheduleSave();
      },
    );
    _ref.listen<Map<FormalSystemKey, DocumentAnnotationCollection>>(
      documentAnnotationsProvider,
      (_, next) {
        _latestAnnotations = next;
        _scheduleSave();
      },
    );
  }

  Future<void> _restore() async {
    _isRestoring = true;
    state = state.copyWith(isRestoring: true);
    try {
      if (!_service.autoSaveEnabled) {
        await _service.clearSession();
        return;
      }

      final session = await _service.loadSession();
      if (_disposed || session == null) {
        return;
      }

      _applySession(session);
    } catch (error, stackTrace) {
      debugPrint('Failed to restore active editor session: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isRestoring = false;
      if (!_disposed) {
        state = state.copyWith(isRestoring: false);
      }
    }
  }

  void _applySession(ActiveSessionSnapshot session) {
    if (session.fsa != null) {
      _ref.read(automatonStateProvider.notifier).replaceAutomaton(session.fsa!);
    }
    if (session.grammar != null) {
      _ref.read(grammarProvider.notifier).applyGrammar(session.grammar!);
    }
    if (session.pda != null) {
      _ref.read(pdaEditorProvider.notifier).setPda(session.pda!);
    }
    if (session.tm != null) {
      _ref.read(tmEditorProvider.notifier).setTm(session.tm!);
    }
    if (session.regex != null) {
      final regex = session.regex!;
      _ref.read(regexEditorProvider.notifier).restorePersistedInput(
            currentRegex: regex.currentRegex,
            testString: regex.testString,
            simplifyOutput: regex.simplifyOutput,
            alphabet: regex.alphabet,
            documentId: regex.documentId,
            documentName: regex.documentName,
          );
    }
    final mealy =
        session.documentFor<MealyMachine>(TransducerFormalSystemIds.mealy);
    if (mealy != null) {
      _ref.read(mealyEditorProvider.notifier).replaceDocument(mealy);
    }
    final moore =
        session.documentFor<MooreMachine>(TransducerFormalSystemIds.moore);
    if (moore != null) {
      _ref.read(mooreEditorProvider.notifier).replaceDocument(moore);
    }
    final unrestricted = session.documentFor<UnrestrictedGrammar>(
      UnrestrictedGrammarCapabilities.systemKey,
    );
    if (unrestricted != null) {
      _ref
          .read(unrestrictedGrammarEditorProvider)
          .replaceGrammar(unrestricted, recordHistory: false);
    }
    final lSystem = session.documentFor<LSystemDocument>(
      LSystemFormalSystemIds.key,
    );
    if (lSystem != null) {
      _ref
          .read(lSystemEditorProvider)
          .replaceDocument(lSystem, recordHistory: false);
    }
    for (final entry in session.annotations.entries) {
      _ref
          .read(documentAnnotationsProvider.notifier)
          .restore(entry.key, entry.value);
    }

    final workspaceIndex = _ref
            .read(workspacePresentationRegistryProvider)
            .indexOfKey(session.activeWorkspaceKey) ??
        0;
    _ref.read(homeNavigationProvider.notifier).setIndex(workspaceIndex);
  }

  void _handleSettingsChanged(SettingsModel? previous, SettingsModel next) {
    if (_disposed) {
      return;
    }

    if (!next.autoSave) {
      _saveDebounce?.cancel();
      _saveDebounce = null;
      _capturePendingChange(autoSave: false);
      unawaited(
        _persistPendingChange()
            .catchError((Object error, StackTrace stackTrace) {
          _logSaveFailure(error, stackTrace);
        }),
      );
      return;
    }

    if (previous?.autoSave == false) {
      _scheduleSave();
    }
  }

  void _scheduleSave() {
    if (_disposed || _isRestoring) {
      return;
    }

    final autoSave = _ref.read(settingsProvider).autoSave;

    if (!autoSave) {
      _saveDebounce?.cancel();
      _saveDebounce = null;
      _capturePendingChange(autoSave: false);
      unawaited(
        _persistPendingChange()
            .catchError((Object error, StackTrace stackTrace) {
          _logSaveFailure(error, stackTrace);
        }),
      );
      return;
    }

    _pendingAutoSave = true;
    _pendingSnapshot = null;
    _hasPendingChange = true;

    _saveDebounce?.cancel();
    _saveDebounce = Timer(activeSessionSaveDebounceDuration, () {
      _saveDebounce = null;
      _capturePendingChange(autoSave: true);
      unawaited(
        _persistPendingChange()
            .catchError((Object error, StackTrace stackTrace) {
          _logSaveFailure(error, stackTrace);
        }),
      );
    });
  }

  Future<void> _persistPendingChange() async {
    final existingWrite = _activeWrite;
    if (!_hasPendingChange) {
      if (existingWrite != null) {
        await existingWrite;
      }
      return;
    }

    _hasPendingChange = false;
    final autoSave = _pendingAutoSave;
    final snapshot = _pendingSnapshot;
    final previousWrite = existingWrite ?? Future<void>.value();
    final write = previousWrite.then((_) {
      return autoSave
          ? _service.saveSession(snapshot!)
          : _service.clearSession();
    });
    _activeWrite = write;

    try {
      await write;
    } catch (_) {
      _hasPendingChange = true;
      rethrow;
    } finally {
      if (identical(_activeWrite, write)) {
        _activeWrite = null;
      }
    }
  }

  void _capturePendingChange({required bool autoSave}) {
    _pendingAutoSave = autoSave;
    _pendingSnapshot = autoSave ? _buildSnapshot() : null;
    _hasPendingChange = true;
  }

  void _capturePendingSnapshotIfNeeded() {
    if (_hasPendingChange && _pendingAutoSave && _pendingSnapshot == null) {
      _capturePendingChange(autoSave: true);
    }
  }

  void _logSaveFailure(Object error, StackTrace stackTrace) {
    debugPrint('Failed to persist active editor session: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  ActiveSessionSnapshot _buildSnapshot() {
    return ActiveSessionSnapshot(
      activeWorkspaceKey: _latestWorkspaceKey,
      savedAt: DateTime.now(),
      fsa: _latestFsa,
      grammar: _latestGrammar,
      pda: _latestPda,
      tm: _latestTm,
      regex: _latestRegex,
      documents: {
        TransducerFormalSystemIds.mealy: _latestMealy,
        TransducerFormalSystemIds.moore: _latestMoore,
        UnrestrictedGrammarCapabilities.systemKey: _latestUnrestrictedGrammar,
        LSystemFormalSystemIds.key: _latestLSystem,
      },
      annotations: _latestAnnotations,
    );
  }

  Grammar? _buildGrammarSnapshot(GrammarState state) {
    final initial = GrammarState.initial();
    final hasGrammarContent = state.productions.isNotEmpty ||
        state.name != initial.name ||
        state.startSymbol != initial.startSymbol ||
        state.type != initial.type;

    if (!hasGrammarContent) {
      return null;
    }

    return _ref.read(grammarProvider.notifier).buildGrammar();
  }

  RegexSessionSnapshot? _buildRegexSnapshot(RegexEditorState state) {
    final snapshot = RegexSessionSnapshot(
      currentRegex: state.currentRegex,
      testString: state.testString,
      simplifyOutput: state.simplifyOutput,
      alphabet: state.alphabet,
      documentId: state.documentId,
      documentName: state.documentName,
    );

    return snapshot.hasContent ? snapshot : null;
  }
}

class _PersistedGrammarState {
  const _PersistedGrammarState({
    required this.name,
    required this.startSymbol,
    required this.productions,
    required this.type,
  });

  factory _PersistedGrammarState.fromState(GrammarState state) {
    return _PersistedGrammarState(
      name: state.name,
      startSymbol: state.startSymbol,
      productions: state.productions,
      type: state.type,
    );
  }

  final String name;
  final String startSymbol;
  final List<Production> productions;
  final GrammarType type;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PersistedGrammarState &&
        other.name == name &&
        other.startSymbol == startSymbol &&
        other.type == type &&
        _listEquals(other.productions, productions);
  }

  @override
  int get hashCode => Object.hash(
        name,
        startSymbol,
        type,
        Object.hashAll(productions),
      );
}

class _PersistedRegexState {
  const _PersistedRegexState({
    required this.currentRegex,
    required this.testString,
    required this.simplifyOutput,
    required this.alphabet,
    required this.documentId,
    required this.documentName,
  });

  factory _PersistedRegexState.fromState(RegexEditorState state) {
    return _PersistedRegexState(
      currentRegex: state.currentRegex,
      testString: state.testString,
      simplifyOutput: state.simplifyOutput,
      alphabet: state.alphabet,
      documentId: state.documentId,
      documentName: state.documentName,
    );
  }

  final String currentRegex;
  final String testString;
  final bool simplifyOutput;
  final String alphabet;
  final String documentId;
  final String documentName;

  RegexSessionSnapshot? toSnapshot() {
    final snapshot = RegexSessionSnapshot(
      currentRegex: currentRegex,
      testString: testString,
      simplifyOutput: simplifyOutput,
      alphabet: alphabet,
      documentId: documentId,
      documentName: documentName,
    );
    return snapshot.hasContent ? snapshot : null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PersistedRegexState &&
        other.currentRegex == currentRegex &&
        other.testString == testString &&
        other.simplifyOutput == simplifyOutput &&
        other.alphabet == alphabet &&
        other.documentId == documentId &&
        other.documentName == documentName;
  }

  @override
  int get hashCode => Object.hash(
        currentRegex,
        testString,
        simplifyOutput,
        alphabet,
        documentId,
        documentName,
      );
}

class _PersistedPdaState {
  const _PersistedPdaState(this.pda);

  factory _PersistedPdaState.fromState(PDAEditorState state) {
    return _PersistedPdaState(state.pda);
  }

  final PDA? pda;

  @override
  bool operator ==(Object other) {
    return other is _PersistedPdaState && _pdaEquals(other.pda, pda);
  }

  @override
  int get hashCode => pda == null ? 0 : _pdaHash(pda!);
}

class _PersistedTmState {
  const _PersistedTmState(this.tm);

  factory _PersistedTmState.fromState(TMEditorState state) {
    return _PersistedTmState(state.tm);
  }

  final TM? tm;

  @override
  bool operator ==(Object other) {
    return other is _PersistedTmState && _tmEquals(other.tm, tm);
  }

  @override
  int get hashCode => tm == null ? 0 : _tmHash(tm!);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _pdaEquals(PDA? left, PDA? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return false;
  }

  return _automatonContentEquals(left, right) &&
      setEquals(left.stackAlphabet, right.stackAlphabet) &&
      left.initialStackSymbol == right.initialStackSymbol &&
      left.acceptanceMode == right.acceptanceMode;
}

bool _tmEquals(TM? left, TM? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return false;
  }

  return _automatonContentEquals(left, right) &&
      setEquals(left.tapeAlphabet, right.tapeAlphabet) &&
      left.blankSymbol == right.blankSymbol &&
      left.tapeCount == right.tapeCount &&
      left.acceptancePolicy == right.acceptancePolicy;
}

bool _automatonContentEquals(Automaton left, Automaton right) {
  return left.id == right.id &&
      left.name == right.name &&
      left.type == right.type &&
      setEquals(left.states, right.states) &&
      setEquals(left.transitions, right.transitions) &&
      setEquals(left.alphabet, right.alphabet) &&
      left.initialState == right.initialState &&
      setEquals(left.acceptingStates, right.acceptingStates) &&
      left.created == right.created &&
      left.modified == right.modified &&
      left.bounds == right.bounds &&
      left.zoomLevel == right.zoomLevel &&
      left.panOffset == right.panOffset;
}

int _pdaHash(PDA pda) {
  return Object.hash(
    _automatonHash(pda),
    Object.hashAllUnordered(pda.stackAlphabet),
    pda.initialStackSymbol,
    pda.acceptanceMode,
  );
}

int _tmHash(TM tm) {
  return Object.hash(
    _automatonHash(tm),
    Object.hashAllUnordered(tm.tapeAlphabet),
    tm.blankSymbol,
    tm.tapeCount,
    tm.acceptancePolicy,
  );
}

int _automatonHash(Automaton automaton) {
  return Object.hash(
    automaton.id,
    automaton.name,
    automaton.type,
    Object.hashAllUnordered(automaton.states),
    Object.hashAllUnordered(automaton.transitions),
    Object.hashAllUnordered(automaton.alphabet),
    automaton.initialState,
    Object.hashAllUnordered(automaton.acceptingStates),
    automaton.created,
    automaton.modified,
    automaton.bounds,
    automaton.zoomLevel,
    automaton.panOffset,
  );
}
