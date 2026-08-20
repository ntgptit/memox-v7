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
/// [tappableCards] is the number of `MxCard`s built with an `onTap`. Each hosts
/// an `InkWell`, which contributes an ink layer and a clip painted by a
/// `CustomPaint` with no painter of its own.
///
/// [pills] is the number of `MxPillButton`s. A `ChoiceChip` contributes three
/// unreadable nodes rather than two: an ink layer, a `CustomPaint`, and
/// `_RenderChip` itself, which lays out and paints its own shape through a
/// private render object no extractor claims.
///
/// [filledButtons] is the number of `FilledButton`s *inside the screen item* —
/// the deck card's Study action. Each is an ink host and draws its own rounded
/// `_ShapeBorderPainter`, the same pair an icon button contributes; it is a
/// separate parameter because calling a labelled action an icon button in an
/// allowance is how a count stops describing the screen.
///
/// [hasFloatingAction] for the create button. Same two nodes as a tappable card —
/// it is a `Material` with an `InkWell` and a clip.
///
/// [breadcrumbSteps] is the number of **tappable** steps in an `MxBreadcrumb` —
/// the deck list and every ancestor, but not its last step, which is the deck the
/// user is in and renders as text rather than as a control. So a deck with no
/// ancestors still has one: every deck level has a strip now. Each tappable step
/// is again a `Material` with an `InkWell` and a clip, so it counts like a card.
///
/// A zero count is not passed as `expectedMatches: 0`: an allowance that matches
/// nothing is an unused allowance, which this harness treats as fatal, so the
/// entry is omitted instead.
List<AuditSkipAllowance> deckShellAllowances({
  required int screenIconButtons,
  required String screenItemId,
  bool hasAppBar = true,
  bool hasBackButton = false,
  int tappableCards = 0,
  int pills = 0,
  int filledButtons = 0,
  int breadcrumbSteps = 0,
  bool hasFloatingAction = false,

  /// Whether the level's subheader carries the search *control*. Every deck
  /// level does; the parameter exists so a state that renders no shell at all
  /// does not have to opt out of it silently.
  ///
  /// **A toggle now, not a field.** The density pass collapsed the resting
  /// field into an icon button in the breadcrumb strip, so at rest a level
  /// contributes one more InkWell host and no `RenderEditable` at all — the
  /// field, its decoration and its cursor painter exist only after the toggle
  /// is pressed, which no audited state does. The mx_search_field_* goldens
  /// still pin the field itself.
  bool hasSearchField = true,
}) {
  final iconButtons =
      screenIconButtons + (hasBackButton ? 1 : 0) + (hasSearchField ? 1 : 0);
  // The chevron on the path line contributes nothing to either count: it is a
  // bare `InkWell` painting into the app bar's own `Material`, with no
  // rounded clip of its own (owner review, 2026-08-20).
  final floatingActions = hasFloatingAction ? 1 : 0;
  // Every one of these hosts an InkWell inside its own Material.
  final inkHosts =
      iconButtons +
      tappableCards +
      pills +
      filledButtons +
      breadcrumbSteps +
      floatingActions;
  // The InkWell's rounded clip, once per host that has one. Icon buttons draw a
  // `_ShapeBorderPainter` instead, which is counted separately below.
  // The path chevron is not in this list: its `InkWell` has no rounded clip
  // to paint, being a plain rectangle in a 20px line.
  final unnamedPainters =
      tappableCards + pills + breadcrumbSteps + floatingActions;

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
          'primaryContainer, set in navigationBarTheme, and the two selected '
          'states are pinned by the mx_navigation_bar_* goldens.',
    ),
    AuditSkipAllowance(
      itemId: screenItemId,
      reason: SkipReason.rasterOnly,
      detailContains: '_RenderInkFeatures',
      // MxContentShell's Scaffold, its AppBar when it has one, and one per thing
      // that hosts an InkWell — icon buttons, tappable cards, pills, the
      // floating action.
      expectedMatches: (hasAppBar ? 2 : 1) + inkHosts,
      rationale:
          'The branch screen Material layers: its Scaffold and its AppBar from '
          'MxContentShell, plus one per InkWell host — MxIconButton, a tappable '
          'MxCard, an MxPillButton, a breadcrumb step, the floating action. Same '
          'raster-only reason '
          'as the shell: a Material paints background, splash and highlight into '
          'a layer no render object reports. The icon button states are pinned by '
          'the mx_icon_button_* goldens (M4.8), the card and pill surfaces by '
          'app_theme_test.dart.',
    ),
    if (unnamedPainters > 0)
      AuditSkipAllowance(
        itemId: screenItemId,
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        expectedMatches: unnamedPainters,
        rationale:
            'The rounded clip an InkWell paints for its ripple, one per tappable '
            'MxCard, MxPillButton and floating action. It has no painter to '
            'interrogate because the shape is the ripple boundary rather than a '
            'drawn stroke — the visible border is the DecoratedBox behind it, '
            'which the audit does read.',
      ),
    if (pills > 0)
      AuditSkipAllowance(
        itemId: screenItemId,
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        expectedMatches: pills,
        rationale:
            'ChoiceChip lays out and paints through a private _RenderChip, so '
            'neither its fill nor its border is reachable from the render tree. '
            'Both come from chipTheme in app_theme.dart and the selected and '
            'unselected fills are asserted to differ, in both themes, in '
            'mx_pill_button_test.dart.',
      ),
    if (iconButtons + filledButtons > 0)
      AuditSkipAllowance(
        itemId: screenItemId,
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: iconButtons + filledButtons,
        rationale:
            'One per MxIconButton, and one per FilledButton: the deck card Study '
            'action draws its pill through the same painter. An '
            'IconButton draws its shape with a '
            "CustomPainter, so the outline exists in no render object — the "
            "audit's own SkipReason doc names this case for OutlinedButton and it "
            'is the same painter. The buttons are transparent-shaped and their '
            'icon colour is read from the icon itself; mx_icon_button_* goldens '
            'pin the pixels.',
      ),
  ];
}

