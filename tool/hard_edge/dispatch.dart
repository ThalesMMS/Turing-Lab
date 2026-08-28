import 'dart:async';

import 'catalog.dart';
import 'mutation.dart';
import 'runner.dart';
import 'shrinking.dart';

/// Routes property cases to the executor registered for their family.
final class HardEdgePropertyExecutorRegistry
    implements HardEdgeGeneratedPropertyExecutor {
  HardEdgePropertyExecutorRegistry(
    Map<String, HardEdgePropertyExecutor> executors,
  ) : _executors = Map<String, HardEdgePropertyExecutor>.unmodifiable(
          _validateExecutors(executors),
        );

  final Map<String, HardEdgePropertyExecutor> _executors;

  Iterable<String> get families => _executors.keys;

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    return _executorFor(testCase.family).execute(testCase, fixture);
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    final executor = _executorFor(template.family);
    if (executor is! HardEdgeGeneratedPropertyExecutor) {
      throw HardEdgeConfigurationException(
        'Family "${template.family}" does not support generated seed ranges.',
      );
    }
    return executor.materialize(template, templateFixture, seed);
  }

  HardEdgePropertyExecutor _executorFor(String family) {
    final executor = _executors[family];
    if (executor == null) {
      throw HardEdgeConfigurationException(
        'No hard-edge property executor is registered for family "$family".',
      );
    }
    return executor;
  }
}

/// Routes mutation cases to the executor registered for their family.
final class HardEdgeMutationExecutorRegistry
    implements HardEdgeMutationExecutor {
  HardEdgeMutationExecutorRegistry(
    Map<String, HardEdgeMutationExecutor> executors,
  ) : _executors = Map<String, HardEdgeMutationExecutor>.unmodifiable(
          _validateExecutors(executors),
        );

  final Map<String, HardEdgeMutationExecutor> _executors;

  Iterable<String> get families => _executors.keys;

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    final executor = _executors[mutation.family];
    if (executor == null) {
      throw HardEdgeConfigurationException(
        'No hard-edge mutation executor is registered for family '
        '"${mutation.family}".',
      );
    }
    return executor.execute(mutation, fixture);
  }
}

/// Domain-specific controls used when minimizing a central failure artifact.
final class HardEdgeShrinkAdapter {
  const HardEdgeShrinkAdapter({
    required this.shrinker,
    required this.isValid,
    required this.isApplicable,
  });

  final DomainShrinker<Object?> shrinker;
  final FutureOr<bool> Function(Object? fixture) isValid;
  final FutureOr<bool> Function(Object? fixture) isApplicable;
}

/// Resolves the domain shrinker that owns a catalog family's fixtures.
final class HardEdgeShrinkAdapterRegistry {
  HardEdgeShrinkAdapterRegistry(Map<String, HardEdgeShrinkAdapter> adapters)
      : _adapters = Map<String, HardEdgeShrinkAdapter>.unmodifiable(
          _validateExecutors(adapters),
        );

  final Map<String, HardEdgeShrinkAdapter> _adapters;

  Iterable<String> get families => _adapters.keys;

  HardEdgeShrinkAdapter? forFamily(String family) => _adapters[family];
}

Map<String, T> _validateExecutors<T>(Map<String, T> executors) {
  if (executors.isEmpty) {
    throw ArgumentError.value(executors, 'executors', 'must not be empty');
  }
  for (final family in executors.keys) {
    if (family.trim().isEmpty) {
      throw ArgumentError.value(
        family,
        'executors',
        'family identifiers must not be empty',
      );
    }
  }
  return executors;
}
