import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';

class _HelpPageTestHelpers {
  // ignore: constant_identifier_names
  static const APACHE_LICENSE_TEXT =
      'Apache License\nVersion 2.0, January 2004\n'
      'Licensed under the Apache License, Version 2.0.';
  // ignore: constant_identifier_names
  static const JFLAP_LICENSE_TEXT =
      'JFLAP 7.1 LICENSE\nFor use by students and educators\njflap@cs.duke.edu';
  // ignore: constant_identifier_names
  static const GRAPHVIEW_LICENSE_TEXT = 'MIT License\n'
      'Copyright (c) 2025 Nabil Mosharraf';
  // ignore: constant_identifier_names
  static const APPLE_THIRD_PARTY_NOTICES_TEXT =
      'Turing Lab Apple Platform Third-Party Notices\n'
      'graphview 1.5.2\n'
      'file_picker 8.3.7';

  /// Registers mock asset handlers so rootBundle.loadString resolves in tests.
  static void setUpAssetMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List());
      if (key == 'LICENSE.txt') {
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(APACHE_LICENSE_TEXT)),
        );
      }
      if (key == 'LICENSE_JFLAP.txt') {
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(JFLAP_LICENSE_TEXT)),
        );
      }
      if (key == 'assets/LICENSE_GRAPHVIEW.txt') {
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(GRAPHVIEW_LICENSE_TEXT)),
        );
      }
      if (key == 'THIRD_PARTY_NOTICES_APPLE.txt') {
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode(APPLE_THIRD_PARTY_NOTICES_TEXT)),
        );
      }
      return null;
    });
  }

  static void tearDownAssetMocks() {
    rootBundle.evict('LICENSE.txt');
    rootBundle.evict('LICENSE_JFLAP.txt');
    rootBundle.evict('assets/LICENSE_GRAPHVIEW.txt');
    rootBundle.evict('THIRD_PARTY_NOTICES_APPLE.txt');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }

  /// Pumps HelpPage inside ProviderScope + MaterialApp.
  /// [size] controls the logical screen size used by MediaQuery.
  /// Defaults to a desktop-sized viewport so the sidebar ListTiles are visible.
  static Future<void> pumpHelpPage(
    WidgetTester tester, {
    Size size = const Size(1200, 800),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HelpPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  static Future<void> openLicensesAndSettle(WidgetTester tester) async {
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
  }

  /// Ensures the widget with [text] is scrolled into view, then taps it.
  static Future<void> ensureVisibleAndTap(
    WidgetTester tester,
    String text,
  ) async {
    final textFinder = find.text(text);
    if (textFinder.evaluate().isEmpty) {
      await tester.dragUntilVisible(
        textFinder,
        find.byType(ListView).first,
        const Offset(-240, 0),
      );
    }
    final chipFinder = find.ancestor(
      of: textFinder,
      matching: find.byType(FilterChip),
    );
    final tapTarget = chipFinder.evaluate().isEmpty ? textFinder : chipFinder;
    await tester.ensureVisible(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
  }

  static Future<void> expandLicenseCard(
    WidgetTester tester,
    String title,
  ) async {
    await tester.ensureVisible(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
  }

  static Finder licenseCardFinder(String title) {
    return find.ancestor(
      of: find.text(title),
      matching: find.byType(Card),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Original PR smoke test (preserved and extended)
  // ---------------------------------------------------------------------------

  // Uses desktop layout (default 1200x800) so the 'About' ListTile in the
  // sidebar is directly tappable without scrolling.
  group('Help page exposes bundled license texts and attribution', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('navigating to About shows attribution content', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('About'), findsWidgets);
      expect(find.text('Apache License 2.0'), findsOneWidget);
      expect(find.text('JFLAP 7.1 License'), findsOneWidget);
      expect(find.text('GraphView (MIT License)'), findsOneWidget);
      expect(find.text('Apple Platform Third-Party Notices'), findsOneWidget);
      expect(find.text('Susan H. Rodger'), findsOneWidget);
    });

    testWidgets(
      'expanding JFLAP license card shows bundled license text',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
            tester, 'JFLAP 7.1 License');

        expect(
          find.textContaining('JFLAP 7.1 LICENSE', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('jflap@cs.duke.edu', skipOffstage: false),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // About section navigation – mobile layout (width < 768)
  // ---------------------------------------------------------------------------

  group('About section – mobile layout', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('mobile layout renders FilterChips for navigation', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester,
          size: const Size(430, 932));

      // Mobile layout shows FilterChips in a horizontal scroll bar.
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('tapping About chip shows About content', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester,
          size: const Size(430, 932));

      // Scroll the horizontal chip bar to make 'About' visible, then tap.
      await _HelpPageTestHelpers.ensureVisibleAndTap(tester, 'About');

      expect(find.text('Open Source Licenses'), findsOneWidget);
    });

    testWidgets(
      'About chip is a FilterChip in mobile horizontal scrollable nav',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester,
            size: const Size(430, 932));

        await tester.dragUntilVisible(
          find.text('About'),
          find.byType(ListView).first,
          const Offset(-240, 0),
        );

        final licensesChip = find.ancestor(
          of: find.text('About'),
          matching: find.byType(FilterChip),
        );
        expect(licensesChip, findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // About section navigation – desktop layout (width >= 768)
  // ---------------------------------------------------------------------------

  group('About section – desktop layout', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('About ListTile is visible in sidebar on wide screen', (
      tester,
    ) async {
      // Desktop breakpoint is width >= 768.
      await _HelpPageTestHelpers.pumpHelpPage(tester,
          size: const Size(1200, 800));

      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('About'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping About ListTile navigates to license content on desktop',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester,
            size: const Size(1200, 800));

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        expect(find.text('Open Source Licenses'), findsOneWidget);
      },
    );

    testWidgets('About entry has info icon in desktop sidebar', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester,
          size: const Size(1200, 800));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // _LicensesHelpContent static content
  // ---------------------------------------------------------------------------

  group('_LicensesHelpContent static text and structure', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('shows not-official-JFLAP disclaimer', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining('not an official JFLAP release'),
        findsOneWidget,
      );
    });

    testWidgets('shows Flutter reimplementation description', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining('Flutter reimplementation inspired by'),
        findsOneWidget,
      );
    });

    testWidgets('shows Open Source Licenses subsection title', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Open Source Licenses'), findsOneWidget);
    });

    testWidgets('shows JFLAP Acknowledgments subsection title', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('JFLAP Acknowledgments'), findsOneWidget);
    });

    testWidgets('shows Distribution subsection title', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Distribution'), findsOneWidget);
    });

    testWidgets('shows free non-monetized educational app distribution text', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining('free, non-monetized educational app'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // _LicensesHelpContent – JFLAP acknowledgment cards
  // ---------------------------------------------------------------------------

  group('JFLAP acknowledgment cards', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('shows Susan H. Rodger card with Duke University description', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Susan H. Rodger'), findsOneWidget);
      expect(find.textContaining('Duke University'), findsOneWidget);
    });

    testWidgets('shows JFLAP Team card', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('JFLAP Team'), findsOneWidget);
    });

    testWidgets('JFLAP Team card lists Thomas Finley', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.textContaining('Thomas Finley'), findsOneWidget);
    });

    testWidgets('JFLAP Team card lists Ryan Cavalcante', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.textContaining('Ryan Cavalcante'), findsOneWidget);
    });

    testWidgets('shows Original Project card', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Original Project'), findsOneWidget);
    });

    testWidgets('Original Project card references jflap.org', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining('http://www.jflap.org'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // _LicenseTextCard – Apache License card
  // ---------------------------------------------------------------------------

  group('Apache License card (_LicenseTextCard)', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('shows Apache License 2.0 title', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Apache License 2.0'), findsOneWidget);
    });

    testWidgets('shows Apache card summary text', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining('licensed under Apache 2.0'),
        findsOneWidget,
      );
    });

    testWidgets('Apache card renders license body area', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);
      await _HelpPageTestHelpers.expandLicenseCard(
          tester, 'Apache License 2.0');

      expect(find.byType(SelectableText, skipOffstage: false), findsWidgets);
    });

    testWidgets(
      'expanding Apache card shows bundled license text',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
            tester, 'Apache License 2.0');

        expect(
          find.textContaining(
            'Licensed under the Apache License',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // _LicenseTextCard – JFLAP License card
  // ---------------------------------------------------------------------------

  group('JFLAP License card (_LicenseTextCard)', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('shows JFLAP 7.1 License title', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('JFLAP 7.1 License'), findsOneWidget);
    });

    testWidgets('shows JFLAP card summary text', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining('JFLAP-derived portions remain under'),
        findsOneWidget,
      );
    });

    testWidgets(
      'expanding JFLAP card shows bundled license contact email',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
            tester, 'JFLAP 7.1 License');

        expect(
          find.textContaining('jflap@cs.duke.edu', skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'expanding JFLAP card shows selectable text widget',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
            tester, 'JFLAP 7.1 License');

        expect(find.byType(SelectableText, skipOffstage: false), findsWidgets);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // _LicenseTextCard – Graphview license card
  // ---------------------------------------------------------------------------

  group('Graphview license card (_LicenseTextCard)', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('shows Graphview license title', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('GraphView (MIT License)'), findsOneWidget);
    });

    testWidgets('shows Graphview card summary text', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(
        find.textContaining(
          'Graph visualization library, forked and modified for Turing Lab.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Nabil Mosharraf'), findsWidgets);
    });

    testWidgets(
      'expanding Graphview card shows bundled license text',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
          tester,
          'GraphView (MIT License)',
        );

        final graphviewCardFinder =
            _HelpPageTestHelpers.licenseCardFinder('GraphView (MIT License)');
        expect(
          find.descendant(
            of: graphviewCardFinder,
            matching: find.textContaining(
              'Copyright (c) 2025 Nabil Mosharraf',
              skipOffstage: false,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: graphviewCardFinder,
            matching: find.byType(SelectableText, skipOffstage: false),
          ),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // _LicenseTextCard – Apple third-party notices card
  // ---------------------------------------------------------------------------

  group('Apple third-party notices card (_LicenseTextCard)', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('shows Apple third-party notices title', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Apple Platform Third-Party Notices'), findsOneWidget);
    });

    testWidgets('shows graphview fork acknowledgment card', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('GraphView Fork'), findsOneWidget);
    });

    testWidgets(
      'expanding Apple third-party notices shows bundled text',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
          tester,
          'Apple Platform Third-Party Notices',
        );

        expect(
          find.textContaining(
            'Turing Lab Apple Platform Third-Party Notices',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // _LicenseTextCard – loading fallback (asset unavailable)
  // ---------------------------------------------------------------------------

  group('_LicenseTextCard error state when asset bundle returns null', () {
    setUp(() {
      // Simulate missing assets: handler returns null for any key.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (_) async => null);
    });
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets(
      'shows explicit error text when asset is unavailable and card expanded',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
            tester, 'Apache License 2.0');

        final apacheCardFinder =
            _HelpPageTestHelpers.licenseCardFinder('Apache License 2.0');
        expect(
          find.descendant(
            of: apacheCardFinder,
            matching: find.textContaining(
              'LICENSE.txt',
              skipOffstage: false,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: apacheCardFinder,
            matching: find.byIcon(
              Icons.error_outline,
              skipOffstage: false,
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'license card titles are visible even when assets are unavailable',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        // Titles are synchronous and independent of asset loading.
        expect(find.text('Apache License 2.0'), findsOneWidget);
        expect(find.text('JFLAP 7.1 License'), findsOneWidget);
        expect(find.text('GraphView (MIT License)'), findsOneWidget);
        expect(find.text('Apple Platform Third-Party Notices'), findsOneWidget);
      },
    );

    testWidgets(
      'JFLAP license card also shows explicit error when asset unavailable',
      (tester) async {
        await _HelpPageTestHelpers.pumpHelpPage(tester);

        await _HelpPageTestHelpers.openLicensesAndSettle(tester);

        await _HelpPageTestHelpers.expandLicenseCard(
            tester, 'JFLAP 7.1 License');

        final jflapCardFinder =
            _HelpPageTestHelpers.licenseCardFinder('JFLAP 7.1 License');
        expect(
          find.descendant(
            of: jflapCardFinder,
            matching: find.textContaining(
              'LICENSE_JFLAP.txt',
              skipOffstage: false,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: jflapCardFinder,
            matching: find.byIcon(
              Icons.error_outline,
              skipOffstage: false,
            ),
          ),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // HelpPage section list – structural tests
  // ---------------------------------------------------------------------------

  group('HelpPage section list structure', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('About is present alongside other expected sections', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      // All section titles should appear in the navigation.
      for (final title in [
        'Getting Started',
        'FSA',
        'Grammar',
        'PDA',
        'Turing Machine',
        'Regular Expression',
        'Pumping Lemma',
        'File Operations',
        'Troubleshooting',
        'About',
      ]) {
        expect(
          find.text(title),
          findsAtLeastNWidgets(1),
          reason: 'Section "$title" not found in HelpPage navigation',
        );
      }
    });

    testWidgets('About section does not break other sections', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      // Navigate to a different section before About to ensure no regressions.
      await tester.tap(find.text('Troubleshooting'));
      await tester.pumpAndSettle();

      expect(find.text('Troubleshooting'), findsWidgets);

      // Then navigate to About.
      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Open Source Licenses'), findsOneWidget);
    });

    testWidgets('Help page AppBar title remains correct', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      expect(find.text('Help & Documentation'), findsOneWidget);
    });

    testWidgets('Portuguese locale renders localized help shell copy', (
      tester,
    ) async {
      await _HelpPageTestHelpers.pumpHelpPage(
        tester,
        locale: const Locale('pt'),
      );

      expect(find.text('Ajuda e documentação'), findsOneWidget);
      expect(find.text('Primeiros passos'), findsWidgets);
      expect(find.text('Operações de arquivo'), findsWidgets);
      expect(find.byTooltip('Guia rápido'), findsOneWidget);

      await tester.tap(find.byTooltip('Guia rápido'));
      await tester.pumpAndSettle();

      expect(find.text('Guia rápido'), findsOneWidget);
      expect(find.textContaining('Bem-vindo ao Turing Lab'), findsOneWidget);
      expect(find.text('Entendi!'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Regression: About section does not interfere with scrolling
  // ---------------------------------------------------------------------------

  group('Regression: About content scrollability', () {
    setUp(_HelpPageTestHelpers.setUpAssetMocks);
    tearDown(_HelpPageTestHelpers.tearDownAssetMocks);

    testWidgets('About content is inside a scrollable view', (tester) async {
      await _HelpPageTestHelpers.pumpHelpPage(tester);

      await _HelpPageTestHelpers.openLicensesAndSettle(tester);

      final licensesHeaderFinder = find.text('Open Source Licenses');

      expect(licensesHeaderFinder, findsOneWidget);
      expect(
        find.ancestor(
          of: licensesHeaderFinder,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });
  });
}
