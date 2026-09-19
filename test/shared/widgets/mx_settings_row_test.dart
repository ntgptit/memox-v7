import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// `MxSettingsRow` — a settings-screen row: leading `MxIconTile`, label +
/// optional sub, and an optional trailing control (inline, wide, or a
/// navigation chevron). See the SettingsRow component handoff and
/// `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` §15.2.
///
/// Typography and colour + semantics assertions live in
/// `mx_settings_row_contract_test.dart` (400-line guard split, same shape as
/// `mx_list_tile_test.dart` / `mx_list_tile_contract_test.dart`).
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const long =
      'A setting name long enough that it has to wrap or be cut off, twice over';

  group('MxSettingsRow layout', () {
    testWidgets('renders label, sub and a leading MxIconTile', (tester) async {
      await pump(
        tester,
        const MxSettingsRow(
          label: 'Notifications',
          sub: 'Reminders and study nudges',
          leadingIcon: Icons.notifications_outlined,
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Reminders and study nudges'), findsOneWidget);
      expect(find.byType(MxIconTile), findsOneWidget);
    });

    testWidgets('with no leadingIcon, no MxIconTile is built', (tester) async {
      await pump(tester, const MxSettingsRow(label: 'Notifications'));

      expect(find.byType(MxIconTile), findsNothing);
    });

    testWidgets('is at least AppSizing.touchTarget tall', (tester) async {
      await pump(tester, const MxSettingsRow(label: 'Notifications'));

      expect(
        tester.getSize(find.byType(MxSettingsRow)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('a long label and sub wrap rather than overflow', (
      tester,
    ) async {
      await pump(
        tester,
        MxSettingsRow(label: long, sub: long, onTap: () {}),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('MxSettingsRow trailing shapes', () {
    testWidgets('navigable: draws the chevron', (tester) async {
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('a static row (no onTap) draws no chevron', (tester) async {
      await pump(tester, const MxSettingsRow(label: 'App version'));

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('a trailing control suppresses the chevron', (tester) async {
      await pump(
        tester,
        MxSettingsRow(
          label: 'Reminders',
          onTap: () {},
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('a wideControl drops to its own line and suppresses the '
        'chevron', (tester) async {
      await pump(
        tester,
        MxSettingsRow(
          label: 'Daily goal',
          onTap: () {},
          wideControl: const Text('stepper'),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      final rowBottom = tester.getBottomLeft(find.text('Daily goal')).dy;
      final controlTop = tester.getTopLeft(find.text('stepper')).dy;
      expect(
        controlTop,
        greaterThan(rowBottom),
        reason: 'the control is not on its own line',
      );
    });

    test('passing both trailing and wideControl is a contract violation', () {
      expect(
        () => MxSettingsRow(
          label: 'Bad',
          trailing: const Icon(Icons.check),
          wideControl: const Text('x'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('MxSettingsRow interaction', () {
    testWidgets('a navigable row taps once', (tester) async {
      var taps = 0;
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () => taps++));

      await tester.tap(find.byType(MxSettingsRow));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('a row with a trailing control is not itself tappable', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        MxSettingsRow(
          label: 'Reminders',
          onTap: () => taps++,
          trailing: Switch(value: true, onChanged: (_) {}),
        ),
      );

      await tester.tap(find.byType(MxSettingsRow), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(taps, 0);
    });

    testWidgets('disabled: dims and drops the tap', (tester) async {
      var taps = 0;
      await pump(
        tester,
        MxSettingsRow(label: 'Theme', isEnabled: false, onTap: () => taps++),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, AppStateOpacity.disabled);

      await tester.tap(find.byType(MxSettingsRow), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
      // The `InkWell` still exists (it carries the button's semantics), but
      // its `onTap` is nulled — that is what actually drops the tap and the
      // focus stop, not its absence.
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    });

    testWidgets(
      'a trailing control stays Tab-reachable even though the row is not '
      'navigable — the exact defect a prior version shipped with',
      (tester) async {
        await pump(
          tester,
          MxSettingsRow(
            label: 'Reminders',
            leadingIcon: Icons.notifications_outlined,
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final switchElement = tester.element(find.byType(Switch));
        final focusNode = Focus.maybeOf(switchElement, scopeOk: true);
        expect(
          focusNode?.hasFocus ?? false,
          isTrue,
          reason:
              'a caller-supplied trailing control must stay reachable '
              'by Tab when the row itself does not navigate',
        );
      },
    );

    testWidgets(
      'a wideControl stays Tab-reachable too — same code path as trailing',
      (tester) async {
        await pump(
          tester,
          MxSettingsRow(
            label: 'Daily goal',
            wideControl: TextButton(
              onPressed: () {},
              child: const Text('12 cards / day'),
            ),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final buttonElement = tester.element(find.byType(TextButton));
        final focusNode = Focus.maybeOf(buttonElement, scopeOk: true);
        expect(
          focusNode?.hasFocus ?? false,
          isTrue,
          reason:
              'a caller-supplied wideControl must stay reachable by Tab '
              'when the row itself does not navigate',
        );
      },
    );

    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      final label = mode.$1;
      final isDark = mode.$2;

      testWidgets('$label · a navigable row focuses with the shared ring', (
        tester,
      ) async {
        await pump(
          tester,
          MxSettingsRow(label: 'Theme', onTap: () {}),
          isDark: isDark,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final inkWellElement = tester.element(find.byType(InkWell));
        final focusNode = Focus.maybeOf(inkWellElement, scopeOk: true);
        expect(focusNode?.hasFocus ?? false, isTrue, reason: label);
      });
    }

    testWidgets(
      'a navigable row hovers and presses with the shared row overlay',
      (tester) async {
        await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));
        final theme = buildLightTheme();
        final hoverWash = AppInteractionStates.rowOverlay(
          theme.colorScheme,
        ).resolve(const <WidgetState>{WidgetState.hovered});

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.hoverColor, hoverWash);
      },
    );
  });
}
