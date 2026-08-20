import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

part 'mx_breadcrumb_step.dart';

/// The focus underline is twice the font's own stroke — the kit's
/// `--border-focus`, and the same value `mx_text_button.dart` resolves for its
/// own label. Declared here rather than shared: two widgets is not yet a token,
/// and `core/theme/` has no home for a stroke width.
const double _kFocusUnderlineThickness = 2;

/// One step in an [MxBreadcrumb].
///
/// A plain value with no domain type in it: the widget is told a name and what to
/// do, and knows nothing about decks, files or anything else it might be pointing
/// at. That is what keeps this in `shared/` — a breadcrumb that knew a `DeckEntity`
/// would drag the deck domain into every widget test in the project.
///
/// [onTap] null marks the step the user is already on. It is not "disabled": there
/// is nowhere to go, so it is rendered as text rather than as a control that does
/// nothing.
@immutable
class MxBreadcrumbItem {
  const MxBreadcrumbItem({required this.label, this.onTap});

  /// Already-localized, or a user's own text. Components never reach for ARB.
  final String label;

  /// Null for the step that is already open.
  final VoidCallback? onTap;
}

/// The path from the top of a hierarchy down to where the user is now.
///
/// **Why this is not one of the existing components.** `MxNavigationBar` switches
/// between siblings at a fixed top level; a breadcrumb moves *up* an arbitrary
/// number of levels. `MxPillButton` is one of N views of the same content — a set,
/// not a sequence, and it has a selected state where a path has a last element.
/// `MxListTile` is a row. Nothing in `shared/widgets/` held "where am I, and how
/// do I get back up", so this is the missing piece.
///
/// **A deep path folds in the middle, and the fold opens.** A path can be ten deep
/// (BR-55 caps the deck tree there). Collapsing beats truncating because the
/// ellipsis is a button that expands in place: nothing is hidden for good, and
/// the two ends — where you came from, where you are going back to — stay on
/// screen. The design system reached the same shape and is the source for
/// [collapseAfter]'s default of 4: first step, fold, last two.
///
/// It still scrolls horizontally, so nothing can overflow even expanded, and it
/// **starts at the left and stays there.** It used to jump to its deep end on
/// arrival; the fold made that pointless, and the jump cost the one thing a path
/// is read for — seeing where it begins.
///
/// A step with no [MxBreadcrumbItem.onTap] renders as quiet text rather than as a
/// control — how a caller marks the step the user is already on.
///
/// Every step is its own tap target at [AppSpacing.minimumTouchTarget]. The
/// design's CSS sets 36 and its usage note says 48; 48 wins, because 36 breaks
/// the touch-target floor the same design declares.
///
/// **The floor is on the strip, not on the step.** On each step it made the
/// strip's height depend on whether any item happened to carry an `onTap` — a
/// path of pure text came out 16 tall where every other level came out 48, so a
/// recursive screen rendered two different shapes. A height that reads a
/// per-item property cannot be uniform.
class MxBreadcrumb extends StatefulWidget {
  const MxBreadcrumb({
    required this.items,
    this.semanticLabel,
    this.rootIcon,
    this.collapseAfter = 4,
    this.lineHeight = AppSpacing.minimumTouchTarget,
    super.key,
  });

  /// The compact line: a strip that is a *line of a header* rather than a band
  /// of its own (owner review, 2026-08-20).
  ///
  /// **It is under the touch floor, deliberately and only here.** A step is a
  /// control, and [AppSpacing.minimumTouchTarget] is what every other control
  /// in the app gets — including this one at its default. The owner's header
  /// spec asks for a fixed 20px path line at every level so the bar does not
  /// change height on the way into a sub-deck, and 48 cannot fit inside 20.
  /// The trade is recorded in `docs/reviews/design-parity-checklist.md`; the
  /// root level, where the only step carries no `onTap`, has no target to
  /// shrink.
  static const double compactLineHeight = 20;

  /// Ordered from the top of the hierarchy to the current step.
  ///
  /// An empty list renders nothing at all rather than an empty strip, so a caller
  /// at the top of a tree does not have to branch.
  final List<MxBreadcrumbItem> items;

