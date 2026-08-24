import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/widgets/help_tree_view.dart';

class _LicenseAssetFixture {
  static const texts = <String, String>{
    'LICENSE.txt': 'Apache License\nVersion 2.0, January 2004\n'
        'Licensed under the Apache License, Version 2.0.',
    'LICENSE_JFLAP.txt':
        'JFLAP 7.1 LICENSE\nFor students and educators\njflap@cs.duke.edu',
    'assets/LICENSE_GRAPHVIEW.txt':
        'MIT License\nCopyright (c) 2025 Nabil Mosharraf',
    'THIRD_PARTY_NOTICES_APPLE.txt':
        'Turing Lab Apple Platform Third-Party Notices\ngraphview 1.5.2',
  };

  final Map<String, int> loadCounts = <String, int>{};
  final Set<String> unavailableAssets = <String>{};
  final Map<String, Completer<ByteData?>> pendingAssets =
      <String, Completer<ByteData?>>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List());
      loadCounts.update(key, (count) => count + 1, ifAbsent: () => 1);
      final pending = pendingAssets[key];
      if (pending != null) return pending.future;
      final text = unavailableAssets.contains(key) ? null : texts[key];
      return _byteData(text);
    });
  }

  ByteData? _byteData(String? text) {
    return text == null
        ? null
        : ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }

  void completePending(String path) {
    pendingAssets[path]!.complete(_byteData(texts[path]));
  }

  void uninstall() {
    for (final path in texts.keys) {
      rootBundle.evict(path);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }
}

Future<void> _pumpLicenses(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1000, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HelpPage(initialTopicId: HelpTopicIds.aboutLicenses),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expandLicense(WidgetTester tester, String title) async {
  final titleFinder = find.text(title);
  await tester.ensureVisible(titleFinder);
  await tester.pumpAndSettle();
  await tester.tap(titleFinder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _LicenseAssetFixture assets;
  setUp(() {
    assets = _LicenseAssetFixture()..install();
  });
  tearDown(() => assets.uninstall());

  testWidgets('renders rich license content inline in the help tree', (
    tester,
  ) async {
    await _pumpLicenses(tester);

    expect(
      find.byKey(const ValueKey('help-body-about.licenses')),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Licenses'), findsOneWidget);
    expect(find.text('Apache License 2.0'), findsOneWidget);
    expect(find.text('JFLAP 7.1 License'), findsOneWidget);
    expect(find.text('GraphView (MIT License)'), findsOneWidget);
    expect(find.text('Apple Platform Third-Party Notices'), findsOneWidget);
    expect(find.text('Susan H. Rodger'), findsOneWidget);
  });

  testWidgets('bundled license assets remain lazy until expanded', (
    tester,
  ) async {
    await _pumpLicenses(tester);

    for (final path in _LicenseAssetFixture.texts.keys) {
      expect(assets.loadCounts[path] ?? 0, 0, reason: path);
    }

    await _expandLicense(tester, 'JFLAP 7.1 License');

    expect(assets.loadCounts['LICENSE_JFLAP.txt'], 1);
    expect(
      find.textContaining('jflap@cs.duke.edu', skipOffstage: false),
      findsOneWidget,
    );
    expect(assets.loadCounts['LICENSE.txt'] ?? 0, 0);
  });

  testWidgets('expanded license future survives scroll virtualization', (
    tester,
  ) async {
    assets.pendingAssets['LICENSE_JFLAP.txt'] = Completer<ByteData?>();
    await _pumpLicenses(tester);

    await _expandLicense(tester, 'JFLAP 7.1 License');
    expect(assets.loadCounts['LICENSE_JFLAP.txt'], 1);
    expect(find.text('Loading bundled license text...'), findsOneWidget);

    final tree = tester.widget<HelpTreeView>(find.byType(HelpTreeView));
    tree.controller.revealTopic(HelpTopicIds.gettingStartedQuickStart);
    await tester.pumpAndSettle();
    assets.completePending('LICENSE_JFLAP.txt');
    await tester.pump();

    tree.controller.revealTopic(HelpTopicIds.aboutLicenses);
    await tester.pumpAndSettle();

    expect(assets.loadCounts['LICENSE_JFLAP.txt'], 1);
    expect(
      find.textContaining('jflap@cs.duke.edu', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('each bundled license expands to its matching source', (
    tester,
  ) async {
    await _pumpLicenses(tester);

    const cases = <(String, String)>[
      ('Apache License 2.0', 'Licensed under the Apache License'),
      ('GraphView (MIT License)', 'Copyright (c) 2025 Nabil Mosharraf'),
      (
        'Apple Platform Third-Party Notices',
        'Turing Lab Apple Platform Third-Party Notices',
      ),
    ];
    for (final (title, expectedText) in cases) {
      await _expandLicense(tester, title);
      expect(
        find.textContaining(expectedText, skipOffstage: false),
        findsOneWidget,
      );
    }
  });

  testWidgets('missing bundled license shows localized English error', (
    tester,
  ) async {
    assets.unavailableAssets.add('LICENSE_JFLAP.txt');
    await _pumpLicenses(tester);

    await _expandLicense(tester, 'JFLAP 7.1 License');

    expect(
      find.textContaining('Failed to load license', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('missing bundled license shows localized Portuguese error', (
    tester,
  ) async {
    assets.unavailableAssets.add('LICENSE_JFLAP.txt');
    await _pumpLicenses(tester, locale: const Locale('pt'));

    await _expandLicense(tester, 'JFLAP 7.1 License');

    expect(
      find.textContaining('Falha ao carregar a licença', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('package license entry opens Flutter LicensePage', (
    tester,
  ) async {
    await _pumpLicenses(tester);
    final packageLicenses = find.byKey(
      const ValueKey('about_package_licenses'),
    );
    await tester.ensureVisible(packageLicenses);
    await tester.tap(packageLicenses);
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
