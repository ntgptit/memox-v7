import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/core/theme/app_spacing.dart';

/// Measures the frame a demo golden is about to capture, and writes the numbers
/// down beside the picture.
///
/// **Why this hooks the capture point rather than being a suite of its own.**
/// The gallery's 29 screens each need their own fixture — a fake repository, a
/// router location, a session already part-way through — and those setups live
/// in the demo tests that build them. A separate measuring suite would have to
/// clone all 29, and a clone drifts: it would go on measuring a screen the app
/// no longer renders, which is the exact failure the gallery exists to prevent.
/// Hooking `matchesReviewGolden` means the numbers and the picture always come
/// out of the same pump.
///
/// **Off unless asked for.** `MEMOX_LAYOUT_PROBE=1` turns it on; without it the
/// cost is one environment lookup per golden. It writes rather than asserts,
/// because it is a review instrument — the rules that *fail* a build live in
/// `test/visual_audit/`, and mixing the two would let a spacing opinion break
/// CI.
bool get isLayoutProbeEnabled =>
    Platform.environment['MEMOX_LAYOUT_PROBE'] == '1';

/// Widgets that mean "a finger goes here".
///
/// Listed by name rather than by type so the probe stays in `test/` without
/// importing half the widget library. Material's own buttons are included
/// because a screen can use them directly; the app's `Mx` components wrap
/// these, so their targets are counted through the wrapper's `InkWell`.
const Set<String> _interactive = <String>{
  'InkWell',
  'InkResponse',
  'GestureDetector',
  'IconButton',
  'TextButton',
  'ElevatedButton',
  'FilledButton',
  'OutlinedButton',
  'Switch',
  'Checkbox',
  'Radio',
  'FloatingActionButton',
  'Chip',
  'ActionChip',
  'FilterChip',
};

/// How far outside its own box a target still receives a tap, in one axis.
///
/// **Hit-tested, because the box is not the target.** Material expands a
/// checkbox, radio or chip past its painted size with an `_InputPadding` render
/// object that answers hits outside its child — so reading the `InkWell`'s
/// rectangle under-reports those by 8px a side. The opposite error is worse and
/// this project has already paid for it: a 48px box overflowing a 32px row
/// passes `meetsGuideline`, which reads the *semantics* rect, while every real
/// tap 4px out is dropped by an ancestor whose hit test begins with
/// `size.contains`. Asking the binding what it would actually deliver is the
/// only reading that is true of a device.
///
/// Probes outward one pixel at a time and stops at the first miss, capped —
/// beyond 16 the answer no longer changes any verdict.
///
/// Returns `-1` when the target's own centre is not reachable: it is behind a
/// modal barrier, which is what a dialog or a bottom sheet puts over the screen
/// it opened from. Those are not small targets, they are unreachable ones, and
/// counting them as small would have reported the card list's whole filter row
/// as a defect on all four screens that open a sheet over it.
double _reach(RenderBox target, Rect rect, Axis axis) {
  final view = RendererBinding.instance.renderViews.first.flutterView;
  final centre = rect.center;

  bool hits(Offset point) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, point, view.viewId);
    return result.path.any((entry) => entry.target == target);
  }

  if (!hits(centre)) return -1;

  for (var out = 1.0; out <= 16.0; out++) {
    final before = axis == Axis.vertical
        ? Offset(centre.dx, rect.top - out)
        : Offset(rect.left - out, centre.dy);
    final after = axis == Axis.vertical
        ? Offset(centre.dx, rect.bottom + out - 1)
        : Offset(rect.right + out - 1, centre.dy);
    if (!hits(before) && !hits(after)) return out - 1;
  }

  return 16;
}

/// Counts one occurrence of a spacing value, rounded to a tenth.
void _record(Map<double, int> tally, double value) {
  final key = double.parse(value.toStringAsFixed(1));
  tally[key] = (tally[key] ?? 0) + 1;
}

/// A spacing value the design system admits: a step, or a multiple of the base
/// grid. Off-scale means somebody typed a number.
bool _isOnScale(double value) =>
    AppSpacing.scale.any((step) => (value - step).abs() < 0.01);

