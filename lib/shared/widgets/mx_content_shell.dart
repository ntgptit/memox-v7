import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// The frame every screen is built in: app bar, gutters, an optional pinned
/// subheader and an optional floating action.
///
/// Exists so screen padding and the app-bar shape are decided once. Without it
/// each screen picks its own padding and the difference is visible the moment
/// two screens sit next to each other in a flow.
///
/// The app bar sits on the **page** colour with no elevation and no scroll tint —
/// during a review the header must stay still, because a colour shift behind the
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
    this.padding,
    this.isScrollable = false,
    this.floatingActionButton,
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

  /// How tall the subheader is. `AppBar.bottom` needs the number up front, so a
  /// caller stacking two rows in there — a path and a search field — has to say
  /// so, and has to scale it with the text: at `textScaler` 2.0 a row that fit

  /// Screen padding. `null` resolves to the scale for the current width:
  /// [AppSpacing.lg], or [AppSpacing.md] below [AppBreakpoints.compact].
  final EdgeInsetsGeometry? padding;

  /// Opt-in: a body that already scrolls must not be nested inside another
  /// scroll view.
  final bool isScrollable;

  final Widget? floatingActionButton;

  @override
  State<MxContentShell> createState() => _MxContentShellState();
}

class _MxContentShellState extends State<MxContentShell> {
  bool _hasScrolled = false;

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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.subheader != null)
              _MxSubheader(
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

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    final subheader = widget.subheader;
    if (widget.title == null && subheader == null) return null;

    return AppBar(
      title: widget.title == null ? null : Text(widget.title!),
      leading: widget.leading,
      automaticallyImplyLeading: widget.leading == null,
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

/// The pinned strip under the bar.
///
/// Carries the screen's horizontal gutter so its contents line up with the body
/// below.
/// **The top of the body, not `AppBar.bottom`.** It was the latter, which forces
/// a height to be declared up front — and the height of this strip depends on the
/// user's text scale, so a declared number is a guess that overflows the moment
/// the guess is low. Above an `Expanded` body it takes the height it needs and
/// stays just as pinned: nothing above the `Expanded` scrolls.
class _MxSubheader extends StatelessWidget {
  const _MxSubheader({required this.gutter, required this.child});

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

/// 16 normally, 12 below [AppBreakpoints.compact] — the design uses the same two
/// numbers at the same breakpoint.
EdgeInsets _defaultPadding(BuildContext context) {
  final isCompact = AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
  return EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg);
}
