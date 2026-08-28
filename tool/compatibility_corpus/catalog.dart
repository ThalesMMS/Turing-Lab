import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/l_system_jflap_codec.dart';
import 'package:turing_lab/data/codecs/l_system_json_codec.dart';
import 'package:turing_lab/data/codecs/mealy_jflap_codec.dart';
import 'package:turing_lab/data/codecs/mealy_json_document_codec.dart';
import 'package:turing_lab/data/codecs/moore_document_codecs.dart';
import 'package:turing_lab/data/formal_systems/registered_formal_system_module.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_module.dart';

import 'manifest.dart';

final class CompatibilityCodecCatalog {
  CompatibilityCodecCatalog._({
    required this.formalSystems,
    required this.codecs,
  });

  final FormalSystemRegistry formalSystems;
  final Map<String, DocumentCodecCapability<Object>> codecs;

  factory CompatibilityCodecCatalog.create() {
    final modules = <FormalSystemModule<Object>>[
      ...DefaultFormalSystemModules.modules,
      RegisteredFormalSystemModule<MealyMachine>(
        base: TransducerFormalSystemModules.mealy,
        codecs: [
          const MealyJflapDocumentCodec(),
          MealyJsonDocumentCodec(),
        ],
      ),
      RegisteredFormalSystemModule<MooreMachine>(
        base: TransducerFormalSystemModules.moore,
        codecs: MooreDocumentCodecs.all,
      ),
      RegisteredFormalSystemModule<LSystemDocument>(
        base: LSystemFormalSystemModule(
          codecs: [
            const LSystemJflapCodec(),
            LSystemJsonCodec(),
          ],
        ),
      ),
      createUnrestrictedGrammarModule(),
    ];
    final base = FormalSystemRegistry(
      modules: modules,
      formats: DefaultFormalSystemModules.formats,
    );
    final formalSystems =
        DefaultDocumentInteroperabilityRegistry.withBuiltInCodecs(base);
    final codecs = <String, DocumentCodecCapability<Object>>{};
    for (final module in formalSystems.modules) {
      for (final codec in module.codecs) {
        final id = codec.descriptor.codecId.value;
        if (codecs.containsKey(id)) {
          throw StateError('Duplicate compatibility codec id $id.');
        }
        codecs[id] = codec;
      }
    }
    return CompatibilityCodecCatalog._(
      formalSystems: formalSystems,
      codecs: Map.unmodifiable(codecs),
    );
  }

  List<String> validateManifest(CompatibilityManifest manifest) {
    final issues = <String>[];
    final coverage = <String, Set<CompatibilityCaseRole>>{};
    for (final testCase in manifest.cases) {
      if (!codecs.containsKey(testCase.codecId)) {
        issues.add(
          '${testCase.id}: unknown codec ${testCase.codecId}.',
        );
        continue;
      }
      if (_unsafeFixturePath(testCase.fixture)) {
        issues.add(
          '${testCase.id}: fixture path must stay relative to the repository.',
        );
      }
      if (testCase.equivalent case final equivalent?) {
        final equivalentCodec = codecs[equivalent.codecId];
        if (equivalentCodec == null) {
          issues.add(
            '${testCase.id}: unknown equivalent codec ${equivalent.codecId}.',
          );
        } else if (equivalentCodec.descriptor.systemKey !=
            codecs[testCase.codecId]!.descriptor.systemKey) {
          issues.add(
            '${testCase.id}: equivalent codec belongs to another system.',
          );
        }
        if (_unsafeFixturePath(equivalent.fixture)) {
          issues.add(
            '${testCase.id}: equivalent fixture path must stay relative to '
            'the repository.',
          );
        }
      }
      coverage
          .putIfAbsent(testCase.codecId, () => <CompatibilityCaseRole>{})
          .addAll(testCase.roles);
      final descriptor = codecs[testCase.codecId]!.descriptor;
      final expectedCapabilities =
          testCase.expectation.unsupportedCapabilities.toList()..sort();
      final actualCapabilities = descriptor.knownUnsupportedFields.toList()
        ..sort();
      if (!_sameStrings(expectedCapabilities, actualCapabilities)) {
        issues.add(
          '${testCase.id}: unsupported capability report is stale for '
          '${testCase.codecId}.',
        );
      }
      if (testCase.expectation.outcome ==
              CompatibilityExpectedOutcome.success &&
          testCase.oracle.kind == CompatibilityOracleKind.outcome) {
        issues.add('${testCase.id}: success cases require a semantic oracle.');
      }
      if (testCase.expectation.outcome ==
              CompatibilityExpectedOutcome.success &&
          testCase.roles.contains(CompatibilityCaseRole.representative) &&
          testCase.equivalent == null) {
        issues.add(
          '${testCase.id}: representative cases require a canonical '
          'cross-format equivalent.',
        );
      }
      if (testCase.expectation.outcome !=
              CompatibilityExpectedOutcome.success &&
          testCase.oracle.kind != CompatibilityOracleKind.outcome) {
        issues.add(
          '${testCase.id}: non-success cases must use the outcome oracle.',
        );
      }
    }

    final requiredRoles = CompatibilityCaseRole.values.toSet();
    for (final codecId in codecs.keys.toList()..sort()) {
      final missing = requiredRoles.difference(coverage[codecId] ?? const {});
      if (missing.isNotEmpty) {
        final names = missing.map((role) => role.name).toList()..sort();
        issues.add('$codecId: missing corpus roles ${names.join(', ')}.');
      }
    }
    return issues..sort();
  }
}

bool _unsafeFixturePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.startsWith('/') ||
      RegExp(r'^[A-Za-z]:/').hasMatch(normalized) ||
      normalized.split('/').contains('..');
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
