import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Compatibility destination for the historical single Pumping Lemma route.
class PumpingLemmaChooserPage extends StatelessWidget {
  const PumpingLemmaChooserPage({super.key});

  static const route = '/pumping-lemma';
  static const regularRoute = '/pumping-lemma/regular';
  static const contextFreeRoute = '/pumping-lemma/context-free';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeNavigationPumpingDescription)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.choosePumpingLemmaEnvironment,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.choosePumpingLemmaEnvironmentDescription),
                    const SizedBox(height: 24),
                    _EnvironmentCard(
                      key: const ValueKey('choose-regular-pumping'),
                      icon: Icons.games_outlined,
                      title: l10n.homeNavigationRegularPumpingLabel,
                      description: l10n.homeNavigationRegularPumpingDescription,
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(regularRoute),
                    ),
                    const SizedBox(height: 16),
                    _EnvironmentCard(
                      key: const ValueKey('choose-context-free-pumping'),
                      icon: Icons.schema_outlined,
                      title: l10n.homeNavigationContextFreePumpingLabel,
                      description:
                          l10n.homeNavigationContextFreePumpingDescription,
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(contextFreeRoute),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: title,
        hint: description,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Icon(icon, size: 32),
            title: Text(title),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(description),
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: onTap,
          ),
        ),
      );
}
