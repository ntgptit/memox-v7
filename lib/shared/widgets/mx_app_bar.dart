import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/typography/app_typography.dart';

/// How much room the bar gives its content, and which title rung it draws.
///
/// **Two densities, not a size parameter.** `compact` is every current call
/// site — a content-title bar over a list or a form. `large` reads the
/// screen-title rung (24/w700/−0.5) for a bar that has to carry more weight
/// than a content bar, and ships fully built even though nothing in the app
/// calls it yet (task-1-brief: "NOT PART OF CURRENT V3 CONTRACT").
enum MxAppBarDensity {
  /// 16/w700/−0.3 title, [AppSpacing.sm] edge padding. Every existing
  /// `MxContentShell` call site.
  compact,

  /// 24/w700/−0.5 title, [AppSpacing.lg] edge padding. No call site yet.
  large,
}

/// The top bar's row: leading, title, actions — extracted from
/// `MxContentShell`'s inline `AppBar` build so the row itself is one
/// component instead of one `_buildAppBar` per screen shape.
///
/// **Paints nothing of its own** (checklist: "Không nhận background"). The
/// ambient `Scaffold`/`ColorScheme.surface` supplies the background —
/// `app_app_bar_theme.dart` already binds that role globally — so this
/// widget is a [SizedBox] and a [Row], never a [Container] with its own
/// colour.
///
/// **A fixed 56dp bar, always** ([kToolbarHeight]). The two-line
/// `titleSubline` bar `MxContentShell` still builds inline is the one shape
/// this widget does not cover — see that file's `_buildAppBar`.
class MxAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MxAppBar({
    required this.title,
    this.leading,
    this.actions,
    this.density = MxAppBarDensity.compact,
    super.key,
  });

  /// Takes a `Widget?`, not a `String`, so a caller can hand in a pre-built
  /// `Text` (or anything else) rather than being forced through one string
  /// API. `MxContentShell` does the `Text(title)` wrapping at its own call
  /// site; this widget only styles and lays out whatever it is given.
  final Widget? title;

  final Widget? leading;

  final List<Widget>? actions;

  final MxAppBarDensity density;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  double get _horizontalPadding => switch (density) {
    MxAppBarDensity.compact => AppSpacing.sm,
    MxAppBarDensity.large => AppSpacing.lg,
  };

  /// `AppTypography`'s own `_role`-built style for this density — a
  /// component-level trio, not a `TextTheme` rung (GC-4's seven roles have
  /// no slot for this bar).
  TextStyle _titleStyle() => switch (density) {
    MxAppBarDensity.compact => AppTypography.appBarContentTitleStyle,
    MxAppBarDensity.large => AppTypography.appBarScreenTitleStyle,
  };

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    final actions = this.actions;

    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading,
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : DefaultTextStyle.merge(
                      style: _titleStyle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title!,
                    ),
            ),
            if (actions != null && actions.isNotEmpty) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (
                    var index = 0;
                    index < actions.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const SizedBox(width: AppSpacing.xs),
                    actions[index],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
