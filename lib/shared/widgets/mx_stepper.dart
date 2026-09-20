import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';
import 'mx_tap_target.dart';

/// A compact numeric control whose caller owns the value and every bound.
///
/// The component deliberately has no minimum, maximum, validation message, or
/// persistence: a setting, a study option, and an editor field do not share
/// those rules. Nulling an individual callback is the caller's sole way to
/// make that action unavailable; [isEnabled] disables the complete control.
class MxStepper extends StatelessWidget {
  const MxStepper({
    required this.value,
    required this.decrementSemanticLabel,
    required this.incrementSemanticLabel,
    required this.onDecrement,
    required this.onIncrement,
    this.isInvalid = false,
    this.isBusy = false,
    this.isEnabled = true,
    super.key,
  });

  /// The caller-owned value. It is rendered unchanged, including negatives.
  final int value;

  /// Already-localized name for the decrement icon action.
  final String decrementSemanticLabel;

  /// Already-localized name for the increment icon action.
  final String incrementSemanticLabel;

  /// Null means only this action is unavailable; the component does not infer
  /// or paint an at-bound state.
  final VoidCallback? onDecrement;

  /// Null means only this action is unavailable; the component does not infer
  /// or paint an at-bound state.
  final VoidCallback? onIncrement;

  /// Paints the value's invariant border and ink as an error without changing
  /// the component's geometry.
  final bool isInvalid;

  /// Replaces the numeral only, preserving the value column and both actions.
  final bool isBusy;

  /// Blocks the entire control and applies the disabled opacity exactly once.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.circular(AppRadius.md);
    final Widget core = Semantics(
      container: true,
      enabled: isEnabled,
      value: isBusy ? null : value.toString(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: <Widget>[
          _StepperButton(
            paintKey: const ValueKey<String>('mx-stepper-decrement-paint'),
            icon: Icons.remove,
            semanticLabel: decrementSemanticLabel,
            onPressed: onDecrement,
            isEnabled: isEnabled,
            shape: shape,
          ),
          _ValueColumn(value: value, isInvalid: isInvalid, isBusy: isBusy),
          _StepperButton(
            paintKey: const ValueKey<String>('mx-stepper-increment-paint'),
            icon: Icons.add,
            semanticLabel: incrementSemanticLabel,
            onPressed: onIncrement,
            isEnabled: isEnabled,
            shape: shape,
          ),
        ],
      ),
    );

    return isEnabled
        ? core
        : Opacity(opacity: AppStateOpacity.disabled, child: core);
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.paintKey,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    required this.isEnabled,
    required this.shape,
  });

  final Key paintKey;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final BorderRadius shape;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = isEnabled ? onPressed : null;

    return Semantics(
      button: true,
      enabled: action != null,
      focusable: action != null,
      label: semanticLabel,
      onTap: action,
      child: ExcludeSemantics(
        child: MxTapTarget(
          child: MxFocusRing(
            borderRadius: shape,
            child: Material(
              key: paintKey,
              color: context.colors.surfaceContainer,
              borderRadius: shape,
              child: InkWell(
                onTap: action,
                borderRadius: shape,
                overlayColor: AppInteractionStates.controlOverlay(
                  context.colors,
                ),
                child: SizedBox.square(
                  dimension: AppSizing.controlSmall,
                  child: Center(child: Icon(icon, size: AppIconSize.sm)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueColumn extends StatelessWidget {
  const _ValueColumn({
    required this.value,
    required this.isInvalid,
    required this.isBusy,
  });

  final int value;
  final bool isInvalid;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final AppInk valueInk = isInvalid ? AppInk.errorDirect : AppInk.stated;
    final TextStyle valueStyle = context.textStyles.stepperValue.inked(
      context,
      valueInk,
    );

    return Semantics(
      container: true,
      value: isBusy ? null : value.toString(),
      child: DecoratedBox(
        key: const ValueKey<String>('mx-stepper-value-column'),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.error.withValues(alpha: isInvalid ? 1 : 0),
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSizing.touchTarget),
          child: SizedBox(
            height: AppSizing.controlSmall,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Visibility(
                  visible: !isBusy,
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  child: ExcludeSemantics(
                    child: Text(value.toString(), style: valueStyle),
                  ),
                ),
                if (isBusy)
                  SizedBox.square(
                    dimension: AppIconSize.sm,
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                      strokeWidth: AppStroke.indicator,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
