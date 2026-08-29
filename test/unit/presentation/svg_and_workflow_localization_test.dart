import 'dart:math';

import 'package:flutter/material.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/svg_export_defaults.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations pt;
  late AppLocalizations en;

  setUpAll(() async {
    pt = await AppLocalizations.delegate.load(const Locale('pt'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  FSA emptyFsa() {
    final now = DateTime(2026, 1, 1);
    return FSA(
      id: 'empty',
      name: 'Empty',
      states: <State>{},
      transitions: <Transition>{},
      alphabet: <String>{},
      acceptingStates: <State>{},
      created: now,
      modified: now,
      bounds: const Rectangle<double>(0, 0, 100, 100),
    );
  }

  test(
    'empty SVG uses English placeholder by default and Portuguese when asked',
    () {
      final defaultSvg = SvgExporter.exportFsaToSvg(emptyFsa());
      expect(defaultSvg, contains(kDefaultSvgEmptyAutomatonLabel));
      expect(defaultSvg, contains('class="empty-automaton"'));

      final ptSvg = SvgExporter.exportFsaToSvg(
        emptyFsa(),
        options: SvgExportOptions(emptyAutomatonLabel: pt.svgNoStatesDefined),
      );
      expect(ptSvg, contains(pt.svgNoStatesDefined));
      expect(ptSvg, isNot(contains(kDefaultSvgEmptyAutomatonLabel)));
      expect(en.svgNoStatesDefined, kDefaultSvgEmptyAutomatonLabel);
    },
  );

  test('TM SVG legend is localized instead of hardcoded Portuguese', () {
    expect(pt.svgTmLegend, isNot(en.svgTmLegend));
    expect(en.svgTmLegend, contains('read'));
    expect(pt.svgTmLegend, contains('leitura'));
  });

  test('SVG excludes annotations by default and includes them explicitly', () {
    final timestamp = DateTime.utc(2026);
    final annotations = DocumentAnnotationCollection(
      documentId: 'empty',
      documentRevision: '1',
      annotations: [
        DocumentAnnotation(
          id: 'note-1',
          documentId: 'empty',
          documentRevision: '1',
          text: 'Review <this> & that',
          x: 20,
          y: 40,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    );

    final excluded = SvgExporter.exportFsaToSvg(
      emptyFsa(),
      options: SvgExportOptions(annotations: annotations),
    );
    final included = SvgExporter.exportFsaToSvg(
      emptyFsa(),
      options: SvgExportOptions(
        annotations: annotations,
        includeAnnotations: true,
      ),
    );

    expect(excluded, isNot(contains('class="annotations"')));
    expect(included, contains('class="annotations"'));
    expect(included, contains('Review &lt;this&gt; &amp; that'));
  });

  test('Portuguese workflow adapter localizes core algorithm prose', () {
    expect(
      pt.localizeWorkflowText('Compute initial ε-closure'),
      'Calcular o ε-fecho inicial',
    );
    expect(
      pt.localizeWorkflowText('Introduce new start symbol'),
      'Introduzir novo símbolo inicial',
    );
    expect(
      pt.localizeWorkflowText('Read symbol "a" from the input.'),
      'Leu o símbolo "a" da entrada.',
    );
    expect(
      pt.localizeWorkflowText(
        'Turing Lab could not write to the selected location. '
        'The file may be outside the app sandbox or no longer writable. '
        'Choose a destination again from the system save dialog and try again.',
      ),
      contains('não conseguiu gravar'),
    );
    expect(
      en.localizeWorkflowText('Introduce new start symbol'),
      'Introduce new start symbol',
    );
    expect(pt.localizeWorkflowText('steps'), 'passos');
    expect(pt.localizeWorkflowText('Step limit'), 'Limite de passos');
  });
}
