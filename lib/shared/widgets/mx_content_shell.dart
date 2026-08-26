import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';
import 'mx_breadcrumb.dart';

/// The frame every screen is built in: app bar, gutters, an optional pinned
/// subheader and an optional floating action.
///
/// Exists so screen padding and the app-bar shape are decided once. Without it
/// each screen picks its own padding and the difference is visible the moment
/// two screens sit next to each other in a flow.
///
/// The app bar sits on the **page** colour with no elevation and no scroll tint —
/// during a study session the header must stay still, because a colour shift behind the
/// card reads as the card itself changing.
///
/// **[subheader] is pinned, and that is the point.** It sits between the bar and
/// the scrolling body and does not move with it — a breadcrumb that scrolls away
/// stops answering "where am I" at exactly the moment a long list makes the
/// question worth asking, and a search field that scrolls away has to be hunted
/// for. Before this slot existed the deck list put its breadcrumb inside the
/// body, which is why it did both.
///
/// **The hairline is derived from scroll position, not drawn always.** A screen
/// whose content fits shows no line at all; once the body has scrolled under the
/// chrome, one appears to separate them. That is a 1px line, not Material's
/// `scrolledUnderElevation` tint, which stays off for the reason above.
class MxContentShell extends StatefulWidget {
  const MxContentShell({
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.subheader,
    this.titleSubline,
    this.padding,
    this.isScrollable = false,
    this.floatingActionButton,
    this.bottomBar,
    super.key,
  });

  final Widget body;

  /// Already-localized text. Components never reach for ARB themselves — the
  /// screen that owns the copy passes it in.
  final String? title;

  /// Usually an `MxIconButton`. Passing it explicitly is what lets a screen
  /// choose its own back affordance; left null, `AppBar` keeps its automatic one.
  final Widget? leading;

  final List<Widget>? actions;

  /// Pinned between the app bar and the scrolling body — a breadcrumb, a search
  /// field, or both.
  final Widget? subheader;

  /// A second line **inside the title**, under [title] itself.
  ///
  /// **Why not [subheader], which is also pinned.** Both stay put when the
  /// body scrolls; what differs is whether the reader sees one header or two
  /// things stacked. As a subheader the breadcrumb sat below the bar with the
  /// bar's bottom slack, the band's padding and the strip's 48dp tap floor
  /// between it and the title — measured on device at roughly 60px, far
  /// enough that the two read as unrelated elements (owner review,
  /// 2026-08-20).
  ///
  /// **In the title slot, not `AppBar.bottom`.** `bottom` gave the line the
  /// full bar width but kept it a separate band with the toolbar's own slack
  /// above it; a `Column` in the title makes the two lines one block with a
  /// single [AppSpacing.sm] between them. The cost is width — the line ends
  /// where the actions begin — which the caller answers by keeping the line
  /// short and letting it ellipsize.
  final Widget? titleSubline;

  /// Screen padding. `null` resolves to the scale for the current width:
  /// [AppSpacing.lg], or [AppSpacing.md] below [AppBreakpoints.compact].
  final EdgeInsetsGeometry? padding;

  /// Opt-in: a body that already scrolls must not be nested inside another
  /// scroll view.
  final bool isScrollable;

  final Widget? floatingActionButton;

  /// An action pinned to the bottom of the screen, below the scrolling body.
  ///
  /// **For the commit a long form ends in.** A save button laid out inside a
  /// scroll view is only reachable from wherever the user happens to have
  /// scrolled to, and everything under it reads as outside what the button
  /// saves — the card editor put `Save changes` above its tag section, and the
  /// tags are written the instant they are typed, so the order actively lied
  /// about what the button did (owner review, 2026-08-26).
  ///
  /// **`Scaffold.bottomNavigationBar`, not a `Column` under the body.** That
  /// slot is what the soft keyboard's inset is measured against, so the bar
  /// rides above the keyboard instead of behind it — which is the state a form
  /// spends most of its life in.
  ///
  /// The shell supplies the gesture inset and the screen gutter, for the same
  /// reason it supplies the body's: a second screen pinning an action must not
  /// have to re-derive the padding, because the two only ever drift apart.
  final Widget? bottomBar;

  @override
  State<MxContentShell> createState() => _MxContentShellState();
}

class _MxContentShellState extends State<MxContentShell> {
  bool _hasScrolled = false;

