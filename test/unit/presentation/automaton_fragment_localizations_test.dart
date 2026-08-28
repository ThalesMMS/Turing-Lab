import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/automaton_fragments/automaton_fragments.dart';
import 'package:turing_lab/core/interoperability/codec_outcome.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/automaton_fragment_localizations.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('keeps fragment diagnostics in English for the English locale', () {
    const diagnostic = AutomatonFragmentDiagnostic(
      code: AutomatonFragmentDiagnosticCode.pdaAcceptanceModeConflict,
      severity: AutomatonFragmentDiagnosticSeverity.blocking,
      message:
          'PDA acceptance modes differ and require an explicit conversion plan.',
    );

    expect(
      en.localizedAutomatonFragmentDiagnostic(diagnostic),
      diagnostic.message,
    );
  });

  test('translates fragment diagnostics and dynamic transition IDs to PT', () {
    const acceptance = AutomatonFragmentDiagnostic(
      code: AutomatonFragmentDiagnosticCode.pdaAcceptanceModeConflict,
      severity: AutomatonFragmentDiagnosticSeverity.blocking,
      message:
          'PDA acceptance modes differ and require an explicit conversion plan.',
    );
    const dangling = AutomatonFragmentDiagnostic(
      code: AutomatonFragmentDiagnosticCode.danglingTransition,
      severity: AutomatonFragmentDiagnosticSeverity.blocking,
      message:
          'Transition source-transition-4 has an endpoint outside the selected fragment.',
    );
    const connector = AutomatonFragmentDiagnostic(
      code: AutomatonFragmentDiagnosticCode.connectorUnsupported,
      severity: AutomatonFragmentDiagnosticSeverity.blocking,
      message: 'Moore connectors require an explicit input rule.',
    );

    expect(
      pt.localizedAutomatonFragmentDiagnostic(acceptance),
      'Os modos de aceitação dos APs são diferentes e exigem um plano de conversão explícito.',
    );
    expect(
      pt.localizedAutomatonFragmentDiagnostic(dangling),
      'A transição source-transition-4 tem um ponto final fora do fragmento selecionado.',
    );
    expect(
      pt.localizedAutomatonFragmentDiagnostic(connector),
      'Os conectores Moore exigem uma regra explícita de entrada.',
    );
  });

  test(
    'translates known import diagnostics while preserving English fallback',
    () {
      const canonicalOrder = CodecDiagnostic(
        code: 'jflap.canonical-order',
        message: 'State and transition ordering is canonicalized on export.',
      );
      const unknown = CodecDiagnostic(
        code: 'vendor.unknown-diagnostic',
        message: 'A vendor-specific detail is available.',
      );

      expect(
        en.localizedAutomatonFragmentCodecDiagnostic(canonicalOrder),
        canonicalOrder.message,
      );
      expect(
        pt.localizedAutomatonFragmentCodecDiagnostic(canonicalOrder),
        'A ordem de estados e transições foi padronizada.',
      );
      expect(
        pt.localizedAutomatonFragmentCodecDiagnostic(unknown),
        unknown.message,
      );
    },
  );

  test('translates codec diagnostics from conversion and JSON families', () {
    const diagnostics = <(CodecDiagnostic, String)>[
      (
        CodecDiagnostic(
          code: 'jflap.grammar-token-boundaries-lossy',
          message:
              'JFLAP XML cannot preserve multi-character token boundaries.',
        ),
        'O XML do JFLAP não pode preservar fronteiras de tokens com vários caracteres.',
      ),
      (
        CodecDiagnostic(
          code: 'jflap.l-system.execution-extension',
          message: 'Seed and weighted choices use Turing Lab XML parameters.',
        ),
        'Semente, símbolos de contexto ignorados e escolhas ponderadas usam parâmetros XML do Turing Lab.',
      ),
      (
        CodecDiagnostic(
          code: 'jflap.regex-dialect-normalized',
          message: 'JFLAP syntax was normalized to the Turing Lab dialect.',
        ),
        'A sintaxe de união e ε do JFLAP foi normalizada para o dialeto do Turing Lab.',
      ),
      (
        CodecDiagnostic(
          code: 'json.legacy-envelope-migrated',
          message: 'Legacy unversioned JSON was migrated to envelope v1.',
        ),
        'O JSON sem versão foi migrado para o envelope v1.',
      ),
      (
        CodecDiagnostic(
          code: 'jflap.note-presentation-dropped',
          message: 'JFLAP cannot store this note\'s attachment, size.',
          sourceValue: ['attachment', 'size'],
        ),
        'O JFLAP não pode armazenar esta nota: attachment, size.',
      ),
    ];

    for (final (diagnostic, expected) in diagnostics) {
      expect(
        pt.localizedAutomatonFragmentCodecDiagnostic(diagnostic),
        expected,
      );
      expect(
        en.localizedAutomatonFragmentCodecDiagnostic(diagnostic),
        diagnostic.message,
      );
    }
  });
}
