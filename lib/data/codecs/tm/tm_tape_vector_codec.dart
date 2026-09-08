//
//  tm_tape_vector_codec.dart
//  Turing Lab
//
//  Per-tape read/write/move vectors of JFLAP TM transitions: reading them
//  from XML in the classic and building-block dialects, writing them back,
//  and the symbol rules JFLAP can represent atomically.
//

import 'package:xml/xml.dart';

import '../../../core/interoperability/interoperability.dart';
import '../../../core/messages/structured_message.dart';
import '../../../core/models/tm.dart';
import '../../../core/models/tm_transition.dart';
import '../codec_utils.dart';
import '../tm_jflap_messages.dart';

/// Which JFLAP TM dialect produced a transition; they report tape-index
/// problems with different messages and paths.
enum TmTapeVectorDialect { classic, buildingBlock }

sealed class TmTapeVectorOutcome {
  const TmTapeVectorOutcome();
}

final class TmTapeVector extends TmTapeVectorOutcome {
  const TmTapeVector({
    required this.reads,
    required this.writes,
    required this.moves,
  });

  final List<String> reads;
  final List<String> writes;
  final List<TapeDirection> moves;
}

final class TmTapeVectorMalformed extends TmTapeVectorOutcome {
  const TmTapeVectorMalformed({
    required this.reason,
    required this.message,
    required this.path,
    required this.structuredMessage,
  });

  final CodecMalformedReason reason;
  final String message;
  final String path;
  final StructuredMessage structuredMessage;
}

final class TmTapeVectorUnsupported extends TmTapeVectorOutcome {
  const TmTapeVectorUnsupported({
    required this.message,
    required this.structuredMessage,
  });

  final String message;
  final StructuredMessage structuredMessage;
}

abstract final class TmTapeVectorCodec {
  static TapeDirection? direction(String raw) =>
      switch (raw.trim().toUpperCase()) {
        'L' => TapeDirection.left,
        'R' => TapeDirection.right,
        'S' => TapeDirection.stay,
        _ => null,
      };

  static bool usesJflapReadPredicate(String symbol) =>
      symbol == '~' || symbol.startsWith('!') || symbol.contains('}');

  static String jflapSymbol(String value, String blankSymbol) =>
      value.isEmpty || value == '□' ? blankSymbol : value;

  static String signature(
    String from,
    String to,
    List<String> reads,
    List<String> writes,
    List<TapeDirection> moves,
  ) => canonicalJson({
    'from': from,
    'to': to,
    'read': reads,
    'write': writes,
    'move': moves.map((move) => move.symbol).toList(),
  });

