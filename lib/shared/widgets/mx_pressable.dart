import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';

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
    return Material(
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
    );
  }
}
