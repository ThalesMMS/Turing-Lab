import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';

void main() {
  test('toggleTool selects an inactive tool and cancels an active tool', () {
    final controller = AutomatonCanvasToolController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.toggleTool(AutomatonCanvasTool.transition);

    expect(controller.activeTool, AutomatonCanvasTool.transition);
    expect(notifications, 1);

    controller.toggleTool(AutomatonCanvasTool.transition);

    expect(controller.activeTool, AutomatonCanvasTool.selection);
    expect(notifications, 2);
  });
}
