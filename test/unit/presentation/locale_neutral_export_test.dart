import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/fsa_jflap_codec.dart';
import 'package:turing_lab/presentation/localization/locale_value_formatter.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('display metrics are localized without changing their source value', () {
    const metric = 1234.5;

    expect(
      LocaleValueFormatter(const Locale('en')).decimal(metric),
      '1,234.50',
    );
    expect(
      LocaleValueFormatter(const Locale('pt', 'BR')).decimal(metric),
      '1.234,50',
    );

    final report = _batchReport(metric: metric);
    final values = report.results.single.metrics;
    expect(values['steps'], metric);
    final encoded =
        jsonDecode(BatchReportEncoder.json(report)) as Map<String, dynamic>;
    final encodedResult =
        (encoded['results'] as List).single as Map<String, dynamic>;
    expect((encodedResult['metrics'] as Map)['steps'], metric);
  });

  test('JSON and JFLAP XML exports are byte-stable across locales', () {
    final document = _fsaDocument();
    final registry = DefaultDocumentInteroperabilityRegistry.create();

    final englishJson = _withDefaultLocale('en_US', () {
      return _encodedText(
        registry.encode(
          document,
          format: DefaultFormalSystemIds.turingLabJsonFormat,
        ),
      );
    });
    final portugueseJson = _withDefaultLocale('pt_BR', () {
      return _encodedText(
        registry.encode(
          document,
          format: DefaultFormalSystemIds.turingLabJsonFormat,
        ),
      );
    });

    final englishXml = _withDefaultLocale('en_US', () {
      return _encodedText(const FsaJflapDocumentCodec().encode(document));
    });
    final portugueseXml = _withDefaultLocale('pt_BR', () {
      return _encodedText(const FsaJflapDocumentCodec().encode(document));
    });

    expect(portugueseJson, englishJson);
    expect(portugueseXml, englishXml);
    expect(englishJson, contains('12.5'));
    expect(englishJson, contains('-34.75'));
    expect(englishXml, contains('<x>12.5</x>'));
    expect(englishXml, contains('<y>-34.75</y>'));
    expect(englishJson, isNot(contains('12,5')));
    expect(englishXml, isNot(contains('-34,75')));
  });

  test('batch JSON and CSV exports keep numeric fields locale-neutral', () {
    final report = _batchReport(metric: 1234.5);
    final english = _withDefaultLocale('en_US', () {
      return (
        json: BatchReportEncoder.json(report),
        csv: BatchReportEncoder.csv(report),
      );
    });
    final portuguese = _withDefaultLocale('pt_BR', () {
      return (
        json: BatchReportEncoder.json(report),
        csv: BatchReportEncoder.csv(report),
      );
    });

    expect(portuguese.json, english.json);
    expect(portuguese.csv, english.csv);
    expect(english.json, contains('"steps": 1234.5'));
    expect(english.csv, contains(',1234.5,'));
    expect(english.json, isNot(contains('1.234,5')));
    expect(english.csv, isNot(contains('1.234,5')));
  });
}

T _withDefaultLocale<T>(String locale, T Function() action) {
  final previous = Intl.defaultLocale;
  Intl.defaultLocale = locale;
  try {
    return action();
  } finally {
    Intl.defaultLocale = previous;
  }
}

String _encodedText(CodecOutcome<EncodedDocument> outcome) {
  final success = outcome as CodecSuccess<EncodedDocument>;
  return utf8.decode(success.value.bytes);
}

InteroperableDocument<Object> _fsaDocument() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(12.5, -34.75),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'estado formal',
    position: Vector2(100.25, 2.5),
    isAccepting: true,
  );
  final transition = FSATransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    inputSymbols: const {'á', 'β'},
    controlPoint: Vector2(-3.5, 8.25),
  );
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return InteroperableDocument<Object>(
    document: FSA(
      id: 'fsa-locale-contract',
      name: 'Locale contract',
      states: {q0, q1},
      transitions: {transition},
      alphabet: const {'á', 'β'},
      initialState: q0,
      acceptingStates: {q1},
      created: epoch,
      modified: epoch,
      bounds: const math.Rectangle<double>(-10.25, -40.5, 120.75, 80.25),
    ),
    systemKey: DefaultFormalSystemIds.fsa,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.fsa'),
      version: DocumentSchemaVersion(1),
    ),
  );
}

BatchExecutionReport _batchReport({required double metric}) {
  final inputCase = BatchInputCase(id: 'case-0', input: 'áβ');
  final request = BatchExecutionRequest(
    modelId: 'fsa-locale-contract',
    modelRevision: 'r1',
    strategyId: 'simulate',
    tokenizationMode: BatchTokenizationMode.unicodeScalar,
    cases: [inputCase],
    sharedLimits: const BatchExecutionLimits(
      maxSteps: 1200,
      maxConfigurations: 3400,
      timeout: Duration(milliseconds: 1250),
    ),
  );
  return BatchExecutionReport(
    request: request,
    results: [
      BatchCaseResult(
        inputCase: inputCase,
        outcome: BatchOutcomeCode.accepted,
        output: const ['áβ'],
        metrics: {'steps': metric, 'configurations': 2},
        elapsed: const Duration(microseconds: 987654),
      ),
    ],
    startedAt: DateTime.utc(2026, 8, 27, 12, 34, 56, 789),
    elapsed: const Duration(milliseconds: 1500),
  );
}
