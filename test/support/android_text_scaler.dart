import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';

/// Android's **non-linear** font scaling, as a `TextScaler` a widget test can
/// hand to a `MediaQuery`.
///
/// **`TextScaler.linear` cannot express the bug this exists to catch.** Since
/// Android 14 the platform interpolates over a table instead of multiplying, and
/// the table's whole purpose is that large type grows less than small type: a
/// headline at 2× is already enormous, body text at 2× is merely readable. A
/// test written with `TextScaler.linear(2.0)` therefore agrees with a layout
/// that scales its breakpoints by `scale(240)` — the very code path that is
/// wrong — because under a linear scaler every size grows by the same factor and
/// the mistake cancels out.
///
/// The numbers below are Android's published `FontScaleConverter` control
/// points. At the platform's 2.0 setting:
///
/// | declared | painted | factor |
/// |---|---|---|
/// | 12sp | 24 | 2.00 |
/// | 14sp | 28 | 2.00 |
/// | 20sp | 40 | 2.00 |
/// | 30sp | 52 | 1.73 |
/// | 100sp | 100 | **1.00** |
///
/// Read the last row again: at the largest accessibility setting the platform
/// hands back a 100sp "font" unchanged. Anything past the table is flat, so
/// `scale(240)` returns 240 and a threshold built that way never moves.
class AndroidTextScaler extends TextScaler {
  const AndroidTextScaler._(this._fromSp, this._toDp, this.name);

  /// The platform's largest ordinary accessibility step.
  ///
  /// Its factor at body rungs is 2.0 — the same number `TextScaler.linear(2.0)`
  /// applies everywhere — which is what makes it a fair comparison: any
  /// difference a test sees between the two comes from the *shape* of the
  /// curve, not from a different amount of scaling.
  static const AndroidTextScaler largest = AndroidTextScaler._(
    <double>[8, 10, 12, 14, 18, 20, 24, 30, 100],
    <double>[16, 20, 24, 28, 36, 40, 48, 52, 100],
    'android 2.0',
  );

  /// One step below, where the compression at the top is already visible.
  static const AndroidTextScaler large = AndroidTextScaler._(
    <double>[8, 10, 12, 14, 18, 20, 24, 30, 100],
    <double>[12, 15, 18, 21, 27, 30, 34, 37, 100],
    'android 1.5',
  );

  final List<double> _fromSp;
  final List<double> _toDp;
  final String name;

  @override
  double scale(double fontSize) {
    if (fontSize <= _fromSp.first) {
      // Below the table Android keeps the first segment's ratio.
      return fontSize * (_toDp.first / _fromSp.first);
    }
    if (fontSize >= _fromSp.last) {
      // **Flat past the end, and that is the point.** A 240sp "font" comes back
      // as 240.
      return fontSize;
    }
    for (var i = 1; i < _fromSp.length; i++) {
      if (fontSize > _fromSp[i]) continue;
      final double t =
          (fontSize - _fromSp[i - 1]) / (_fromSp[i] - _fromSp[i - 1]);

      return lerpDouble(_toDp[i - 1], _toDp[i], t)!;
    }

    return fontSize;
  }

  /// Deprecated on the base class, but still abstract. Reported at the body
  /// rung, which is the factor a reader would describe the setting by.
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => scale(14) / 14;

  @override
  String toString() => 'AndroidTextScaler($name)';
}
