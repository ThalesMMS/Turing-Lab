import 'dart:async';

import 'capability_availability.dart';
import 'formal_system_ids.dart';

final class ConversionEdge {
  const ConversionEdge({
    required this.id,
    required this.source,
    required this.target,
    this.availability = const SupportedCapability(),
  });

  final ConversionEdgeId id;
  final FormalSystemKey source;
  final FormalSystemKey target;
  final CapabilityAvailability availability;

  String get stableKey => '${source.value}->${target.value}:${id.value}';
}

abstract interface class ConversionCapability<TSource extends Object,
    TTarget extends Object> {
  ConversionEdge get edge;

  FutureOr<TTarget> convert(TSource source);
}
