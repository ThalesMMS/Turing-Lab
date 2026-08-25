//
//  about_page.dart
//  Turing Lab
//
//  Product overview adapted from the public landing page, shown from Settings.
//
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/help_topic_ids.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/help_navigation.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static final Uri _sourceUri = Uri.parse(
    'https://github.com/ThalesMMS/Turing-Lab',
  );
  static final Uri _docsUri = Uri.parse(
    'https://github.com/ThalesMMS/Turing-Lab#readme',
  );
  static final Uri _issuesUri = Uri.parse(
    'https://github.com/ThalesMMS/Turing-Lab/issues',
  );
  static final Uri _privacyUri = Uri.parse(
    'https://thalesmms.github.io/Turing-Lab/privacy.html',
  );
  static final Uri _supportUri = Uri.parse(
    'https://thalesmms.github.io/Turing-Lab/support.html',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('about_page'),
      appBar: AppBar(title: Text(l10n.aboutPageTitle)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aboutEyebrow,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Turing Lab',
                key: const ValueKey('about_overview_title'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.aboutLead, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.aboutDetail),
              const SizedBox(height: 8),
              Text(
                l10n.aboutDevelopmentStatus,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => _openUri(_sourceUri),
                    child: Text(l10n.aboutViewSource),
                  ),
                  OutlinedButton(
                    onPressed: () => _openUri(_docsUri),
                    child: Text(l10n.aboutReadDocumentation),
                  ),
                  OutlinedButton(
                    onPressed: () => _openUri(_issuesUri),
                    child: Text(l10n.aboutReportIssue),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _sectionTitle(context, l10n.aboutCapabilitiesTitle),
              const SizedBox(height: 8),
              Text(l10n.aboutCapabilitiesIntro),
              const SizedBox(height: 12),
              Column(
                key: const ValueKey('about_capabilities'),
                children: [
                  _workspaceCard(
                    context,
                    title: l10n.aboutWorkspaceFsa,
                    editing: l10n.aboutWorkspaceFsaEditing,
                    simulation: l10n.aboutWorkspaceFsaSimulation,
                    transformations: l10n.aboutWorkspaceFsaTransformations,
                    files: l10n.aboutWorkspaceFsaFiles,
                  ),
                  _workspaceCard(
                    context,
                    title: l10n.aboutWorkspaceGrammar,
                    editing: l10n.aboutWorkspaceGrammarEditing,
                    simulation: l10n.aboutWorkspaceGrammarSimulation,
                    transformations: l10n.aboutWorkspaceGrammarTransformations,
                    files: l10n.aboutWorkspaceGrammarFiles,
                  ),
                  _workspaceCard(
                    context,
                    title: l10n.aboutWorkspacePda,
                    editing: l10n.aboutWorkspacePdaEditing,
                    simulation: l10n.aboutWorkspacePdaSimulation,
                    transformations: l10n.aboutWorkspacePdaTransformations,
                    files: l10n.aboutWorkspacePdaFiles,
                  ),
                  _workspaceCard(
                    context,
                    title: l10n.aboutWorkspaceTm,
                    editing: l10n.aboutWorkspaceTmEditing,
                    simulation: l10n.aboutWorkspaceTmSimulation,
                    transformations: l10n.aboutWorkspaceTmTransformations,
                    files: l10n.aboutWorkspaceTmFiles,
                  ),
                  _workspaceCard(
                    context,
                    title: l10n.aboutWorkspaceRegex,
                    editing: l10n.aboutWorkspaceRegexEditing,
                    simulation: l10n.aboutWorkspaceRegexSimulation,
                    transformations: l10n.aboutWorkspaceRegexTransformations,
                    files: l10n.aboutWorkspaceRegexFiles,
                  ),
                  _workspaceCard(
                    context,
                    title: l10n.aboutWorkspacePumping,
                    editing: l10n.aboutWorkspacePumpingEditing,
                    simulation: l10n.aboutWorkspacePumpingSimulation,
                    transformations: l10n.aboutWorkspacePumpingTransformations,
                    files: l10n.aboutWorkspacePumpingFiles,
                  ),
                ],
              ),
              _infoCard(
                context,
                l10n.aboutFiniteAutomataTitle,
                l10n.aboutFiniteAutomataBody,
              ),
              _infoCard(
                context,
                l10n.aboutGrammarAnalysisTitle,
                l10n.aboutGrammarAnalysisBody,
              ),
              _infoCard(
                context,
                l10n.aboutExecutionTracesTitle,
                l10n.aboutExecutionTracesBody,
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, l10n.aboutFormatsTitle),
              const SizedBox(height: 8),
              Column(
                key: const ValueKey('about_formats'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aboutFormatsIntro),
                  const SizedBox(height: 12),
                  _bullet(context, l10n.aboutFormatFsa),
                  _bullet(context, l10n.aboutFormatGrammar),
                  _bullet(context, l10n.aboutFormatPdaTm),
                  _bullet(context, l10n.aboutFormatWebLimitation),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, l10n.aboutPlatformsTitle),
              const SizedBox(height: 8),
              Text(l10n.aboutPlatformsIntro),
              const SizedBox(height: 12),
              Card(
                key: const ValueKey('about_platforms'),
                child: Column(
                  children: [
                    _platformRow(
                      context,
                      l10n.aboutPlatformIos,
                      l10n.aboutStatusTesting,
                    ),
                    _platformRow(
                      context,
                      l10n.aboutPlatformMacos,
                      l10n.aboutStatusTesting,
                    ),
                    _platformRow(
                      context,
                      l10n.aboutPlatformAndroid,
                      l10n.aboutStatusTesting,
                    ),
                    _platformRow(
                      context,
                      l10n.aboutPlatformWeb,
                      l10n.aboutStatusExperimental,
                    ),
                    _platformRow(
                      context,
                      l10n.aboutPlatformWindows,
                      l10n.aboutStatusExperimental,
                    ),
                    _platformRow(
                      context,
                      l10n.aboutPlatformLinux,
                      l10n.aboutStatusExperimental,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, l10n.aboutScreenshotsTitle),
              const SizedBox(height: 8),
              Text(l10n.aboutScreenshotsIntro),
              const SizedBox(height: 12),
              Column(
                key: const ValueKey('about_screenshots'),
                children: [
                  _screenshotCard(
                    context,
                    assetPath: 'assets/about/fsa.webp',
                    caption: l10n.aboutScreenshotFsa,
                  ),
                  _screenshotCard(
                    context,
                    assetPath: 'assets/about/grammar.webp',
                    caption: l10n.aboutScreenshotGrammar,
                  ),
                  _screenshotCard(
                    context,
                    assetPath: 'assets/about/tm.webp',
                    caption: l10n.aboutScreenshotTm,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.aboutAttribution,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      key: const ValueKey('about_open_licenses'),
                      leading: const Icon(Icons.policy_outlined),
                      title: Text(l10n.aboutOpenLicenses),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        openHelp(
                          context,
                          topicId: HelpTopicIds.aboutLicenses,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.aboutOpenPrivacy),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openUri(_privacyUri),
                    ),
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined),
                      title: Text(l10n.aboutOpenSupport),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openUri(_supportUri),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _workspaceCard(
    BuildContext context, {
    required String title,
    required String editing,
    required String simulation,
    required String transformations,
    required String files,
  }) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _labeledLine(context, l10n.aboutCapabilityEditing, editing),
            _labeledLine(context, l10n.aboutCapabilitySimulation, simulation),
            _labeledLine(
              context,
              l10n.aboutCapabilityTransformations,
              transformations,
            ),
            _labeledLine(context, l10n.aboutCapabilityImportExport, files),
          ],
        ),
      ),
    );
  }

  Widget _labeledLine(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _platformRow(
    BuildContext context,
    String platform,
    String status, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(platform),
          trailing: Text(status),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  Widget _screenshotCard(
    BuildContext context, {
    required String assetPath,
    required String caption,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(height: 120);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(caption),
          ),
        ],
      ),
    );
  }

  Future<void> _openUri(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
