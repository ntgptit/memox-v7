import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the state layer an `InkWell` actually painted.
///
/// **Why this rather than reading the widget's `overlayColor`.** A test that
/// asserts `inkWell.overlayColor.resolve({hovered})` proves a property was
/// assigned, not that hovering paints anything — it passes just as happily when
/// the pointer never reaches the control, when the control is disabled, and when
/// something above it eats the event. These helpers drive a real mouse and then
/// look at the paint commands, so the assertion covers the whole path.
///
/// The ink is painted by a private `_RenderInkFeatures`, which is why the layers
/// are found by type name: a `Material` puts its splash and its highlight there
/// and no public render object reports them. Flutter's own Material tests reach
/// for it the same way.
///
/// **Every layer is searched, not one.** Which `Material` receives the ink is a
/// detail of the widget under test — `MxCard` hosts its own, `MxListTile` paints
/// into the `Scaffold`'s — and a probe that guessed would silently assert
/// against an empty layer and pass for the wrong reason.
Iterable<RenderObject> _inkLayers(WidgetTester tester) => tester
    .allRenderObjects
    .where((object) => object.runtimeType.toString() == '_RenderInkFeatures');

/// Shape-agnostic on purpose. An `InkHighlight` draws an `rrect` when it was
/// given a `borderRadius`, a `path` when it was given a `customBorder` and a
/// plain `rect` otherwise — three shapes for one idea, and a test that pinned
/// the shape would break on a change that moved no pixel.
///
/// Compared as packed ARGB rather than by `==`, and that is not a convenience.
/// `InkHighlight` animates its alpha as an *integer* and paints
/// `color.withAlpha(value)`, so a token declared at `alpha: 0.04` reaches the
/// canvas as `10/255 = 0.0392`. The two are the same pixel and are not the same
/// object; comparing the bytes asks the question the eye asks.
PaintPattern _paintsColor(Color color) => paints
  ..something(
    (symbol, arguments) => arguments.whereType<Paint>().any(
      (paint) => paint.color.toARGB32() == color.toARGB32(),
    ),
  );

bool _anyLayerPaints(WidgetTester tester, Color color) {
  // `paints` is typed as `PaintPattern` for the cascade syntax; the object it
  // returns is the `Matcher` that `expect` uses. Cast rather than `expect`,
  // because this has to ask several layers and take the first that answers.
  final matcher = _paintsColor(color) as Matcher;

  return _inkLayers(
    tester,
  ).any((layer) => matcher.matches(layer, <dynamic, dynamic>{}));
}

/// Asserts some ink layer painted [color].
void expectInkColor(WidgetTester tester, Color color, {String? reason}) =>
    expect(
      _anyLayerPaints(tester, color),
      isTrue,
      reason: reason ?? 'no ink layer painted $color',
    );

/// Asserts no ink layer painted [color] — the half usually missing from a hover
/// test, which proves a state can be entered and never that it can be left.
void expectNoInkColor(WidgetTester tester, Color color, {String? reason}) =>
    expect(
      _anyLayerPaints(tester, color),
      isFalse,
      reason: reason ?? 'an ink layer still paints $color',
    );

/// Moves a real mouse onto [finder] and leaves it there.
///
/// Returns the gesture so the caller can move it away again.
Future<TestGesture> hover(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();

  return gesture;
}
