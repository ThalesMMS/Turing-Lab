//
//  grammar_analysis_result_formatter.dart
//  Turing Lab
//
//  Text rendering of grammar transformation and LL(1) analysis reports for
//  the results card. Pure: it only depends on the localized strings.
//

import '../../../core/algorithms/grammar/grammar_analyzer.dart';
import '../../../core/models/grammar.dart';
import '../../../core/models/grammar_diagnostic.dart';
import '../../../core/utils/epsilon_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_structured_messages.dart';
import '../../../l10n/app_localizations_workflows.dart';

class GrammarAnalysisResultFormatter {
  const GrammarAnalysisResultFormatter(this.strings);

  final AppLocalizations strings;

  String formatTransformation({
    required String title,
    required Grammar original,
    required Grammar transformed,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('')
      ..writeln(strings.originalGrammarLabel)
      ..writeln(formatGrammar(original))
      ..writeln('')
      ..writeln(strings.transformedGrammarLabel)
      ..writeln(formatGrammar(transformed));

    _appendSection(buffer, strings.notesSection, notes);
    _appendSection(buffer, strings.derivationsSection, derivations);

    return buffer.toString();
  }

  String formatSets({
    required String title,
    required String setName,
    required Map<String, Set<String>> sets,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final entries = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('');

    for (final entry in entries) {
      final values = entry.value.toList()..sort(_symbolComparator);
      buffer.writeln('$setName(${entry.key}) = {${values.join(', ')}}');
    }

    _appendSection(buffer, strings.notesSection, notes);
    _appendSection(buffer, strings.derivationsSection, derivations);

    return buffer.toString();
  }

  String formatParseTable(GrammarAnalysisReport<LL1ParseTable> report) {
    final table = report.value;
    final terminals = table.terminals.toList()..sort(_symbolComparator);
    final nonTerminals = table.nonTerminals.toList()..sort(_symbolComparator);
    final buffer = StringBuffer()
      ..writeln(strings.ll1ParseTableAnalysis)
      ..writeln('');

    buffer.writeln(['NT', ...terminals].join('\t'));
    for (final nt in nonTerminals) {
      final row = <String>[nt];
      for (final terminal in terminals) {
        final entries = table.table[nt]?[terminal] ?? const <List<String>>[];
        if (entries.isEmpty) {
          row.add('-');
        } else {
          row.add(
            entries
                .map(
                  (symbols) =>
                      symbols.isEmpty ? kEpsilonSymbol : symbols.join(' '),
                )
                .join(' | '),
          );
        }
      }
      buffer.writeln(row.join('\t'));
    }

    _appendSection(buffer, strings.notesSection, report.notes);
    _appendSection(buffer, strings.conflictsSection, report.conflicts);
    _appendSection(buffer, strings.derivationsSection, report.derivations);

    return buffer.toString();
  }

  String formatAmbiguity(GrammarAnalysisReport<bool> report) {
    final status = report.value
        ? strings.ll1NoConflicts
        : strings.notLl1Conflicts;
    final buffer = StringBuffer()
      ..writeln(strings.ll1Classification)
      ..writeln('')
      ..writeln(strings.classificationLabel(status));

    _appendSection(buffer, strings.notesSection, [
      ...report.structuredNotes.map(strings.resolveStructuredMessage),
      ...report.notes.map(strings.localizeWorkflowText),
    ]);
    _appendSection(buffer, strings.conflictsSection, report.conflicts);
    _appendSection(buffer, strings.derivationsSection, report.derivations);

    return buffer.toString();
  }

  String formatGrammar(Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final grouped = <String, List<String>>{};

    for (final production in productions) {
      if (production.leftSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.first;
      final right = production.isLambda || production.rightSide.isEmpty
          ? kEpsilonSymbol
          : production.rightSide.join(' ');
      grouped.putIfAbsent(left, () => <String>[]).add(right);
    }

    final nonTerminals = grouped.keys.toList()..sort(_symbolComparator);
    return nonTerminals
        .map((nt) => '$nt → ${grouped[nt]!.join(' | ')}')
        .join('\n');
  }

  void _appendSection(StringBuffer buffer, String title, List<String> entries) {
    if (entries.isEmpty) {
      return;
    }

    buffer
      ..writeln('')
      ..writeln('$title:');
    for (final entry in entries) {
      buffer.writeln('- $entry');
    }
  }

  String formatError(String heading, List<String> messages) {
    final buffer = StringBuffer()
      ..writeln(heading)
      ..writeln('');

    for (final message in messages) {
      buffer.writeln('- $message');
    }

    return buffer.toString();
  }

  String diagnosticMessage(GrammarDiagnostic diagnostic) {
    final structured = diagnostic.structuredMessage;
    return structured == null
        ? strings.localizeWorkflowText(diagnostic.message)
        : strings.resolveStructuredMessage(structured);
  }

  int _symbolComparator(String a, String b) {
    if (a == b) {
      return 0;
    }
    return a.compareTo(b);
  }
}
