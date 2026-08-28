import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/tm_advanced_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt', 'BR'));

  test('localizes TM batch and building-block trace copy', () {
    const sources = [
      'Batch testing',
      'Run ordered, bounded TM simulations',
      'TM batch execution',
      'Nested call trace',
      'Call stack: root',
      '3 calls · maximum depth 2',
      'Enter scan',
      'Transition t0',
      'Return to root',
      'Call stack: root > invoke_scan',
    ];

    for (final source in sources) {
      if (source.contains('calls ·')) {
        expect(en.tmBlockTraceSummary(3, 2), source);
      } else if (source.startsWith('Enter ') ||
          source.startsWith('Transition ') ||
          source.startsWith('Return to ')) {
        expect(en.tmBlockTraceAction(source), source);
      } else if (source.startsWith('Call stack: ')) {
        final stack = source == 'Call stack: root'
            ? const <String>[]
            : source.substring('Call stack: '.length).split(' > ');
        expect(en.tmBlockCallStackLabel(stack), source);
      } else {
        expect(en.tmAdvancedText(source), source);
      }
    }

    expect(pt.tmAdvancedText('Batch testing'), 'Testes em lote');
    expect(
      pt.tmAdvancedText('Run ordered, bounded TM simulations'),
      'Execute simulações de MT ordenadas e limitadas',
    );
    expect(pt.tmAdvancedText('TM batch execution'), 'Execução em lote de MT');
    expect(
      pt.tmAdvancedText('Nested call trace'),
      'Traço de chamadas aninhadas',
    );
    expect(pt.tmBlockCallStackLabel(const []), 'Pilha de chamadas: raiz');
    expect(pt.tmBlockTraceSummary(3, 2), '3 chamadas · profundidade máxima 2');
    expect(pt.tmBlockTraceAction('Enter scan'), 'Entrar em scan');
    expect(pt.tmBlockTraceAction('Transition t0'), 'Transição t0');
    expect(pt.tmBlockTraceAction('Return to root'), 'Retornar para root');
    expect(
      pt.tmBlockCallStackLabel(const ['root', 'invoke_scan']),
      'Pilha de chamadas: root > invoke_scan',
    );
  });
}
