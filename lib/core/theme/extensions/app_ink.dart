import 'package:flutter/material.dart';

import '../foundations/app_semantic_colors.dart';
import '../typography/app_typography.dart';
import 'theme_context_extension.dart';

/// Every colour a piece of feature text or a feature icon is allowed to wear.
///
/// **An enum, for the reason `MxActionButtonVariant` is one**: the moment a
/// caller can pass a `Color`, the design system stops being enforceable. Before
/// this existed, features styled text through 167 ad-hoc
/// `texts.X.copyWith(color: …)` sites across 89 files — every one a small
/// decision made where no reviewer compares decisions. The clustering that
/// produced this list is in M99.66: half of all sites were the same thought
/// ("this rung, in the quiet ink"), and the whole population fit fourteen
/// names.
///
/// **The names are meanings, not colours.** [overdue] resolves to the same
/// value as [danger] today — the alias exists in `AppSemanticColors` so an
/// audit can tell "this is late" apart from "this deletes", and the enum keeps
/// that distinction rather than flattening it back into one name.
///
/// The `on*Container` members are for text sitting **on their container**, not
/// on the page; `app_ink_test.dart` measures each ink against the ground it is
/// for.
enum AppInk {
  /// `onSurface` — the primary ink, *stated*. Exists because a style taken
  /// from the text theme carries the body colour implicitly, and on a tinted
  /// ground "implicit" has measured 2.33:1 before. Saying it is the fix.
  stated,

  /// `onSurfaceVariant` — the secondary ink. Half the app's restyles were
  /// exactly this.
  quiet,

  /// `primary` — brand as *text*. It used to be a separate text-safe alias,
  /// because the old dark fill tone measured 3.33:1 as bare text on the page;
  /// since M100.18 inverted it to tone 80 the role itself reads at 11.36:1 and
  /// the alias is gone.
  accent,

  /// The verdict and status family.
  success,
  warning,
  danger,
  info,

  /// `scheme.error` — the error family's text on plain grounds.
  error,

  /// `scheme.tertiary` — the steel-blue "same family as info, quieter job"
  /// role; the import preview wears it for duplicates.
  tertiary,

  /// `scheme.secondary` — the slate support role; the import preview's
  /// "ready" rows wear it.
  secondary,

  /// `semanticColors.overdue` — "this is late", distinct in name from
  /// [danger]'s "this deletes".
  overdue,

  /// `onDisabled` — text inside a disabled control.
  disabled,

  /// Inks for text on a tinted container, never on the page.
  onPrimary,
  onPrimaryContainer,
  onSecondaryContainer,
  onErrorContainer,
  onTertiaryContainer,
  onDueContainer,

  /// The label on a status container — the pills an import summary prints.
  ///
  /// `onDangerContainer` **is** [onErrorContainer]; both exist so a call site
  /// can say which it means. A row that failed to parse is an error; a card
  /// that is overdue is not (M100.21).
  onSuccessContainer,
  onWarningContainer,
  onInfoContainer,
  onDangerContainer;

  /// The colour this ink resolves to under [context]'s theme.
  Color resolve(BuildContext context) {
    final ColorScheme colors = context.colors;
    final AppSemanticColors semantic = context.semanticColors;

    return switch (this) {
      AppInk.stated => colors.onSurface,
      AppInk.quiet => colors.onSurfaceVariant,
      AppInk.accent => colors.primary,
      AppInk.success => semantic.success,
      AppInk.warning => semantic.warning,
      AppInk.danger => semantic.danger,
      AppInk.info => semantic.info,
      AppInk.error => colors.error,
      AppInk.tertiary => colors.tertiary,
      AppInk.secondary => colors.secondary,
      AppInk.overdue => semantic.overdue,
      AppInk.disabled => semantic.onDisabled,
      AppInk.onPrimary => colors.onPrimary,
      AppInk.onPrimaryContainer => colors.onPrimaryContainer,
      AppInk.onSecondaryContainer => colors.onSecondaryContainer,
      AppInk.onErrorContainer => colors.onErrorContainer,
      AppInk.onTertiaryContainer => colors.onTertiaryContainer,
      AppInk.onDueContainer => semantic.onDueContainer,
      AppInk.onSuccessContainer => semantic.onSuccessContainer,
      AppInk.onWarningContainer => semantic.onWarningContainer,
      AppInk.onInfoContainer => semantic.onInfoContainer,
      AppInk.onDangerContainer => semantic.onDangerContainer,
    };
  }
}

/// The one legal way for a feature to colour a text rung.
///
/// Replaces the open `copyWith(color: …, fontWeight: …)` with a closed call:
/// the ink comes from [AppInk]'s finite list, emphasis is exactly the app's
/// one emphatic weight and goes through [AppTypography.withWeight] (a bare
/// `fontWeight:` reports one weight and paints another — the bug class the
/// guard's `no_bare_font_weight` exists for), and tabular figures are a flag
/// because a ticking number that shifts its neighbours is a layout bug with a
/// typographic cause.
///
/// **What this deliberately cannot do**: change size, height or tracking. A
/// rung's metrics belong to the rung; text that needs different ones needs a
/// different rung, or a named role on `AppTextStyles` — which is where
/// `cardPrompt` and `sectionLabel` already live.
extension InkedTextStyle on TextStyle {
  TextStyle inked(
    BuildContext context,
    AppInk ink, {
    bool isEmphasized = false,
    bool isTabular = false,
  }) {
    final TextStyle base = isEmphasized
        ? AppTypography.withWeight(this, FontWeight.w600)
        : this;

    return base.copyWith(
      color: ink.resolve(context),
      fontFeatures: isTabular
          ? const <FontFeature>[FontFeature.tabularFigures()]
          : fontFeatures,
    );
  }
}
