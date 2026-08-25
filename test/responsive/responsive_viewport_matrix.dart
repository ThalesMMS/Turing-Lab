//
//  responsive_viewport_matrix.dart
//  Turing Lab
//
//  Single source of truth for the responsive test matrix: viewport sizes,
//  device pixel ratios, safe-area insets, target platforms, text scales and
//  locales. Responsive tests must read these values from here instead of
//  recopying literals, so the contract can be changed in one place.
//
import 'package:flutter/material.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';

/// Layout breakpoints the responsive contract is written against.
///
/// The values are re-exported from the production scaffold so a change in the
/// widget cannot silently drift away from the tests that guard it.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  /// Below this width a workspace renders its mobile layout.
  static const double mobile = AutomatonWorkspaceScaffold.mobileBreakpoint;

  /// Between [mobile] and this width a workspace renders its tablet layout;
  /// at or above it the desktop layout takes over.
  static const double tablet = AutomatonWorkspaceScaffold.tabletBreakpoint;

  /// Width at which the home shell switches from the bottom navigation bar to
  /// the side rail.
  static const double homeNavigationRail = 1024;

  /// Width at which the desktop navigation rail becomes extended.
  static const double extendedNavigationRail = 1440;
}

/// How a page is attached to the surface under test.
enum ResponsiveMount {
  /// The page owns the whole window, as it does on a real device.
  window,

  /// The page is embedded in a narrower pane inside a wider window, which is
  /// how split-view and side-by-side desktop layouts constrain it. The window
  /// stays wide, so any breakpoint decision that reads `MediaQuery.size`
  /// instead of the incoming constraints shows up here.
  pane,
}

/// One entry of the canonical responsive matrix.
@immutable
class ResponsiveViewport {
  const ResponsiveViewport({
    required this.name,
    required this.logicalSize,
    required this.devicePixelRatio,
    required this.platform,
    this.safeArea = EdgeInsets.zero,
    this.paneWidth,
  });

  /// Short identifier used in test names and failure messages.
  final String name;

  /// Window size in logical pixels.
  final Size logicalSize;

  final double devicePixelRatio;

  /// Platform reported through `Theme.of(context).platform`.
  final TargetPlatform platform;

  /// Safe-area insets in logical pixels.
  final EdgeInsets safeArea;

  /// When set, the page is mounted inside a pane of this logical width rather
  /// than filling the window.
  final double? paneWidth;

  ResponsiveMount get mount =>
      paneWidth == null ? ResponsiveMount.window : ResponsiveMount.pane;

  /// Window size in physical pixels, the unit `TestFlutterView` expects.
  Size get physicalSize => Size(
        logicalSize.width * devicePixelRatio,
        logicalSize.height * devicePixelRatio,
      );

  /// Width actually available to the page's own layout.
  double get layoutWidth => paneWidth ?? logicalSize.width;

  /// Returns a copy resized to [size], used by live-resize transitions.
  ResponsiveViewport resized(Size size, {required String name}) =>
      ResponsiveViewport(
        name: name,
        logicalSize: size,
        devicePixelRatio: devicePixelRatio,
        platform: platform,
        safeArea: safeArea,
        paneWidth: paneWidth,
      );

  @override
  String toString() => name;
}

/// The canonical viewport matrix.
class ResponsiveViewports {
  const ResponsiveViewports._();

  /// Smallest phone the app still supports.
  static const ResponsiveViewport narrowPhone = ResponsiveViewport(
    name: 'narrow-phone-320x568',
    logicalSize: Size(320, 568),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.android,
    safeArea: EdgeInsets.only(top: 20),
  );

  /// Mainstream phone size.
  static const ResponsiveViewport standardPhone = ResponsiveViewport(
    name: 'standard-phone-390x844',
    logicalSize: Size(390, 844),
    devicePixelRatio: 3.0,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 47, bottom: 34),
  );

  /// Large phone size.
  static const ResponsiveViewport largePhone = ResponsiveViewport(
    name: 'large-phone-430x932',
    logicalSize: Size(430, 932),
    devicePixelRatio: 3.0,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 59, bottom: 34),
  );

  static const ResponsiveViewport tabletPortrait = ResponsiveViewport(
    name: 'tablet-portrait-834x1194',
    logicalSize: Size(834, 1194),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 24, bottom: 20),
  );

  static const ResponsiveViewport tabletLandscape = ResponsiveViewport(
    name: 'tablet-landscape-1194x834',
    logicalSize: Size(1194, 834),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 24, bottom: 20),
  );

  /// Tablet split view: the system hands the app a genuinely narrow window.
  static const ResponsiveViewport splitViewWindow = ResponsiveViewport(
    name: 'split-view-window-507x1194',
    logicalSize: Size(507, 1194),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.iOS,
    safeArea: EdgeInsets.only(top: 24, bottom: 20),
  );

  /// Constrained pane: the window stays wide while the page only gets a slice
  /// of it, the shape an embedded workspace sees. The 800-of-1600 split is the
  /// one the existing FSA pane coverage already exercises.
  static const ResponsiveViewport constrainedPane = ResponsiveViewport(
    name: 'constrained-pane-800-of-1600',
    logicalSize: Size(1600, 900),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.macOS,
    paneWidth: 800,
  );

  static const ResponsiveViewport desktopCompact = ResponsiveViewport(
    name: 'desktop-1280x800',
    logicalSize: Size(1280, 800),
    devicePixelRatio: 1.0,
    platform: TargetPlatform.macOS,
  );

  static const ResponsiveViewport desktopLarge = ResponsiveViewport(
    name: 'desktop-1440x900',
    logicalSize: Size(1440, 900),
    devicePixelRatio: 2.0,
    platform: TargetPlatform.macOS,
  );

  static const List<ResponsiveViewport> phones = [
    narrowPhone,
    standardPhone,
    largePhone,
  ];

  static const List<ResponsiveViewport> tablets = [
    tabletPortrait,
    tabletLandscape,
  ];

  static const List<ResponsiveViewport> constrained = [
    splitViewWindow,
    constrainedPane,
  ];

  static const List<ResponsiveViewport> desktops = [
    desktopCompact,
    desktopLarge,
  ];

  /// Every viewport class the responsive gate walks.
  static const List<ResponsiveViewport> all = [
    ...phones,
    ...tablets,
    ...constrained,
    ...desktops,
  ];

  /// Subset used for surfaces that are cheap enough to sweep exhaustively but
  /// still need one representative per layout band.
  static const List<ResponsiveViewport> representative = [
    narrowPhone,
    largePhone,
    tabletPortrait,
    splitViewWindow,
    desktopLarge,
  ];
}

/// Text scales the responsive contract is asserted at.
class ResponsiveTextScales {
  const ResponsiveTextScales._();

  static const double standard = 1.0;
  static const double large = 1.3;

  /// Accessibility pressure case.
  static const double accessibility = 2.0;

  static const List<double> all = [standard, large, accessibility];
}

/// Locales covered by the long-label surfaces.
class ResponsiveLocales {
  const ResponsiveLocales._();

  static const Locale english = Locale('en');
  static const Locale portuguese = Locale('pt');

  static const List<Locale> all = [english, portuguese];
}

/// Minimum interactive size the contract requires for primary actions.
///
/// Matches Material's own [kMinInteractiveDimension] so a control that shrinks
/// below the platform touch target is reported instead of silently accepted.
const double kResponsiveMinTouchTarget = kMinInteractiveDimension;
