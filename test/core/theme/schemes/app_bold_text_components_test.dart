import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/schemes/app_bold_text.dart';
import 'package:memox/core/theme/typography/app_typography.dart';

/// A20.1 P1-11 — the OS Bold-text setting reaches the text a *component* draws,
/// through the `wght` axis, and it is tracked **per component theme and slot**.
///
/// **The key is `owner.slot`, and that is the whole point of this file.** The
/// registry this replaces collected bare field names — `textStyle`,
/// `labelStyle`, `labelTextStyle` — into one set and asked whether
/// `app_bold_text.dart` contained each name *anywhere*. Four component themes
/// spell a slot `labelStyle` and two more spell one `labelTextStyle`, so
/// re-weighting the chip's label made the tab bar's label pass too, and a
/// missed owner could not fail the test. That is a global substring check
/// wearing a registry's name, and it is exactly how `dialTextStyle` and
/// `valueIndicatorTextStyle` were missed by hand twice.
///
/// So the registry is *discovered from the built theme*, not written down:
/// [_discover] walks `ThemeData`'s own diagnostics, which emit every component
/// sub-theme and suppress a slot the app left null. What comes back is the set
/// of text-style slots this app actually sets, each named by its owner —
/// `chipTheme.labelStyle` and `tabBarTheme.labelStyle` are two entries, not one.
void main() {
  const FontWeight boldWeight = FontWeight.w700;
  const FontVariation wght700 = FontVariation('wght', 700);

  /// The slots the four themes set, pinned. Discovery answers "what is set";
  /// this answers "what should be set" — without it, a slot that silently left
  /// a component theme would take its own coverage with it and stay green.
  const Set<String> registry = <String>{
    'chipTheme.labelStyle',
    'datePickerTheme.dayStyle',
    'datePickerTheme.weekDayStyle',
    'dialogTheme.contentTextStyle',
    'dialogTheme.titleTextStyle',
    'filledButtonTheme.style.textStyle',
    'inputDecorationTheme.hintStyle',
    'listTileTheme.leadingAndTrailingTextStyle',
    'listTileTheme.subtitleTextStyle',
    'listTileTheme.titleTextStyle',
    'navigationBarTheme.labelTextStyle',
    'outlinedButtonTheme.style.textStyle',
    'popupMenuTheme.labelTextStyle',
    'sliderTheme.valueIndicatorTextStyle',
    'snackBarTheme.contentTextStyle',
    'tabBarTheme.labelStyle',
    'tabBarTheme.unselectedLabelStyle',
    'textButtonTheme.style.textStyle',
    'timePickerTheme.dayPeriodTextStyle',
    'timePickerTheme.dialTextStyle',
    'timePickerTheme.helpTextStyle',
    'timePickerTheme.hourMinuteTextStyle',
    'tooltipTheme.textStyle',
  };

  final themes = <(String, ThemeData Function())>[
    ('light', buildLightTheme),
    ('dark', buildDarkTheme),
    ('high contrast light', buildHighContrastLightTheme),
    ('high contrast dark', buildHighContrastDarkTheme),
  ];

  group(
    'the registry is discovered from the theme, keyed by owner and slot',
    () {
      for (final (name, build) in themes) {
        test(name, () {
          expect(_discover(build()).keys.toSet(), registry);
        });
      }
    },
  );

  group('every owner+slot resolves wght 700 in every state', () {
    for (final (name, build) in themes) {
      test(name, () {
        final base = build();
        final bold = _discover(applyBoldText(base));
        var statefulSlotsWithTwoInks = 0;

        for (final entry in _discover(base).entries) {
          final key = entry.key;
          final after = bold[key];
          expect(after, isNotNull, reason: '$key lost its slot');
          expect(
            after!.kind,
            entry.value.kind,
            reason: '$key changed resolver kind',
          );

          final inks = <Color?>{};
          for (final states in _stateMatrix) {
            final before = entry.value.resolve(states);
            final resolved = after.resolve(states);
            if (before == null) {
              expect(
                resolved,
                isNull,
                reason: '$key $states: invented a style',
              );
              continue;
            }
            inks.add(before.color);
            // **Exact equality, and it carries four claims at once**: the slot
            // resolves `wght 700`; its resolver still answers *this* state
            // rather than the resting one; its state colour survived; and its
            // geometry — size, height, tracking, face — is untouched. A
            // re-weight that flattened `hintStyle`'s disabled ink into the
            // resting ink fails here on the `{disabled}` row.
            expect(
              resolved,
              AppTypography.withWeight(before, boldWeight),
              reason: '$key $states is not the same style re-weighted',
            );
            expect(resolved!.fontWeight, boldWeight, reason: '$key $states');
            expect(
              resolved.fontVariations,
              contains(wght700),
              reason:
                  '$key $states: a variable face reads the axis, not '
                  'fontWeight',
            );
          }
          if (entry.value.kind != _SlotKind.plain && inks.length > 1) {
            statefulSlotsWithTwoInks++;
          }
        }

        // The state matrix is not vacuous: at least one state-resolved slot
        // really answers two inks, so the `{disabled}` rows above are proving
        // something. `hintStyle` is the one that regressed (corrective pass 2).
        expect(
          statefulSlotsWithTwoInks,
          greaterThanOrEqualTo(1),
          reason: 'no state-resolved slot varies its ink — matrix is vacuous',
        );
      });
    }
  });

  test(
    'the base type scale is the other half, and nothing else reads a face',
    () {
      // `textTheme` and `primaryTextTheme` are excluded from the registry above:
      // the first is the type scale, owned by `app_bold_text_test.dart`; the
      // second is derived by `ThemeData` and read only by Material's **M2**
      // branches — `CircleAvatar`, `TabBar` and `AboutDialog` each take
      // `textTheme` when `useMaterial3` is true. This pins the condition that
      // keeps it unreachable rather than asserting it in prose.
      for (final (name, build) in themes) {
        expect(build().useMaterial3, isTrue, reason: name);
      }
    },
  );

  group('every slot MemoX sets in a component theme is in the registry', () {
    test('the theme sources name no owner+slot the registry misses', () {
      // The cross-check the discovery cannot make on its own: discovery reads
      // `debugFillProperties`, so a slot an SDK theme declares but does not
      // report would be invisible to it. This reads MemoX's own component
      // sources instead — the constructor that opens the argument list is the
      // owner — and requires each pair it finds to be in the registry.
      final missing = <String>[];
      for (final (owner, slot) in _sourceSlots()) {
        final accessor = _accessorFor(owner);
        if (accessor == null) continue;
        final hit = registry.any(
          (key) =>
              key.toLowerCase() == '$accessor.$slot'.toLowerCase() ||
              key.toLowerCase() == '$accessor.style.$slot'.toLowerCase(),
        );
        if (!hit) missing.add('$owner.$slot');
      }
      expect(missing, isEmpty, reason: 'set by a theme, not in the registry');
    });

    test('the source scan finds the slots it is meant to find', () {
      // A scan that parses nothing passes the test above vacuously.
      final pairs = _sourceSlots();
      expect(pairs.length, greaterThanOrEqualTo(20));
      expect(pairs, contains(('TimePickerThemeData', 'dialTextStyle')));
      expect(pairs, contains(('SliderThemeData', 'valueIndicatorTextStyle')));
      // The two the naive line-based scan mis-attributed: `labelTextStyle` sits
      // after a nested `IconThemeData(` in the navigation bar's theme, so an
      // owner read off the last constructor *seen* names the wrong one.
      expect(pairs, contains(('NavigationBarThemeData', 'labelTextStyle')));
      expect(pairs, contains(('PopupMenuThemeData', 'labelTextStyle')));
    });
  });
}

