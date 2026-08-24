import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';

Future<void> _pumpAbout(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Future<bool> Function(Uri uri)? externalUrlLauncher,
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
        home: HelpPage(
          initialTopicId: HelpTopicIds.aboutLicenses,
          externalUrlLauncher: externalUrlLauncher ?? (_) async => true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapRepository(WidgetTester tester) async {
  final repository = find.text('https://github.com/ThalesMMS/jflutter');
  await tester.ensureVisible(repository);
  await tester.tap(repository);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About licenses includes the existing rich attribution content', (
    tester,
  ) async {
    await _pumpAbout(tester);

    expect(find.text('Thales Matheus Mendonça Santos'), findsOneWidget);
    expect(find.text('https://github.com/ThalesMMS/jflutter'), findsOneWidget);
    expect(find.text('GraphView (MIT License)'), findsOneWidget);
    expect(find.text('Package licenses'), findsOneWidget);
    expect(find.text('JFLAP Acknowledgments'), findsOneWidget);
    expect(find.text('Distribution'), findsOneWidget);
  });

  testWidgets('project repository opens the public Turing Lab URL', (
    tester,
  ) async {
    Uri? openedUri;
    await _pumpAbout(
      tester,
      externalUrlLauncher: (uri) async {
        openedUri = uri;
        return true;
      },
    );

    await _tapRepository(tester);

    expect(openedUri, Uri.parse('https://github.com/ThalesMMS/jflutter'));
  });

  testWidgets('failed project repository launch shows localized feedback', (
    tester,
  ) async {
    await _pumpAbout(tester, externalUrlLauncher: (_) async => false);

    await _tapRepository(tester);

    expect(
      find.text('Could not open the project repository.'),
      findsOneWidget,
    );
  });

  testWidgets('failed project launch shows Portuguese feedback', (
    tester,
  ) async {
    await _pumpAbout(
      tester,
      locale: const Locale('pt'),
      externalUrlLauncher: (_) async => false,
    );

    await _tapRepository(tester);

    expect(
      find.text('Não foi possível abrir o repositório do projeto.'),
      findsOneWidget,
    );
  });

  testWidgets('About content is localized in Portuguese', (tester) async {
    await _pumpAbout(tester, locale: const Locale('pt'));

    expect(find.text('Licenças'), findsOneWidget);
    expect(find.text('Desenvolvedor'), findsOneWidget);
    expect(find.text('Repositório do projeto'), findsOneWidget);
    expect(find.text('Licenças dos pacotes'), findsOneWidget);
    expect(
      find.text('Avisos de terceiros das plataformas Apple'),
      findsOneWidget,
    );
    expect(find.text('Projeto original'), findsOneWidget);
    expect(find.text('Fork do GraphView'), findsOneWidget);
  });
}
