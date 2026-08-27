import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_ink.dart';

/// How large an icon draws. The values are `AppIconSize`'s; the enum exists so
/// a call site names a step instead of shipping a number.
enum MxIconSize {
  /// 16 — inline with text, leading a label.
  sm(AppIconSize.sm),

  /// 20 — the compact rows' step.
  mdCompact(AppIconSize.mdCompact),

  /// 24 — the default glyph.
  md(AppIconSize.md),

  /// 40 — hero glyphs in empty/result states.
  lg(AppIconSize.lg);

  const MxIconSize(this.dp);

  final double dp;
}

/// The app's icon, for the places an icon carries meaning of its own.
///
/// Takes no `Color` and no `double` — tone comes from [AppInk]'s finite list
/// and size from [MxIconSize]'s, for the reason `MxActionButton` takes no
/// colour: an open parameter is a decision made per call site, and the guard's
/// `no_raw_style_escape` bans the literal spellings this replaces.
///
/// **A bare `Icon` stays legal.** An icon inside a themed slot — a button's
/// leading glyph, a list tile's `leading:` — inherits the right `IconTheme`
/// and needs nothing from this widget; wrapping it would restate what the slot
/// already decided. This widget is for the icon that stands on its own ground
/// and would otherwise reach for `Icon(color: …)`.
///
/// **[semanticLabel] null means decorative, and decorative means silent.** An
/// icon beside a label that already says the thing must not be read twice;
/// one that carries the only copy of a meaning must say it. The parameter
/// forces the author to decide which one this is.
class MxIcon extends StatelessWidget {
  const MxIcon(
    this.icon, {
    this.ink = AppInk.quiet,
    this.size = MxIconSize.md,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;

  /// Defaults to the quiet ink — the skill's rule for resting icons: an icon
  /// at full text strength competes with the words it decorates.
  final AppInk ink;

  final MxIconSize size;

  /// Read by screen readers; null excludes the icon from semantics entirely.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget glyph = Icon(
      icon,
      size: size.dp,
      color: ink.resolve(context),
      semanticLabel: semanticLabel,
    );
    if (semanticLabel != null) return glyph;

    return ExcludeSemantics(child: glyph);
  }
}
