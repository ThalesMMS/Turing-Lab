enum EducationalContentReferenceErrorCode {
  invalidShape,
  invalidId,
  invalidVersion,
  invalidArgumentKey,
  duplicateArgumentKey,
  unsupportedContent,
  invalidContentSet,
}

final class EducationalContentReferenceException implements Exception {
  const EducationalContentReferenceException(this.code);

  final EducationalContentReferenceErrorCode code;
}

/// Stable, locale-neutral pointer to one version of shipped educational copy.
///
/// [argumentKeys] names the formal/runtime values interpolated by a localized
/// renderer. Values stay in their owning model and are never stored here.
final class EducationalContentReference {
  factory EducationalContentReference({
    required String id,
    required int version,
    Iterable<String> argumentKeys = const <String>[],
  }) {
    _validateId(id);
    if (version < 1) {
      throw const EducationalContentReferenceException(
        EducationalContentReferenceErrorCode.invalidVersion,
      );
    }
    final frozenArgumentKeys = List<String>.unmodifiable(argumentKeys);
    _validateArgumentKeys(frozenArgumentKeys);
    return EducationalContentReference._(
      id: id,
      version: version,
      argumentKeys: frozenArgumentKeys,
    );
  }

  const EducationalContentReference._({
    required this.id,
    required this.version,
    required this.argumentKeys,
  });

  final String id;
  final int version;
  final List<String> argumentKeys;

  static final RegExp _idPattern = RegExp(
    r'^[a-z0-9]+(?:-[a-z0-9]+)*(?:/[a-z0-9]+(?:-[a-z0-9]+)*)+$',
  );
  static final RegExp _argumentKeyPattern = RegExp(r'^[a-z][A-Za-z0-9]*$');

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'version': version,
    'argumentKeys': argumentKeys,
  };

  factory EducationalContentReference.fromJson(Object? encoded) {
    if (encoded is! Map) {
      throw const EducationalContentReferenceException(
        EducationalContentReferenceErrorCode.invalidShape,
      );
    }
    final map = Map<String, Object?>.from(encoded);
    final id = map['id'];
    final version = map['version'];
    final argumentKeys = map['argumentKeys'];
    if (id is! String ||
        version is! int ||
        argumentKeys is! List ||
        argumentKeys.any((value) => value is! String)) {
      throw const EducationalContentReferenceException(
        EducationalContentReferenceErrorCode.invalidShape,
      );
    }
    return EducationalContentReference(
      id: id,
      version: version,
      argumentKeys: List<String>.unmodifiable(argumentKeys.cast<String>()),
    );
  }

  static void _validateId(String id) {
    if (!_idPattern.hasMatch(id)) {
      throw const EducationalContentReferenceException(
        EducationalContentReferenceErrorCode.invalidId,
      );
    }
  }

  static void _validateArgumentKeys(List<String> argumentKeys) {
    final seen = <String>{};
    for (final key in argumentKeys) {
      if (!_argumentKeyPattern.hasMatch(key)) {
        throw const EducationalContentReferenceException(
          EducationalContentReferenceErrorCode.invalidArgumentKey,
        );
      }
      if (!seen.add(key)) {
        throw const EducationalContentReferenceException(
          EducationalContentReferenceErrorCode.duplicateArgumentKey,
        );
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationalContentReference &&
          id == other.id &&
          version == other.version &&
          _listsEqual(argumentKeys, other.argumentKeys);

  @override
  int get hashCode => Object.hash(id, version, Object.hashAll(argumentKeys));

  static bool _listsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
