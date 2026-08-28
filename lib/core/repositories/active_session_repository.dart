import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import '../formal_systems/formal_systems.dart';
import '../annotations/document_annotation_collection.dart';

abstract interface class ActiveSessionRepository {
  bool get autoSaveEnabled;
  Future<void> saveSession(ActiveSessionSnapshot session);
  Future<ActiveSessionSnapshot?> loadSession();
  Future<void> clearSession();
}

class ActiveSessionSnapshot {
  ActiveSessionSnapshot({
    FormalSystemKey? activeWorkspaceKey,
    int? activeWorkspaceIndex,
    required this.savedAt,
    this.fsa,
    this.grammar,
    this.pda,
    this.tm,
    this.regex,
    Map<FormalSystemKey, Object> documents = const {},
    Map<FormalSystemKey, DocumentAnnotationCollection> annotations = const {},
  })  : assert(activeWorkspaceKey != null || activeWorkspaceIndex != null),
        activeWorkspaceKey = activeWorkspaceKey ??
            _keyForHistoricalIndex(activeWorkspaceIndex ?? 0),
        documents = Map<FormalSystemKey, Object>.unmodifiable({
          ...documents,
          if (fsa != null) DefaultFormalSystemIds.fsa: fsa,
          if (grammar != null) DefaultFormalSystemIds.grammar: grammar,
          if (pda != null) DefaultFormalSystemIds.pda: pda,
          if (tm != null) DefaultFormalSystemIds.tm: tm,
          if (regex != null) DefaultFormalSystemIds.regex: regex,
        }),
        annotations =
            Map<FormalSystemKey, DocumentAnnotationCollection>.unmodifiable(
                annotations);

  static const int currentVersion = 3;

  final FormalSystemKey activeWorkspaceKey;
  final DateTime savedAt;
  final FSA? fsa;
  final Grammar? grammar;
  final PDA? pda;
  final TM? tm;
  final RegexSessionSnapshot? regex;
  final Map<FormalSystemKey, Object> documents;
  final Map<FormalSystemKey, DocumentAnnotationCollection> annotations;

  /// Compatibility view for callers that still display the historical order.
  int get activeWorkspaceIndex {
    final index = _historicalWorkspaceKeys.indexOf(activeWorkspaceKey);
    return index < 0 ? 0 : index;
  }

  T? documentFor<T extends Object>(FormalSystemKey key) {
    final document = documents[key];
    return document is T ? document : null;
  }

  static const _historicalWorkspaceKeys = [
    DefaultFormalSystemIds.fsa,
    DefaultFormalSystemIds.grammar,
    DefaultFormalSystemIds.pda,
    DefaultFormalSystemIds.tm,
    DefaultFormalSystemIds.regex,
    DefaultFormalSystemIds.pumping,
  ];

  static FormalSystemKey _keyForHistoricalIndex(int index) {
    if (index < 0 || index >= _historicalWorkspaceKeys.length) {
      return DefaultFormalSystemIds.fsa;
    }
    return _historicalWorkspaceKeys[index];
  }
}

class RegexSessionSnapshot {
  const RegexSessionSnapshot({
    required this.currentRegex,
    required this.testString,
    required this.simplifyOutput,
    this.alphabet = defaultAlphabet,
    this.documentId = 'regex-workspace',
    this.documentName = 'Regular expression',
  });

  static const defaultAlphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?_-';

  final String currentRegex;
  final String testString;
  final bool simplifyOutput;
  final String alphabet;
  final String documentId;
  final String documentName;

  bool get hasContent =>
      currentRegex.isNotEmpty ||
      testString.isNotEmpty ||
      !simplifyOutput ||
      alphabet != defaultAlphabet ||
      documentId != 'regex-workspace' ||
      documentName != 'Regular expression';

  Map<String, dynamic> toJson() => {
        'currentRegex': currentRegex,
        'testString': testString,
        'simplifyOutput': simplifyOutput,
        'alphabet': alphabet,
        'documentId': documentId,
        'documentName': documentName,
      };

  factory RegexSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return RegexSessionSnapshot(
      currentRegex: json['currentRegex'] as String? ?? '',
      testString: json['testString'] as String? ?? '',
      simplifyOutput: json['simplifyOutput'] as bool? ?? true,
      alphabet: json['alphabet'] as String? ?? defaultAlphabet,
      documentId: json['documentId'] as String? ?? 'regex-workspace',
      documentName: json['documentName'] as String? ?? 'Regular expression',
    );
  }
}

class UnsupportedActiveSessionVersionException implements Exception {
  const UnsupportedActiveSessionVersionException({
    required this.version,
    required this.supportedVersion,
  });

  final int version;
  final int supportedVersion;

  @override
  String toString() =>
      'Unsupported active session version $version; this app supports version $supportedVersion. The saved session was preserved for recovery.';
}

class UnsupportedActiveSessionSchemaVersionException implements Exception {
  const UnsupportedActiveSessionSchemaVersionException({
    required this.systemKey,
    required this.version,
    required this.supportedVersion,
  });

  final FormalSystemKey systemKey;
  final int version;
  final int supportedVersion;

  @override
  String toString() =>
      'Unsupported ${systemKey.value} session schema version $version; '
      'this app supports version $supportedVersion. The saved session was '
      'preserved for recovery.';
}

class ActiveSessionPersistenceException implements Exception {
  const ActiveSessionPersistenceException(this.operation);

  final String operation;

  @override
  String toString() =>
      'ActiveSessionPersistenceException: $operation operation failed';
}
