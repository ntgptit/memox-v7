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
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: _buildBody(context),
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
      bottom: subheader == null
          ? null
          : _MxSubheader(
              gutter: _defaultPadding(context).left,
              child: subheader,
            ),
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
/// below, and pads only its bottom — the app bar already provides the space above.
class _MxSubheader extends StatelessWidget implements PreferredSizeWidget {
  const _MxSubheader({required this.gutter, required this.child});

  final double gutter;
  final Widget child;

  /// A breadcrumb step is [AppSpacing.minimumTouchTarget] tall and the strip pads
  /// [AppSpacing.md] below it. `AppBar.bottom` needs its height up front, so this
  /// is that number.
  static const double _height = AppSpacing.minimumTouchTarget + AppSpacing.md;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: gutter,
        right: gutter,
        bottom: AppSpacing.md,
      ),
      child: SizedBox(
        height: AppSpacing.minimumTouchTarget,
        child: Align(alignment: AlignmentDirectional.centerStart, child: child),
      ),
    );
  }
}

/// 16 normally, 12 below [AppBreakpoints.compact] — the design uses the same two
/// numbers at the same breakpoint.
EdgeInsets _defaultPadding(BuildContext context) {
  final isCompact = AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
  return EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg);
}
