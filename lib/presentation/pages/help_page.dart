//
//  help_page.dart
//  Turing Lab
//
//  Gathers interactive documentation into a single expandable tree, with
//  tutorials for automata, grammars, and app tools.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/help_catalog.dart';
import '../../core/models/help_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_help.dart';
import '../controllers/help_tree_controller.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/help_tree_view.dart';

part 'help_page_content.dart';
part 'license_text_card.dart';
part 'licenses_help_content.dart';

/// Help page with interactive documentation and tutorials
/// Based on JFLAP's HelpAction.java and documentation structure
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({
    super.key,
    this.initialTopicId,
    this.externalUrlLauncher = _launchExternalUrl,
  });

  final String? initialTopicId;
  final Future<bool> Function(Uri uri) externalUrlLauncher;

  static Future<bool> _launchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFieldFocusNode = FocusNode(
    debugLabel: 'help-search-field',
  );
  final FocusNode _searchActionFocusNode = FocusNode(
    debugLabel: 'help-search-action',
  );
  late final Map<String, GlobalKey> _topicKeys = {
    for (final topicId in kHelpCatalog.topicIds)
      topicId: GlobalKey(debugLabel: 'help-topic-$topicId'),
  };
  late final Map<String, FocusNode> _nodeFocusNodes = {
    for (final node in kHelpCatalog.nodes)
      node.id: FocusNode(debugLabel: 'help-node-${node.id}'),
  };

  HelpTreeController? _treeController;
  bool _searchOpen = false;
  bool _revealScheduled = false;
  int _revealGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final copy = jflapLocalizationsOf(context).helpCatalogCopy;
    if (_treeController == null) {
      _treeController = HelpTreeController(
        catalog: kHelpCatalog,
        copy: copy,
        initialTopicId: widget.initialTopicId,
      )..addListener(_handleTreeChanged);
      _schedulePendingReveal();
    } else if (!identical(_treeController!.copy, copy)) {
      _treeController!.updateCopy(copy);
    }
  }

  @override
  void dispose() {
    _revealGeneration++;
    _treeController?.removeListener(_handleTreeChanged);
    _treeController?.dispose();
    _scrollController.dispose();
    _searchTextController.dispose();
    _searchFieldFocusNode.dispose();
    _searchActionFocusNode.dispose();
    for (final focusNode in _nodeFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTreeChanged() {
    if ((_treeController?.query ?? '').isEmpty &&
        _searchTextController.text.trim().isNotEmpty) {
      _searchTextController.clear();
    }
    _schedulePendingReveal();
    if (mounted) setState(() {});
  }

  void _toggleSearch() {
    if (_searchOpen) {
      _closeSearch();
      return;
    }
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFieldFocusNode.requestFocus();
    });
  }

  void _clearSearch() {
    _searchTextController.clear();
    _treeController?.clearQuery();
    _searchFieldFocusNode.requestFocus();
  }

  void _closeSearch() {
    _searchTextController.clear();
    _treeController?.clearQuery();
    setState(() => _searchOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchActionFocusNode.requestFocus();
    });
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (!_searchOpen ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    if (_treeController?.isSearching ?? false) {
      _clearSearch();
    } else {
      _closeSearch();
    }
    return KeyEventResult.handled;
  }

  void _schedulePendingReveal() {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted) return;
      final topicId = _treeController?.consumePendingReveal();
      if (topicId != null) {
        final generation = ++_revealGeneration;
        _materializeAndReveal(topicId, generation);
      }
    });
  }

  Future<void> _materializeAndReveal(
    String topicId,
    int generation,
  ) async {
    if (!_isRevealActive(generation) || !_scrollController.hasClients) return;

    if (_topicKeys[topicId]?.currentContext == null) {
      final position = _scrollController.position;
      if (position.pixels > position.minScrollExtent) {
        _scrollController.jumpTo(position.minScrollExtent);
        await WidgetsBinding.instance.endOfFrame;
      }
    }

    while (_isRevealActive(generation) && _scrollController.hasClients) {
      final topicContext = _topicKeys[topicId]?.currentContext;
      if (topicContext != null) {
        if (!mounted ||
            generation != _revealGeneration ||
            !topicContext.mounted) {
          return;
        }
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        await Scrollable.ensureVisible(
          topicContext,
          alignment: 0.25,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
        if (_isRevealActive(generation)) {
          _nodeFocusNodes[topicId]?.requestFocus();
        }
        return;
      }

      final position = _scrollController.position;
      if (!position.hasContentDimensions ||
          position.pixels >= position.maxScrollExtent) {
        return;
      }

      final viewportStep = position.viewportDimension > 0
          ? position.viewportDimension * 0.8
          : 48.0;
      final proposedOffset = position.pixels + viewportStep;
      final nextOffset = proposedOffset < position.maxScrollExtent
          ? proposedOffset
          : position.maxScrollExtent;
      if (nextOffset <= position.pixels) return;

      _scrollController.jumpTo(nextOffset);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  bool _isRevealActive(int generation) {
    return mounted && generation == _revealGeneration;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    final treeController = _treeController!;
    final searchStatusMessage = treeController.isSearching
        ? treeController.matchingTopicIds.isEmpty
            ? l10n.helpSearchNoResults
            : l10n.helpSearchResultCount(
                treeController.matchingTopicIds.length,
              )
        : '';
    final showVisibleSearchStatus = treeController.isSearching &&
        treeController.matchingTopicIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpPageTitle),
        actions: [
          IconButton(
            key: const ValueKey('help-search-action'),
            focusNode: _searchActionFocusNode,
            onPressed: _toggleSearch,
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            tooltip:
                _searchOpen ? l10n.helpSearchClose : l10n.helpSearchTooltip,
          ),
        ],
      ),
      body: Focus(
        canRequestFocus: false,
        onKeyEvent: _handleSearchKeyEvent,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_searchOpen)
                Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: helpTreeMaxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        12,
                        16,
                        0,
                      ),
                      child: TextField(
                        key: const ValueKey('help-search-field'),
                        controller: _searchTextController,
                        focusNode: _searchFieldFocusNode,
                        onChanged: treeController.setQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: l10n.helpSearchFieldLabel,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: treeController.isSearching
                              ? IconButton(
                                  key: const ValueKey('help-search-clear'),
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.clear),
                                  tooltip: l10n.helpSearchClear,
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_searchOpen)
                Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: helpTreeMaxContentWidth,
                    ),
                    child: Semantics(
                      key: const ValueKey('help-search-status'),
                      container: true,
                      liveRegion: true,
                      label: searchStatusMessage,
                      child: ExcludeSemantics(
                        child: showVisibleSearchStatus
                            ? Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  20,
                                  8,
                                  20,
                                  0,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    searchStatusMessage,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: HelpTreeView(
                  controller: treeController,
                  scrollController: _scrollController,
                  topicKeys: _topicKeys,
                  nodeFocusNodes: _nodeFocusNodes,
                  disclosureSemanticLabel: l10n.helpDisclosureSemanticLabel,
                  relatedTopicsLabel: l10n.helpRelatedTopics,
                  unavailableTitle: l10n.helpTopicUnavailable,
                  unavailableDescription: l10n.helpTopicUnavailableDescription,
                  noResultsTitle: l10n.helpSearchNoResults,
                  noResultsDescription: l10n.helpSearchNoResultsDescription,
                  topicContentBuilder: (context, topic) {
                    if (topic.contentKind !=
                        HelpTopicContentKind.aboutAndLicenses) {
                      return null;
                    }
                    return _LicensesHelpContent(
                      key: const ValueKey('help-licenses-content'),
                      onOpenProject: () => _openProject(l10n),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _openProject(AppLocalizations l10n) async {
    final opened = await widget.externalUrlLauncher(
      Uri.parse('https://github.com/ThalesMMS/Turing-Lab'),
    );
    if (!opened && mounted) {
      showAppSnackBar(
        context,
        message: l10n.aboutProjectOpenError,
        tone: AppSnackBarTone.error,
      );
    }
    return opened;
  }
}
