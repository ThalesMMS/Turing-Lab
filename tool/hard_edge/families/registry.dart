import 'dart:io';

import '../dispatch.dart';
import '../mutation.dart';
import '../runner.dart';
import 'codec_certification.dart';
import 'codec_executor.dart';
import 'grammar_adapter.dart';
import 'graph_family.dart';
import 'formal_systems_family.dart';
import 'pda_executor.dart';
import 'pda_family.dart';
import 'regular_family.dart';
import 'tm_certification.dart';
import 'tm_family.dart';

HardEdgePropertyExecutorRegistry hardEdgePropertyExecutorRegistry(
  Directory repositoryRoot,
) =>
    HardEdgePropertyExecutorRegistry({
      'framework': const SyntheticPropertyExecutor(),
      'codec': const CodecHardEdgePropertyExecutor(),
      'formal-systems': const FormalSystemsHardEdgePropertyExecutor(),
      'grammar': const GrammarHardEdgePropertyExecutor(),
      'graph': GraphHardEdgePropertyExecutor(),
      'pda': const PdaHardEdgePropertyExecutor(),
      'regular': RegularHardEdgeExecutor(repositoryRoot: repositoryRoot),
      'tm': TmHardEdgeExecutor(repositoryRoot: repositoryRoot),
    });

HardEdgeMutationExecutorRegistry hardEdgeMutationExecutorRegistry() =>
    HardEdgeMutationExecutorRegistry({
      'framework': const SyntheticMutationExecutor(),
      'codec': const CodecHardEdgeMutationExecutor(),
      'formal-systems': const FormalSystemsHardEdgeMutationExecutor(),
      'grammar': const GrammarHardEdgeMutationExecutor(),
      'graph': const GraphHardEdgeMutationExecutor(),
      'pda': const PdaHardEdgeMutationExecutor(),
      'regular': RegularHardEdgeMutationExecutor(),
      'tm': TmHardEdgeMutationExecutor(),
    });

HardEdgeShrinkAdapterRegistry hardEdgeShrinkAdapterRegistry() =>
    HardEdgeShrinkAdapterRegistry({
      'codec': codecHardEdgeShrinkAdapter(
        isApplicable: (fixture) async {
          final check = await CodecCertificationRunner().runProperty(fixture);
          return check.status == CodecCertificationStatus.failed;
        },
      ),
      'formal-systems': const HardEdgeShrinkAdapter(
        shrinker: FormalSystemsFailureFixtureShrinker(),
        isValid: formalSystemsFailureFixtureIsValid,
        isApplicable: formalSystemsFailureFixtureIsApplicable,
      ),
      'grammar': const HardEdgeShrinkAdapter(
        shrinker: GrammarFailureFixtureShrinker(),
        isValid: grammarFailureFixtureIsValid,
        isApplicable: grammarFailureFixtureIsApplicable,
      ),
      'graph': const HardEdgeShrinkAdapter(
        shrinker: GraphFailureFixtureShrinker(),
        isValid: graphFailureFixtureIsValid,
        isApplicable: graphFailureFixtureIsApplicable,
      ),
      'pda': pdaHardEdgeShrinkAdapter(
        isApplicable: (fixture) async {
          final check = await const PdaCertificationRunner().runProperty(
            property: fixture.property,
            fixture: fixture,
          );
          return check.status == PdaCertificationStatus.failed;
        },
      ),
      'regular': const HardEdgeShrinkAdapter(
        shrinker: regularFailureFixtureShrinker,
        isValid: regularFailureFixtureIsValid,
        isApplicable: regularFailureFixtureIsApplicable,
      ),
      'tm': const HardEdgeShrinkAdapter(
        shrinker: TmFailureFixtureShrinker(),
        isValid: tmFailureFixtureIsValid,
        isApplicable: tmFailureFixtureIsApplicable,
      ),
    });
