import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview/canvas_viewport_adapter.dart';

void main() {
  test('singular viewport matrices degrade to finite identity mapping', () {
    final transformation = TransformationController();
    final controller = GraphViewCanvasController(
      automatonStateNotifier: AutomatonStateNotifier(),
      transformationController: transformation,
    );
    addTearDown(() {
      controller.dispose();
      transformation.dispose();
    });
    transformation.value = Matrix4.zero();
    final adapter = AutomatonGraphViewViewportAdapter(controller: controller);

    const point = Offset(120, 80);
    expect(adapter.screenToWorld(point), point);
    expect(adapter.worldToScreen(point), point);
  });

  test('non-finite viewport matrices degrade to finite identity mapping', () {
    final transformation = TransformationController();
    final controller = GraphViewCanvasController(
      automatonStateNotifier: AutomatonStateNotifier(),
      transformationController: transformation,
    );
    addTearDown(() {
      controller.dispose();
      transformation.dispose();
    });
    final adapter = AutomatonGraphViewViewportAdapter(controller: controller);
    const point = Offset(120, 80);

    for (final invalid in [
      Matrix4.identity()..setEntry(0, 0, double.nan),
      Matrix4.identity()..setEntry(1, 1, double.infinity),
    ]) {
      transformation.value = invalid;
      expect(adapter.screenToWorld(point), point);
      expect(adapter.worldToScreen(point), point);
    }
  });
}
