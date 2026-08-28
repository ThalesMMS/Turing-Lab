import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/document_annotation_collection.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/tm.dart';
import '../../core/repositories/active_session_repository.dart';
import 'active_session_module_registry.dart';

final class ActiveSessionSnapshotCodec {
  ActiveSessionSnapshotCodec({FormalSystemRegistry? registry})
      : registry = registry ?? ActiveSessionModuleRegistry.registry;

  final FormalSystemRegistry registry;

  Map<String, Object?> encode(ActiveSessionSnapshot snapshot) {
    _requireModule(snapshot.activeWorkspaceKey);
    final documents = <String, Object?>{};
    for (final entry in snapshot.documents.entries) {
      final module = _requireModule(entry.key);
      final session = _requireSession(module);
      final schema = module.descriptor.schema;
      documents[entry.key.value] = {
        'schema': {
          'id': schema.id.value,
          'version': schema.version.value,
        },
        'data': session.encodeSession(entry.value),
      };
    }

    return {
      'version': ActiveSessionSnapshot.currentVersion,
      'savedAt': snapshot.savedAt.toIso8601String(),
      'activeWorkspace': snapshot.activeWorkspaceKey.value,
      'documents': documents,
      if (snapshot.annotations.isNotEmpty)
        'annotations': {
          for (final entry in snapshot.annotations.entries)
            entry.key.value: entry.value.toJson(),
        },
    };
  }

  ActiveSessionSnapshot decode(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    if (rawVersion != null && rawVersion is! int) {
      throw const FormatException('Active session version must be an integer');
    }
    final version = rawVersion as int? ?? 0;
    if (version < 0 || version > ActiveSessionSnapshot.currentVersion) {
      throw UnsupportedActiveSessionVersionException(
        version: version,
        supportedVersion: ActiveSessionSnapshot.currentVersion,
      );
    }
    return version <= 1 ? _decodeLegacy(json) : _decodeCurrent(json);
  }

  ActiveSessionSnapshot _decodeCurrent(Map<String, dynamic> json) {
    final activeWorkspace = _keyForValue(json['activeWorkspace']);
    final savedAt = _decodeSavedAt(json['savedAt']);
    final rawDocuments = json['documents'];
    if (rawDocuments is! Map) {
      throw const FormatException('Active session documents must be an object');
    }

    final documents = <FormalSystemKey, Object>{};
    for (final entry in rawDocuments.entries) {
      if (entry.key is! String) {
        throw const FormatException('Active session document key is invalid');
      }
      final key = _keyForValue(entry.key);
      final module = _requireModule(key);
      final envelope = _stringMap(
        entry.value,
        'Active session document envelope must be an object',
      );
      final schemaJson = _stringMap(
        envelope['schema'],
        'Active session document schema must be an object',
      );
      final schemaId = schemaJson['id'];
      final schemaVersion = schemaJson['version'];
      final expected = module.descriptor.schema;
      if (schemaId == expected.id.value &&
          schemaVersion is int &&
          schemaVersion > expected.version.value) {
        throw UnsupportedActiveSessionSchemaVersionException(
          systemKey: key,
          version: schemaVersion,
          supportedVersion: expected.version.value,
        );
      }
      if (schemaId != expected.id.value ||
          schemaVersion != expected.version.value) {
        throw FormatException(
          'Unsupported schema for ${key.value}: $schemaId@$schemaVersion',
        );
      }
      final data = _stringMap(
        envelope['data'],
        'Active session document data must be an object',
      );
      documents[key] = _requireSession(module).decodeSession(
        data,
        schema: expected,
      );
    }

    final annotations = <FormalSystemKey, DocumentAnnotationCollection>{};
    final rawAnnotations = json['annotations'];
    if (rawAnnotations != null) {
      if (rawAnnotations is! Map) {
        throw const FormatException(
          'Active session annotations must be an object',
        );
      }
      for (final entry in rawAnnotations.entries) {
        if (entry.key is! String) {
          throw const FormatException(
            'Active session annotation key is invalid',
          );
        }
        final key = _keyForValue(entry.key);
        annotations[key] = DocumentAnnotationCollection.fromJson(
          _stringMap(
            entry.value,
            'Active session annotation collection must be an object',
          ).cast<String, dynamic>(),
        );
      }
    }

    return _snapshot(
      activeWorkspace: activeWorkspace,
      savedAt: savedAt,
      documents: documents,
      annotations: annotations,
    );
  }

