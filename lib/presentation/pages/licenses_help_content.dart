part of 'help_page.dart';

class _LicensesHelpContent extends StatefulWidget {
  const _LicensesHelpContent({super.key, required this.onOpenProject});

  final Future<bool> Function() onOpenProject;

  @override
  State<_LicensesHelpContent> createState() => _LicensesHelpContentState();
}

class _LicensesHelpContentState extends State<_LicensesHelpContent>
    with AutomaticKeepAliveClientMixin<_LicensesHelpContent> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = jflapLocalizationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard(
          title: l10n.aboutDeveloperLabel,
          description: 'Thales Matheus Mendonça Santos',
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.aboutProjectRepositoryLabel),
            subtitle: const Text(
              'https://github.com/ThalesMMS/jflutter',
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              await widget.onOpenProject();
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.aboutLicensesIntro),
        const SizedBox(height: 16),
        _LicenseTextCard(
          key: const ValueKey('license-text-LICENSE.txt'),
          title: 'Apache License 2.0',
          assetPath: 'LICENSE.txt',
          summary: l10n.aboutTuringLabLicenseSummary,
        ),
        _LicenseTextCard(
          key: const ValueKey('license-text-LICENSE_JFLAP.txt'),
          title: 'JFLAP 7.1 License',
          assetPath: 'LICENSE_JFLAP.txt',
          summary: l10n.aboutJflapLicenseSummary,
        ),
        _LicenseTextCard(
          key: const ValueKey(
            'license-text-assets/LICENSE_GRAPHVIEW.txt',
          ),
          title: 'GraphView (MIT License)',
          assetPath: 'assets/LICENSE_GRAPHVIEW.txt',
          summary: l10n.aboutGraphViewLicenseSummary,
        ),
        _LicenseTextCard(
          key: const ValueKey(
            'license-text-THIRD_PARTY_NOTICES_APPLE.txt',
          ),
          title: l10n.aboutAppleNoticesTitle,
          assetPath: 'THIRD_PARTY_NOTICES_APPLE.txt',
          summary: l10n.aboutAppleNoticesSummary,
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            key: const ValueKey('about_package_licenses'),
            leading: const Icon(Icons.policy_outlined),
            title: Text(l10n.aboutPackageLicenses),
            subtitle: Text(l10n.aboutPackageLicensesDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Turing Lab',
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(l10n.aboutAcknowledgments),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Susan H. Rodger',
          description: l10n.aboutJflapCreator,
        ),
        _buildCard(
          title: 'JFLAP Team',
          description: l10n.aboutJflapTeam,
        ),
        _buildCard(
          title: l10n.aboutOriginalProjectTitle,
          description: l10n.aboutOriginalProject,
        ),
        _buildCard(
          title: l10n.aboutGraphViewForkTitle,
          description: l10n.aboutGraphViewFork,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(l10n.aboutDistribution),
        const SizedBox(height: 16),
        Text(l10n.aboutDistributionDescription),
      ],
    );
  }
}
