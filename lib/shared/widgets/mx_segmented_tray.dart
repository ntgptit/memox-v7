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
class MxSegmentedTray<T> extends StatefulWidget {
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

  @override
  State<MxSegmentedTray<T>> createState() => _MxSegmentedTrayState<T>();
}

class _MxSegmentedTrayState<T> extends State<MxSegmentedTray<T>> {
  late List<GlobalKey> _optionKeys;
  int? _focusedOption;

  bool get _showsFocusRing =>
      _focusedOption != null &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    _optionKeys = _keysFor(widget.options.length);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void didUpdateWidget(covariant MxSegmentedTray<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length) {
      _optionKeys = _keysFor(widget.options.length);
      _focusedOption = null;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    super.dispose();
  }

  void _onHighlightModeChanged(FocusHighlightMode _) {
    if (_focusedOption != null) setState(() {});
  }

  List<GlobalKey> _keysFor(int optionCount) =>
      List<GlobalKey>.generate(optionCount, (_) => GlobalKey());

  double get _horizontalPadding => switch (widget.variant) {
    MxSegmentedTrayVariant.settings => AppSpacing.md,
    MxSegmentedTrayVariant.progressRange => AppSpacing.lg,
  };

  void _onFocusChanged(int index, bool hasFocus) {
    if (hasFocus) {
      setState(() => _focusedOption = index);
      return;
    }
    if (_focusedOption == index) setState(() => _focusedOption = null);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: _MxSegmentedTraySurface(
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _optionGap,
                children: <Widget>[
                  for (var index = 0; index < widget.options.length; index++)
                    _SegmentedTrayOption<T>(
                      key: _optionKeys[index],
                      option: widget.options[index],
                      isSelected:
                          widget.options[index].value == widget.selected,
                      isEnabled: widget.onChanged != null,
                      horizontalPadding: _horizontalPadding,
                      onChanged: widget.onChanged,
                      onFocusChanged: (hasFocus) =>
                          _onFocusChanged(index, hasFocus),
                    ),
                ],
              ),
            ),
            if (_showsFocusRing)
              if (_focusedOption case final focusedIndex?)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _MxSegmentedTrayFocusLayer(
                      targetKey: _optionKeys[focusedIndex],
                    ),
                  ),
                ),
          ],
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
    super.key,
    required this.option,
    required this.isSelected,
    required this.isEnabled,
    required this.horizontalPadding,
    required this.onChanged,
    required this.onFocusChanged,
  });

  final MxSegmentedTrayOption<T> option;
  final bool isSelected;
  final bool isEnabled;
  final double horizontalPadding;
  final ValueChanged<T>? onChanged;
  final ValueChanged<bool> onFocusChanged;

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

    final Widget visual = _MxFocusPaintOffset(
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: onFocusChanged,
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

/// Reserves the focus ring's 4dp exterior without widening the option's layout
/// footprint. Its child is no longer the painter: the tray-level overlay owns
/// that so it can draw over every sibling surface.
class _MxFocusPaintOffset extends SingleChildRenderObjectWidget {
  const _MxFocusPaintOffset({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFocusPaintOffset();
}

class _RenderFocusPaintOffset extends RenderShiftedBox {
  _RenderFocusPaintOffset() : super(null);

  static const double _extent = AppSpacing.xs;

  Size _contentSize(Size childSize) => Size(
    math.max(0, childSize.width - (_extent * 2)),
    math.max(0, childSize.height - (_extent * 2)),
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
    (child.parentData! as BoxParentData).offset = const Offset(
      -_extent,
      -_extent,
    );
  }
}

/// Paints after the row, so a focused earlier option is never hidden by a
/// later selected Material surface. The 4dp outside extent keeps 2dp clear of
/// the 2dp indicator without changing the 2dp option layout gap.
class _MxSegmentedTrayFocusLayer extends StatefulWidget {
  const _MxSegmentedTrayFocusLayer({required this.targetKey});

  final GlobalKey targetKey;

  @override
  State<_MxSegmentedTrayFocusLayer> createState() =>
      _MxSegmentedTrayFocusLayerState();
}

class _MxSegmentedTrayFocusLayerState
    extends State<_MxSegmentedTrayFocusLayer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MxSegmentedTrayFocusPainter(
      target: widget.targetKey.currentContext?.findRenderObject() as RenderBox?,
      overlay: context.findRenderObject() as RenderBox?,
      color: context.colors.primary,
    ),
  );
}

class _MxSegmentedTrayFocusPainter extends CustomPainter {
  const _MxSegmentedTrayFocusPainter({
    required this.target,
    required this.overlay,
    required this.color,
  });

  final RenderBox? target;
  final RenderBox? overlay;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (target == null || overlay == null) return;

    final Offset origin = target!.localToGlobal(Offset.zero, ancestor: overlay);
    final RRect ring = RRect.fromRectAndRadius(
      (origin & target!.size).inflate(AppSpacing.xs),
      const Radius.circular(AppRadius.md),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MxSegmentedTrayFocusPainter oldDelegate) =>
      target != oldDelegate.target ||
      overlay != oldDelegate.overlay ||
      color != oldDelegate.color;
}
