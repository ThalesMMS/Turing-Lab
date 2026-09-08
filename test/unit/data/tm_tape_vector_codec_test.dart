import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/data/codecs/tm/tm_tape_vector_codec.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

void main() {
  XmlElement transition(String inner) =>
      XmlDocument.parse('<transition>$inner</transition>').rootElement;

  TmTapeVectorOutcome read(
    String inner, {
    int tapeCount = 2,
    TmTapeVectorDialect dialect = TmTapeVectorDialect.classic,
    TapeDirection defaultMove = TapeDirection.right,
  }) => TmTapeVectorCodec.read(
    transition(inner),
    index: 3,
    tapeCount: tapeCount,
    blankSymbol: 'B',
    dialect: dialect,
    defaultMove: defaultMove,
  );

  test('fills every tape and defaults absent operations', () {
    final outcome =
        read(
              '<read tape="1">a</read><write tape="1">b</write>'
              '<move tape="1">L</move><read tape="2"/>',
            )
            as TmTapeVector;
    expect(outcome.reads, ['a', 'B']);
    expect(outcome.writes, ['b', 'B']);
    expect(outcome.moves, [TapeDirection.left, TapeDirection.right]);
  });

  test('the visible blank marker maps to the blank symbol', () {
    final outcome = read('<read>□</read>', tapeCount: 1) as TmTapeVector;
    expect(outcome.reads, ['B']);
  });

  test('classic dialect distinguishes invalid and duplicate tape indexes', () {
    final invalid = read('<read tape="3">a</read>') as TmTapeVectorMalformed;
    expect(invalid.reason, CodecMalformedReason.invalidValue);
    expect(invalid.path, '/structure/automaton/transition[3]/read/@tape');

    final duplicate =
        read('<read tape="1">a</read><read tape="1">b</read>')
            as TmTapeVectorMalformed;
    expect(duplicate.reason, CodecMalformedReason.duplicateIdentity);
    expect(duplicate.path, '/structure/automaton/transition[3]/read');
  });

  test('building-block dialect reports both as one invalid-value failure', () {
    for (final inner in [
      '<read tape="3">a</read>',
      '<read tape="1">a</read><read tape="1">b</read>',
    ]) {
      final outcome =
          read(inner, dialect: TmTapeVectorDialect.buildingBlock)
              as TmTapeVectorMalformed;
      expect(outcome.reason, CodecMalformedReason.invalidValue);
      expect(outcome.path, '/structure/automaton/transition[3]/read');
    }
  });

  test('read predicates are unsupported and multi-unit symbols malformed', () {
    expect(read('<read>~</read>'), isA<TmTapeVectorUnsupported>());
    final classic = read('<write>ab</write>') as TmTapeVectorMalformed;
    expect(classic.path, '/structure/automaton/transition/write');
    final block =
        read('<write>ab</write>', dialect: TmTapeVectorDialect.buildingBlock)
            as TmTapeVectorMalformed;
    expect(block.path, '/structure/automaton/transition[3]/write');
    final move = read('<move>X</move>') as TmTapeVectorMalformed;
    expect(move.path, '/structure/automaton/transition[3]/move');
  });

  test('block transitions can default to staying in place', () {
    final outcome =
        read(
              '',
              dialect: TmTapeVectorDialect.buildingBlock,
              defaultMove: TapeDirection.stay,
            )
            as TmTapeVector;
    expect(outcome.moves, [TapeDirection.stay, TapeDirection.stay]);
  });

  test('writes one triple per tape, self-closing the blank symbol', () {
    final builder = XmlBuilder();
    builder.element(
      'transition',
      nest: () => TmTapeVectorCodec.writeOperations(
        builder,
        TMTransition(
          id: 't',
          fromState: _state('q0'),
          toState: _state('q1'),
          label: 't',
          readSymbols: const ['a', 'B'],
          writeSymbols: const ['B', 'c'],
          directions: const [TapeDirection.left, TapeDirection.stay],
        ),
        tapeCount: 2,
        blankSymbol: 'B',
      ),
    );
    final xml = builder.buildDocument().toXmlString();
    expect(
      xml,
      '<transition><read tape="1">a</read><write tape="1"/>'
      '<move tape="1">L</move><read tape="2"/><write tape="2">c</write>'
      '<move tape="2">S</move></transition>',
    );
  });
}

State _state(String id) => State(
  id: id,
  label: id,
  position: Vector2.zero(),
  isInitial: id == 'q0',
  isAccepting: id == 'q1',
);
