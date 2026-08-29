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
/// A glyph whose colour is **named**, not chosen.
///
/// [ink] is an `AppInk`, not a `Color`, and that is the whole point: a caller
/// can say *quiet* or *danger* and cannot say `#5656C9`. The enum resolves
/// against the theme, so light, dark and high contrast each get the right
/// value from one spelling.
///
/// ## When a raw `Icon` is still correct
///
/// **M100.4 moved ten glyphs in this kit onto `MxIcon` and deliberately left
/// nine on `Icon`.** The count is not the measure — reaching for `MxIcon`
/// everywhere would be a regression, twice over:
///
/// **A glyph inside a button inherits its colour, and must keep inheriting.**
/// `MxActionButton`, `MxTextButton`, `MxIconButton`, `MxFab`, `MxMenuButton`
/// and the search field's clear button all pass no `color:` at all, so the
/// glyph takes `IconTheme` — which the button's own `ButtonStyle` resolves per
/// state. Naming an ink there freezes one colour and the icon then stays lit
/// while the button goes disabled, or stays flat while the label blends on
/// hover. Those six are correct as `Icon` and a future sweep should leave them.
///
/// **A colour that is genuinely computed cannot be a name.**
/// `MxPillButton` reads `DefaultTextStyle.of(context).style.color`, which is
/// the chip theme's `WidgetStateColor` already resolved for this row's state;
/// there is no enum member for "whatever the chip decided". `MxMetricWell`
/// takes a `Color` parameter, which is its own defect and belongs to the API
/// cleanup, not here.
///
/// So the rule this widget enforces is narrower and firmer than "always use
/// MxIcon": **a glyph that names a palette token must name it through
/// `AppInk`.** `test/app/icon_ink_boundary_test.dart` holds the allowlist and the
/// reason for each entry, so an exception has to be argued rather than added.
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
