import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  testWidgets(
      'owns implicit transformation controller until the current view '
      'detaches', (tester) async {
    final graph = Graph()..addNode(Node.Id('target'));
    final controller = GraphViewController();
    addTearDown(controller.dispose);
    final transformationController = controller.transformationController;

    expect(transformationController, isNotNull);
    if (transformationController == null) {
      return;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: GraphView.builder(
          graph: graph,
          algorithm: SugiyamaAlgorithm(SugiyamaConfiguration()),
          controller: controller,
          builder: (node) => const SizedBox(width: 20, height: 20),
        ),
      ),
    );

    expect(controller.hasAttachedView, isTrue);
    expect(
      tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController,
      same(transformationController),
    );

    controller.dispose();
    void listener() {}

    expect(
      () => transformationController.addListener(listener),
      returnsNormally,
    );
    transformationController.removeListener(listener);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(controller.hasAttachedView, isFalse);
    expect(
      () => transformationController.addListener(listener),
      throwsFlutterError,
    );
    expect(controller.dispose, returnsNormally);
  });
}
