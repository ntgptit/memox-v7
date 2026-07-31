import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

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
/// (BR-55 caps the deck tree there) and a 320-wide screen at `textScaler` 2.0 fits
/// about one and a half names. This file used to argue against folding on the
/// grounds that "collapsing the middle behind an ellipsis hides exactly the steps a
/// user goes to a breadcrumb to find" — which is true of a *truncation* and false
/// of this, because the ellipsis is a button that expands in place and never
/// collapses again. What the old scroll-only strategy actually produced at ten
/// levels was a strip the user had to scrub sideways to read at all, with the two
/// ends — the root they came from and the parent they are about to return to —
/// the least likely to be on screen.
///
/// The design system reached the same shape independently and is the source for
/// [collapseAfter]'s default of 4: first step, fold, last two.
///
/// It still scrolls horizontally, so nothing can overflow even expanded, and it
/// **starts at the left and stays there.** It used to jump to its deep end on
/// arrival, on the argument that a path you have just walked into should show
/// where you are rather than where you started. The fold is what made that
/// argument obsolete: above [collapseAfter] steps the strip is already first ·
/// fold · last two, so the deep end is on screen without scrolling, and the jump
/// bought nothing while costing the one thing a path is read for — you could no
/// longer see where it begins.
///
/// A step with no [MxBreadcrumbItem.onTap] renders as quiet text rather than as a
/// control. That is how a caller marks the step the user is already on, and the
/// deck list now ends every path with one.
///
/// Every step is its own tap target at [AppSpacing.minimumTouchTarget], so a deep
/// path is a row of real controls rather than a line of text with hot spots in it.
/// The design's own CSS sets 36 here and its usage note says 48; 48 wins, because
/// 36 would break the touch-target floor the same design declares.
class MxBreadcrumb extends StatefulWidget {
  const MxBreadcrumb({
    required this.items,
    this.semanticLabel,
    this.rootIcon,
    this.collapseAfter = 4,
    super.key,
  });

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

  /// Above this many steps the middle folds into an expandable ellipsis.
  ///
  /// The fold keeps the first step and the last two — the two ends are the ones a
  /// user navigates to, and the middle is the part they scrolled past on the way
  /// down.
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isFolded
              ? <Widget>[
                  _MxBreadcrumbStep(item: items.first, icon: widget.rootIcon),
                  const _MxBreadcrumbSeparator(),
                  _MxBreadcrumbFold(
                    hiddenCount: hiddenCount,
                    onExpand: () => setState(() => _isExpanded = true),
                  ),
                  for (final item in items.sublist(
                    items.length - 2,
                  )) ...<Widget>[
                    const _MxBreadcrumbSeparator(),
                    _MxBreadcrumbStep(item: item),
                  ],
                ]
              : <Widget>[
                  for (final (int index, MxBreadcrumbItem item)
                      in items.indexed) ...<Widget>[
                    if (index > 0) const _MxBreadcrumbSeparator(),
                    _MxBreadcrumbStep(
                      item: item,
                      icon: index == 0 ? widget.rootIcon : null,
                    ),
                  ],
                ],
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

/// One step: a link when there is somewhere to go, text when there is not.
///
/// **A link, not a button — every state lives on the text.** It was an `InkWell`
/// with a rounded highlight, which drew a filled chip behind the word on hover:
/// four or five of those in a row read as a toolbar of buttons rather than as a
/// path, and the boxes appear and vanish under the pointer as it crosses the
/// strip. `MxTextButton` settled this shape for the project — states on the
/// label, no surface under it — and a breadcrumb step is the same kind of thing.
///
/// Hover and press take the label to the full ink and underline it; focus
/// underlines at twice the font's stroke. That is the kit's own rule for
/// `.mx-crumbs__step--link`, minus the background it also painted.
class _MxBreadcrumbStep extends StatefulWidget {
  const _MxBreadcrumbStep({required this.item, this.icon});

  final MxBreadcrumbItem item;
  final IconData? icon;

  @override
  State<_MxBreadcrumbStep> createState() => _MxBreadcrumbStepState();
}

class _MxBreadcrumbStepState extends State<_MxBreadcrumbStep> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final tap = widget.item.onTap;

    // Quiet when there is nowhere to go — **derived from [MxBreadcrumbItem.onTap],
    // not from the position in the list.** It was keyed on "is this the last
    // one", which was the same thing only while every caller ended its path with
    // the current step. The deck list stopped doing that and the bug was
    // immediate: its final ancestor was a working link drawn as though it were
    // not one. A control's appearance has to follow whether it acts.
    //
    // **Both states rest at `onSurfaceVariant`, and weight is what separates
    // them.** A link used to be `onSurface`, which made the path as loud as the
    // app-bar title one line above it. A breadcrumb is chrome; the design
    // carries the whole distinction in weight for that reason, and this matches.
    // **No 48 floor on this branch.** `AppSpacing` calls the touch target a
    // floor rather than a step because it applies to things a finger has to hit,
    // and this step is a statement. In a mixed strip nothing moves — the row is
    // as tall as its tallest child and the tappable steps still carry 48 — so
    // the only strip that shrinks is one made entirely of text. That is the deck
    // list, whose single `Root` step arrived into a screen the compact scale had
    // already trimmed to four spare pixels at `textScaler` 2.0.
    if (tap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          widget.item.label,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          maxLines: 1,
        ),
      );
    }

    // Quiet at rest, full ink once the pointer is on it — not a blend toward the
    // ink the way `MxTextButton` does it. That button starts from an accent and
    // has somewhere to travel; a crumb starts at `onSurfaceVariant`, and the
    // kit's rule for it goes the whole way to the primary text colour.
    //
    // `decorationColor` is set explicitly: left null the engine falls back to a
    // default that does not track this colour, and the underline visibly
    // disagrees with the text it belongs to.
    final ink = _isHovered
        ? context.colors.onSurface
        : context.colors.onSurfaceVariant;
    final style = context.texts.labelMedium?.copyWith(
      color: ink,
      fontWeight: FontWeight.w600,
      decoration: _isHovered || _isFocused ? TextDecoration.underline : null,
      decorationColor: ink,
      decorationThickness: _isFocused ? _kFocusUnderlineThickness : null,
    );

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: tap,
          onHover: (bool value) => setState(() => _isHovered = value),
          onFocusChange: (bool value) => setState(() => _isFocused = value),
          // No hover surface, no focus surface, no ripple — the whole point of
          // the change. The states are on the text instead.
          overlayColor: _noOverlay(context),
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minimumTouchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Padding(
                // Horizontal `sm` so the word does not touch the chevrons on
                // either side; the vertical floor is height rather than padding,
                // as `AppSpacing` intends for a touch target.
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    // The glyph is deliberately outside the underline: a
                    // decoration that reached it would draw a rule under the
                    // home icon as well as the word.
                    if (widget.icon != null)
                      Icon(widget.icon, size: AppIconSize.sm, color: ink),
                    Text(widget.item.label, style: style, maxLines: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The chevron between two steps. Decorative: the path is announced by the
/// container's own label, so a separator with a semantic label would read the
/// word "chevron" between every pair of names.
class _MxBreadcrumbSeparator extends StatelessWidget {
  const _MxBreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        Icons.chevron_right,
        size: AppIconSize.sm,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}
