import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

/// **Does any combination of states move a slot off its canonical role?**
///
/// `m3_role_contract_test.dart` asks each slot what it resolves to for
/// `{}` and `{selected}`. That is the question a resolver answers *last*, and it
/// is not the one that broke: every one of these resolvers is an ordered chain,
/// so the failure lives in a combination — `{selected, focused}` reaching a
/// `focused` branch placed above the `selected` one, and returning a role the
/// component has no business wearing.
///
/// Four slots were doing exactly that until M100.23. A keyboard user tabbing
/// onto an applied filter, a switched-on toggle, a chosen segment or a ticked
/// checkbox saw the control leave its Material role — and no test could see it,
/// because no test asked about two states at once.
///
/// **The rule this file encodes:** a slot's colour answers *what the component
/// is*; an interaction state answers *what is happening to it*. Material 3
/// keeps those in different channels — the semantic state is decided first, and
/// feedback arrives as a state layer, an overlay or a stroke. Where M3 itself
/// changes a role on focus, that is stated here rather than assumed, so the one
/// real exception cannot be mistaken for licence.
void main() {
  const Set<WidgetState> resting = <WidgetState>{};
  const Set<WidgetState> selected = <WidgetState>{WidgetState.selected};
  const Set<WidgetState> focused = <WidgetState>{WidgetState.focused};
  const Set<WidgetState> selectedFocused = <WidgetState>{
    WidgetState.selected,
    WidgetState.focused,
  };
  const Set<WidgetState> hovered = <WidgetState>{WidgetState.hovered};
  const Set<WidgetState> pressed = <WidgetState>{WidgetState.pressed};
  const Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};
  const Set<WidgetState> disabledSelected = <WidgetState>{
    WidgetState.disabled,
    WidgetState.selected,
  };

  for (final (String mode, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    final ThemeData theme = build();
    final ColorScheme scheme = theme.colorScheme;

    /// Asserts every state in [states] resolves [slot] to [role].
    void holds(
      String label,
      Color? Function(Set<WidgetState>) slot,
      List<Set<WidgetState>> states,
      Color role,
    ) {
      for (final Set<WidgetState> state in states) {
        expect(
          slot(state),
          role,
          reason: '$mode: $label left its role under ${_name(state)}',
        );
      }
    }

    group('$mode · ChoiceChip', () {
      final chip = theme.chipTheme;
      Color? side(Set<WidgetState> s) =>
          (chip.side! as WidgetStateBorderSide).resolve(s)?.color;
      Color? fill(Set<WidgetState> s) => chip.color!.resolve(s);
      Color? label(Set<WidgetState> s) =>
          (chip.labelStyle!.color! as WidgetStateColor).resolve(s);

      test('a selected chip has no edge, focused or not', () {
        // The bug this file was written for. `focused` used to be read first
        // and returned a `primary` ring, so tabbing onto an applied filter
        // swapped the chip's boundary role for an interaction cue.
        holds('side', side, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], Colors.transparent);
      });

      test('an unselected chip keeps outlineVariant under focus', () {
        holds('side', side, <Set<WidgetState>>[
          resting,
          focused,
        ], scheme.outlineVariant);
      });

      test('the fill carries the focus cue, and the roles do not move', () {
        holds('fill', fill, <Set<WidgetState>>[
          selected,
        ], scheme.secondaryContainer);
        holds('fill', fill, <Set<WidgetState>>[
          resting,
        ], scheme.surfaceContainerLow);
        // Focus is visible — it is a state layer over the resting fill, not a
        // different token. Both directions are asserted: it must change, and it
        // must not become some other role.
        expect(
          fill(focused),
          isNot(scheme.surfaceContainerLow),
          reason: '$mode: no focus cue',
        );
        expect(fill(selectedFocused), isNot(scheme.secondaryContainer));
      });

      test('the label ink stays with its container in every combination', () {
        holds('label', label, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], scheme.onSecondaryContainer);
        holds('label', label, <Set<WidgetState>>[
          resting,
          focused,
          hovered,
        ], scheme.onSurfaceVariant);
      });
    });

    group('$mode · Switch', () {
      final sw = theme.switchTheme;
      Color? thumb(Set<WidgetState> s) => sw.thumbColor!.resolve(s);
      Color? track(Set<WidgetState> s) => sw.trackColor!.resolve(s);
      Color? edge(Set<WidgetState> s) => sw.trackOutlineColor!.resolve(s);

      test('off keeps outline on surfaceContainerHighest under focus', () {
        holds('thumb', thumb, <Set<WidgetState>>[
          resting,
          focused,
        ], scheme.outline);
        holds('track', track, <Set<WidgetState>>[
          resting,
          focused,
        ], scheme.surfaceContainerHighest);
        holds('trackOutline', edge, <Set<WidgetState>>[
          resting,
          focused,
        ], scheme.outline);
      });

      test('on keeps its pair, and the edge stays gone under focus', () {
        holds('thumb', thumb, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], scheme.onPrimary);
        holds('track', track, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], scheme.primary);
        // `_SwitchDefaultsM3.trackOutlineColor` returns transparent once
        // selected, with no focus branch above it. This used to return
        // `primary` for a focused-on switch — a boundary M3 says should not
        // exist, in a colour that means something else.
        holds('trackOutline', edge, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], Colors.transparent);
      });

      test('the overlay is what a focused switch shows instead', () {
        expect(
          sw.overlayColor!.resolve(focused),
          isNotNull,
          reason:
              '$mode: focus lost its cue when the outline stopped carrying it',
        );
      });
    });

    group('$mode · SegmentedButton', () {
      final style = theme.segmentedButtonTheme.style!;
      Color? side(Set<WidgetState> s) => style.side!.resolve(s)?.color;
      Color? bg(Set<WidgetState> s) => style.backgroundColor!.resolve(s);
      Color? fg(Set<WidgetState> s) => style.foregroundColor!.resolve(s);

      test('the side is outline in every enabled combination', () {
        holds('side', side, <Set<WidgetState>>[
          resting,
          focused,
          selected,
          selectedFocused,
          hovered,
          pressed,
        ], scheme.outline);
      });

      test('the selected pair survives focus', () {
        holds('background', bg, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], scheme.secondaryContainer);
        holds('foreground', fg, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], scheme.onSecondaryContainer);
        holds('foreground', fg, <Set<WidgetState>>[
          resting,
          focused,
        ], scheme.onSurface);
      });
    });

    group('$mode · Checkbox', () {
      final box = theme.checkboxTheme;
      BorderSide? side(Set<WidgetState> s) =>
          (box.side! as WidgetStateBorderSide).resolve(s);
      Color? fill(Set<WidgetState> s) => box.fillColor!.resolve(s);

      test('a ticked box draws no edge, focused or not', () {
        // `_CheckboxDefaultsM3.side` decides `selected` before every
        // interaction state. Reading focus first drew a ring where M3 draws
        // nothing, and inset the fill by the stroke while doing it.
        for (final Set<WidgetState> state in <Set<WidgetState>>[
          selected,
          selectedFocused,
        ]) {
          expect(
            side(state)!.width,
            0,
            reason: '$mode: a ticked box grew an edge under ${_name(state)}',
          );
        }
      });

      test('an empty box darkens to onSurface under focus, as under hover', () {
        holds('side', (s) => side(s)?.color, <Set<WidgetState>>[
          focused,
          hovered,
          pressed,
        ], scheme.onSurface);
        holds('side', (s) => side(s)?.color, <Set<WidgetState>>[
          resting,
        ], scheme.onSurfaceVariant);
      });

      test('the fill is primary whenever it is ticked and enabled', () {
        holds('fill', fill, <Set<WidgetState>>[
          selected,
          selectedFocused,
        ], scheme.primary);
      });
    });

    group('$mode · OutlinedButton', () {
      final style = theme.outlinedButtonTheme.style!;
      Color? side(Set<WidgetState> s) => style.side!.resolve(s)?.color;
      Color? fg(Set<WidgetState> s) => style.foregroundColor!.resolve(s);

      test('focus turns the border primary — and that is M3, not an exception '
          'the app invented', () {
        // The one component in this theme whose *border role* Material itself
        // changes on focus: `_OutlinedButtonDefaultsM3.side` resolves focus to
        // `primary` above its fall-through to `outline`. Stated here so the
        // rule the other four now follow cannot be read as forbidding this.
        holds('side', side, <Set<WidgetState>>[
          resting,
          hovered,
        ], scheme.outline);
        holds('side', side, <Set<WidgetState>>[focused], scheme.primary);
      });

      test('the label is primary in both', () {
        holds('foreground', fg, <Set<WidgetState>>[
          resting,
          focused,
          hovered,
        ], scheme.primary);
      });
    });

    group('$mode · NavigationBar', () {
      final bar = theme.navigationBarTheme;

      test('the active glyph and label keep their own roles under focus', () {
        holds(
          'icon',
          (s) => bar.iconTheme!.resolve(s)?.color,
          <Set<WidgetState>>[selected, selectedFocused],
          scheme.onSecondaryContainer,
        );
        holds(
          'label',
          (s) => bar.labelTextStyle!.resolve(s)?.color,
          <Set<WidgetState>>[selected, selectedFocused],
          scheme.onSurface,
        );
      });
    });

    group('$mode · TextField', () {
      // The one component whose theme declares five state borders by hand,
      // and the one this file skipped (#433 G2). The framework picks the
      // painted border *before* any resolver runs — `input_decorator.dart`
      // 2362–2370 at 3.44.8 — so the combinations are reproduced here in the
      // order it takes them: disabled first, then focus, then error inside
      // each branch.
      final input = theme.inputDecorationTheme;
      Color edge(InputBorder? border) =>
          (border! as OutlineInputBorder).borderSide.color;

      test('error keeps its hue under focus — the stroke tells them apart', () {
        // `{focused, error}` selects `focusedErrorBorder`; `{error}` selects
        // `errorBorder`. Both are `error`: M3 never moves this slot to a
        // third hue (its `onErrorContainer` is hover-under-error, which this
        // theme cannot reach). Discriminability is the stroke's job and is
        // asserted in `app_theme_test.dart`.
        expect(edge(input.errorBorder), scheme.error, reason: mode);
        expect(edge(input.focusedErrorBorder), scheme.error, reason: mode);
      });

      test('focus alone is primary, never error', () {
        expect(edge(input.focusedBorder), scheme.primary, reason: mode);
        expect(edge(input.focusedBorder), isNot(scheme.error), reason: mode);
      });

      test('disabled with an error paints the error edge — canonical', () {
        // `input_decorator.dart:2364`: inside the disabled branch, error wins.
        // A busy form that disables its fields while an error is still on
        // screen (`deck_form_widget`, `tag_rename_widget`) paints a full
        // `error` outline on a greyed field. Pinned so the day the framework
        // changes its mind, the goldens are regenerated on purpose.
        // The framework's own selection, restated as data rather than
        // re-run: `!enabled ? (hasError ? errorBorder : disabledBorder)`.
        final InputBorder chosenWhenDisabledAndErrored = input.errorBorder!;
        expect(edge(chosenWhenDisabledAndErrored), scheme.error, reason: mode);
        expect(
          edge(chosenWhenDisabledAndErrored),
          isNot(edge(input.disabledBorder)),
          reason: '$mode: the disabled edge and the error edge collapsed',
        );
      });

      test('disabled without an error is not a live role', () {
        final Color disabledEdge = edge(input.disabledBorder);
        for (final Color live in <Color>[
          scheme.outline,
          scheme.primary,
          scheme.error,
        ]) {
          expect(disabledEdge, isNot(live), reason: mode);
        }
      });
    });

    group('$mode · disabled does not leak a live role', () {
      test('a disabled control never resolves to an enabled accent', () {
        final chipFill = theme.chipTheme.color!;
        final boxFill = theme.checkboxTheme.fillColor!;

        for (final Set<WidgetState> state in <Set<WidgetState>>[
          disabled,
          disabledSelected,
        ]) {
          expect(
            chipFill.resolve(state),
            isNot(scheme.secondaryContainer),
            reason: '$mode: a disabled chip looks as live as an enabled one',
          );
          expect(
            boxFill.resolve(state),
            isNot(scheme.primary),
            reason: '$mode: a disabled box looks as live as an enabled one',
          );
        }
      });
    });
  }
}

String _name(Set<WidgetState> states) =>
    states.isEmpty ? '{}' : states.map((s) => s.name).join(' + ');
