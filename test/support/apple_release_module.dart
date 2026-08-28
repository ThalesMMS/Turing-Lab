//
//  apple_release_module.dart
//  Turing Lab
//
//  Enumerates the release-visible workspace modules and resolves their
//  navigation label and description from AppLocalizations, so smoke tests
//  assert against localized copy instead of duplicated English literals.
//

import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_help.dart';

/// A workspace module that must stay reachable in the Apple v1.0 release.
enum AppleReleaseModule {
  fsa('fsa'),
  grammar('grammar'),
  pda('pda'),
  tm('tm'),
  regex('regex'),
  regularPumpingLemma('regularPumping'),
  contextFreePumpingLemma('contextFreePumping');

  const AppleReleaseModule(this.id);

  /// Identifier used by `AppLocalizations.homeNavigationLabel`.
  final String id;

  /// Navigation label rendered in the mobile bar and the desktop rail.
  String label(AppLocalizations l10n) => l10n.homeNavigationLabel(id);

  /// Long form description rendered in the app bar and the rail tooltip.
  String description(AppLocalizations l10n) =>
      l10n.homeNavigationDescription(id);
}
