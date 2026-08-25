//
//  language_comparison_responsive_test.dart
//  Turing Lab
//
//  Responsive gate for the language comparison surface. It walks the canonical
//  viewport matrix in test/responsive/ and asserts the viewer lays out without
//  a single framework error in both hosts it is mounted in - the bounded
//  dialog box and the production scrolling host - across locales, text scales
//  and live resizes, for decided and for stopped comparisons alike.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/language_comparison_outcome.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_semantics.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';

import '../../responsive/responsive_fixtures.dart';
import '../../responsive/responsive_harness.dart';
import '../../responsive/responsive_viewport_matrix.dart';

/// Width below which the viewer stacks the two automata.
///
/// Mirrors the production threshold; the tests derive the expected
/// arrangement from it instead of hard-coding one per viewport.
const double _stackBreakpoint = 640;

/// Fraction of the window the comparison dialog occupies, as
/// `algorithm_panel.dart` sizes it.
const double _dialogFraction = 0.9;

/// Bounded host: the dialog box the algorithm panel opens.
class _DialogHost extends StatelessWidget {
  const _DialogHost({required this.comparisonResult, this.failure});

  final EquivalenceComparisonResult? comparisonResult;
  final LanguageComparisonFailure? failure;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width * _dialogFraction,
          height: size.height * _dialogFraction,
          child: Column(
            children: [
              const _DialogHeader(),
              const Divider(height: 1),
              Expanded(
                child: failure != null
                    ? LanguageComparisonViewer.unavailable(failure: failure!)
                    : LanguageComparisonViewer(
                        comparisonResult: comparisonResult,
                        showProductAutomaton: true,
                        showSteps: true,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Production host: `algorithm_panel.dart` puts the viewer inside an
/// `Expanded(SingleChildScrollView(...))`, which hands it an unbounded height.
class _ScrollingHost extends StatelessWidget {
  const _ScrollingHost({required this.comparisonResult});

  final EquivalenceComparisonResult comparisonResult;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width * _dialogFraction,
          height: size.height * _dialogFraction,
          child: Column(
            children: [
              const _DialogHeader(),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: LanguageComparisonViewer(
                    comparisonResult: comparisonResult,
                    showProductAutomaton: true,
                    showSteps: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Language comparison',
              style: Theme.of(context).textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () {}),
        ],
      ),
    );
  }
}

EquivalenceComparisonResult _comparisonFixture() {
  final automatonA = buildResponsiveFsaFixture();
  final automatonB = buildResponsiveFsaFixture();
  return EquivalenceComparisonResult(
    originalAutomaton: automatonA,
    comparedAutomaton: automatonB,
    isEquivalent: false,
    distinguishingString: 'aab',
    productAutomaton: automatonA,
    steps: const [
      {
        'type': 'initialization',
        'description': 'Initialize product automaton construction',
      },
      {'type': 'bfs_exploration', 'description': 'Exploring state (q0,p0)'},
      {
        'type': 'counterexample_found',
        'description': 'Found distinguishing string: aab',
        'data': {
          'distinguishingString': 'aab',
          'stateA': 'q1',
          'stateB': 'q2',
          'acceptsA': true,
          'acceptsB': false,
        },
      },
    ],
    executionTimeMs: 87,
    timestamp: DateTime.utc(2026, 1, 1),
  );
}

/// Width the viewer actually receives inside the dialog host on [viewport].
double _hostWidth(ResponsiveViewport viewport) {
  final dialogWidth = viewport.logicalSize.width * _dialogFraction;
  return dialogWidth < viewport.layoutWidth
      ? dialogWidth
      : viewport.layoutWidth;
}

void _expectArrangement(WidgetTester tester, {required bool isStacked}) {
  expect(
    find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: isStacked)),
    findsOneWidget,
  );
  expect(
    find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: !isStacked)),
    findsNothing,
  );
}

