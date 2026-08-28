import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/data/services/manual_conversion_session_store.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/manual_conversion_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hint does not mutate and reveal explicitly completes the step', (
    tester,
  ) async {
    Map<String, Object?>? opened;
    await _pumpWorkspace(tester, onOpenResult: (artifact) => opened = artifact);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Hint'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Read the source edge'), findsOneWidget);
    expect(find.text('Construction complete'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reveal step'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The edge maps directly'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    expect(find.text('Construction complete'), findsOneWidget);
    final openButton = find.byKey(
      const ValueKey('manual-conversion-open-result'),
    );
    expect(tester.widget<FilledButton>(openButton).onPressed, isNotNull);
    await tester.tap(openButton);
    expect(opened, {'regex': 'a'});
  });

  testWidgets('switches reference-backed copy without losing the draft', (
    tester,
  ) async {
    final requirement = ManualConversionRequirement(
      id: 'fa-to-regex.complete',
      contentReference: ManualConversionContent.faToRegexComplete,
      type: ManualConversionActionType.complete,
      title: 'Legacy title',
      instruction: 'Legacy instruction',
      expectedPayload: const {'regex': 'a'},
      allowedPayloadKeys: const {'regex'},
      hint: 'Legacy hint',
      revealExplanation: 'Legacy reveal',
      evidence: ManualConversionEvidence(summary: 'Exact result.'),
    );

    await _pumpWorkspace(
      tester,
      requirements: [requirement],
      locale: const Locale('en'),
    );
    expect(find.textContaining('Read the final regular expression'), findsOne);
    expect(
      find.bySemanticsLabel('Read the final regular expression'),
      findsOne,
    );
    await tester.enterText(find.byType(TextField), 'draft-regex');

    await _pumpWorkspace(
      tester,
      requirements: [requirement],
      locale: const Locale('pt', 'BR'),
    );

    expect(find.textContaining('Leia a expressão regular final'), findsOne);
    expect(find.text('draft-regex'), findsOne);
  });

  testWidgets('stacks panes without overflow at 320 px and 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpWorkspace(tester, textScaler: const TextScaler.linear(2));
    await tester.pumpAndSettle();

    expect(find.text('Source pane'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Learner construction'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Learner construction'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opens the validated learner artifact and compares real evidence',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, Object?>? opened;
      await _pumpWorkspace(
        tester,
        onOpenResult: (artifact) => opened = artifact,
        onApplyPayload: (session, payload) => session.applyValidated(
          requirementId: session.currentRequirement!.id,
          type: session.currentRequirement!.type,
          payload: payload,
          validationEvidence: ManualConversionEvidence(
            summary: 'The learner artifact was compared by the test oracle.',
            certainty: ManualConversionCertainty.exact,
          ),
          learnerArtifact: {'regex': payload['expression']},
        ),
      );

      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Compare'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'learner-a');
      final applyButton = find.byKey(const ValueKey('manual-conversion-apply'));
      await tester.scrollUntilVisible(
        find.text('Learner construction'),
        240,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.scrollUntilVisible(
        applyButton,
        120,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Compare'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('compared by the test oracle'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('manual-conversion-open-result')),
      );
      expect(opened, {'regex': 'learner-a'});
    },
  );

  testWidgets('reveal after a learner step keeps a complete learner artifact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Map<String, Object?>? opened;
    await _pumpWorkspace(
      tester,
      requirements: [_requirement('first', 'a'), _requirement('second', 'b')],
      onOpenResult: (artifact) => opened = artifact,
      onApplyPayload: (session, payload) {
        final previous = session.learnerArtifact?['regex'] as String? ?? '';
        return session.applyValidated(
          requirementId: session.currentRequirement!.id,
          type: session.currentRequirement!.type,
          payload: payload,
          validationEvidence: ManualConversionEvidence(
            summary: 'The revealed value was validated by the test oracle.',
            certainty: ManualConversionCertainty.exact,
          ),
          learnerArtifact: {'regex': '$previous${payload['expression']}'},
        );
      },
    );

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byKey(const ValueKey('manual-conversion-apply')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reveal step'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('manual-conversion-open-result')),
    );

    expect(opened, {'regex': 'ab'});
  });

  testWidgets('restart after a source edit reopens from the canonical key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = await SharedPreferences.getInstance();
    final original = _sessionForSource('old-source', 1);
    final fresh = _sessionForSource('new-source', 2);
    var documentId = 'old-source';
    var revision = 1;
    late StateSetter rebuild;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Scaffold(
                body: ManualConversionWorkspace(
                  title: 'Manual conversion',
                  workspaceKey: 'fa-to-regex.old-source.1',
                  initialSession: original,
                  currentSourceDocumentId: documentId,
                  currentSourceRevision: revision,
                  sourcePreview: const Text('Source'),
                  resultPreviewBuilder: (_) => const Text('Result'),
                  onRestartFromSource: (invalidated) =>
                      invalidated.restartFromNewSource(freshSession: fresh),
                  onOpenResult: (_) {},
                  onClose: () {},
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    rebuild(() {
      documentId = 'new-source';
      revision = 2;
    });
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart from edited source'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reveal step'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    expect(
      preferences.containsKey(
        '${ManualConversionSessionStore.keyPrefix}fa-to-regex.new-source.2',
      ),
      isTrue,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ManualConversionWorkspace(
              title: 'Manual conversion',
              workspaceKey: 'fa-to-regex.new-source.2',
              initialSession: fresh,
              sourcePreview: const Text('Source'),
              resultPreviewBuilder: (_) => const Text('Result'),
              onOpenResult: (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Construction complete'), findsOneWidget);
  });

  testWidgets('custom requirement editor submits through the oracle pipeline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Map<String, Object?>? opened;
    await _pumpWorkspace(
      tester,
      onOpenResult: (artifact) => opened = artifact,
      onApplyPayload: (session, payload) => session.applyValidated(
        requirementId: session.currentRequirement!.id,
        type: session.currentRequirement!.type,
        payload: payload,
        validationEvidence: ManualConversionEvidence(
          summary: 'Custom editor payload validated.',
        ),
        learnerArtifact: {'regex': payload['expression']},
      ),
      requirementEditorBuilder: (context, requirement, onSubmit) {
        return FilledButton(
          onPressed: () => onSubmit({'expression': 'custom'}),
          child: const Text('Submit semantic editor'),
        );
      },
    );

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Submit semantic editor'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('manual-conversion-open-result')),
    );

    expect(opened, {'regex': 'custom'});
  });

  testWidgets('rejects a restored action with a tampered learner artifact', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final initial = _sessionForSource('fa', 1);
    final accepted = initial
        .applyValidated(
          requirementId: initial.currentRequirement!.id,
          type: initial.currentRequirement!.type,
          payload: const {'expression': 'a'},
          validationEvidence: ManualConversionEvidence(
            summary: 'Artifact checked.',
            certainty: ManualConversionCertainty.exact,
          ),
          learnerArtifact: const {'regex': 'a'},
        )
        .session;
    final encoded = jsonDecode(jsonEncode(accepted.toJson())) as Map;
    final action = (encoded['actions']! as List).single as Map;
    action['learnerArtifact'] = {'regex': 'tampered'};
    await preferences.setString(
      '${ManualConversionSessionStore.keyPrefix}widget-test',
      jsonEncode(encoded),
    );

    await _pumpWorkspace(
      tester,
      initialSession: initial,
      onApplyPayload: (session, payload) => session.applyValidated(
        requirementId: session.currentRequirement!.id,
        type: session.currentRequirement!.type,
        payload: payload,
        validationEvidence: ManualConversionEvidence(
          summary: 'Artifact checked.',
          certainty: ManualConversionCertainty.exact,
        ),
        learnerArtifact: {'regex': payload['expression']},
      ),
    );

    expect(
      find.text('Saved learner actions are no longer valid.'),
      findsOneWidget,
    );
    expect(find.text('Construction complete'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('moves focus into the custom editor for the next step', (
    tester,
  ) async {
    final nextFieldFocus = FocusNode();
    addTearDown(nextFieldFocus.dispose);
    await _pumpWorkspace(
      tester,
      requirements: [_requirement('first', 'a'), _requirement('second', 'b')],
      requirementEditorBuilder: (context, requirement, onSubmit) => Column(
        children: [
          TextField(
            focusNode: nextFieldFocus,
            decoration: InputDecoration(labelText: requirement.id),
          ),
          FilledButton(
            onPressed: () => onSubmit(requirement.expectedPayload),
            child: const Text('Submit custom step'),
          ),
        ],
      ),
    );

    final submit = find.text('Submit custom step');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
    expect(nextFieldFocus.hasFocus, isTrue);
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  void Function(Map<String, Object?>)? onOpenResult,
  ManualConversionCommandResult Function(
    ManualConversionSession,
    Map<String, Object?>,
  )?
  onApplyPayload,
  TextScaler textScaler = TextScaler.noScaling,
  List<ManualConversionRequirement>? requirements,
  Widget Function(
    BuildContext,
    ManualConversionRequirement,
    ValueChanged<Map<String, Object?>>,
  )?
  requirementEditorBuilder,
  ManualConversionSession? initialSession,
  Locale locale = const Locale('en'),
}) async {
  final preferences = await SharedPreferences.getInstance();
  final session =
      initialSession ??
      ManualConversionSession.start(
        id: 'widget-session',
        direction: ManualConversionDirection.faToRegex,
        source: ManualConversionSource(
          documentId: 'fa',
          revision: 1,
          snapshot: const {'edge': 't0'},
        ),
        requirements: requirements ?? [_requirement('edge-t0', 'a')],
        canonicalArtifact: const {'regex': 'a'},
        completionEvidence: ManualConversionEvidence(
          summary: 'The languages are equivalent.',
          certainty: ManualConversionCertainty.exact,
        ),
      );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Scaffold(
            body: ManualConversionWorkspace(
              title: 'Manual conversion',
              workspaceKey: 'widget-test',
              initialSession: session,
              sourcePreview: const Center(child: Text('Source pane')),
              resultPreviewBuilder: (_) => const Text('Result pane'),
              onApplyPayload: onApplyPayload,
              requirementEditorBuilder: requirementEditorBuilder,
              onOpenResult: onOpenResult ?? (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ManualConversionRequirement _requirement(String id, String expression) {
  return ManualConversionRequirement(
    id: id,
    contentReference: ManualConversionContent.legacy,
    type: ManualConversionActionType.addTransition,
    title: 'Map edge',
    instruction: 'Enter the expression for $id.',
    expectedPayload: {'expression': expression},
    allowedPayloadKeys: const {'expression'},
    provenanceIds: [id],
    hint: 'Read the source edge label.',
    revealExplanation: 'The edge maps directly to $expression.',
    evidence: ManualConversionEvidence(
      summary: 'The edge mapping is structurally valid.',
    ),
  );
}

ManualConversionSession _sessionForSource(String documentId, int revision) {
  return ManualConversionSession.start(
    id: 'session-$documentId-$revision',
    direction: ManualConversionDirection.faToRegex,
    source: ManualConversionSource(
      documentId: documentId,
      revision: revision,
      snapshot: {'documentId': documentId},
    ),
    requirements: [_requirement('edge-$documentId', 'a')],
    canonicalArtifact: const {'regex': 'a'},
    completionEvidence: ManualConversionEvidence(
      summary: 'The languages are equivalent.',
      certainty: ManualConversionCertainty.exact,
    ),
  );
}
