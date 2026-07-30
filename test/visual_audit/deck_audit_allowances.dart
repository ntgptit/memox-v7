import 'audit_allowance.dart';
import 'audit_model.dart';

/// The allowances every deck screen audited **through the router** needs.
///
/// Shared because they describe the app's chrome, not one screen: mount any
/// branch inside `AppNavigationShell` and the same nodes appear. Writing them out
/// per screen would mean two copies of the same promise, and the second copy is
/// the one that stops being true.
///
/// Every entry is scoped to one item, names the render type it excuses, and
/// carries an exact count. A count is not decoration here: `expectedMatches`
/// fails when the number moves in **either** direction, so a row that gains a
/// control surfaces as a miscount instead of disappearing into a blanket
/// permission.

/// The chrome outside the branch screen, plus the branch screen's own Material
/// layers and icon buttons.
///
/// [screenIconButtons] is the number of `MxIconButton`s the branch screen paints
/// — the app-bar actions plus one per list row. Each contributes exactly two
/// unreadable nodes: an ink layer and a shape-border painter. The caller counts
/// them because only the caller knows what its fixture renders.
///
/// [screenItemId] is the anchor id the branch screen was given.
///
/// [hasAppBar] because `MxContentShell` only builds one when it is given a
/// title, and a state with nothing to name — the not-found screen — has one
/// Material layer instead of two.
///
/// [hasBackButton] adds the one `AppBar` inserts by itself on a **pushed** route.
/// It is a real IconButton and contributes the same two unreadable nodes as any
/// other, so a nested screen always has one more than it declares. Naming it here
/// rather than folding it into every caller's number is what makes the arithmetic
/// checkable by eye.
///
/// A zero count is not passed as `expectedMatches: 0`: an allowance that matches
/// nothing is an unused allowance, which this harness treats as fatal, so the
/// entry is omitted instead.
List<AuditSkipAllowance> deckShellAllowances({
  required int screenIconButtons,
  required String screenItemId,
  bool hasAppBar = true,
  bool hasBackButton = false,
}) {
  final iconButtons = screenIconButtons + (hasBackButton ? 1 : 0);

  return <AuditSkipAllowance>[
    // One per Navigator: the harness's own MaterialApp, GoRouter's root, and the
    // branch.
    const AuditSkipAllowance(
      itemId: 'screen',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderColoredBox',
      expectedMatches: 3,
      rationale:
          'Page-transition backdrops from _FadeForwardsPageTransition, one per '
          'Navigator (harness MaterialApp, GoRouter root, branch). At rest each '
          'paints Colors.transparent; mid-transition it paints ColorScheme'
          '.surface, which is a palette token. Verified against '
          'page_transitions_theme.dart in the pinned SDK. NOT the Scaffold '
          'background — a Material paints that into its own ink layer.',
    ),
    const AuditSkipAllowance(
      itemId: 'screen',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderInkFeatures',
      rationale:
          "The navigation shell Scaffold's Material layer. A Material paints its "
          'own background and its splash and highlight into this layer, so none '
          'of the three is readable from a render object; scaffoldBackgroundColor '
          'and the overlay colours are asserted in app_theme_test.dart.',
    ),
    const AuditSkipAllowance(
      itemId: 'navigation_bar',
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderInkFeatures',
      rationale:
          'NavigationBar paints its selection indicator into a Material ink '
          'layer, so the pill has no render object of its own. Its colour is '
          'secondaryContainer, set in navigationBarTheme, and the two selected '
          'states are pinned by the mx_navigation_bar_* goldens.',
    ),
    AuditSkipAllowance(
      itemId: screenItemId,
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderInkFeatures',
      // MxContentShell's Scaffold, its AppBar when it has one, and one per icon
      // button — the back button included.
      expectedMatches: (hasAppBar ? 2 : 1) + iconButtons,
      rationale:
          'The branch screen Material layers: its Scaffold and its AppBar from '
          'MxContentShell, plus one per MxIconButton. Same raster-only reason as '
          'the shell — a Material paints background, splash and highlight into a '
          'layer no render object reports. The icon button states are pinned by '
          'the mx_icon_button_* goldens (M4.8).',
    ),
    if (iconButtons > 0)
      AuditSkipAllowance(
        itemId: screenItemId,
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: iconButtons,
        rationale:
            'One per MxIconButton: an IconButton draws its shape with a '
            "CustomPainter, so the outline exists in no render object — the "
            "audit's own SkipReason doc names this case for OutlinedButton and it "
            'is the same painter. The buttons are transparent-shaped and their '
            'icon colour is read from the icon itself; mx_icon_button_* goldens '
            'pin the pixels.',
      ),
  ];
}

/// The two unreadable nodes an `MxActionButton` contributes.
///
/// Scoped to [itemId] so the empty state's button and the error state's Retry
/// cannot excuse each other, and so a second button appearing on either shows up
/// as a miscount.
List<AuditSkipAllowance> mxActionButtonAllowances(
  String itemId,
) => <AuditSkipAllowance>[
  AuditSkipAllowance(
    itemId: itemId,
    reason: SkipReason.customPainter,
    detailContains: '_ShapeBorderPainter',
    rationale:
        'MxActionButton renders a Filled/OutlinedButton, which draws its '
        'border with a CustomPainter, so the stroke exists in no render '
        'object. The stroke is the Material 3 `outline` role and is pinned '
        'by the button_primary / button_secondary goldens (M4.8); the label '
        'contrast against page and card is asserted in app_theme_test.dart.',
  ),
  AuditSkipAllowance(
    itemId: itemId,
    reason: SkipReason.rasterOnly,
    detailContains: '_RenderInkFeatures',
    rationale:
        "The button's own Material ink layer. Splash and highlight are "
        'painted onto Material, so no render object carries them, and the '
        'overlayColor is asserted in app_theme_test.dart.',
  ),
];
