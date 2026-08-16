import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/presentation/widgets/common/workspace_helpers.dart';

void main() {
  final AppLocalizations en = AppLocalizationsEn();
  final AppLocalizations pt = AppLocalizationsPt();

  group('buildAutomatonWorkspaceStatus', () {
    test('describes an empty workspace without structural warnings', () {
      expect(
        buildAutomatonWorkspaceStatus(
          l10n: en,
          stateCount: 0,
          transitionCount: 0,
          hasInitialState: false,
          hasAcceptingState: false,
          hasNondeterministicTransitions: true,
          hasLambdaTransitions: true,
        ),
        'No automaton defined',
      );
    });

    test('formats valid singular and plural counts', () {
      expect(
        buildAutomatonWorkspaceStatus(
          l10n: en,
          stateCount: 1,
          transitionCount: 2,
          hasInitialState: true,
          hasAcceptingState: true,
        ),
        '1 state · 2 transitions',
      );
    });

    test('orders every shared warning before the counts', () {
      expect(
        buildAutomatonWorkspaceStatus(
          l10n: en,
          stateCount: 2,
          transitionCount: 1,
          hasInitialState: false,
          hasAcceptingState: false,
          hasNondeterministicTransitions: true,
          hasLambdaTransitions: true,
        ),
        '⚠ Missing start state · No accepting states · '
        'Nondeterministic transitions · λ-transitions present · '
        '2 states · 1 transition',
      );
    });

    test('renders the status in the active locale', () {
      expect(
        buildAutomatonWorkspaceStatus(
          l10n: pt,
          stateCount: 0,
          transitionCount: 0,
          hasInitialState: false,
          hasAcceptingState: false,
        ),
        'Nenhum autômato definido',
      );
      expect(
        buildAutomatonWorkspaceStatus(
          l10n: pt,
          stateCount: 2,
          transitionCount: 1,
          hasInitialState: false,
          hasAcceptingState: true,
        ),
        '⚠ Estado inicial ausente · 2 estados · 1 transição',
      );
    });
  });
}