  /// Line box over font size, for a theme that declares no line height.
  ///
  /// **A fallback now, not the number in use** (owner review, 2026-08-25). It
  /// was applied unconditionally at Material's high end, 1.5, so a two-line bar
  /// could never clip — and the app's `titleLarge` declares 1.2727, so the bar
  /// reserved 33px for a line that renders 28. Five pixels of slack nobody
  /// chose, on top of the bar's own padding, made the block's leftover **odd**:
  /// 17, halved by centring into 8.5, which is why the distance from the
  /// subtitle to the first thing below the bar read 16.5 and could not be
  /// spent, moved or named. Asking the style for its own line height costs the
  /// safety margin nothing — [_barPadding] carries it, as a token.
  static const double _lineFactor = 1.5;

  /// What the bar keeps around the block it centres.
  ///
  /// **`lg`, and it is doing two jobs.** It is the breathing room a bar puts
  /// around its content, and it is the slack that absorbs a subline growing
  /// past [MxBreadcrumb.compactLineHeight] at a large text scale — the job the
  /// 1.5 line factor used to do by accident. At `lg` the leftover is even, so
  /// centring lands on whole pixels and every distance out of this bar is a
  /// number somebody can point at.
  static const double _barPadding = AppSpacing.lg;

  /// Only reached if the theme has no such style, which the app's does.
  static const double _fallbackTitleSize = 22;

  /// Two pixels rather than zero: a scroll view can report a sub-pixel offset at
  /// rest, and a hairline that flickers on an untouched screen is worse than no
  /// hairline.
  static const double _scrolledThreshold = 2;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final scrolled = notification.metrics.pixels > _scrolledThreshold;
    if (scrolled != _hasScrolled) setState(() => _hasScrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: _buildBottomBar(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.subheader != null)
              MxSubheaderBand(
                gutter: _defaultPadding(context).left,
                child: widget.subheader!,
              ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The pinned action, in the gutter its screen already uses.
  ///
  /// `SafeArea(top: false)` because the bar sits at the bottom: the gesture
  /// bar is what it has to clear, and taking the top inset here would add a
  /// status-bar's worth of space in the middle of the screen.
  Widget? _buildBottomBar(BuildContext context) {
    final bar = widget.bottomBar;
    if (bar == null) return null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(mxScreenGutter(context)),
        child: bar,
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    final subheader = widget.subheader;
    final subline = widget.titleSubline;
    if (widget.title == null && subheader == null && subline == null) {
      return null;
    }

    return AppBar(
      title: _buildTitle(context, subline),
      leading: widget.leading,
      // **A subline owns the way back.** The path's own chevron is the up
      // affordance where there is one, so the bar must not also draw the
      // platform arrow beside a title that already has a line under it
      // (owner review, 2026-08-20).
      automaticallyImplyLeading: widget.leading == null && subline == null,
      // Only when a subline is present: the row is sized to the block it
      // holds rather than to Material's one-line default. It never goes below
      // the touch floor — the row carries the bar's icon buttons — and it
      // grows with the text scale, because a title clipped by a fixed bar is
      // the failure this number exists to avoid.
      toolbarHeight: subline == null ? null : _toolbarHeight(context),
      actions: widget.actions,
      // Below the whole chrome block rather than between bar and subheader: the
      // subheader is chrome too, and the line is there to say where chrome ends
      // and scrolled content begins.
      shape: _hasScrolled
          ? Border(
              bottom: BorderSide(color: context.semanticColors.borderSubtle),
            )
          : null,
    );
  }

  /// The title, alone or over its subline.
  Widget? _buildTitle(BuildContext context, Widget? subline) {
    final title = widget.title;
    if (title == null) return subline;
    if (subline == null) return Text(title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: AppSpacing.sm),
        subline,
      ],
    );
  }

  /// The bar's row when it carries two lines: the title's line box, the gap,
  /// the subline's own height, and the padding a bar puts around its content.
  ///
  /// **Each term is what that thing actually measures**, which is what makes
  /// the total spendable: 28 + 8 + 32 + 16 = 84 against a 68px block, so the
  /// 16 left over halves into 8 on each side rather than 8.5. See
  /// [_lineFactor] for the five pixels this used to reserve for nothing.
  double _toolbarHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final title = context.texts.titleLarge;