  ActiveSessionSnapshot _decodeLegacy(Map<String, dynamic> json) {
    final index = json['activeWorkspaceIndex'] as int? ?? 0;
    final activeWorkspace = _legacyKeyAt(index);
    _requireModule(activeWorkspace);
    final documents = <FormalSystemKey, Object>{};
    for (final entry in _legacyFields.entries) {
      final value = json[entry.key];
      if (value == null) continue;
      final module = _requireModule(entry.value);
      documents[entry.value] = _requireSession(module).decodeSession(
        _stringMap(value, 'Legacy active session document must be an object'),
        schema: module.descriptor.schema,
      );
    }
    return _snapshot(
      activeWorkspace: activeWorkspace,
      savedAt: _decodeSavedAt(json['savedAt']),
      documents: documents,
      annotations: const {},
    );
  }

  ActiveSessionSnapshot _snapshot({
    required FormalSystemKey activeWorkspace,
    required DateTime savedAt,
    required Map<FormalSystemKey, Object> documents,
    required Map<FormalSystemKey, DocumentAnnotationCollection> annotations,
  }) {
    return ActiveSessionSnapshot(
      activeWorkspaceKey: activeWorkspace,
      savedAt: savedAt,
      fsa: documents[DefaultFormalSystemIds.fsa] as FSA?,
      grammar: documents[DefaultFormalSystemIds.grammar] as Grammar?,
      pda: documents[DefaultFormalSystemIds.pda] as PDA?,
      tm: documents[DefaultFormalSystemIds.tm] as TM?,
      regex: documents[DefaultFormalSystemIds.regex] as RegexSessionSnapshot?,
      documents: documents,
      annotations: annotations,
    );
  }

  FormalSystemModule<Object> _requireModule(FormalSystemKey key) {
    final module = registry.moduleFor(key);
    if (module == null) {
      throw FormatException('Unknown formal system key: ${key.value}');
    }
    return module;
  }

  SessionCapability<Object> _requireSession(
    FormalSystemModule<Object> module,
  ) {
    final session = module.session;
    if (!module.descriptor.capabilities.session.isEnabled || session == null) {
      throw FormatException(
        'Session persistence is unavailable for '
        '${module.descriptor.key.value}',
      );
    }
    return session;
  }

  FormalSystemKey _keyForValue(Object? value) {
    if (value is! String) {
      throw const FormatException('Active workspace key must be a string');
    }
    for (final module in registry.modules) {
      if (module.descriptor.key.value == value) return module.descriptor.key;
    }
    throw FormatException('Unknown formal system key: $value');
  }

  static DateTime _decodeSavedAt(Object? value) {
    if (value is! String) {
      throw const FormatException('Active session savedAt must be a string');
    }
    return DateTime.parse(value);
  }

  static Map<String, Object?> _stringMap(Object? value, String message) {
    if (value is! Map) throw FormatException(message);
    try {
      return value.cast<String, Object?>();
    } on TypeError {
      throw FormatException(message);
    }
  }

  static FormalSystemKey _legacyKeyAt(int index) {
    if (index < 0 || index >= _legacyWorkspaceKeys.length) {
      return DefaultFormalSystemIds.fsa;
    }
    return _legacyWorkspaceKeys[index];
  }

  static const _legacyWorkspaceKeys = [
    DefaultFormalSystemIds.fsa,
    DefaultFormalSystemIds.grammar,
    DefaultFormalSystemIds.pda,
    DefaultFormalSystemIds.tm,
    DefaultFormalSystemIds.regex,
    DefaultFormalSystemIds.pumping,
  ];

  static const _legacyFields = {
    'fsa': DefaultFormalSystemIds.fsa,
    'grammar': DefaultFormalSystemIds.grammar,
    'pda': DefaultFormalSystemIds.pda,
    'tm': DefaultFormalSystemIds.tm,
    'regex': DefaultFormalSystemIds.regex,
  };
}
