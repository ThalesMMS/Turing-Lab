import 'package:flutter/foundation.dart';

import 'tm_algorithm_execution_controller.dart';

typedef TMAlgorithmStateProjection<T> = T Function(
  TMAlgorithmAnalysisState state,
);

/// Emits only when a selected slice of TM analysis state changes.
class TMAlgorithmStateSelector<T> extends ChangeNotifier {
  TMAlgorithmStateSelector({
    required TMAlgorithmExecutionController controller,
    required TMAlgorithmStateProjection<T> select,
  })  : _controller = controller,
        _select = select,
        _value = select(controller.state) {
    controller.addListener(_handleControllerChanged);
  }

  final TMAlgorithmExecutionController _controller;
  final TMAlgorithmStateProjection<T> _select;
  T _value;

  T get value => _value;

  void _handleControllerChanged() {
    final next = _select(_controller.state);
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    super.dispose();
  }
}