/// The states a slot is asked to answer. `selected` and `disabled` together is
/// the pair `_ChoiceChipDefaultsM3` resolves in a different order than the
/// resting one, and the pair a flattened resolver gets wrong.
const List<Set<WidgetState>> _stateMatrix = <Set<WidgetState>>[
  <WidgetState>{},
  <WidgetState>{WidgetState.disabled},
  <WidgetState>{WidgetState.selected},
  <WidgetState>{WidgetState.hovered},
  <WidgetState>{WidgetState.focused},
  <WidgetState>{WidgetState.pressed},
  <WidgetState>{WidgetState.error},
  <WidgetState>{WidgetState.selected, WidgetState.disabled},
  <WidgetState>{WidgetState.selected, WidgetState.hovered},
];

enum _SlotKind { plain, stateStyle, stateProperty }

/// One text-style slot of one component theme, with the way it answers states.
class _Slot {
  const _Slot(this.kind, this._resolve);

  final _SlotKind kind;
  final TextStyle? Function(Set<WidgetState>) _resolve;

  TextStyle? resolve(Set<WidgetState> states) => _resolve(states);
}

bool _isOwner(Object value) {
  final name = value.runtimeType.toString();
  return value is Diagnosticable &&
      (name.endsWith('ThemeData') ||
          name.endsWith('Theme') ||
          name.endsWith('ButtonStyle'));
}

