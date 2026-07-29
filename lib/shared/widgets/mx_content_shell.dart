import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';

/// The screen shell every screen uses.
///
/// Exists so screen padding and the app-bar shape are decided once. Without it
/// each screen picks its own padding and the difference is visible the moment
/// two screens sit next to each other in a flow.
class MxContentShell extends StatelessWidget {
  const MxContentShell({
    required this.body,
    this.title,
    this.actions,
    this.padding,
    this.isScrollable = false,
    super.key,
  });

  final Widget body;

  /// Already-localized text. Components never reach for ARB themselves — the
  /// screen that owns the copy passes it in.
  final String? title;

  final List<Widget>? actions;

  /// Screen padding. `null` resolves to the scale for the current width:
  /// [AppSpacing.lg] normally, [AppSpacing.md] below
  /// [AppBreakpoints.compact].
  ///
  /// 16 a side costs 10% of a 320-wide screen and 8% of a 393-wide one. The
  /// gutter is the same number and a different amount of the screen, which is
  /// what makes a narrow phone feel padded rather than laid out.
  final EdgeInsetsGeometry? padding;

  /// Whether [body] should scroll once it no longer fits.
  ///
  /// **Opt-in, and it has to be**, because the right answer depends on what the
  /// body is. A body that already scrolls — a `ListView`, a `CustomScrollView` —
  /// must not be nested inside another scroll view: it would be handed
  /// unbounded height and fail outright. A fixed body such as a form must
  /// scroll, or it overflows the moment the screen gets shorter.
  ///
  /// Measured, not assumed: the card editor inside this shell overflows by
  /// 135px in landscape at `textScaler` 2.0, and by 167px in landscape with the
  /// keyboard open. Portrait alone never shows it, which is why it survived
  /// every earlier size test.
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final resolvedPadding = padding ?? _defaultPadding(context);
    if (!isScrollable) return Padding(padding: resolvedPadding, child: body);

    // `minHeight` is what keeps this from being a plain `SingleChildScrollView`.
    // Shrink-wrapping would quietly break every body that expects the viewport
    // height — a `Center`, a `Column` with a `Spacer`, an action pinned to the
    // bottom — so the layout would change on screens that were never too small.
    // With the constraint the body keeps full height and gains scrolling only
    // when it genuinely runs out of room.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Minus the padding, or the body is asked for a full viewport *inside*
        // a padded box and every screen scrolls by exactly the padding height.
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
            child: body,
          ),
        );
      },
    );
  }
}

EdgeInsets _defaultPadding(BuildContext context) {
  final isCompact = AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width);

  return EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg);
}
