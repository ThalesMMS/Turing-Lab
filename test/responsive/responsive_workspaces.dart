//
//  responsive_workspaces.dart
//  Turing Lab
//
//  Descriptors tying each release-visible workspace to the real page widget,
//  its quick-actions tab and the home navigation index the app uses for it, so
//  responsive suites iterate one list instead of repeating the wiring.
//
import 'package:flutter/widgets.dart';
import 'package:turing_lab/presentation/pages/fsa_page.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/pages/pda_page.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';

/// A workspace the responsive gate covers.
@immutable
class ResponsiveWorkspace {
  const ResponsiveWorkspace({
    required this.name,
    required this.tab,
    required this.navigationIndex,
    required this.page,
  });

  /// Identifier used in test names.
  final String name;

  /// Tab the production quick-actions bar is bound to.
  final WorkspaceTab tab;

  /// Index the home shell uses to reach this workspace.
  final int navigationIndex;

  /// The real page widget, mounted as-is.
  final Widget page;

  /// Type used to locate the page once mounted, whether the home shell built
  /// it or the harness embedded it in a pane.
  Type get pageType => page.runtimeType;

  @override
  String toString() => name;
}

const List<ResponsiveWorkspace> kResponsiveWorkspaces = [
  ResponsiveWorkspace(
    name: 'FSA',
    tab: WorkspaceTab.fsa,
    navigationIndex: HomeNavigationNotifier.fsaIndex,
    page: FSAPage(),
  ),
  ResponsiveWorkspace(
    name: 'Grammar',
    tab: WorkspaceTab.grammar,
    navigationIndex: HomeNavigationNotifier.grammarIndex,
    page: GrammarPage(),
  ),
  ResponsiveWorkspace(
    name: 'PDA',
    tab: WorkspaceTab.pda,
    navigationIndex: HomeNavigationNotifier.pdaIndex,
    page: PDAPage(),
  ),
  ResponsiveWorkspace(
    name: 'TM',
    tab: WorkspaceTab.tm,
    navigationIndex: HomeNavigationNotifier.tmIndex,
    page: TMPage(),
  ),
  ResponsiveWorkspace(
    name: 'Regex',
    tab: WorkspaceTab.regex,
    navigationIndex: HomeNavigationNotifier.regexIndex,
    page: RegexPage(),
  ),
];
