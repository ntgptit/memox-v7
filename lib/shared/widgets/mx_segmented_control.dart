import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_elevation.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import 'mx_focus_ring.dart';

/// One choice in an [MxSegmentedControl].
class MxSegment<T> {
  const MxSegment({required this.value, required this.label});

  final T value;

  /// Already-localized.
  final String label;
}

/// The handoff SegmentedButton (D): two or three exclusive choices on a
/// `surfaceContainer` track; the selected one floats as a
/// `surfaceContainerLowest` pill with `shadow-soft`.
///
/// **Not M3's `SegmentedButton`**, whose outlined segments no theme slot turns
/// into a track; `segmentedButtonTheme` stays planned and unrendered. No
/// production caller yet (owner decision 10).
///
/// **Every segment is the 48 target, and the pill is drawn inside it.** Each
/// segment takes the track's full height and insets its pill by
/// [AppSpacing.xs], so the finger gets 48 while the pill reads 40 — the pill's
/// height is what the inset leaves, not a second number.
class MxSegmentedControl<T> extends StatelessWidget {
  const MxSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  }) : assert(
         segments.length >= 2 && segments.length <= 3,
         'The handoff segmented control holds two or three choices.',
       );

  final List<MxSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotionPolicy.durationOf(context, AppDurations.fast);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final segment in segments)
            Flexible(
              child: _Segment(
                label: segment.label,
                isSelected: segment.value == selected,
                duration: duration,
                onTap: () => onChanged(segment.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    // A node of its own per choice: sibling buttons folded into one node read
    // as one control carrying three labels.
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: MxFocusRing(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizing.touchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: AnimatedContainer(
                  duration: duration,
                  curve: AppDurations.standard,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.surfaceContainerLowest : null,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: isSelected
                        ? shadowsFor(AppElevation.card, scheme)
                        : null,
                  ),
                  // Factors of one shrink-wrap the label and centre it in the
                  // height the inset leaves. A bare `alignment:` stretches the
                  // pill to whatever height the row offers — inside a
                  // `Center`, the whole screen.
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge!.inked(
                        context,
                        isSelected ? AppInk.stated : AppInk.quiet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
