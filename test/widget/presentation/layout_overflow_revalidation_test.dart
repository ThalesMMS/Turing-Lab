//
//  layout_overflow_revalidation_test.dart
//  Turing Lab
//
//  Focused revalidation of the Pumping Lemma and Regex example flows at the
//  viewports that `release/APPLE_QA_MATRIX.md` once recorded as overflowing:
//  iPhone (430x932), iPad (1024x1366) and the 320 px compact width. Every
//  scenario records its locale and text scale explicitly and fails on any
//  RenderFlex overflow reported by the framework.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/regex_preset.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_resolver.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_examples_section.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/pumping_lemma/pumping_lemma_workspace.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

import 'examples_test_helpers.dart';

typedef _Viewport = ({String label, Size size});

const List<_Viewport> _viewports = [
  (label: 'iPhone 430x932', size: Size(430, 932)),
  (label: 'iPad 1024x1366', size: Size(1024, 1366)),
  (label: 'compact 320x700', size: Size(320, 700)),
];

const List<Locale> _locales = [Locale('en'), Locale('pt', 'BR')];

const List<double> _textScales = [1, 1.3];

void _applyViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap({
  required ProviderContainer container,
  required Locale locale,
  required double textScale,
  required Widget home,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

void main() {
  for (final viewport in _viewports) {
    for (final locale in _locales) {
      for (final textScale in _textScales) {
        final scenario =
            '${viewport.label}, ${locale.toLanguageTag()}, '
            '${(textScale * 100).round()}% text';

        for (final theorem in PumpingLemmaTheorem.values) {
          testWidgets(
            'Pumping Lemma ${theorem.name} workspace has no overflow at '
            '$scenario',
            (tester) async {
              _applyViewport(tester, viewport.size);
              final container = ProviderContainer();
              addTearDown(container.dispose);

              await tester.pumpWidget(
                _wrap(
                  container: container,
                  locale: locale,
                  textScale: textScale,
                  home: Scaffold(body: PumpingLemmaWorkspace(theorem: theorem)),
                ),
              );
              await tester.pumpAndSettle();

              expect(find.byType(PumpingLemmaWorkspace), findsOneWidget);
              expect(tester.takeException(), isNull);
            },
          );
        }

        testWidgets('Regex examples have no overflow at $scenario', (
          tester,
        ) async {
          _applyViewport(tester, viewport.size);
          SharedPreferences.setMockInitialValues({});
          final preferences = await SharedPreferences.getInstance();
          final container = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(preferences),
              examplesRepositoryProvider.overrideWithValue(
                TestExamplesRepository(),
              ),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            _wrap(
              container: container,
              locale: locale,
              textScale: textScale,
              home: Scaffold(
                appBar: AppBar(
                  leading: const WorkspaceQuickActionsBar(
                    tab: WorkspaceTab.regex,
                  ),
                  leadingWidth: 144,
                ),
                body: const RegexPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          if (viewport.size.width <
              AutomatonWorkspaceScaffold.mobileBreakpoint) {
            final l10n = appLocalizationsOf(
              tester.element(find.byType(RegexPage)),
            );
            await tester.tap(
              find.byTooltip(l10n.workspaceAlgorithmsAndExamplesTooltip),
            );
          } else {
            await tester.tap(
              find
                  .byKey(
                    WorkspaceDock.railButtonKey(
                      AutomatonWorkspaceScaffold.algorithmPanelId,
                    ),
                  )
                  .hitTestable(),
            );
          }
          await tester.pumpAndSettle();

          final examples = find.byType(AlgorithmExamplesSection<RegexPreset>);
          await pumpUntilFound(tester, examples);
          final firstExample = find.text(
            AppLocalizations.of(
              tester.element(examples.first),
            ).localizedExampleName('Regex - Repetição de A'),
          );
          await pumpUntilFound(tester, firstExample);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
