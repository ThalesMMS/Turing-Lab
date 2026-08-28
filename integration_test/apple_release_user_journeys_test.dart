//
//  apple_release_user_journeys_test.dart
//  Turing Lab
//
//  Level L2 of the Apple release validation matrix: release-visible user
//  journeys driven through `integration_test` on an explicitly selected local
//  iOS simulator or on the local macOS target. The journeys share the same
//  harness as the L1 widget smoke, so the two levels cannot drift apart.
//
//  This suite never archives, signs, uploads or drives real hardware. When no
//  local Apple device has been declared it reports a not-run prerequisite
//  state instead of passing.
//
//  A live binding only makes progress while the host keeps delivering frames.
//  A macOS session that cannot foreground the app window ("Failed to foreground
//  app; open returned 1") stops doing that, and the run stalls; see the
//  "macOS L2 Window Prerequisite" section of release/APPLE_QA_MATRIX.md. Prefer
//  a booted iOS simulator, and treat a stalled run as not run.
//
//  Run with:
//    flutter test integration_test/apple_release_user_journeys_test.dart \
//      -d <device-id> \
//      --dart-define=APPLE_RELEASE_TARGET=<iphone|ipad|macos> \
//      --dart-define=APPLE_RELEASE_DEVICE=<device-id>
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/apple_release_harness.dart';
import '../test/support/apple_release_module.dart';
import '../test/support/apple_release_prerequisites.dart';
import '../test/support/apple_release_shell.dart';
import '../test/support/apple_release_test_level.dart';

const AppleReleaseTestLevel _level =
    AppleReleaseTestLevel.simulatorIntegrationSmoke;

/// Outermost guard for a journey.
///
/// Every wait inside the harness is bounded in pumped frames, which assumes
/// the host keeps delivering frames. A host that never foregrounds the app
/// window breaks that assumption, so each journey also carries a wall-clock
/// timeout.
const Timeout _journeyTimeout = Timeout(Duration(minutes: 4));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final prerequisites = AppleReleasePrerequisites.resolve(level: _level);
  // Printed on every invocation so the run records which device was declared,
  // or why the journeys did not run at all.
  // ignore: avoid_print
  print(prerequisites.report);

  final hasPointerAndKeyboard =
      prerequisites.target?.hasPointerAndKeyboard ?? false;
  final pointerAndKeyboardSkip = hasPointerAndKeyboard
      ? null
      : 'Not run: the declared target exposes no pointer or hardware keyboard.';

  group('${_level.id} Apple release journeys', () {
    testWidgets(
      'journey: first launch reaches every release module and returns to FSA',
      (tester) => AppleReleaseHarness.run(
        tester,
        target: prerequisites.requiredTarget,
        level: _level,
        overrideViewport: false,
        body: (harness) async {
          expect(
            harness.shellFinder,
            findsOneWidget,
            reason:
                'The declared device must render exactly one navigation '
                'shell.\n${harness.describeState()}',
          );
          harness.expectNoUntrackedException('rendering the first launch');

          final l10n = harness.localizations;
          for (final module in AppleReleaseModule.values) {
            await harness.openModule(module);
            expect(
              harness.appBarText(
                harness.shell == AppleReleaseShell.mobile
                    ? module.label(l10n)
                    : module.description(l10n),
              ),
              findsOneWidget,
            );
            harness.expectNoUntrackedException(
              'opening the ${module.name} workspace',
            );
          }

          await harness.openModule(AppleReleaseModule.fsa);
        },
      ),
      timeout: _journeyTimeout,
    );

    testWidgets(
      'journey: settings locale and theme round trip, then help and back',
      (tester) => AppleReleaseHarness.run(
        tester,
        target: prerequisites.requiredTarget,
        level: _level,
        overrideViewport: false,
        body: (harness) async {
          final english = harness.localizationsFor('en');
          final portuguese = harness.localizationsFor('pt');

          await harness.openSettings();
          expect(find.text(english.settingsThemeModeTitle), findsOneWidget);

          await harness.selectLocale('pt');
          expect(
            harness.appBarText(portuguese.settingsPageTitle),
            findsOneWidget,
          );
          await harness.selectLocale('en');

          await harness.tap(
            find.byKey(const ValueKey('settings_theme_dark')),
            description: 'the dark theme chip',
          );
          await harness.tapAndWaitFor(
            find.byKey(const ValueKey('settings_save_button')),
            find.text(english.settingsSaveSuccess),
            description: 'the settings saved confirmation',
          );

          await harness.back(
            expected: harness.shellFinder,
            description: 'the workspace shell',
          );
          expect(harness.shellBrightness, Brightness.dark);

          await harness.openHelp();
          await harness.back(
            expected: harness.shellFinder,
            description: 'the workspace shell',
          );
          harness.expectNoUntrackedException('closing the help page');
        },
      ),
      timeout: _journeyTimeout,
    );

    testWidgets(
      'journey: relaunch restores the persisted locale and theme',
      (tester) => AppleReleaseHarness.run(
        tester,
        target: prerequisites.requiredTarget,
        level: _level,
        overrideViewport: false,
        preferences: const <String, Object>{
          'settings_locale_code': 'pt',
          'settings_theme_mode': 'dark',
        },
        body: (harness) async {
          final portuguese = harness.localizationsFor('pt');
          expect(
            harness.appBarText(
              harness.shell == AppleReleaseShell.mobile
                  ? AppleReleaseModule.fsa.label(portuguese)
                  : AppleReleaseModule.fsa.description(portuguese),
            ),
            findsOneWidget,
            reason: 'A relaunch must restore the persisted locale.',
          );
          expect(
            harness.shellBrightness,
            Brightness.dark,
            reason: 'A relaunch must restore the persisted theme.',
          );
        },
      ),
      timeout: _journeyTimeout,
    );

    group('pointer and keyboard', () {
      testWidgets(
        'journey: keyboard-driven help search without native system UI',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: prerequisites.requiredTarget,
          level: _level,
          overrideViewport: false,
          body: (harness) async {
            await harness.openHelp();
            await harness.tapAndWaitFor(
              find.byKey(const ValueKey('help-search-action')),
              find.byKey(const ValueKey('help-search-field')),
              description: 'the help search field',
            );
            await harness.waitUntil(
              () =>
                  tester.binding.focusManager.primaryFocus?.context != null &&
                  find
                      .descendant(
                        of: find.byKey(const ValueKey('help-search-field')),
                        matching: find.byType(EditableText),
                      )
                      .evaluate()
                      .isNotEmpty,
              description:
                  'the help search field to take keyboard focus '
                  'on the ${harness.shell.name} shell',
            );

            await tester.enterText(
              find.byKey(const ValueKey('help-search-field')),
              'grammar',
            );
            await harness.waitFor(
              find.byKey(const ValueKey('help-search-status')),
              description: 'the help search status region',
            );

            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await harness.waitUntilGone(
              find.byKey(const ValueKey('help-search-field')),
              description: 'the help search field to close on Escape',
            );

            await harness.back(
              expected: harness.shellFinder,
              description: 'the workspace shell',
            );
          },
        ),
        timeout: _journeyTimeout,
      );
    }, skip: pointerAndKeyboardSkip);
  }, skip: prerequisites.notRunReason);
}
