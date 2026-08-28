import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/presentation/widgets/document_annotations.dart';

// feature-localization-contract: interoperability-notes-and-export
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: locale-switch-state-preservation
// feature-localization-surface: formal-content-preservation
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets(
    'document notes stay bilingual and preserve text across locales',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: ValueListenableBuilder<Locale>(
            valueListenable: locale,
            builder: (context, value, child) => MaterialApp(
              locale: value,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const Scaffold(
                body: SizedBox(
                  height: 600,
                  child: DocumentAnnotationsPanel(
                    systemKey: DefaultFormalSystemIds.grammar,
                    documentId: 'grammar-localization',
                    documentRevision: '1',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final en = AppLocalizationsEn();
      final pt = AppLocalizationsPt();
      expect(find.text(en.documentNotesTitle), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, en.documentNoteAdd),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, en.documentNoteAdd));
      await tester.pumpAndSettle();
      expect(find.text(en.documentNoteEditTitle), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, en.documentNoteTextLabel),
        'Keep this production note',
      );
      await tester.tap(find.widgetWithText(FilledButton, en.saveChanges));
      await tester.pumpAndSettle();

      expect(find.text('Keep this production note'), findsOneWidget);
      locale.value = const Locale('pt');
      await tester.pumpAndSettle();

      expect(find.text(pt.documentNotesTitle), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, pt.documentNoteAdd),
        findsOneWidget,
      );
      expect(find.text('Keep this production note'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, pt.documentNoteSearch),
        'inexistente',
      );
      await tester.pump();
      expect(find.text(pt.documentNoteNoMatches), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, pt.documentNoteSearch),
        '',
      );
      await tester.pump();
      expect(find.text('Keep this production note'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('panel adds, edits, and searches notes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: DocumentAnnotationsPanel(
                systemKey: DefaultFormalSystemIds.grammar,
                documentId: 'grammar-1',
                documentRevision: '1',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('No matching notes.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Note text'),
      'Explain **production**',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Explain **production**'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Search notes'),
      'missing',
    );
    await tester.pump();
    expect(find.text('No matching notes.'), findsOneWidget);
  });

  testWidgets('card remains operable at large text scale', (tester) async {
    final timestamp = DateTime.utc(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              height: 220,
              child: DocumentAnnotationCard(
                annotation: DocumentAnnotation(
                  id: 'note-1',
                  documentId: 'doc-1',
                  documentRevision: '1',
                  text: 'Use **bold**, _italic_, and `code`.',
                  x: 0,
                  y: 0,
                  width: 360,
                  height: 220,
                  createdAt: timestamp,
                  updatedAt: timestamp,
                ),
                attachmentResolved: true,
                onDragUpdate: (_) {},
                onDragEnd: () {},
                onEdit: () {},
                onDuplicate: () {},
                onToggleCollapsed: () {},
                onDelete: () {},
                onResize: (_) {},
                onResizeEnd: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp(r'Use \*\*bold\*\*')), findsOneWidget);
    expect(find.byTooltip('Note actions'), findsOneWidget);
  });

  testWidgets('a focused card supports keyboard actions', (tester) async {
    var duplicated = false;
    final timestamp = DateTime.utc(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: DocumentAnnotationCard(
              annotation: DocumentAnnotation(
                id: 'note-1',
                documentId: 'doc-1',
                documentRevision: '1',
                text: 'Keyboard note',
                x: 0,
                y: 0,
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
              attachmentResolved: true,
              onDragUpdate: (_) {},
              onDragEnd: () {},
              onEdit: () {},
              onDuplicate: () => duplicated = true,
              onToggleCollapsed: () {},
              onDelete: () {},
              onResize: (_) {},
              onResizeEnd: () {},
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(duplicated, isTrue);
  });
}
