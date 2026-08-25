//
//  apple_release_shell.dart
//  Turing Lab
//
//  Names the two navigation shells the app can present and derives the
//  expected shell from a logical width, mirroring the breakpoint used by
//  HomePage so smoke tests never hard-code a layout per platform.
//

/// Navigation shell rendered by `HomePage` for a given logical width.
enum AppleReleaseShell {
  /// Bottom navigation bar, used below [desktopBreakpoint].
  mobile,

  /// Side navigation rail, used at or above [desktopBreakpoint].
  desktop;

  /// Logical width at which `HomePage` switches from mobile to desktop.
  static const double desktopBreakpoint = 1024;

  /// Resolves the shell `HomePage` renders for [logicalWidth].
  static AppleReleaseShell forWidth(double logicalWidth) {
    return logicalWidth < desktopBreakpoint ? mobile : desktop;
  }
}
