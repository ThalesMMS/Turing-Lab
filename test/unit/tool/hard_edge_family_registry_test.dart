import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/families/grammar_adapter.dart';
import '../../../tool/hard_edge/families/grammar_certification.dart';
import '../../../tool/hard_edge/families/codec_matrix.dart';
import '../../../tool/hard_edge/families/codec_mutations.dart';
import '../../../tool/hard_edge/families/formal_systems_family.dart';
import '../../../tool/hard_edge/families/graph_family.dart';
import '../../../tool/hard_edge/families/pda_executor.dart';
import '../../../tool/hard_edge/families/pda_family.dart';
import '../../../tool/hard_edge/families/registry.dart';
import '../../../tool/hard_edge/families/regular_family.dart';
import '../../../tool/hard_edge/families/tm_certification.dart';
import '../../../tool/hard_edge/families/tm_family.dart';

void main() {
  test('central catalog and family registries have no descriptor drift',
      () async {
    final root = _repositoryRoot(Directory.current);
    final catalog = await HardEdgeCatalog.load(
      repositoryRoot: root,
      manifestFile: File(
        '${root.path}${Platform.pathSeparator}'
        'test${Platform.pathSeparator}fixtures${Platform.pathSeparator}'
        'hard_edge${Platform.pathSeparator}manifest.v1.json',
      ),
    );
    final propertyRegistry = hardEdgePropertyExecutorRegistry(root);
    final mutationRegistry = hardEdgeMutationExecutorRegistry();
    final shrinkRegistry = hardEdgeShrinkAdapterRegistry();

    expect(
      propertyRegistry.families.toSet(),
      catalog.manifest.cases.map((testCase) => testCase.family).toSet(),
    );
    expect(
      mutationRegistry.families.toSet(),
      catalog.manifest.mutations.map((mutation) => mutation.family).toSet(),
    );
    expect(
      shrinkRegistry.families.toSet(),
      catalog.manifest.cases
          .map((testCase) => testCase.family)
          .where((family) => family != 'framework')
          .toSet(),
    );
    expect(
      _caseKeys(catalog, 'regular'),
      {
        for (final descriptor in regularHardEdgeDescriptors)
          '${descriptor.id}|${descriptor.algorithm}|${descriptor.property}',
      },
    );
    expect(
      _caseKeys(catalog, 'grammar'),
      {
        for (final descriptor in grammarHardEdgeDescriptors)
          _grammarDescriptorKey(descriptor),
      },
    );
    expect(
      _caseKeys(catalog, 'pda'),
      {
        for (final descriptor in pdaHardEdgeCaseDescriptors)
          _pdaDescriptorKey(descriptor),
      },
    );
    expect(
      _caseKeys(catalog, 'tm'),
      {
        for (final descriptor in tmHardEdgeDescriptors)
          '${descriptor.id}|${descriptor.algorithm}|${descriptor.property}',
      },
    );
    expect(
      _caseKeys(catalog, 'formal-systems'),
      {
        for (final descriptor in formalSystemsHardEdgeDescriptors)
          _formalSystemsDescriptorKey(descriptor),
      },
    );
    expect(
      _caseKeys(catalog, 'codec'),
      {
        for (final descriptor in codecHardEdgeCaseDescriptors)
          _codecDescriptorKey(descriptor),
      },
    );
    expect(
      _caseKeys(catalog, 'graph'),
      {
        for (final descriptor in graphHardEdgeDescriptors)
          '${descriptor.id}|${descriptor.algorithm}|${descriptor.property}',
      },
    );
    expect(
      _mutationOperators(catalog, 'regular'),
      regularMutationOperatorIds,
    );
    expect(
      _mutationOperators(catalog, 'grammar'),
      runGrammarMutationProbes().map((result) => result.id).toSet(),
    );
    expect(
      _mutationOperators(catalog, 'pda'),
      pdaMutationProbeDescriptors.keys.toSet(),
    );
    expect(_mutationOperators(catalog, 'tm'), tmMutationOperatorIds);
    expect(
      _mutationOperators(catalog, 'formal-systems'),
      formalSystemsMutationOperatorIds,
    );
    expect(
      _mutationOperators(catalog, 'codec'),
      codecMutationOperators.keys.toSet(),
    );
    expect(
      _mutationOperators(catalog, 'graph'),
      graphMutationOperatorIds,
    );
    expect(
      catalog.manifest.cases.where(
        (testCase) =>
            testCase.expectedOutcome == HardEdgeExpectedOutcome.bounded ||
            testCase.expectedOutcome == HardEdgeExpectedOutcome.cancelled ||
            testCase.expectedOutcome == HardEdgeExpectedOutcome.notApplicable,
      ),
      isEmpty,
      reason: 'Meta-properties must resolve definitively in the central run.',
    );
  });
}

Set<String> _caseKeys(HardEdgeCatalog catalog, String family) => {
      for (final testCase
          in catalog.manifest.cases.where((item) => item.family == family))
        '${testCase.id}|${testCase.algorithm}|${testCase.property}',
    };

Set<String> _mutationOperators(HardEdgeCatalog catalog, String family) => {
      for (final mutation
          in catalog.manifest.mutations.where((item) => item.family == family))
        mutation.operatorId,
    };

String _grammarDescriptorKey(GrammarHardEdgeDescriptor descriptor) => [
      'grammar-${descriptor.caseId}',
      descriptor.algorithm,
      descriptor.property,
    ].join('|');

String _pdaDescriptorKey(PdaHardEdgeCaseDescriptor descriptor) => [
      'pda-${_safeName(descriptor.algorithm)}-${_safeName(descriptor.property)}',
      descriptor.algorithm,
      descriptor.property,
    ].join('|');

String _formalSystemsDescriptorKey(
  FormalSystemsHardEdgeDescriptor descriptor,
) =>
    [
      'formal-systems-${descriptor.caseId}',
      descriptor.algorithm,
      descriptor.property,
    ].join('|');

String _codecDescriptorKey(
  ({String algorithm, String property}) descriptor,
) =>
    [
      'codec-${_safeName(descriptor.algorithm)}-${_safeName(descriptor.property)}',
      descriptor.algorithm,
      descriptor.property,
    ].join('|');

Directory _repositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    ).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('Could not locate the repository root.');
    }
    current = current.parent;
  }
}

String _safeName(String value) =>
    value.replaceAll(RegExp(r'[^a-z0-9._-]'), '-');
