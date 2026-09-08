import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/algorithms/pda/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm/tm_simulator.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/fsa_trace_viewer.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/pda_trace_viewer.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/tm_trace_viewer.dart';

void main() {
  for (final size in const [
    Size(430, 900),
    Size(820, 1180),
    Size(1194, 834),
    Size(1600, 900),
  ]) {
    for (final kind in ['TM', 'PDA', 'FSA']) {
      testWidgets('$kind playback preserves workspace at ${size.width}px', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pages = PageController(initialPage: 1);
        addTearDown(pages.dispose);
        final highlights = SimulationHighlightService();
        final verticalScroll = ScrollController();
        addTearDown(verticalScroll.dispose);
        const steps = [
          SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            tapeContents: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            tapeContents: 'Xb',
            stackContents: 'AZ',
            stepNumber: 1,
          ),
          SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            tapeContents: 'XY',
            stackContents: 'Z',
            stepNumber: 2,
          ),
        ];
        final viewer = switch (kind) {
          'TM' => TMTraceViewer(
            result: TMSimulationResult.success(
              inputString: 'ab',
              steps: steps,
              executionTime: Duration.zero,
            ),
            highlightService: highlights,
          ),
          'PDA' => PDATraceViewer(
            result: PDASimulationResult.success(
              inputString: 'ab',
              steps: steps,
              executionTime: Duration.zero,
            ),
            highlightService: highlights,
          ),
          _ => FsaTraceViewer(
            result: SimulationResult.success(
              inputString: 'ab',
              steps: steps,
              executionTime: Duration.zero,
            ),
            highlightService: highlights,
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              platform: size.width >= 1400
                  ? TargetPlatform.macOS
                  : TargetPlatform.iOS,
            ),
            home: Scaffold(
              body: PageView(
                controller: pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const SizedBox(),
                  Row(
                    children: [
                      const Expanded(child: Placeholder()),
                      SizedBox(
                        width: size.width < 600 ? 280 : 380,
                        child: SingleChildScrollView(
                          controller: verticalScroll,
                          child: Column(
                            children: [
                              if (kind != 'FSA')
                                SizedBox(height: size.height / 2),
                              viewer,
                              if (kind != 'FSA') SizedBox(height: size.height),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(pages.page, 1, reason: 'initial selection frame $frame');
        }
        await tester.tap(find.byTooltip('Play'));
        for (var frame = 0; frame < 200; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(pages.page, 1, reason: 'playback frame $frame');
        }
        if (kind != 'FSA') {
          expect(verticalScroll.offset, greaterThan(0));
        }
        expect(find.text('3 / 3'), findsOneWidget);
      });
    }
  }
}
