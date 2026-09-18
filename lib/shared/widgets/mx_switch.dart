import 'dart:async' show unawaited;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_durations.dart';
import '../../core/theme/foundations/app_motion_policy.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/states/app_interaction_states.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_focus_ring.dart';

/// The bare, label-less toggle. `MxSwitchRow` already owns "a switch beside
/// its words"; this is the control underneath, for a caller that composes its
/// own label — or needs none.
///
/// **Occupies 48×48.** The painted track is 44×26, centred in a 48×48 layout
/// and hit-test box (`AppSizing.touchTarget`), so a caller must not add its
/// own 48dp padding around it. The keyboard focus ring paints *outside* that
/// box (52×34) and adds no layout.
///
/// **Custom-painted, not a themed stock `Switch`.** `SwitchThemeData` exposes
/// colours only; it has no hook for this control's fixed 44×26 track and
/// fixed 20dp non-morphing thumb (`switch.dart`'s `_SwitchConfig` bakes both
/// into private M2/M3 constants with no public size override). So this widget
/// reads `ColorScheme` and the shared state tokens directly and paints its own
/// track and thumb, the same way `MxFocusRing` and `MxPressable` already
/// paint their own layers instead of asking Material for a size it will not
/// give.
///
/// **The thumb is one colour in both states, and that deliberately differs
/// from `app_toggle_themes.dart`.** The v3 role registry
/// (`docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md`)
/// binds `Toggle.thumb` to `surfaceBright` with no on/off split, which is what
/// this widget renders. `buildSwitchTheme` instead resolves the *selected*
/// thumb of the stock `Switch`/`SwitchListTile` (the one `MxSwitchRow` renders
/// through) to `onPrimary` — a different rendering path this widget does not
/// consume or correct.
///
/// **Geometry is fixed, not themed.** One size, no caller-supplied colours —
/// a bare control has nothing else to compose, and every value below is the
/// v3 Toggle contract's own dimension table.
class MxSwitch extends StatefulWidget {
  const MxSwitch({
    required this.isOn,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  /// Whether the switch is on.
  final bool isOn;

  /// Called with the requested value on tap, Space or Enter; the caller owns
  /// the state. `null` disables the control: no tap, no keyboard activation,
  /// no focus, painted at `AppStateOpacity.disabled`.
  final ValueChanged<bool>? onChanged;

  /// For standalone use, since this bare control carries no visible text of
  /// its own. A caller composing this into a labelled row owns merging its
  /// own label instead — that composition is `MxSwitchRow`'s job, not this
  /// widget's.
  final String? semanticLabel;

  @override
  State<MxSwitch> createState() => _MxSwitchState();
}

class _MxSwitchState extends State<MxSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;
  final FocusNode _focusNode = FocusNode(debugLabel: 'MxSwitch');

  bool _hovered = false;
  bool _pressed = false;

  bool get _isEnabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kToggleDuration,
      value: widget.isOn ? 1 : 0,
    );
    // `AppDurations.standard` is this app's one "starts and stops on screen"
    // curve; the 160ms duration is this component's own decision, the easing
    // is not.
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppDurations.standard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion removes the slide rather than hurrying it: a zero
    // duration lands on the final value in the frame the change arrives.
    _controller.duration = AppMotionPolicy.durationOf(
      context,
      _kToggleDuration,
    );
  }

  @override
  void didUpdateWidget(covariant MxSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOn == widget.isOn) return;

    unawaited(widget.isOn ? _controller.forward() : _controller.reverse());
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;

    onChanged(!widget.isOn);
  }

  void _handleTapDown(TapDownDetails details) =>
      setState(() => _pressed = true);

  void _handleTapEnd() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      toggled: widget.isOn,
      enabled: _isEnabled,
      label: widget.semanticLabel,
      onTap: _isEnabled ? _handleToggle : null,
      child: SizedBox(
        width: AppSizing.touchTarget,
        height: AppSizing.touchTarget,
        child: GestureDetector(
          // `opaque`: the touch target is the whole 48×48 box, wider than the
          // 44×26 track it centres — a tap on the padding around the track
          // must land the same as a tap on the track itself.
          behavior: HitTestBehavior.opaque,
          onTap: _isEnabled ? _handleToggle : null,
          onTapDown: _isEnabled ? _handleTapDown : null,
          onTapUp: _isEnabled ? (_) => _handleTapEnd() : null,
          onTapCancel: _isEnabled ? _handleTapEnd : null,
          child: Center(
            // The ring layer is 52×34 (track + 2 × (offset + stroke)), wider
            // than the 48×48 box, so it overflows it: paint only, the layout
            // and hit-test box stay 48×48 and the track stays centred.
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              // **`MxFocusRing` wraps the real focus node as its ancestor, on
              // purpose.** `FocusNode.hasFocus` bubbles from a focused
              // descendant up to its ancestors; nesting the ring's own
              // (non-focusable) `Focus` node outside `FocusableActionDetector`
              // is what lets it light up when the control inside it is
              // actually focused — the same shape `MxPressable` already uses
              // around `InkWell`.
              child: MxFocusRing(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  // The ring's stroke is painted *inside* its own box, so the
                  // clear gap of `AppStroke.focusRingOffset` between track and
                  // ring is only real if the padding also covers the stroke.
                  padding: const EdgeInsets.all(_kRingInset),
                  child: FocusableActionDetector(
                    focusNode: _focusNode,
                    enabled: _isEnabled,
                    mouseCursor: _isEnabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    onShowHoverHighlight: (hovering) =>
                        setState(() => _hovered = hovering),
                    actions: <Type, Action<Intent>>{
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (_) {
                          _handleToggle();
                          return null;
                        },
                      ),
                    },
                    child: Opacity(
                      // The v3 global `op-disabled` rule: 0.38 over the whole
                      // painted control, applied once here — not on the touch
                      // target, which paints nothing.
                      opacity: _isEnabled ? 1 : AppStateOpacity.disabled,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) => _buildTrack(colors, isRtl),
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

  /// The track, the thumb and — when pressed or hovered — the state-layer
  /// wash between them. One [Stack] so the wash can be centred on the thumb
  /// without inflating the track's own 44×26 bounds ([Clip.none]: the wash is
  /// `kRadialReactionRadius`-sized, wider than the track is tall, exactly as
  /// Flutter's own `Switch` overflows its track for the same reason).
  Widget _buildTrack(ColorScheme colors, bool isRtl) {
    final t = _animation.value;
    // RTL mirrors which edge is "off": the thumb rests at the layout's start
    // edge and travels toward its end, same as the stock `Switch`.
    final positionT = isRtl ? 1 - t : t;
    final thumbLeft = lerpDouble(_kThumbOffsetOff, _kThumbOffsetOn, positionT)!;
    final trackColor = Color.lerp(
      colors.surfaceContainerHighest,
      colors.primary,
      t,
    )!;
    final overlayColor = _resolveOverlayColor(colors);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(
          key: kMxSwitchTrackKey,
          width: _kTrackWidth,
          height: _kTrackHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        if (overlayColor != null)
          Positioned(
            left: thumbLeft + _kThumbDiameter / 2 - kRadialReactionRadius,
            top: _kTrackHeight / 2 - kRadialReactionRadius,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: overlayColor,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: kRadialReactionRadius * 2,
                  height: kRadialReactionRadius * 2,
                ),
              ),
            ),
          ),
        Positioned(
          left: thumbLeft,
          top: (_kTrackHeight - _kThumbDiameter) / 2,
          child: SizedBox(
            key: kMxSwitchThumbKey,
            width: _kThumbDiameter,
            height: _kThumbDiameter,
            // A circle, not `borderRadius: AppRadius.pill`: the thumb is
            // already square, and `BoxShape.circle` is what a pill degenerates
            // to on a square without asking `BoxDecoration` to reconcile a
            // shape and a radius at once.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceBright,
                shape: BoxShape.circle,
                boxShadow: AppDecorations.cardWhisperShadow(colors),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Pressed wins over hovered — a pressed thumb is also hovered, and
  /// reading hover first would show the lighter wash while the darker one is
  /// the true state (the same ordering `AppInteractionStates._overlay`
  /// itself keeps).
  Color? _resolveOverlayColor(ColorScheme colors) {
    // A press or hover still latched when the control became disabled must
    // not paint.
    if (!_isEnabled) return null;

    final overlay = AppInteractionStates.controlOverlay(colors);
    if (_pressed) return overlay.resolve(<WidgetState>{WidgetState.pressed});
    if (_hovered) return overlay.resolve(<WidgetState>{WidgetState.hovered});
    return null;
  }
}

/// Test-only hooks into the painted geometry. Public so
/// `test/shared/widgets/mx_switch_test.dart` can locate the track and thumb
/// by key rather than by widget type — `SizedBox` and `DecoratedBox` are not
/// unique to this control, and a `Key`'s value, unlike a private type, is
/// visible across library boundaries.
@visibleForTesting
const Key kMxSwitchTrackKey = ValueKey<String>('mx_switch_track');

@visibleForTesting
const Key kMxSwitchThumbKey = ValueKey<String>('mx_switch_thumb');

/// 160ms: this component's own motion decision, not an `AppDurations` rung —
/// none of `fast`/`normal`/`slow` is 160ms.
const Duration _kToggleDuration = Duration(milliseconds: 160);

const double _kTrackWidth = 44;
const double _kTrackHeight = 26;
const double _kThumbDiameter = 20;

/// 3dp inset from each track edge; `44 − 20 − 3 − 3 = 18` of travel,
/// matching `21 − 3`.
const double _kThumbInset = 3;
const double _kThumbOffsetOff = _kThumbInset;
const double _kThumbOffsetOn = _kTrackWidth - _kThumbDiameter - _kThumbInset;

/// Padding between the track and the ring's box: the clear gap plus the
/// stroke painted inside that box.
const double _kRingInset = AppStroke.focusRingOffset + AppStroke.focus;
