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
          canvasWithToolbar: ({required isMobile}) => Stack(
            children: [
              Center(
                child: Text(isMobile ? 'mobile canvas' : 'wide canvas'),
              ),
              if (isMobile)
                // Mirrors the canvas's transition-mode indicator: centred on
                // the top edge, below the band the floating panel starts in.
                const Positioned(
                  top: 76,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      key: ValueKey('transition-status'),
                      width: 200,
                      height: 40,
                    ),
                  ),
                ),
            ],
          ),
          algorithmPanel: const Text('desktop algorithms'),
          tabletAlgorithmPanel: const Text('tablet algorithms'),
          simulationPanel: const Text('simulation panel'),
          infoPanel: const Text('info panel'),
          mobileFloatingPanelBuilder: (
            context, {
            required onDragDelta,
            required onPanelSizeChanged,
          }) {
            return GestureDetector(
              onPanUpdate: (details) => onDragDelta(details.delta),
              child: const SizedBox.square(
                key: ValueKey('floating-panel'),
                dimension: 48,
                child: Text('mobile floating panel'),
              ),
            );
          },
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
    // The floating panel owns the canvas's top-right corner, so it must not
    // cover the transition-mode indicator sitting below it.
    expect(
      tester.getRect(find.byKey(const ValueKey('transition-status'))).overlaps(
            tester.getRect(find.byKey(const ValueKey('floating-panel'))),
          ),
      isFalse,
    );
  });

  testWidgets('uses tablet layout between 1024px and 1400px', (tester) async {
    await pumpWorkspace(tester, size: const Size(1200, 900));

    expect(find.byType(TabletLayoutContainer), findsOneWidget);
    expect(find.text('wide canvas'), findsOneWidget);
    expect(find.text('tablet algorithms'), findsOneWidget);
    expect(find.text('desktop algorithms'), findsNothing);
  });

  testWidgets('preserves the moved panel position across breakpoints', (
    tester,
  ) async {
    await pumpWorkspace(tester, size: const Size(430, 900));
    final panel = find.byKey(const ValueKey('floating-panel'));

    await tester.drag(panel, const Offset(-120, 140));
    await tester.pumpAndSettle();
    final movedPosition = tester.getTopLeft(panel);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.byType(TabletLayoutContainer), findsOneWidget);

    tester.view.physicalSize = const Size(430, 900);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(panel), movedPosition);
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