  /// Names the strip for assistive tech — "deck path", not the path itself.
  final String? semanticLabel;

  /// Drawn before the first step. The library root is recognisable at a glance
  /// rather than by reading it.
  final IconData? rootIcon;

  /// The strip's height. Defaults to the touch floor; a header passes
  /// [compactLineHeight] — see the note there.
  final double lineHeight;

  /// Above this many steps the middle folds into an expandable ellipsis.
  ///
  /// The fold keeps the first step and the last two — the two ends are the ones a
  /// user navigates to, and the middle is the part they scrolled past on the way
  /// down. A tighter screen passes a lower value: the card list uses 3, the deck
  /// list keeps the default and shows every ancestor on purpose.
  final int collapseAfter;

  @override
  State<MxBreadcrumb> createState() => _MxBreadcrumbState();
}

class _MxBreadcrumbState extends State<MxBreadcrumb> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(MxBreadcrumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new path is a new question about where the user is. Keeping the previous
    // expansion would leave a two-step path rendering as though it had been
    // unfolded.
    if (oldWidget.items.length != widget.items.length) _isExpanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final isFolded = !_isExpanded && items.length > widget.collapseAfter;
    final hiddenCount = items.length - 3;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.lineHeight),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isFolded
                ? <Widget>[
                    _MxBreadcrumbStep(
                      lineHeight: widget.lineHeight,
                      item: items.first,
                      icon: widget.rootIcon,
                      isFirst: true,
                    ),
                    const _MxBreadcrumbSeparator(),
                    _MxBreadcrumbFold(
                      hiddenCount: hiddenCount,
                      onExpand: () => setState(() => _isExpanded = true),
                    ),
                    for (final item in items.sublist(
                      items.length - 2,
                    )) ...<Widget>[
                      const _MxBreadcrumbSeparator(),
                      _MxBreadcrumbStep(
                        item: item,
                        lineHeight: widget.lineHeight,
                      ),
                    ],
                  ]
                : <Widget>[
                    for (final (int index, MxBreadcrumbItem item)
                        in items.indexed) ...<Widget>[
                      if (index > 0) const _MxBreadcrumbSeparator(),
                      _MxBreadcrumbStep(
                        lineHeight: widget.lineHeight,
                        item: item,
                        icon: index == 0 ? widget.rootIcon : null,
                        isFirst: index == 0,
                      ),
                    ],
                  ],
          ),
        ),
      ),
    );
  }
}

/// The middle of a long path, as one control that opens it.
///
/// Styled like the steps either side of it rather than like a button: it sits
/// inside the same strip, and one filled hover box among link hovers is the
/// inconsistency that made the strip read as a toolbar in the first place.
class _MxBreadcrumbFold extends StatefulWidget {
  const _MxBreadcrumbFold({required this.hiddenCount, required this.onExpand});

  final int hiddenCount;
  final VoidCallback onExpand;

  @override
  State<_MxBreadcrumbFold> createState() => _MxBreadcrumbFoldState();
}

class _MxBreadcrumbFoldState extends State<_MxBreadcrumbFold> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // The count, not the glyph: "…" announced on its own says nothing about
      // what pressing it does.
      label: MaterialLocalizations.of(context).moreButtonTooltip,
      value: '${widget.hiddenCount}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onExpand,
          onHover: (bool value) => setState(() => _isHovered = value),
          overlayColor: _noOverlay(context),
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minimumTouchTarget,
              minWidth: AppSpacing.minimumTouchTarget,
            ),
            child: Center(
              child: Icon(
                Icons.more_horiz,
                size: AppIconSize.sm,
                color: _isHovered
                    ? context.colors.onSurface
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Suppresses every ink overlay an `InkWell` would paint — hover, focus, press.
///
/// A scheme colour at alpha zero rather than the framework's transparent
/// constant, which the design-token guard rightly reads as a hardcoded colour.
WidgetStateProperty<Color> _noOverlay(BuildContext context) =>
    WidgetStatePropertyAll<Color>(context.colors.primary.withAlpha(0));
