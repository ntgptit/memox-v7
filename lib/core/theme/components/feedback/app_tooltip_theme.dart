import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_spacing.dart';

/// How long a pointer rests before a tooltip appears.
///
/// **A component token, not a motion one, and the distinction is the point.**
/// `AppDurations` is a three-rung scale for things the user *watches* — 120 for
/// a press, 200 for a surface, 320 as the ceiling — and this is none of them: it
/// is how long the app waits before deciding a hover was a question. Adding a
/// fourth rung at 500 would have put a number on that scale that no animation
/// may use, and reading it as `AppDurations.slower` at a call site would then be
/// a motion decision nobody made.
///
/// So it lives here, beside the only theme that reads it, and it is named. What
/// it must not be is the anonymous `Duration(milliseconds: 500)` it was: a raw
/// duration is invisible to review precisely because it looks deliberate.
///
/// 500 is Material's own default, kept. Shortening it makes a tooltip fire while
/// a finger is still travelling across a toolbar of icon buttons.
const Duration kTooltipWaitDuration = Duration(milliseconds: 500);

/// The label on a long-press or hover — every `MxIconButton` and the floating
/// action have one.
///
/// `inverseSurface` and `onInverseSurface` rather than a hand-made dark box:
/// they are the M3 roles for exactly this, they already carry the seed, and they
/// invert with the mode so the tooltip stays legible in both.
TooltipThemeData buildTooltipTheme(ColorScheme scheme, TextTheme texts) =>
    TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: texts.labelMedium?.copyWith(color: scheme.onInverseSurface),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      waitDuration: kTooltipWaitDuration,
    );
