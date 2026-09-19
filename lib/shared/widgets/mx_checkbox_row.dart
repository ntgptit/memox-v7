import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';

/// A checkbox row in a pick-many list.
///
/// The row, rather than its 20dp mark, is the target. Its public API contains
/// only caller-owned copy and state; geometry and visual states belong here.
class MxCheckboxRow extends StatelessWidget {
  const MxCheckboxRow({
    required this.label,
    required this.isChecked,
    required this.onToggle,
    this.subtitle,
    super.key,
  });

  /// Already-localized words for the choice.
  final String label;

  /// Secondary line under the label — a count or a hint.
  final String? subtitle;

  final bool isChecked;

  /// Called on a tap, Space, or Enter. `null` locks the row.
  final VoidCallback? onToggle;

  bool get _isEnabled => onToggle != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final content = Row(
      children: <Widget>[
        SizedBox(
          width: AppSizing.touchTarget,
          child: Center(child: _CheckboxMark(isChecked: isChecked)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label),
              if (subtitle != null) Text(subtitle!),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      checked: isChecked,
      enabled: _isEnabled,
      label: label,
      onTap: _isEnabled ? onToggle : null,
      child: MxFocusRing(
        borderRadius: BorderRadius.zero,
        child: FocusableActionDetector(
          enabled: _isEnabled,
          mouseCursor: _isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                onToggle?.call();
                return null;
              },
            ),
          },
          child: Material(
            type: MaterialType.transparency,
            child: Opacity(
              opacity: _isEnabled ? 1 : AppStateOpacity.disabled,
              child: InkWell(
                onTap: onToggle,
                overlayColor: AppInteractionStates.rowOverlay(colors),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizing.touchTarget,
                  ),
                  child: ExcludeSemantics(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckboxMark extends StatelessWidget {
  const _CheckboxMark({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      key: kMxCheckboxBoxKey,
      width: _kBoxSize,
      height: _kBoxSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isChecked ? colors.primary : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: isChecked
              ? null
              : Border.all(
                  color: colors.outline,
                  width: AppStroke.selectionControl,
                ),
        ),
        child: isChecked
            ? IconTheme(
                data: IconThemeData(color: colors.onPrimary),
                child: const Icon(
                  Icons.check,
                  key: kMxCheckboxGlyphKey,
                  size: _kCheckGlyphSize,
                ),
              )
            : null,
      ),
    );
  }
}

/// Test hooks for the fixed painted geometry.
@visibleForTesting
const Key kMxCheckboxBoxKey = ValueKey<String>('mx_checkbox_box');

@visibleForTesting
const Key kMxCheckboxGlyphKey = ValueKey<String>('mx_checkbox_glyph');

const double _kBoxSize = 20;
const double _kCheckGlyphSize = 14;