/// Every text-style slot the theme sets, keyed `owner.slot`.
///
/// `ThemeData.debugFillProperties` emits all forty-odd component sub-themes,
/// and each of those suppresses a null slot — so what comes back is what this
/// app set, not what Material could have. `ButtonStyle` is one level deeper,
/// which is why the walk recurses rather than reading a fixed depth.
Map<String, _Slot> _discover(ThemeData theme) {
  final slots = <String, _Slot>{};
  void walk(Diagnosticable node, String path, int depth) {
    if (depth > 4) return;
    for (final property in node.toDiagnosticsNode().getProperties()) {
      final value = property.value;
      final name = property.name;
      if (value == null || name == null) continue;
      // The type scale, not a component slot — see the exclusion test.
      if (depth == 0 && (name == 'textTheme' || name == 'primaryTextTheme')) {
        continue;
      }
      final here = depth == 0 ? name : '$path.$name';
      if (value is WidgetStateTextStyle) {
        slots[here] = _Slot(_SlotKind.stateStyle, value.resolve);
      } else if (value is TextStyle) {
        slots[here] = _Slot(_SlotKind.plain, (_) => value);
      } else if (value is WidgetStateProperty<TextStyle?>) {
        slots[here] = _Slot(_SlotKind.stateProperty, value.resolve);
      } else if (_isOwner(value)) {
        walk(value as Diagnosticable, here, depth + 1);
      }
    }
  }

  walk(theme, '', 0);
  return slots;
}

/// `ChipThemeData` → `chipTheme`; `InputDecorationTheme` → `inputDecorationTheme`.
/// Anything that is not a component theme — `TextStyle`, `BorderSide` — returns
/// null and is skipped: its `fontStyle:` is not a slot.
String? _accessorFor(String constructor) {
  if (!constructor.endsWith('Theme') && !constructor.endsWith('ThemeData')) {
    return null;
  }
  final stripped = constructor.endsWith('Data')
      ? constructor.substring(0, constructor.length - 4)
      : constructor;
  return stripped[0].toLowerCase() + stripped.substring(1);
}

/// Every `slot:` named in a component-theme constructor in MemoX's own theme
/// sources, paired with the constructor that opened the argument list.
///
/// Depth-aware on purpose: the navigation bar sets `labelTextStyle` after a
/// nested `IconThemeData(`, so an owner read off the most recent constructor
/// name names `IconThemeData`. The stack is what makes the pair right.
Set<(String, String)> _sourceSlots() {
  final pairs = <(String, String)>{};
  final slotName = RegExp(r'^[a-z][a-zA-Z0-9]*(?:Style|TextStyle)$');
  final constructorName = RegExp(r'([A-Z][A-Za-z0-9]*)$');

  for (final file
      in Directory('lib/core/theme/components')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    final source = file.readAsStringSync();
    final stack = <String?>[];
    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (char == "'" || char == '"') {
        final quote = char;
        i++;
        while (i < source.length && source[i] != quote) {
          if (source[i] == r'\') i++;
          i++;
        }
        buffer.clear();
        continue;
      }
      if (char == '/' && i + 1 < source.length && source[i + 1] == '/') {
        while (i < source.length && source[i] != '\n') {
          i++;
        }
        buffer.clear();
        continue;
      }
      if (char == '(') {
        final match = constructorName.firstMatch(buffer.toString().trim());
        stack.add(match?.group(1));
        buffer.clear();
        continue;
      }
      if (char == ')') {
        if (stack.isNotEmpty) stack.removeLast();
        buffer.clear();
        continue;
      }
      if (char == ':') {
        final token = buffer.toString().trim();
        if (stack.isNotEmpty &&
            stack.last != null &&
            slotName.hasMatch(token)) {
          pairs.add((stack.last!, token));
        }
        buffer.clear();
        continue;
      }
      if (char == ',' ||
          char == '{' ||
          char == '}' ||
          char == ';' ||
          char == '\n') {
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
  }
  return pairs;
}
