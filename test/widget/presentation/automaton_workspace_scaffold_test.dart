import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/tablet_layout_container.dart';

void main() {
  Future<void> pumpWorkspace(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AutomatonWorkspaceScaffold(
          canvasWithToolbar: ({required isMobile}) => Text(
            isMobile ? 'mobile canvas' : 'wide canvas',
          ),
          algorithmPanel: const Text('desktop algorithms'),
          tabletAlgorithmPanel: const Text('tablet algorithms'),
          simulationPanel: const Text('simulation panel'),
          infoPanel: const Text('info panel'),
          mobileFloatingPanel: const Text('mobile floating panel'),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.help_outline),
          ),
        ),
      ),
    );
  }

  testWidgets('uses mobile canvas and floating panel below 1024px', (
    tester,
  ) async {
    await pumpWorkspace(tester, size: const Size(430, 900));

    expect(find.text('mobile canvas'), findsOneWidget);
    expect(find.text('mobile floating panel'), findsOneWidget);
    expect(find.text('desktop algorithms'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('uses tablet layout between 1024px and 1400px', (tester) async {
    await pumpWorkspace(tester, size: const Size(1200, 900));

    expect(find.byType(TabletLayoutContainer), findsOneWidget);
    expect(find.text('wide canvas'), findsOneWidget);
    expect(find.text('tablet algorithms'), findsOneWidget);
    expect(find.text('desktop algorithms'), findsNothing);
  });

  testWidgets('uses desktop columns at 1400px and above', (tester) async {
    await pumpWorkspace(tester, size: const Size(1400, 900));

    expect(find.text('wide canvas'), findsOneWidget);
    expect(find.text('simulation panel'), findsOneWidget);
    expect(find.text('desktop algorithms'), findsOneWidget);
    expect(find.text('info panel'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
