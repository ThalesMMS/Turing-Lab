import 'dart:async';

enum ResourceLimitKind {
  steps,
  configurations,
  frontier,
  memoryBytes,
  timeout,
  eventLoopDelay,
}

final class ResourceLimitEvidence {
  const ResourceLimitEvidence({
    required this.kind,
    required this.observed,
    required this.maximum,
    required this.unit,
    this.partialEvidence,
  });

  final ResourceLimitKind kind;
  final int observed;
  final int maximum;
  final String unit;
  final Object? partialEvidence;
}

final class ResourceBudget {
  ResourceBudget({
    this.maxSteps,
    this.maxConfigurations,
    this.maxFrontier,
    this.maxMemoryBytes,
    this.timeout,
    this.maxEventLoopDelay,
  }) {
    for (final entry in <String, int?>{
      'maxSteps': maxSteps,
      'maxConfigurations': maxConfigurations,
      'maxFrontier': maxFrontier,
      'maxMemoryBytes': maxMemoryBytes,
    }.entries) {
      if (entry.value != null && entry.value! < 0) {
        throw ArgumentError.value(
            entry.value, entry.key, 'must not be negative');
      }
    }
    if (timeout != null && timeout! < Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must not be negative');
    }
    if (maxEventLoopDelay != null && maxEventLoopDelay! < Duration.zero) {
      throw ArgumentError.value(
        maxEventLoopDelay,
        'maxEventLoopDelay',
        'must not be negative',
      );
    }
  }

  final int? maxSteps;
  final int? maxConfigurations;
  final int? maxFrontier;
  final int? maxMemoryBytes;
  final Duration? timeout;
  final Duration? maxEventLoopDelay;
}

final class ResourceSnapshot {
  const ResourceSnapshot({
    this.steps = 0,
    this.configurations = 0,
    this.frontier = 0,
    this.memoryBytes = 0,
    this.partialEvidence,
  });

  final int steps;
  final int configurations;
  final int frontier;
  final int memoryBytes;
  final Object? partialEvidence;
}

abstract interface class ElapsedClock {
  Duration get elapsed;
}

final class StopwatchElapsedClock implements ElapsedClock {
  StopwatchElapsedClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}

abstract interface class CancellationProbe {
  bool get isCancelled;
}

final class MutableCancellationToken implements CancellationProbe {
  bool _cancelled = false;

  @override
  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

abstract interface class RequestFreshnessProbe {
  bool get isStale;
}

final class GenerationFreshnessProbe implements RequestFreshnessProbe {
  const GenerationFreshnessProbe({
    required this.expectedGeneration,
    required this.currentGeneration,
  });

  final int expectedGeneration;
  final int Function() currentGeneration;

  @override
  bool get isStale => currentGeneration() != expectedGeneration;
}

sealed class ResourceCheck {
  const ResourceCheck();
}

final class ResourceAvailable extends ResourceCheck {
  const ResourceAvailable();
}

final class ResourceLimitReached extends ResourceCheck {
  const ResourceLimitReached(this.evidence);

  final ResourceLimitEvidence evidence;
}

final class ResourceCancelled extends ResourceCheck {
  const ResourceCancelled();
}

final class ResourceStaleRequest extends ResourceCheck {
  const ResourceStaleRequest();
}

final class ResourceAssertions {
  const ResourceAssertions({
    required this.budget,
    required this.clock,
    this.cancellation,
    this.freshness,
  });

  final ResourceBudget budget;
  final ElapsedClock clock;
  final CancellationProbe? cancellation;
  final RequestFreshnessProbe? freshness;

  ResourceCheck evaluate(ResourceSnapshot snapshot) {
    if (cancellation?.isCancelled ?? false) {
      return const ResourceCancelled();
    }
    if (freshness?.isStale ?? false) {
      return const ResourceStaleRequest();
    }
    final checks = <ResourceLimitEvidence?>[
      _countLimit(
        ResourceLimitKind.steps,
        snapshot.steps,
        budget.maxSteps,
        'steps',
        snapshot.partialEvidence,
      ),
      _countLimit(
        ResourceLimitKind.configurations,
        snapshot.configurations,
        budget.maxConfigurations,
        'configurations',
        snapshot.partialEvidence,
      ),
      _countLimit(
        ResourceLimitKind.frontier,
        snapshot.frontier,
        budget.maxFrontier,
        'items',
        snapshot.partialEvidence,
      ),
      _countLimit(
        ResourceLimitKind.memoryBytes,
        snapshot.memoryBytes,
        budget.maxMemoryBytes,
        'bytes',
        snapshot.partialEvidence,
      ),
      if (budget.timeout case final timeout?)
        _durationLimit(
          ResourceLimitKind.timeout,
          clock.elapsed,
          timeout,
          snapshot.partialEvidence,
        ),
    ];
    for (final evidence in checks) {
      if (evidence != null) return ResourceLimitReached(evidence);
    }
    return const ResourceAvailable();
  }

  static ResourceLimitEvidence? _countLimit(
    ResourceLimitKind kind,
    int observed,
    int? maximum,
    String unit,
    Object? partialEvidence,
  ) {
    if (maximum == null || observed <= maximum) return null;
    return ResourceLimitEvidence(
      kind: kind,
      observed: observed,
      maximum: maximum,
      unit: unit,
      partialEvidence: partialEvidence,
    );
  }

  static ResourceLimitEvidence? _durationLimit(
    ResourceLimitKind kind,
    Duration observed,
    Duration maximum,
    Object? partialEvidence,
  ) {
    if (observed <= maximum) return null;
    return ResourceLimitEvidence(
      kind: kind,
      observed: observed.inMicroseconds,
      maximum: maximum.inMicroseconds,
      unit: 'microseconds',
      partialEvidence: partialEvidence,
    );
  }

  Future<ResourceCheck> checkEventLoopResponsiveness({
    Future<void> Function()? yieldToEventLoop,
    Object? partialEvidence,
  }) async {
    final maximum = budget.maxEventLoopDelay;
    if (maximum == null) return const ResourceAvailable();
    final before = clock.elapsed;
    await (yieldToEventLoop ?? _yieldToEventLoop)();
    final delay = clock.elapsed - before;
    final evidence = _durationLimit(
      ResourceLimitKind.eventLoopDelay,
      delay,
      maximum,
      partialEvidence,
    );
    return evidence == null
        ? const ResourceAvailable()
        : ResourceLimitReached(evidence);
  }
}

Future<void> _yieldToEventLoop() => Future<void>.delayed(Duration.zero);
