import 'app_localizations.dart';

/// Presentation copy for the Turing-machine batch and building-block traces.
///
/// These labels describe UI-only data that is not persisted in a document.
/// State, machine, transition, and invocation identifiers remain unchanged.
extension AppLocalizationsTmAdvanced on AppLocalizations {
  String tmAdvancedText(String source) {
    if (!localeName.startsWith('pt')) return source;
    return switch (source) {
      'Batch testing' => 'Testes em lote',
      'Run ordered, bounded TM simulations' =>
        'Execute simulações de MT ordenadas e limitadas',
      'TM batch execution' => 'Execução em lote de MT',
      'Nested call trace' => 'Traço de chamadas aninhadas',
      _ => source,
    };
  }

  String tmBlockTraceSummary(int calls, int maximumDepth) {
    if (!localeName.startsWith('pt')) {
      final callLabel = calls == 1 ? 'call' : 'calls';
      return '$calls $callLabel · maximum depth $maximumDepth';
    }
    final callLabel = calls == 1 ? 'chamada' : 'chamadas';
    return '$calls $callLabel · profundidade máxima $maximumDepth';
  }

  String tmBlockTraceAction(String source) {
    if (!localeName.startsWith('pt')) return source;
    if (source.startsWith('Enter ')) return 'Entrar em ${source.substring(6)}';
    if (source.startsWith('Transition ')) {
      return 'Transição ${source.substring(11)}';
    }
    if (source.startsWith('Return to ')) {
      return 'Retornar para ${source.substring(10)}';
    }
    return source;
  }

  String tmBlockCallStackLabel(Iterable<String> stack) {
    if (!localeName.startsWith('pt')) {
      return 'Call stack: ${stack.isEmpty ? 'root' : stack.join(' > ')}';
    }
    if (stack.isEmpty) return 'Pilha de chamadas: raiz';
    return 'Pilha de chamadas: ${stack.join(' > ')}';
  }
}