/// Walks the rendered tree and writes `build/layout_probe/<name>.json`.
void probeLayout(String goldenPath) {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;

  final name = goldenPath.split('/').last.replaceAll('.png', '');
  final texts = <String, Map<String, Object?>>{};
  final targets = <Map<String, Object?>>[];
  final seenTarget = <String>{};
  final leftEdges = <String, int>{};
  final spacers = <double, int>{};
  final insets = <double, int>{};
  // Who wrote an off-scale number, so a report can say where to look instead
  // of leaving a value nobody can trace.
  final offScaleOwners = <String, Set<String>>{};

  Rect? rectOf(RenderObject? object) {
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return null;
    }
    return object.localToGlobal(Offset.zero) & object.size;
  }

  void visit(Element element, List<String> ancestry, {required bool inChrome}) {
    final render = element.renderObject;

    // --- typography: one entry per rung actually painted --------------------
    //
    // **Icons are not a text rung.** `Icon` paints through a `RenderParagraph`
    // with the icon font, so counting every paragraph counted 16 icons on the
    // deck list as a 24px/400 style and put the screen two rungs over what a
    // reader would ever see as type.
    if (render is RenderParagraph) {
      final style = render.text.style;
      final size = style?.fontSize;
      final isIcon = style?.fontFamily == 'MaterialIcons';
      if (style != null && size != null && !isIcon) {
        final key =
            '$size/${style.fontWeight?.value ?? 400}/'
            '${style.height?.toStringAsFixed(3) ?? '-'}/'
            '${style.letterSpacing?.toStringAsFixed(2) ?? '0'}'
            '${inChrome ? '/nav' : ''}';
        final row = texts.putIfAbsent(
          key,
          () => <String, Object?>{
            'size': size,
            'family': style.fontFamily,
            'weight': style.fontWeight?.value ?? 400,
            'height': style.height,
            'tracking': style.letterSpacing,
            'inNavigationBar': inChrome,
            'count': 0,
          },
        );
        row['count'] = (row['count']! as int) + 1;
      }

      final rect = rectOf(render);
      if (rect != null && !isIcon) {
        final key = rect.left.toStringAsFixed(1);
        leftEdges[key] = (leftEdges[key] ?? 0) + 1;
      }
    }

    // --- touch targets ------------------------------------------------------
    final type = element.widget.runtimeType.toString();
    if (_interactive.contains(type)) {
      final rect = rectOf(render);
      // **Deduplicated by rectangle.** Material builds an `InkResponse` inside
      // an `InkWell` inside a `GestureDetector` over the same box, so counting
      // elements counts one target three times — and three times as many
      // "under 48" when it is under 48.
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final key =
            '${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)},'
            '${rect.width.toStringAsFixed(1)},${rect.height.toStringAsFixed(1)}';
        if (seenTarget.add(key)) {
          targets.add(<String, Object?>{
            'type': type,
            'w': rect.width,
            'h': rect.height,
            'x': rect.left,
            'y': rect.top,
            'render': render,
          });
        }
      }
    }

    // --- the spacing actually written down ----------------------------------
    //
    // **Spacers, not gaps between siblings.** The first version of this walked
    // each `Column`'s children and measured the distance between consecutive
    // ones, and reported almost nothing: a spacer `SizedBox` *is* a child, so
    // its neighbours touch and every gap came out zero. What a person means by
    // "the spacing on this screen" is the numbers somebody typed — the empty
    // boxes between things, and the insets around them — so those are what get
    // read.
    final widget = element.widget;
    if (widget is SizedBox && widget.child == null) {
      final height = widget.height;
      if (height != null && height > 0.5) _record(spacers, height);
    }
    if (widget is Padding) {
      final inset = widget.padding.resolve(TextDirection.ltr);
      for (final edge in <double>[
        inset.top,
        inset.bottom,
        inset.left,
        inset.right,
      ]) {
        if (edge <= 0.5) continue;
        _record(insets, edge);
        if (_isOnScale(edge)) continue;
        offScaleOwners
            .putIfAbsent(edge.toStringAsFixed(1), () => <String>{})
            .add(ancestry.reversed.join(' < '));
      }
    }

    // **A sliding window of the nearest six.** The first version capped the
    // list's length instead, which froze it at the first 25 entries — all of
    // them framework scaffolding near the root — so every off-scale value was
    // blamed on `RootRestorationScope`.
    final grown = <String>[...ancestry, widget.runtimeType.toString()];
    final nextAncestry = grown.length > 6
        ? grown.sublist(grown.length - 6)
        : grown;
    // **The shared tab bar is chrome, not this screen's typography.** Without
    // this the deck list reads as ten rungs when three of them belong to a bar
    // every tab shows — and the screens whose golden omits the bar would be
    // compared against that inflated number.
    final nowInChrome =
        inChrome || element.widget.runtimeType.toString() == 'MxNavigationBar';
    element.visitChildren(
      (child) => visit(child, nextAncestry, inChrome: nowInChrome),
    );
  }

  visit(root, <String>[], inChrome: false);

  final surface = rectOf(root.renderObject);
  for (final target in targets) {
    final render = target.remove('render')! as RenderBox;
    final rect = Rect.fromLTWH(
      target['x']! as double,
      target['y']! as double,
      target['w']! as double,
      target['h']! as double,
    );
    final across = _reach(render, rect, Axis.horizontal);
    final down = _reach(render, rect, Axis.vertical);
    target['occluded'] = across < 0 || down < 0;
    target['effectiveW'] = across < 0 ? 0.0 : rect.width + 2 * across;
    target['effectiveH'] = down < 0 ? 0.0 : rect.height + 2 * down;
  }

  final reachable = targets.where((t) => t['occluded'] == false).toList();

  // **A small target sitting inside a big one is a different claim.** A radio
  // is 40x40 by design and sits in a 361x80 row that answers the same tap, so
  // every finger that lands on it hits something — reporting it as a defect
  // read three deck sheets as broken when a tap anywhere in the row selects.
  // The opposite case is real, though: a delete button inside a card that
  // opens a detail page does a *different* thing, and 40px there is a genuine
  // miss. The probe cannot tell those apart — whether the two do the same
  // thing is a question about intent — so it separates them and lets the
  // reviewer answer, rather than guessing and being silently wrong either way.
  bool enclosedByReachable(Map<String, Object?> target) {
    final rect = Rect.fromLTWH(
      target['x']! as double,
      target['y']! as double,
      target['w']! as double,
      target['h']! as double,
    );
    return reachable.any((other) {
      if (identical(other, target)) return false;
      if ((other['effectiveW']! as double) < 47.5 ||
          (other['effectiveH']! as double) < 47.5) {
        return false;
      }
      final host = Rect.fromLTWH(
        other['x']! as double,
        other['y']! as double,
        other['w']! as double,
        other['h']! as double,
      );
      return host.contains(rect.topLeft) && host.contains(rect.bottomRight);
    });
  }

  final undersized = reachable
      .where(
        (t) =>
            (t['effectiveW']! as double) < 47.5 ||
            (t['effectiveH']! as double) < 47.5,
      )
      .toList();
  for (final target in undersized) {
    target['insideLargerTarget'] = enclosedByReachable(target);
  }
  final small = undersized
      .where((t) => t['insideLargerTarget'] == false)
      .toList();
  final nested = undersized
      .where((t) => t['insideLargerTarget'] == true)
      .toList();

  final report = <String, Object?>{
    'screen': name,
    'surface': <double>[surface?.width ?? 0, surface?.height ?? 0],
    'typographyRungs': texts.length,
    'typographyRungsInContent': texts.values
        .where((t) => t['inNavigationBar'] == false)
        .length,
    'hasNavigationBar': texts.values.any((t) => t['inNavigationBar'] == true),
    'typography': texts.values.toList()
      ..sort((a, b) => (b['size']! as double).compareTo(a['size']! as double)),
    'weights': texts.values.map((t) => t['weight']! as int).toSet().toList()
      ..sort(),
    'tapTargetCount': reachable.length,
    'tapTargetsOccluded': targets.length - reachable.length,
    'tapTargets': reachable,
    'tapTargetsUnder48': small,
    // Under 48 but wholly inside a target that is not — see the note above.
    // Not a verdict: whether the row does the same thing as the control still
    // needs a person.
    'tapTargetsUnder48Nested': nested,
    'textLeftEdges': leftEdges,
    'spacers': _tally(spacers),
    'spacersOffScale': _offScale(spacers),
    'insets': _tally(insets),
    'insetsOffScale': _offScale(insets),
    'offScaleOwners': <String, List<String>>{
      for (final entry in offScaleOwners.entries)
        entry.key: entry.value.toList(),
    },
  };

  final directory = Directory('build/layout_probe');
  if (!directory.existsSync()) directory.createSync(recursive: true);
  File(
    '${directory.path}/$name.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
}

/// `{value: count}` with the values in order, for a report a person reads.
Map<String, int> _tally(Map<double, int> tally) {
  final keys = tally.keys.toList()..sort();
  return <String, int>{for (final key in keys) '$key': tally[key]!};
}

/// Only the values that are not steps — the ones worth a sentence.
Map<String, int> _offScale(Map<double, int> tally) {
  final keys = tally.keys.where((k) => !_isOnScale(k)).toList()..sort();
  return <String, int>{for (final key in keys) '$key': tally[key]!};
}
