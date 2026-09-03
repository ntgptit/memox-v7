import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import 'mx_focus_ring.dart';

/// How a pressable surface rounds its ripple. The values are `AppRadius`'s;
/// the enum exists so a call site names a step instead of shipping a
/// `BorderRadius`.
enum MxPressableShape {
  /// Square — a full-bleed row whose ripple runs edge to edge.
  none(null),

  /// 8 — an inline disclosure row.
  sm(AppRadius.sm),

  /// 12 — the house control corner; tiles and option rows.
  md(AppRadius.md);

  const MxPressableShape(this.radius);

  final double? radius;

  BorderRadius? get borderRadius =>
      radius == null ? null : BorderRadius.circular(radius!);
}

/// The ripple leg of a custom interactive surface.
///
/// **Exists so no feature builds a raw `InkWell` again.** Five sites used to:
/// two hand-wrote the `Material(transparency)` + `InkWell` pair their painted
/// container needs, three leaned on whatever `Material` happened to be above
/// them — and one of the five drew a 36dp-tall toggle, because nothing made
/// the touch floor anyone's job. This widget makes it its job:
///
/// - the `Material(transparency)` + `InkWell` pair comes as one piece, so a
///   ripple works identically inside a `DecoratedBox` and on a bare page;
/// - the ripple's corner comes from [MxPressableShape]'s closed list;
/// - the content is floored at [AppSizing.touchTarget] — a pressable
///   thing is a target, and 48 is the floor every control in this app keeps.
///
/// **What it deliberately is not**: a surface. It paints no fill, no border,
/// no elevation — the container around it owns those (a match tile's skin, a
/// guess row's outline, a card). Semantics likewise stay with the caller,
/// because only the caller knows whether this is a button, a disclosure or a
/// selection row.
///
/// **Focus is the shared ring** (M100.36 10C, #431 P1-3). Five feature rows —
/// the trash row, the guess option, the match tile, two disclosure rows —
/// gave a keyboard user a `ThemeData.focusColor` wash at ~1.15:1 and nothing
/// else, where WCAG 1.4.11 asks 3:1. `MxFocusRing` adds the indicator in a
/// foreground layer: additive, no layout movement, keyboard mode only, and
/// it erases no selected or business state the caller painted underneath.
class MxPressable extends StatelessWidget {
  const MxPressable({
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.shape = MxPressableShape.md,
    super.key,
  });

  /// `null` disables the surface: no ripple, no target.
  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  final MxPressableShape shape;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MxFocusRing(
      // A square surface gets a square ring; `BorderRadius.zero` is the
      // shape's own answer for `none`, not a default the ring invented.
      borderRadius: shape.borderRadius ?? BorderRadius.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: shape.borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
            child: child,
          ),
        ),
      ),
    );
  }
}
