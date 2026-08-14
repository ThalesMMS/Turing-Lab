//
//  help_page.dart
//  Turing Lab
//
//  Reúne a documentação interativa com seções temáticas controladas por
//  PageView e filtros, oferecendo tutoriais guiados para cada módulo de
//  autômatos, gramáticas e ferramentas presentes no aplicativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_help.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/help_search_delegate.dart';

part 'help_page_content.dart';
part 'license_text_card.dart';
part 'licenses_help_content.dart';

/// Help page with interactive documentation and tutorials
/// Based on JFLAP's HelpAction.java and documentation structure
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({
    super.key,
    this.externalUrlLauncher = _launchExternalUrl,
  });

  final Future<bool> Function(Uri uri) externalUrlLauncher;

  static Future<bool> _launchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  /// Keeps the PageView element identity stable when the layout moves it
  /// between the mobile and desktop subtrees, so its scroll position is
  /// reparented instead of re-attached to [_pageController].
  final GlobalKey _pageViewKey = GlobalKey(debugLabel: 'help-page-view');
  final ScrollController _chipScrollController = ScrollController();
  late final List<GlobalKey> _chipKeys;
  bool _chipKeysInitialized = false;

  List<HelpSection> _helpSections(AppLocalizations l10n) => [
        HelpSection(
          title: l10n.helpSectionTitle('gettingStarted'),
          icon: Icons.play_circle_outline,
          content: const _HelpArticleContent(articleId: 'gettingStarted'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('fsa'),
          icon: Icons.account_tree,
          content: const _HelpArticleContent(articleId: 'fsa'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('grammar'),
          icon: Icons.text_fields,
          content: const _HelpArticleContent(articleId: 'grammar'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('pda'),
          icon: Icons.storage,
          content: const _HelpArticleContent(articleId: 'pda'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('tm'),
          icon: Icons.settings,
          content: const _HelpArticleContent(articleId: 'tm'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('regex'),
          icon: Icons.pattern,
          content: const _HelpArticleContent(articleId: 'regex'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('pumping'),
          icon: Icons.games,
          content: const _HelpArticleContent(articleId: 'pumping'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('fileOperations'),
          icon: Icons.folder_open,
          content: const _HelpArticleContent(articleId: 'fileOperations'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('troubleshooting'),
          icon: Icons.help_outline,
          content: const _HelpArticleContent(articleId: 'troubleshooting'),
        ),
        HelpSection(
          title: l10n.helpSectionTitle('about'),
          icon: Icons.info_outline,
          content: _LicensesHelpContent(
            onOpenProject: () async {
              final opened = await widget.externalUrlLauncher(
                Uri.parse('https://github.com/ThalesMMS/jflutter'),
              );
              if (!opened && mounted) {
                showAppSnackBar(
                  context,
                  message: l10n.aboutProjectOpenError,
                  tone: AppSnackBarTone.error,
                );
              }
              return opened;
            },
          ),
        ),
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_chipKeysInitialized) {
      _chipKeys = List.generate(
        _helpSections(jflapLocalizationsOf(context)).length,
        (_) => GlobalKey(),
      );
      _chipKeysInitialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  void _onSectionSelected(int index) {
    _updateSelectedIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateSelectedIndex(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    _scrollSelectedChipIntoView();
  }

  void _scrollSelectedChipIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipScrollController.hasClients) {
        return;
      }

      final chipContext = _chipKeys[_selectedIndex].currentContext;
      if (chipContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpPageTitle),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: HelpSearchDelegate(
                  ref: ref,
                  searchFieldLabel: l10n.helpSearchFieldLabel,
                ),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: l10n.helpSearchTooltip,
          ),
          IconButton(
            onPressed: _showQuickStart,
            icon: const Icon(Icons.rocket_launch),
            tooltip: l10n.helpQuickStartTitle,
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout(l10n) : _buildDesktopLayout(l10n),
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    final helpSections = _helpSections(l10n);
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 68,
            child: ListView.builder(
              controller: _chipScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: helpSections.length,
              itemBuilder: (context, index) {
                final section = helpSections[index];
                final isSelected = index == _selectedIndex;

                return Padding(
                  key: _chipKeys[index],
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onSectionSelected(index),
                    avatar: Icon(section.icon, size: 16),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: PageView(
              key: _pageViewKey,
              controller: _pageController,
              onPageChanged: (index) {
                _updateSelectedIndex(index);
              },
              children: helpSections.map((section) => section.content).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AppLocalizations l10n) {
    final helpSections = _helpSections(l10n);
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: ListView.builder(
            itemCount: helpSections.length,
            itemBuilder: (context, index) {
              final section = helpSections[index];
              final isSelected = index == _selectedIndex;

              return ListTile(
                leading: Icon(section.icon),
                title: Text(section.title),
                selected: isSelected,
                onTap: () => _onSectionSelected(index),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: PageView(
            key: _pageViewKey,
            controller: _pageController,
            onPageChanged: (index) => _updateSelectedIndex(index),
            children: helpSections.map((section) => section.content).toList(),
          ),
        ),
      ],
    );
  }

  void _showQuickStart() {
    final l10n = jflapLocalizationsOf(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.helpQuickStartTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.helpQuickStartBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.helpGotIt),
          ),
        ],
      ),
    );
  }
}
