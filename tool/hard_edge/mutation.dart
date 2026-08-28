import 'dart:convert';
import 'dart:io';

enum HardEdgeMutationStatus { killed, survived, notRun }

final class HardEdgeMutation {
  const HardEdgeMutation({
    required this.id,
    required this.family,
    required this.property,
    required this.operatorId,
    required this.fixture,
    required this.sha256,
    required this.requiredTool,
  });

  final String id;
  final String family;
  final String property;
  final String operatorId;
  final String fixture;
  final String sha256;
  final String? requiredTool;

  factory HardEdgeMutation.parse(Object? source, String path) {
    if (source is! Map) throw FormatException('$path must be an object.');
    final json = <String, Object?>{
      for (final entry in source.entries) entry.key.toString(): entry.value,
    };
    const expected = {
      'id',
      'family',
      'property',
      'operatorId',
      'fixture',
      'sha256',
      'requiredTool',
    };
    final missing = expected.difference(json.keys.toSet());
    final unknown = json.keys.toSet().difference(expected);
    if (missing.isNotEmpty) {
      throw FormatException(
          '$path is missing keys: ${(missing.toList()..sort()).join(', ')}.');
    }
    if (unknown.isNotEmpty) {
      throw FormatException(
          '$path has unknown keys: ${(unknown.toList()..sort()).join(', ')}.');
    }
    String identifier(String key) {
      final value = json[key];
      if (value is! String ||
          !RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(value)) {
        throw FormatException(
            '$path.$key must be a stable lower-case identifier.');
      }
      return value;
    }

    final fixture = json['fixture'];
    if (fixture is! String ||
        fixture.isEmpty ||
        File(fixture).isAbsolute ||
        fixture.split(RegExp(r'[/\\]+')).contains('..')) {
      throw FormatException('$path.fixture must stay inside the repository.');
    }
    final digest = json['sha256'];
    if (digest is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      throw FormatException(
          '$path.sha256 must be a lower-case SHA-256 digest.');
    }
    final requiredTool = json['requiredTool'];
    if (requiredTool != null &&
        (requiredTool is! String || requiredTool.trim().isEmpty)) {
      throw FormatException(
          '$path.requiredTool must be null or a non-empty string.');
    }
    return HardEdgeMutation(
      id: identifier('id'),
      family: identifier('family'),
      property: identifier('property'),
      operatorId: identifier('operatorId'),
      fixture: fixture.replaceAll('\\', '/'),
      sha256: digest,
      requiredTool: requiredTool as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'family': family,
        'fixture': fixture,
        'id': id,
        'operatorId': operatorId,
        'property': property,
        'requiredTool': requiredTool,
        'sha256': sha256,
      };
}

final class HardEdgeMutationResult {
  const HardEdgeMutationResult({
    required this.mutation,
    required this.status,
    required this.message,
  });

  final HardEdgeMutation mutation;
  final HardEdgeMutationStatus status;
  final String message;

  Map<String, Object?> toJson() => {
        'family': mutation.family,
        'id': mutation.id,
        'message': message,
        'operatorId': mutation.operatorId,
        'property': mutation.property,
        'status': status.name,
      };
}

abstract interface class HardEdgeMutationExecutor {
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  );
}

final class SyntheticMutationExecutor implements HardEdgeMutationExecutor {
  const SyntheticMutationExecutor();

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (fixture is! Map) {
      throw const FormatException(
          'Synthetic mutation fixture must be an object.');
    }
    final status = fixture['mutationStatus'];
    if (status is! String) {
      throw const FormatException(
        'Synthetic mutation fixture must contain mutationStatus.',
      );
    }
    return switch (status) {
      'killed' => HardEdgeMutationStatus.killed,
      'survived' => HardEdgeMutationStatus.survived,
      'notRun' => HardEdgeMutationStatus.notRun,
      _ =>
        throw FormatException('Unknown synthetic mutation status "$status".'),
    };
  }
}

Future<Object?> readMutationFixture(File file) async {
  try {
    return jsonDecode(await file.readAsString());
  } on FormatException catch (error) {
    throw FormatException(
      'Invalid mutation fixture ${file.path}: ${error.message}',
    );
  }
}
