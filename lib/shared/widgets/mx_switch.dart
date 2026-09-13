import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';

/// The handoff Switch's paint: a 44 × 26 track and a 20 thumb, nothing else.
///
/// **Its own paint because no theme slot reaches the handoff geometry.**
/// Material's `Switch` fixes its track at 52 × 32 in `_SwitchConfigM3`, and
/// `SwitchThemeData` has no size or duration field (`switch-spec.md` §5).
///
/// **No semantics and no gesture.** [MxSwitchRow] owns both, so the state is
/// announced once and the whole row is the target. [onChanged] only decides
/// whether the paint reads as enabled.
///
/// Disabled keeps a colour per slot rather than one flat alpha (D3): the thumb
/// takes `onDisabled` and the track `disabledSurface`, the pair
/// `app_toggle_themes_test.dart` measures.
class MxSwitch extends StatelessWidget {
  const MxSwitch({required this.isOn, required this.onChanged, super.key});

  final bool isOn;

  /// `null` paints the disabled state.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final isEnabled = onChanged != null;
    final Color track = switch ((isEnabled, isOn)) {
      (false, _) => semantic.disabledSurface,
      (true, true) => scheme.primary,
      (true, false) => scheme.surfaceContainerHighest,
    };
    final Color thumb = isEnabled ? scheme.surfaceBright : semantic.onDisabled;
    // Reduced motion drops the slide and keeps the state.
    final duration = AppMotionPolicy.durationOf(context, AppDurations.toggle);

    return AnimatedContainer(
      duration: duration,
      curve: AppDurations.standard,
      width: AppSizing.switchTrackWidth,
      height: AppSizing.switchTrackHeight,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: AppDurations.standard,
        alignment: isOn
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.switchThumbInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: thumb,
              shape: BoxShape.circle,
              boxShadow: shadowsFor(AppElevation.card, scheme),
            ),
            child: const SizedBox.square(dimension: AppSizing.switchThumb),
          ),
        ),
      ),
    );
  }
}
