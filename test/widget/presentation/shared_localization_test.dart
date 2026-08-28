import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/navigation_item.dart';
import 'package:turing_lab/presentation/widgets/workspace_selector.dart';

void main() {
  test('generated shared copy preserves EN/PT placeholders and plurals', () {
    final en = lookupAppLocalizations(const Locale('en', 'US'));
    final pt = lookupAppLocalizations(const Locale('pt', 'BR'));

    expect(en.helpSearchResultCount(0), '0 results');
    expect(en.helpSearchResultCount(1), '1 result');
    expect(en.helpSearchResultCount(2), '2 results');
    expect(pt.helpSearchResultCount(0), '0 resultados');
    expect(pt.helpSearchResultCount(1), '1 resultado');
    expect(pt.helpSearchResultCount(2), '2 resultados');
    expect(en.showHelpFor('Grammar'), 'Show help for Grammar');
    expect(pt.showHelpFor('Gramática'), 'Mostrar ajuda sobre Gramática');
    expect(en.attachedNotesTransitionDeletionMessage(2), contains('2 notes'));
    expect(pt.attachedNotesTransitionDeletionMessage(2), contains('2 notas'));
  });

  testWidgets('shared chrome follows runtime locale changes', (tester) async {
    await tester.pumpWidget(const _RuntimeLocaleHarness());

    expect(find.bySemanticsLabel('Workspace: FSA'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('switch-locale')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Espaço de trabalho: AF'), findsOneWidget);
    expect(find.bySemanticsLabel('Workspace: FSA'), findsNothing);
  });

  testWidgets('unsupported locale falls back to English', (tester) async {
    await tester.pumpWidget(
      const _LocalizedSelector(locale: Locale('fr', 'FR')),
    );

    expect(find.bySemanticsLabel('Workspace: FSA'), findsOneWidget);
  });

  testWidgets('shared selector fits 320px at 200 percent text in EN and PT', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final locale in const [Locale('en', 'US'), Locale('pt', 'BR')]) {
      await tester.pumpWidget(
        _LocalizedSelector(
          locale: locale,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}

class _RuntimeLocaleHarness extends StatefulWidget {
  const _RuntimeLocaleHarness();

  @override
  State<_RuntimeLocaleHarness> createState() => _RuntimeLocaleHarnessState();
}

class _RuntimeLocaleHarnessState extends State<_RuntimeLocaleHarness> {
  Locale _locale = const Locale('en', 'US');

  @override
  Widget build(BuildContext context) {
    return _LocalizedSelector(
      locale: _locale,
      onSwitchLocale: () {
        setState(() => _locale = const Locale('pt', 'BR'));
      },
    );
  }
}

class _LocalizedSelector extends StatelessWidget {
  const _LocalizedSelector({
    required this.locale,
    this.textScaler = TextScaler.noScaling,
    this.onSwitchLocale,
  });

  final Locale locale;
  final TextScaler textScaler;
  final VoidCallback? onSwitchLocale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final item = NavigationItem(
            label: l10n.homeNavigationFsaLabel,
            icon: Icons.hub,
            description: l10n.homeNavigationFsaDescription,
          );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: Scaffold(
              body: Column(
                children: [
                  if (onSwitchLocale != null)
                    TextButton(
                      key: const ValueKey('switch-locale'),
                      onPressed: onSwitchLocale,
                      child: const Text('switch'),
                    ),
                  SizedBox(
                    width: 320,
                    child: WorkspaceSelector(
                      items: [item],
                      currentIndex: 0,
                      onSelected: (_) {},
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