/// The hero card's own surface, which its content now covers.
///
/// The brand-tinted context row and the full-width Study action leave no
/// single colour at the 90% the raster cross-check needs, so the card's
/// declared `surface` can be neither confirmed nor contradicted. The fill is
/// pinned by the `mx_card_*` goldens; the row and the button declare colours
/// the audit does read.
const AuditSkipAllowance heroCardRasterAllowance = AuditSkipAllowance(
  itemId: 'deck_screen',
  reason: SkipReason.rasterNotFlat,
  detailContains: 'covers only 0%',
  rationale:
      'The hero card declares `surface` and its own content covers it: the '
      'brand-tinted context row and the full-width Study action. No single '
      'colour reaches 90%, so the declaration cannot be checked from the '
      'raster. The card fill is pinned by the mx_card_* goldens.',
);

/// The two unreadable nodes an `MxActionButton` contributes.
///
/// Scoped to [itemId] so the empty state's button and the error state's Retry
/// cannot excuse each other, and so a second button appearing on either shows up
/// as a miscount.
List<AuditSkipAllowance> mxActionButtonAllowances(
  String itemId, {

  /// How many MxActionButtons the item holds. The empty library holds two
  /// since UC-01 put the starter catalog beside the blank deck.
  int buttons = 1,
}) => <AuditSkipAllowance>[
  AuditSkipAllowance(
    itemId: itemId,
    reason: SkipReason.customPainter,
    detailContains: '_ShapeBorderPainter',
    expectedMatches: buttons,
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
    expectedMatches: buttons,
    rationale:
        "The button's own Material ink layer. Splash and highlight are "
        'painted onto Material, so no render object carries them, and the '
        'overlayColor is asserted in app_theme_test.dart.',
  ),
];