  /// Reads the `<read>`, `<write>` and `<move>` children of a transition
  /// element into per-tape vectors. Absent operations default to the blank
  /// symbol and [defaultMove].
  static TmTapeVectorOutcome read(
    XmlElement element, {
    required int index,
    required int tapeCount,
    required String blankSymbol,
    required TmTapeVectorDialect dialect,
    TapeDirection defaultMove = TapeDirection.right,
  }) {
    final reads = List<String>.filled(tapeCount, blankSymbol);
    final writes = List<String>.filled(tapeCount, blankSymbol);
    final moves = List<TapeDirection>.filled(tapeCount, defaultMove);
    final classic = dialect == TmTapeVectorDialect.classic;
    final seen = <String>{};
    for (final tag in const ['read', 'write', 'move']) {
      for (final child in element.findElements(tag)) {
        final tape = int.tryParse(child.getAttribute('tape') ?? '1');
        final invalidTape = tape == null || tape < 1 || tape > tapeCount;
        if (classic) {
          if (invalidTape) {
            return TmTapeVectorMalformed(
              reason: CodecMalformedReason.invalidValue,
              message: 'JFLAP TM transition has an invalid tape index.',
              path: '/structure/automaton/transition[$index]/$tag/@tape',
              structuredMessage: TmJflapMessages.invalidTapeIndex(),
            );
          }
          if (!seen.add('$tag:$tape')) {
            return TmTapeVectorMalformed(
              reason: CodecMalformedReason.duplicateIdentity,
              message: 'JFLAP TM transition repeats $tag for tape $tape.',
              path: '/structure/automaton/transition[$index]/$tag',
              structuredMessage: TmJflapMessages.duplicateTapeOperation(tag),
            );
          }
        } else if (invalidTape || !seen.add('$tag:$tape')) {
          return TmTapeVectorMalformed(
            reason: CodecMalformedReason.invalidValue,
            message:
                'JFLAP TM transition has an invalid or duplicate tape index.',
            path: '/structure/automaton/transition[$index]/$tag',
            structuredMessage: TmJflapMessages.invalidOrDuplicateTapeIndex(),
          );
        }
        // The classic dialect historically reported symbol errors without the
        // transition index; keep the paths stable for existing consumers.
        final symbolPath = classic
            ? '/structure/automaton/transition'
            : '/structure/automaton/transition[$index]';
        final value = child.innerText;
        if (tag == 'read') {
          if (usesJflapReadPredicate(value)) {
            return TmTapeVectorUnsupported(
              message:
                  'JFLAP wildcard, negated, and variable TM reads are not supported.',
              structuredMessage: TmJflapMessages.unsupportedReadPredicate(),
            );
          }
          if (value.isNotEmpty && value.length != 1) {
            return TmTapeVectorMalformed(
              reason: CodecMalformedReason.invalidValue,
              message:
                  'JFLAP TM read symbols must contain one UTF-16 code unit.',
              path: '$symbolPath/read',
              structuredMessage: TmJflapMessages.invalidReadSymbol(),
            );
          }
          reads[tape - 1] = jflapSymbol(value, blankSymbol);
        }
        if (tag == 'write') {
          if (value.isNotEmpty && value.length != 1) {
            return TmTapeVectorMalformed(
              reason: CodecMalformedReason.invalidValue,
              message:
                  'JFLAP TM write symbols must contain one UTF-16 code unit.',
              path: '$symbolPath/write',
              structuredMessage: TmJflapMessages.invalidWriteSymbol(),
            );
          }
          writes[tape - 1] = jflapSymbol(value, blankSymbol);
        }
        if (tag == 'move') {
          final resolved = direction(value);
          if (resolved == null) {
            return TmTapeVectorMalformed(
              reason: CodecMalformedReason.invalidValue,
              message: 'JFLAP TM movement must be L, R, or S.',
              path: '/structure/automaton/transition[$index]/move',
              structuredMessage: TmJflapMessages.invalidMove(),
            );
          }
          moves[tape - 1] = resolved;
        }
      }
    }
    return TmTapeVector(reads: reads, writes: writes, moves: moves);
  }

  /// Writes one `<read>`, `<write>` and `<move>` triple per tape.
  static void writeOperations(
    XmlBuilder builder,
    TMTransition transition, {
    required int tapeCount,
    required String blankSymbol,
  }) {
    final operations = transition.operationsForTapeCount(
      tapeCount,
      blankSymbol,
    );
    for (var tape = 0; tape < tapeCount; tape++) {
      final attributes = tapeCount > 1
          ? <String, String>{'tape': '${tape + 1}'}
          : const <String, String>{};
      writeSymbol(
        builder,
        'read',
        operations.readSymbols[tape],
        blankSymbol,
        attributes,
      );
      writeSymbol(
        builder,
        'write',
        operations.writeSymbols[tape],
        blankSymbol,
        attributes,
      );
      builder.element(
        'move',
        attributes: attributes,
        nest: operations.directions[tape].symbol,
      );
    }
  }

  static void writeSymbol(
    XmlBuilder builder,
    String name,
    String symbol,
    String blankSymbol,
    Map<String, String> attributes,
  ) {
    if (symbol == blankSymbol) {
      builder.element(name, attributes: attributes, isSelfClosing: true);
    } else {
      builder.element(name, attributes: attributes, nest: symbol);
    }
  }

  /// First read or write symbol JFLAP cannot represent atomically, if any.
  static ({String message, StructuredMessage structuredMessage})?
  unsupportedOperation(TM machine) {
    for (final transition in machine.tmTransitions) {
      final operations = transition.operationsForTapeCount(
        machine.tapeCount,
        machine.blankSymbol,
      );
      for (var tape = 0; tape < machine.tapeCount; tape++) {
        final read = operations.readSymbols[tape];
        final write = operations.writeSymbols[tape];
        if (read != machine.blankSymbol &&
            (usesJflapReadPredicate(read) || read.length != 1)) {
          return (
            message:
                'Transition ${transition.id} uses a read symbol that JFLAP '
                'cannot represent atomically.',
            structuredMessage: TmJflapMessages.unsupportedOperation(
              transitionId: transition.id,
              operation: 'read',
              symbol: read,
            ),
          );
        }
        if (write != machine.blankSymbol && write.length != 1) {
          return (
            message:
                'Transition ${transition.id} uses a write symbol that JFLAP '
                'cannot represent atomically.',
            structuredMessage: TmJflapMessages.unsupportedOperation(
              transitionId: transition.id,
              operation: 'write',
              symbol: write,
            ),
          );
        }
      }
    }
    return null;
  }
}
