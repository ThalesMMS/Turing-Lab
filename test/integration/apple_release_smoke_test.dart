//
//  apple_release_smoke_test.dart
//  Turing Lab
//
//  Level L1 of the Apple release validation matrix: deterministic
//  widget/platform smoke over the iPhone, iPad and macOS form factors. Every
//  case is parameterized from the shared harness, needs no simulator, signing
//  identity or hardware, and never touches archive or App Store Connect work.
//
//  Run with:
//    flutter test test/integration/apple_release_smoke_test.dart --concurrency=1
//

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations_help.dart';

import '../support/apple_release_harness.dart';
import '../support/apple_release_module.dart';
import '../support/apple_release_shell.dart';
import '../support/apple_release_target.dart';
import '../support/apple_release_test_level.dart';

const AppleReleaseTestLevel _level = AppleReleaseTestLevel.widgetPlatformSmoke;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final target in AppleReleaseTarget.all) {
    group('${_level.id} Apple smoke - ${target.label}', () {
      testWidgets(
        'first launch renders the ${target.expectedShell.name} shell and '
        'reaches every release module',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          body: (harness) async {
            expect(
              harness.shell,
              target.expectedShell,
              reason: 'HomePage must pick the ${target.expectedShell.name} '
                  'shell at ${target.logicalSize.width}px.\n'
                  '${harness.describeState()}',
            );
            expect(harness.shellFinder, findsOneWidget);

            harness.expectNoUntrackedException(
                'rendering the first launch workspace');

            final l10n = harness.localizations;
            for (final module in AppleReleaseModule.values) {
              await harness.openModule(module);
              expect(
                harness.appBarText(module.description(l10n)),
                findsOneWidget,
                reason: 'The ${module.name} workspace heading must be the only '
                    'one in the app bar.',
              );
              harness.expectNoUntrackedException(
                  'opening the ${module.name} workspace');
            }

            await harness.openModule(AppleReleaseModule.fsa);
            harness
                .expectNoUntrackedException('returning to the FSA workspace');
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'settings round trip switches locale, saves the dark theme and '
        'returns to the workspace',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          body: (harness) async {
            await harness.openSettings();
            final english = harness.localizationsFor('en');
            expect(
                harness.appBarText(english.settingsPageTitle), findsOneWidget);
            expect(find.text(english.settingsThemeModeTitle), findsOneWidget);
            expect(find.text(english.settingsLanguageTitle), findsOneWidget);

            await harness.selectLocale('pt');
            final portuguese = harness.localizationsFor('pt');
            expect(
              harness.appBarText(portuguese.settingsPageTitle),
              findsOneWidget,
              reason:
                  'Selecting Portuguese must retranslate the settings page.',
            );

            await harness.selectLocale('en');
            expect(
                harness.appBarText(english.settingsPageTitle), findsOneWidget);

            await harness.tap(
              find.byKey(const ValueKey('settings_theme_dark')),
              description: 'the dark theme chip',
            );
            await harness.waitUntil(
              () => tester
                  .widget<FilterChip>(
                    find.byKey(const ValueKey('settings_theme_dark')),
                  )
                  .selected,
              description: 'the dark theme chip to report itself selected',
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
            expect(
              harness.shellBrightness,
              Brightness.dark,
              reason: 'The saved dark theme must survive the pop back to the '
                  'workspace.',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'help opens from the workspace app bar, searches and returns',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          enableSemantics: true,
          body: (harness) async {
            final l10n = harness.localizations;

            await harness.openHelp();
            harness.expectNoUntrackedException('opening the help catalog');

            await harness.tapAndWaitFor(
              find.byKey(const ValueKey('help-search-action')),
              find.byKey(const ValueKey('help-search-field')),
              description: 'the help search field',
            );
            await tester.enterText(
              find.byKey(const ValueKey('help-search-field')),
              'grammar',
            );
            await harness.waitFor(
              find.byKey(const ValueKey('help-search-status')),
              description: 'the help search status region',
            );

            await harness.back(
              expected: harness.shellFinder,
              description: 'the workspace shell',
            );
            expect(
              harness.appBarText(
                AppleReleaseModule.fsa.description(l10n),
              ),
              findsOneWidget,
              reason: 'Closing help must restore the workspace it was opened '
                  'from.',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      testWidgets(
        'launch restores the persisted locale and theme',
        (tester) => AppleReleaseHarness.run(
          tester,
          target: target,
          level: _level,
          preferences: const <String, Object>{
            'settings_locale_code': 'pt',
            'settings_theme_mode': 'dark',
          },
          body: (harness) async {
            final portuguese = harness.localizationsFor('pt');
            expect(
              harness.appBarText(
                AppleReleaseModule.fsa.description(portuguese),
              ),
              findsOneWidget,
              reason: 'A relaunch must restore the persisted locale before the '
                  'workspace is usable.',
            );
            expect(
              harness.shellBrightness,
              Brightness.dark,
              reason: 'A relaunch must restore the persisted theme.',
            );
          },
        ),
        variant: TargetPlatformVariant.only(target.platform),
      );

      if (target.hasPointerAndKeyboard) {
        testWidgets(
          'pointer hover and keyboard traversal work without native system UI',
          (tester) => AppleReleaseHarness.run(
            tester,
            target: target,
            level: _level,
            body: (harness) async {
              expect(
                harness.shell,
                AppleReleaseShell.desktop,
                reason: 'Pointer and keyboard coverage targets the desktop '
                    'shell only.',
              );

              final l10n = harness.localizations;
              final selectorHint = l10n.workspaceSelectorHint;
              final selector = find
                  .descendant(
                    of: harness.shellFinder,
                    matching: find.byIcon(Icons.arrow_drop_down),
                  )
                  .first;

              final pointer = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await pointer.addPointer();
              addTearDown(pointer.removePointer);
              await pointer.moveTo(tester.getCenter(selector));

              await harness.waitFor(
                find.text(selectorHint),
                description: 'the workspace selector tooltip shown on hover',
              );

              await pointer.moveTo(Offset.zero);
              await harness.waitUntilGone(
                find.text(selectorHint),
                description: 'the workspace selector tooltip to be dismissed',
              );

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
                description: 'the help search field to take keyboard focus',
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
          variant: TargetPlatformVariant.only(target.platform),
        );
      }
    });
  }
}
