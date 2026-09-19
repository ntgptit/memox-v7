import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';
import 'mx_tap_target.dart';

/// The component-owned horizontal gap between adjacent choices.
const double _optionGap = 2;

/// The layout vocabulary for the two approved SegmentedTray callers.
enum MxSegmentedTrayVariant { settings, progressRange }

/// One typed, already-localized choice in an [MxSegmentedTray].
class MxSegmentedTrayOption<T> {
  const MxSegmentedTrayOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A compact, exclusive two-or-three-option selector.
///
/// The recessed tray, raised selected thumb, hit target and focus treatment
/// belong here so Settings and Progress cannot drift while retaining ownership
/// of their localized labels and state transitions.
class MxSegmentedTray<T> extends StatelessWidget {
  static const Key surfaceKey = ValueKey<String>('mx-segmented-tray-surface');
  static const Key thumbKey = ValueKey<String>('mx-segmented-tray-thumb');

  MxSegmentedTray({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.variant,
    super.key,
  }) {
    if (options.length != 2 && options.length != 3) {
      throw ArgumentError.value(
        options.length,
        'options.length',
        'MxSegmentedTray requires two or three options.',
      );
    }
  }

  final List<MxSegmentedTrayOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;
  final MxSegmentedTrayVariant variant;

  double get _horizontalPadding => switch (variant) {
    MxSegmentedTrayVariant.settings => AppSpacing.md,
    MxSegmentedTrayVariant.progressRange => AppSpacing.lg,
  };

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double optionMaxWidth = viewportWidth <= 0
        ? double.infinity
        : (viewportWidth -
                  (AppSpacing.lg * 4) -
                  (AppSpacing.xs * 2) -
                  (_optionGap * (options.length - 1))) /
              options.length;

    return Align(
      widthFactor: 1,
      child: MxTapTarget(
        child: _MxSegmentedTraySurface(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _optionGap,
              children: <Widget>[
                for (final option in options)
                  _SegmentedTrayOption<T>(
                    option: option,
                    isSelected: option.value == selected,
                    isEnabled: onChanged != null,
                    horizontalPadding: _horizontalPadding,
                    maxWidth: optionMaxWidth,
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The recessed, shared tray surface.
///
/// Public for direct geometry tests; callers receive it only through
/// [MxSegmentedTray].
class _MxSegmentedTraySurface extends StatelessWidget {
  const _MxSegmentedTraySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: MxSegmentedTray.surfaceKey,
    height: AppSizing.touchTarget,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          top: (AppSizing.touchTarget - AppSizing.controlCompact) / 2,
          right: 0,
          bottom: (AppSizing.touchTarget - AppSizing.controlCompact) / 2,
          left: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppDecorations.cardWhisperShadow(context.colors),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// The selected option's raised 32dp visual surface.
///
/// Public for direct geometry tests; callers receive it only through
/// [MxSegmentedTray].
class _MxSegmentedTrayThumb extends StatelessWidget {
  const _MxSegmentedTrayThumb({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: MxSegmentedTray.thumbKey,
    height: AppSizing.controlDense,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppDecorations.cardWhisperShadow(context.colors),
      ),
      child: child,
    ),
  );
}

class _SegmentedTrayOption<T> extends StatelessWidget {
  const _SegmentedTrayOption({
    required this.option,
    required this.isSelected,
    required this.isEnabled,
    required this.horizontalPadding,
    required this.maxWidth,
    required this.onChanged,
  });

  final MxSegmentedTrayOption<T> option;
  final bool isSelected;
  final bool isEnabled;
  final double horizontalPadding;
  final double maxWidth;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppInk ink = isSelected ? AppInk.stated : AppInk.quiet;
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);
    final VoidCallback? changed = isEnabled
        ? () => onChanged!(option.value)
        : null;

    final Widget optionBody = Material(
      type: isSelected ? MaterialType.canvas : MaterialType.transparency,
      color: isSelected ? context.colors.surfaceContainerLowest : null,
      borderRadius: radius,
      child: InkWell(
        onTap: changed,
        borderRadius: radius,
        overlayColor: AppInteractionStates.controlOverlay(context.colors),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Center(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall!.inked(context, ink),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      focusable: isEnabled,
      inMutuallyExclusiveGroup: true,
      label: option.label,
      onTap: changed,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Align(
            widthFactor: 1,
            child: SizedBox(
              height: AppSizing.touchTarget,
              child: Center(
                widthFactor: 1,
                child: MxFocusRing(
                  borderRadius: radius,
                  child: isSelected
                      ? _MxSegmentedTrayThumb(child: optionBody)
                      : SizedBox(
                          height: AppSizing.controlDense,
                          child: optionBody,
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
