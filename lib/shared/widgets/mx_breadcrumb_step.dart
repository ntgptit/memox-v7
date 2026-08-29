// The strip's step and its separator.
//
// A `part`, not a second library: they are private to `MxBreadcrumb` and read
// its private helpers, so splitting them out as public types would widen the
// component's surface to satisfy a line count. Cut here when the line-height
// parameter took the file past the 400-line guard.
part of 'mx_breadcrumb.dart';

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
  const _MxBreadcrumbStep({
    required this.item,
    required this.lineHeight,
    this.icon,
    this.isFirst = false,
  });

  final MxBreadcrumbItem item;

  /// The strip's own height — see [MxBreadcrumb.lineHeight].
  final double lineHeight;

  final IconData? icon;

  /// Drops the leading padding, so the strip's first glyph starts exactly on
  /// the gutter every other element on the screen starts from.
  ///
  /// Symmetric `sm` on every step put the first word 8px inside the search field
  /// and the list below it. The padding is there to keep a word off the chevrons
  /// beside it, and the first step has nothing on its left.
  final bool isFirst;

  @override
  State<_MxBreadcrumbStep> createState() => _MxBreadcrumbStepState();
}

class _MxBreadcrumbStepState extends State<_MxBreadcrumbStep> {
  bool _isHovered = false;
  bool _isFocused = false;

  EdgeInsetsGeometry get _padding => EdgeInsetsDirectional.only(
    start: widget.isFirst ? 0 : AppSpacing.sm,
    end: AppSpacing.sm,
  );

  /// The step's leading glyph, tinted to match the label it belongs to.
  ///
  /// **Drawn on both branches.** It was on the tappable one only for a release,
  /// which took the home icon off the deck list — the single non-tappable `Root`
  /// step — and left a bare word where the design's own recognisable mark goes.
  Widget? _icon(AppInk tint) => widget.icon == null
      ? null
      : MxIcon(widget.icon!, ink: tint, size: MxIconSize.sm);

  @override
  Widget build(BuildContext context) {
    final tap = widget.item.onTap;

    // Quiet when there is nowhere to go — **derived from [MxBreadcrumbItem.onTap],
    // not from the position in the list.** It was keyed on "is this the last
    // one", which held only while every caller ended its path with the current
    // step. The deck list stopped doing that and the bug was immediate: its
    // final ancestor was a working link drawn as though it were not one.
    //
    // Both states rest at `onSurfaceVariant` and weight separates them: a link
    // used to be `onSurface`, which made the path as loud as the app-bar title
    // one line above it. A breadcrumb is chrome.
    //
    // **No 48 floor here.** `AppSpacing` calls the touch target a floor because
    // it applies to what a finger must hit, and this step is a statement. A
    // mixed strip does not move — the tappable steps still carry 48 — so the
    // only strip that shrinks is one made entirely of text, which is the deck
    // list's.
    if (tap == null) {
      final quiet = context.colors.onSurfaceVariant;

      return Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: <Widget>[
            ?_icon(AppInk.quiet),
            Text(
              widget.item.label,
              style: context.texts.labelMedium?.copyWith(color: quiet),
              maxLines: 1,
            ),
          ],
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
    // Through the wght axis — a bare `fontWeight:` paints the rung's old
    // weight.
    final style =
        AppTypography.withWeight(
          context.texts.labelMedium!,
          FontWeight.w600,
        ).copyWith(
          color: ink,
          decoration: _isHovered || _isFocused
              ? TextDecoration.underline
              : null,
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
            constraints: BoxConstraints(minHeight: widget.lineHeight),
            child: Center(
              widthFactor: 1,
              child: Padding(
                // `sm` so the word does not touch the chevrons beside it; the
                // vertical floor is height rather than padding, as `AppSpacing`
                // intends for a touch target.
                padding: _padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    // The glyph is deliberately outside the underline: a
                    // decoration that reached it would draw a rule under the
                    // home icon as well as the word.
                    ?_icon(_isHovered ? AppInk.stated : AppInk.quiet),
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
    // **A slash, not a chevron** (owner review, 2026-08-21). The header's way
    // back is a `<`, and a `>` between every step put two arrows pointing
    // opposite ways on one line — the eye reads them as controls in
    // disagreement rather than as punctuation.
    return ExcludeSemantics(
      child: Text(
        _kSeparator,
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Between two steps. A path is read, and a path is written with slashes.
const String _kSeparator = '/';

/// Stands in for the steps a narrow header could not fit.
///
/// A character rather than the `more_horiz` icon the scrolling strip folds
/// with: this one sits in a line of text between two slashes, where an icon
/// would be the wrong size and off the baseline. It is also not a control here
/// — the whole header is one target — so it has nothing to announce that the
/// strip's fold button does.
const String _kFoldedSteps = '…';