    return math.max(
      AppSpacing.minimumTouchTarget,
      scaler.scale(title?.fontSize ?? _fallbackTitleSize) *
              (title?.height ?? _lineFactor) +
          AppSpacing.sm +
          MxBreadcrumb.compactLineHeight +
          _barPadding,
    );
  }

  Widget _buildBody(BuildContext context) {
    final resolvedPadding = widget.padding ?? _defaultPadding(context);
    if (!widget.isScrollable) {
      return Padding(padding: resolvedPadding, child: widget.body);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = resolvedPadding
            .resolve(Directionality.of(context))
            .vertical;
        final available = constraints.maxHeight - inset;
        return SingleChildScrollView(
          padding: resolvedPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: available < 0 ? 0 : available,
            ),
            child: widget.body,
          ),
        );
      },
    );
  }
}

/// A subheader strip: the screen's horizontal gutter plus the vertical rhythm
/// the strip is entitled to.
///
/// **It carries no height of its own, and that is the point.** As
/// [MxContentShell.subheader] it sits at the top of the body rather than in
/// `AppBar.bottom`, because the latter forces a height to be declared up front
/// — and this strip's height depends on the user's text scale, so a declared
/// number is a guess that overflows the moment the guess is low. Above an
/// `Expanded` body it takes the height it needs and is just as pinned: nothing
/// above the `Expanded` scrolls.
///
/// **Public because one screen pins the band from inside its own scroll view.**
/// `/progress` composes the overview above the deck level, so the range
/// selector has to travel with the overview and only then stick — that is a
/// `PinnedHeaderSliver`, and [MxContentShell.subheader] cannot express it,
/// being above the body rather than in it. Same band, same padding rule; the
/// widget exists so the compact-tier rule below is not four numbers copied to
/// a second site. A caller pinning it itself supplies its own background —
/// inside the body this widget is transparent, and content would scroll
/// through it.
class MxSubheaderBand extends StatelessWidget {
  const MxSubheaderBand({required this.gutter, required this.child, super.key});

  final double gutter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    return Padding(
      // **The strip's total height is fixed; what changed is where its space
      // sits.** Top used to be zero, on the reasoning that the app bar already
      // provides the gap above. It provides some — a 56pt bar leaves roughly 17
      // under its title — but that is the bar centring its own title, not a gap
      // anyone chose between two elements, and the search pill read as stuck to
      // the chrome. Splitting the regular-width gap `sm` above / `xs` below
      // gives the pill air without moving the body a single pixel.
      //
      // **Keeping the total fixed is the constraint, not an aesthetic.** Adding
      // the space instead of moving it pushes every body pixel down with it, and
      // on the deck list that puts the last card's trailing icon under the
      // floating action — 24px of `textSecondary` on `primary`, which the visual
      // audit fails at 1.13:1. The clearance there is 7px, so any real addition
      // above `xs` collides. See `deck_list_screen.dart`'s `_kListBottomInset`:
      // it reserves room at the *end* of the scroll, which does nothing for a
      // row sitting under the action at rest.
      //
      // More space above than below is also the right grouping. The strip
      // belongs to the content it filters, not to the bar it hangs under.
      //
      // Compact keeps all of it below. At 320 with `textScaler` 2.0 the chrome
      // and this strip together wanted four pixels more than the screen had —
      // the same trade `app_compact_scale.dart` makes with gutters and button
      // padding — and there is nothing left there to redistribute.
      padding: EdgeInsets.only(
        left: gutter,
        right: gutter,
        top: isCompact ? 0 : AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Align(alignment: AlignmentDirectional.centerStart, child: child),
    );
  }
}

/// The screen gutter: 16 normally, 12 below [AppBreakpoints.compact] — the
/// design uses the same two numbers at the same breakpoint.
///
/// Public because a screen that opts out of [MxContentShell.padding] to let one
/// band bleed to the edge still has to line the *rest* of itself up with every
/// other screen. Re-deriving the breakpoint rule at the call site is how the two
/// drift apart, and the drift only shows below 360 where nobody looks.
double mxScreenGutter(BuildContext context) {
  final isCompact = AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
  return isCompact ? AppSpacing.md : AppSpacing.lg;
}

EdgeInsets _defaultPadding(BuildContext context) =>
    EdgeInsets.all(mxScreenGutter(context));
