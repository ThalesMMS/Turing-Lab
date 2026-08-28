/// Reviewed native snapshot shared by the native and browser TM probes.
///
/// The native certification recomputes every value before accepting this
/// snapshot. The browser test then recomputes the same typed outcomes under
/// dart2js, so these are not browser-only expectations.
const tmCanonicalRuntimeSnapshot = <String, String>{
  'accepted.kind': 'accepted',
  'accepted.outcome': 'accepted',
  'step.outcome': 'boundedUnknown',
  'step.limit': 'steps',
  'configuration.outcome': 'boundedUnknown',
  'configuration.limit': 'configurations',
  'timeout.kind': 'timeout',
  'timeout.outcome': 'boundedUnknown',
  'timeout.limit': 'timeout',
  'cancel.kind': 'cancelled',
};
