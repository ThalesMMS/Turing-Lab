//
//  cooperative_yield.dart
//  Turing Lab
//
//  Time-sliced cooperative scheduling for long-running algorithms that stay
//  on the UI isolate: after a slice of synchronous work the caller awaits
//  `maybeYield`, which hands the event loop back only when the slice budget
//  has elapsed, so short runs pay no scheduling cost.
//

/// Yields to the event loop once every [slice] of elapsed work.
class CooperativeYield {
  CooperativeYield({this.slice = const Duration(milliseconds: 8)})
    : _stopwatch = Stopwatch()..start();

  /// Longest span of synchronous work between two yields. Eight milliseconds
  /// leaves half of a 16 ms frame for layout and painting.
  final Duration slice;
  final Stopwatch _stopwatch;

  /// Number of times the event loop was handed back.
  int yields = 0;

  Future<void> maybeYield() async {
    if (_stopwatch.elapsed < slice) return;
    yields++;
    await Future<void>.delayed(Duration.zero);
    _stopwatch.reset();
  }
}
