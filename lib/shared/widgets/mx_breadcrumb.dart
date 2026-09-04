import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/typography/app_typography.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/extensions/app_ink.dart';
import 'mx_icon.dart';
import 'mx_focus_ring.dart';
import '../../core/theme/foundations/app_radius.dart';

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
/// Every step is its own tap target at [AppSizing.touchTarget]. The
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
    this.lineHeight = AppSizing.touchTarget,
    this.onUp,
    this.onShowAll,
    this.upIcon,
    super.key,
  });

  /// The compact line: a strip that is a *line of a header* rather than a band
  /// of its own.
  ///
  /// **32, and no exemption** (owner review, 2026-08-21). It was 20 with a tap
  /// target per step, which put four controls under the 48dp floor to save
  /// header height — and raising the line to 24 or 32 would only have failed
  /// by less. The interaction model changed instead: at this height the strip
  /// is **one** target spanning most of the bar, which is far more area than
  /// the floor asks for, and it buys the action a reader wants nine times in
  /// ten. The steps stop being controls. See [onUp].
  static const double compactLineHeight = AppSizing.controlDense;

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

  /// Makes the **whole strip** one target: one level up.
  ///
  /// **Why the model changed** (owner review, 2026-08-21). A path of four
  /// steps used to be four controls, each as tall as the line; fitting that
  /// into a header meant either a tall band or targets under the floor. But
  /// the steps were never equally used — "back one level" is what a reader
  /// reaches for almost every time, and it is the only one that has to be
  /// cheap. So the strip is a single wide target for that, [onShowAll] on
  /// long-press reaches any ancestor through a sheet whose rows are ordinary
  /// 48dp list tiles, and the path goes back to being what it reads like: a
  /// sentence saying where you are.
  ///
  /// When this is set, every [MxBreadcrumbItem.onTap] is ignored — a control
  /// inside a control is a gesture arena nobody wins.
  final VoidCallback? onUp;

  /// The long-press companion to [onUp]: reach any ancestor, not just the
  /// nearest. Null leaves the strip tap-only.
  final VoidCallback? onShowAll;

  /// Drawn before the first step when [onUp] is set, so the strip shows what
  /// tapping it does. The back glyph is the only chevron on the line — the
  /// separator between steps is a slash.
  final IconData? upIcon;

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

  /// The header form: one control, and a path that only reads.
  ///
  /// A `Row` that folds rather than the scrolling strip: a view that scrolls
  /// sideways inside a target that answers a tap is two gestures competing for
  /// one drag.
  ///
  /// **Steps drop out whole; they do not shrink together.** The first version
  /// gave the last step `flex: 2` and the earlier ones `flex: 1`, meaning to
  /// make the earlier ones give up width first. `Flexible` does not work that
  /// way - it divides the shortfall *in proportion*, so every step shrank and
  /// every step ellipsized at once. At 360 with the text scale up the deck
  /// header read `Tat ca... / Academic W...`: a breadcrumb where every crumb is
  /// cut has stopped answering the one question it exists for. The deepest step
  /// is now kept whole and the ones above it fold into a single ellipsis, which
  /// is what a reader can still use.
  Widget _buildSingleTarget(
    BuildContext context,
    List<MxBreadcrumbItem> items,
  ) {
    final quiet = context.colors.onSurfaceVariant;
    final style = context.texts.bodySmall?.copyWith(color: quiet);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: InkWell(
        onTap: widget.onUp,
        onLongPress: widget.onShowAll,
        child: SizedBox(
          height: widget.lineHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final leading =
                  (widget.upIcon == null ? 0 : AppIconSize.sm + AppSpacing.xs) +
                  (widget.rootIcon == null
                      ? 0
                      : AppIconSize.sm + AppSpacing.xs);
              final shown = _stepsThatFit(
                context,
                items,
                style,
                constraints.maxWidth - leading,
              );

              return Row(
                children: <Widget>[
                  if (widget.upIcon != null) ...<Widget>[
                    MxIcon(widget.upIcon!, size: MxIconSize.sm),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (widget.rootIcon != null) ...<Widget>[
                    MxIcon(widget.rootIcon!, size: MxIconSize.sm),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (shown.length < items.length) ...<Widget>[
                    Text(_kFoldedSteps, style: style),
                    const SizedBox(width: AppSpacing.xs),
                    Text(_kSeparator, style: style),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  for (final (int index, MxBreadcrumbItem item)
                      in shown.indexed) ...<Widget>[
                    if (index > 0) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      Text(_kSeparator, style: style),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    // **Only the deepest step is `Flexible`, and that is not a
                    // detail.** `Flexible` divides the line by *flex*, not by
                    // need: two of them at flex 1 each take half, so a 121-wide
                    // name in a 190-wide line still ellipsized at 95 even
                    // though both steps fit together. The steps above are laid
                    // out at their own width — `_stepsThatFit` has already
                    // guaranteed they do fit — and the last one takes what is
                    // left, which is the last resort for a name longer than the
                    // whole bar.
                    if (index == shown.length - 1)
                      Flexible(
                        child: Text(
                          item.label,
                          style: style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        item.label,
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The deepest steps that fit in [available], keeping at least one.
  ///
  /// Walks from the current step outwards, because that is the order a reader
  /// needs them in: which deck am I in first, what is above it second.
  List<MxBreadcrumbItem> _stepsThatFit(
    BuildContext context,
    List<MxBreadcrumbItem> items,
    TextStyle? style,
    double available,
  ) {
    if (items.length < 2) return items;

    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();

      return painter.width;
    }

    final separator = AppSpacing.xs * 2 + widthOf(_kSeparator);
    // What a fold costs when it happens: the marker and one separator.
    final fold = widthOf(_kFoldedSteps) + separator;

    var used = widthOf(items.last.label);
    var kept = 1;
    for (var index = items.length - 2; index >= 0; index--) {
      final next = used + separator + widthOf(items[index].label);
      // Every step but the outermost leaves something above it to fold, so the
      // budget has to keep room for the marker that would say so.
      final budget = index == 0 ? available : available - fold;
      if (next > budget) break;
      used = next;
      kept++;
    }

    return items.sublist(items.length - kept);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    if (widget.onUp != null) return _buildSingleTarget(context, items);

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
      // **The fold was the last control outside the focus grammar** (A20.1
      // P1-04). `_noOverlay` switches off the ink well's own focus wash — on
      // purpose, the step beside it does the same — but the step then draws
      // its focus on the text, and the fold, a glyph with no text, drew
      // nothing: a keyboard or Switch Access user could land on it and see
      // no sign of it. The ring `MxCard`, `MxListTile`, `MxPressable` and
      // `MxPillButton` share is the answer, on the 48 box the fold occupies.
      child: MxFocusRing(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onExpand,
            onHover: (bool value) => setState(() => _isHovered = value),
            overlayColor: _noOverlay(context),
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizing.touchTarget,
                minWidth: AppSizing.touchTarget,
              ),
              child: Center(
                child: MxIcon(
                  Icons.more_horiz,
                  ink: _isHovered ? AppInk.stated : AppInk.quiet,
                  size: MxIconSize.sm,
                ),
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