void main() {
  group('language comparison viewer in the dialog host', () {
    for (final viewport in ResponsiveViewports.all) {
      testWidgets('lays out without overflow on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          child: _DialogHost(comparisonResult: _comparisonFixture()),
        );

        expect(find.byType(LanguageComparisonViewer), findsOneWidget);
        _expectArrangement(
          tester,
          isStacked: _hostWidth(viewport) < _stackBreakpoint,
        );
        await surface.assertNoLayoutErrors(
          'language comparison dialog on ${viewport.name}',
        );
      });
    }
  });

  group('language comparison viewer in the production scrolling host', () {
    for (final viewport in ResponsiveViewports.all) {
      testWidgets('sizes to its content on ${viewport.name}', (tester) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          child: _ScrollingHost(comparisonResult: _comparisonFixture()),
        );

        expect(find.byType(LanguageComparisonViewer), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsWidgets);
        await surface.assertNoLayoutErrors(
          'language comparison scrolling host on ${viewport.name}',
        );
      });
    }
  });

  group('language comparison viewer across locales and text scales', () {
    for (final viewport in ResponsiveViewports.representative) {
      for (final locale in ResponsiveLocales.all) {
        testWidgets(
          'lays out in ${locale.languageCode} at the accessibility scale on '
          '${viewport.name}',
          (tester) async {
            final surface = await pumpResponsiveSurface(
              tester,
              viewport: viewport,
              locale: locale,
              textScale: ResponsiveTextScales.accessibility,
              child: _DialogHost(comparisonResult: _comparisonFixture()),
            );

            expect(find.byType(LanguageComparisonViewer), findsOneWidget);
            await surface.assertNoLayoutErrors(
              'language comparison ${locale.languageCode} x'
              '${ResponsiveTextScales.accessibility} on ${viewport.name}',
            );
          },
        );
      }
    }

    for (final textScale in ResponsiveTextScales.all) {
      testWidgets(
        'lays out in pt at text scale $textScale on the narrowest phone',
        (tester) async {
          final surface = await pumpResponsiveSurface(
            tester,
            viewport: ResponsiveViewports.narrowPhone,
            locale: ResponsiveLocales.portuguese,
            textScale: textScale,
            child: _DialogHost(comparisonResult: _comparisonFixture()),
          );

          expect(find.byType(LanguageComparisonViewer), findsOneWidget);
          _expectArrangement(tester, isStacked: true);
          await surface.assertNoLayoutErrors(
            'language comparison pt x$textScale on the narrowest phone',
          );
        },
      );
    }
  });

  group('language comparison viewer under live resizes', () {
    testWidgets('keeps the verdict, witness and selected step across bands', (
      tester,
    ) async {
      final surface = await pumpResponsiveSurface(
        tester,
        viewport: ResponsiveViewports.desktopLarge,
        child: _DialogHost(comparisonResult: _comparisonFixture()),
      );

      _expectArrangement(tester, isStacked: false);

      final nextStep = find.byKey(
        const ValueKey<String>(LanguageComparisonSemantics.nextStep),
      );
      await tester.ensureVisible(nextStep);
      await surface.settle();
      await tester.tap(nextStep);
      await surface.settle();

      Finder witness() => find.text('"aab"');
      Finder verdict() => find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.notEquivalent,
            ),
          );
      Finder selectedStep() => find.byKey(
            LanguageComparisonSemantics.stepKey(1),
          );

      expect(witness(), findsWidgets);
      expect(verdict(), findsOneWidget);
      expect(selectedStep(), findsOneWidget);

      for (final size in const [
        Size(700, 900),
        Size(420, 900),
        Size(1400, 900),
      ]) {
        await surface.resizeTo(size, label: 'resize-${size.width.toInt()}');
        _expectArrangement(
          tester,
          isStacked: size.width * _dialogFraction < _stackBreakpoint,
        );
        expect(verdict(), findsOneWidget);
        expect(witness(), findsWidgets);
        expect(selectedStep(), findsOneWidget);
      }

      await surface.assertNoLayoutErrors('language comparison live resize');
    });
  });

  group('stopped comparison surface', () {
    for (final viewport in ResponsiveViewports.representative) {
      testWidgets('lays out the failure panel on ${viewport.name}', (
        tester,
      ) async {
        final surface = await pumpResponsiveSurface(
          tester,
          viewport: viewport,
          locale: ResponsiveLocales.portuguese,
          textScale: ResponsiveTextScales.large,
          child: const _DialogHost(
            comparisonResult: null,
            failure: LanguageComparisonFailure(
              reason: LanguageComparisonFailureReason.determinization,
              message: 'Determinization of automaton A exceeded its budget '
                  'while expanding the subset construction',
            ),
          ),
        );

        expect(
          find.byKey(
            LanguageComparisonSemantics.failureKey(
              LanguageComparisonFailureReason.determinization,
            ),
          ),
          findsOneWidget,
        );
        await surface.assertNoLayoutErrors(
          'stopped comparison on ${viewport.name}',
        );
      });
    }
  });
}
