//
//  import_error_dialog_goldens_test.dart
//  Turing Lab
//
//  Testes golden de regressão visual para o diálogo de erro de importação,
//  capturando snapshots de todos os tipos de erro (JFF malformado, JSON
//  inválido, versão não suportada, dados corrompidos, autômato inválido),
//  com e sem detalhes técnicos, em estados expandidos/colapsados. Garante
//  consistência visual das mensagens de erro entre mudanças e detecta
//  regressões automáticas.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:turing_lab/presentation/widgets/import_error_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImportErrorDialog golden tests', () {
    testGoldens('renders malformed JFF error', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'automaton.jff',
          errorType: ImportErrorType.malformedJFF,
          detailedMessage:
              'The file structure does not conform to JFLAP format specifications. Please ensure the file was exported correctly from JFLAP.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_malformed_jff');
    });

    testGoldens('renders invalid JSON error', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'automaton.json',
          errorType: ImportErrorType.invalidJSON,
          detailedMessage:
              'The JSON file contains syntax errors or is not properly formatted. Please check the file for missing brackets, commas, or quotes.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_invalid_json');
    });

    testGoldens('renders unsupported version error', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'old_automaton.jff',
          errorType: ImportErrorType.unsupportedVersion,
          detailedMessage:
              'This file was created with a version of JFLAP that is not supported. Please try converting it to a newer format.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_unsupported_version');
    });

    testGoldens('renders inaccessible file error', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'icloud_drive_automaton.json',
          errorType: ImportErrorType.inaccessibleFile,
          detailedMessage:
              'Turing Lab could not access the selected file. Pick it again from the system dialog and keep it available until the import finishes.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_inaccessible_file');
    });

    testGoldens('renders corrupted data error', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'damaged_file.jff',
          errorType: ImportErrorType.corruptedData,
          detailedMessage:
              'The file appears to be damaged or incomplete. Try re-exporting from the original source or restoring from a backup.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_corrupted_data');
    });

    testGoldens('renders invalid automaton error', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'broken_automaton.jff',
          errorType: ImportErrorType.invalidAutomaton,
          detailedMessage:
              'The automaton definition is incomplete or invalid. Check for missing states, invalid transitions, or undefined symbols.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_invalid_automaton');
    });

    testGoldens('renders with technical details collapsed', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'error_automaton.jff',
          errorType: ImportErrorType.malformedJFF,
          detailedMessage:
              'The parser encountered unexpected tags while reading the file.',
          technicalDetails:
              'XmlParseException at line 42: Unexpected closing tag </state>. Expected </transition>.\nStack trace:\n  at XmlParser.parse (xml_parser.dart:156)\n  at JffImporter.import (jff_importer.dart:89)',
          showTechnicalDetails: false,
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 500),
      );

      await screenMatchesGolden(
        tester,
        'import_error_technical_details_collapsed',
      );
    });

    testGoldens('renders with technical details expanded', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'error_automaton.jff',
          errorType: ImportErrorType.malformedJFF,
          detailedMessage:
              'The parser encountered unexpected tags while reading the file.',
          technicalDetails:
              'XmlParseException at line 42: Unexpected closing tag </state>. Expected </transition>.\nStack trace:\n  at XmlParser.parse (xml_parser.dart:156)\n  at JffImporter.import (jff_importer.dart:89)',
          showTechnicalDetails: true,
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 600),
      );

      await screenMatchesGolden(
        tester,
        'import_error_technical_details_expanded',
      );
    });

    testGoldens('renders with long file name', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName:
              'very_long_automaton_file_name_that_might_need_truncation.jff',
          errorType: ImportErrorType.invalidJSON,
          detailedMessage: 'Unable to parse the JSON structure in this file.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_long_filename');
    });

    testGoldens('renders with short file name', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'a.jff',
          errorType: ImportErrorType.corruptedData,
          detailedMessage: 'The file is corrupted and cannot be read.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_short_filename');
    });

    testGoldens('renders with long detailed message', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'complex_automaton.jff',
          errorType: ImportErrorType.invalidAutomaton,
          detailedMessage:
              'The automaton definition contains several critical issues: '
              'State q0 is referenced but not defined, transition from q1 to q2 '
              'uses an undefined symbol "x", the initial state marker is missing, '
              'and multiple final states have conflicting labels. Please review '
              'the automaton structure carefully and ensure all components are '
              'properly defined according to JFLAP specifications.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 500),
      );

      await screenMatchesGolden(tester, 'import_error_long_message');
    });

    testGoldens('renders with minimal message', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'file.jff',
          errorType: ImportErrorType.malformedJFF,
          detailedMessage: 'Invalid file.',
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 350),
      );

      await screenMatchesGolden(tester, 'import_error_minimal_message');
    });

    testGoldens('renders with complex technical details', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'automaton.jff',
          errorType: ImportErrorType.corruptedData,
          detailedMessage:
              'Multiple data integrity issues detected during import.',
          technicalDetails: 'Error: CRC mismatch at byte offset 1024\n'
              'Expected: 0x4A5F4C41\n'
              'Actual: 0x00000000\n\n'
              'Additional errors:\n'
              '- Missing XML declaration\n'
              '- Truncated content at position 2048\n'
              '- Invalid UTF-8 sequence at line 15\n\n'
              'Stack trace:\n'
              '#0 DataValidator.verify (validator.dart:234)\n'
              '#1 FileImporter.validateIntegrity (importer.dart:167)\n'
              '#2 ImportService.import (service.dart:89)',
          showTechnicalDetails: true,
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 700),
      );

      await screenMatchesGolden(
        tester,
        'import_error_complex_technical_details',
      );
    });

    testGoldens('renders without technical details', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'simple_error.jff',
          errorType: ImportErrorType.unsupportedVersion,
          detailedMessage:
              'This file version is not supported by the current application.',
          technicalDetails: null,
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_no_technical_details');
    });

    testGoldens('renders with empty technical details', (tester) async {
      await tester.pumpWidgetBuilder(
        ImportErrorDialog(
          fileName: 'empty_details.jff',
          errorType: ImportErrorType.invalidJSON,
          detailedMessage: 'JSON parsing failed.',
          technicalDetails: '',
          showTechnicalDetails: false,
          onRetry: () {},
          onCancel: () {},
        ),
        surfaceSize: const Size(600, 400),
      );

      await screenMatchesGolden(tester, 'import_error_empty_technical_details');
    });
  });
}
