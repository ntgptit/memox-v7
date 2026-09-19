import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  const MxSegmentedTrayOption({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  final T value;

  /// The one-line visible label. Callers whose labels cannot fit side by side
  /// must use an option-row control instead of truncating their copy here.
  final String label;

  /// The fuller accessible description when the compact visible label omits
  /// material context, such as Progress's window ending today.
  final String? semanticLabel;
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
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
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
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The recessed, shared tray surface.
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
    required this.onChanged,
  });

  final MxSegmentedTrayOption<T> option;
  final bool isSelected;
  final bool isEnabled;
  final double horizontalPadding;
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
              softWrap: false,
              style: context.texts.labelSmall!.inked(context, ink),
            ),
          ),
        ),
      ),
    );

    final Widget visual = _MxFocusRingOffset(
      child: MxFocusRing(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: isSelected
              ? _MxSegmentedTrayThumb(child: optionBody)
              : SizedBox(height: AppSizing.controlDense, child: optionBody),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      focusable: isEnabled,
      inMutuallyExclusiveGroup: true,
      label: option.semanticLabel ?? option.label,
      onTap: changed,
      child: ExcludeSemantics(child: MxTapTarget(child: visual)),
    );
  }
}

/// Lets [MxFocusRing] paint 2dp clear of the thumb without changing its
/// content-driven footprint or pushing a neighbouring option away.
class _MxFocusRingOffset extends SingleChildRenderObjectWidget {
  const _MxFocusRingOffset({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFocusRingOffset();
}

class _RenderFocusRingOffset extends RenderShiftedBox {
  _RenderFocusRingOffset() : super(null);

  static const double _extent = AppSpacing.xs;

  Size _contentSize(Size ringSize) => Size(
    math.max(0, ringSize.width - (_extent * 2)),
    math.max(0, ringSize.height - (_extent * 2)),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(Size.zero);

    return constraints.constrain(
      _contentSize(child.getDryLayout(constraints.loosen())),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(0, (child?.getMinIntrinsicWidth(height) ?? 0) - (_extent * 2));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, (child?.getMaxIntrinsicWidth(height) ?? 0) - (_extent * 2));

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(0, (child?.getMinIntrinsicHeight(width) ?? 0) - (_extent * 2));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(0, (child?.getMaxIntrinsicHeight(width) ?? 0) - (_extent * 2));

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(_contentSize(child.size));
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = const Offset(-_extent, -_extent);
  }
}
