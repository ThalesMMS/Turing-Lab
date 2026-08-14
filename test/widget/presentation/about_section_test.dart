import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';

Future<void> _pumpHelpPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Future<bool> Function(Uri uri)? externalUrlLauncher,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: externalUrlLauncher == null
            ? const HelpPage()
            : HelpPage(externalUrlLauncher: externalUrlLauncher),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About exposes developer, project, and license entry points', (
    tester,
  ) async {
    await _pumpHelpPage(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('Thales Matheus Mendonça Santos'), findsOneWidget);
    expect(find.text('https://github.com/ThalesMMS/jflutter'), findsOneWidget);
    expect(find.text('Open Source Licenses'), findsOneWidget);
    expect(find.text('GraphView (MIT License)'), findsOneWidget);
    expect(find.text('Package licenses'), findsOneWidget);
  });

  testWidgets('project repository opens the public Turing Lab URL', (
    tester,
  ) async {
    Uri? openedUri;
    await _pumpHelpPage(
      tester,
      externalUrlLauncher: (uri) async {
        openedUri = uri;
        return true;
      },
    );

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('https://github.com/ThalesMMS/jflutter'));
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse('https://github.com/ThalesMMS/jflutter'));
  });

  testWidgets('failed project repository launch shows localized feedback', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      externalUrlLauncher: (_) async => false,
    );

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('https://github.com/ThalesMMS/jflutter'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not open the project repository.'),
      findsOneWidget,
    );
  });

  testWidgets('failed project launch shows Portuguese feedback', (
    tester,
  ) async {
    await _pumpHelpPage(
      tester,
      locale: const Locale('pt'),
      externalUrlLauncher: (_) async => false,
    );

    await tester.tap(find.text('Sobre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('https://github.com/ThalesMMS/jflutter'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível abrir o repositório do projeto.'),
      findsOneWidget,
    );
  });

  testWidgets('package licenses opens Flutter LicensePage', (tester) async {
    await _pumpHelpPage(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    final packageLicenses = find.byKey(
      const ValueKey('about_package_licenses'),
    );
    await tester.ensureVisible(packageLicenses);
    await tester.tap(packageLicenses);
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('About content is localized in Portuguese', (tester) async {
    await _pumpHelpPage(tester, locale: const Locale('pt'));

    await tester.tap(find.text('Sobre'));
    await tester.pumpAndSettle();

    expect(find.text('Desenvolvedor'), findsOneWidget);
    expect(find.text('Repositório do projeto'), findsOneWidget);
    expect(find.text('Licenças de código aberto'), findsOneWidget);
    expect(find.text('Licenças dos pacotes'), findsOneWidget);
    expect(
      find.text('Avisos de terceiros das plataformas Apple'),
      findsOneWidget,
    );
    expect(find.text('Projeto original'), findsOneWidget);
    expect(find.text('Fork do GraphView'), findsOneWidget);
  });
}
