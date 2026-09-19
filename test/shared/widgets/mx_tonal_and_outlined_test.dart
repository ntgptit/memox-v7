import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/components/actions/app_button_themes.dart';
import 'package:memox/core/theme/components/actions/app_icon_button_theme.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The two variants M100.73 admitted, and the reasons each was admitted.
///
/// **Not a "does it render" suite.** Both variants exist to be a *third
/// weight* rather than a third colour, and both are one careless edit away from
/// becoming a second spelling of something the theme already answers. What is
/// pinned here is the part that would go wrong silently: which roles they read,
/// that the state mechanism is the shared one, and that the outlined border is
/// still the app's hairline once its width stopped being written down.
void main() {
  final ThemeData light = buildLightTheme();
  final ThemeData dark = buildDarkTheme();

  Widget host(ThemeData theme, Widget child) => MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  );

  group('the tonal pair reads the v3 secondary-tone roles, and only those', () {
    // `surfaceContainer` / `onSurface` is the v3 Button handoff's binding for
    // the "secondary" tone (`themeRoleUsage`, M3_COLOR/DIRECT/FULL_STRENGTH),
    // superseding M100.73's choice of M3's own `FilledButton.tonal` pair
    // (`secondaryContainer` / `onSecondaryContainer`). Reading anything else
    // here would make the app's tonal button some other colour than the
    // handoff names — and it would do it invisibly, because any container
    // role looks plausible on screen.
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ('light', light),
      ('dark', dark),
    ]) {
      test(name, () {
        final scheme = theme.colorScheme;
        final semantic = theme.extension<AppSemanticColors>()!;

        expect(
          MxFilledPair.tonal.fillOf(scheme, semantic),
          scheme.surfaceContainer,
        );
        expect(MxFilledPair.tonal.labelOf(scheme, semantic), scheme.onSurface);
        expect(
          MxFilledPair.tonal.stateLayerOf(scheme, semantic),
          scheme.onSurface,
          reason:
              'the state layer is the pair\'s own `on` role for every pair — a '
              'layer in some other role rotates the hue on press',
        );
      });
    }
  });

  group('the destructive pair reads the v3 error-fill tokens, not error', () {
    // The handoff's `themeRoleUsage` binds the destructive container to
    // `error-fill` — "the SOLID destructive fill, deeper than `error`, which is
    // the error text colour". `scheme.error` / `onError` stay the text/icon
    // "this is an error" colour; a button painted with them would be the wrong
    // red, and both reds are plausible on screen, hence the exact pin.
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ('light', light),
      ('dark', dark),
    ]) {
      test(name, () {
        final scheme = theme.colorScheme;
        final semantic = theme.extension<AppSemanticColors>()!;

        expect(
          MxFilledPair.destructive.fillOf(scheme, semantic),
          semantic.errorFill,
        );
        expect(
          MxFilledPair.destructive.labelOf(scheme, semantic),
          semantic.onErrorFill,
        );
        expect(
          MxFilledPair.destructive.stateLayerOf(scheme, semantic),
          semantic.onErrorFill,
          reason: 'the state layer is the pair\'s own `on` token',
        );
      });
    }
  });

  testWidgets('the tonal variant is the filled button, not a second one', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        light,
        const MxActionButton(
          label: 'Study',
          variant: MxActionButtonVariant.tonal,
          onPressed: _noop,
        ),
      ),
    );

    // The same widget `primary` and `destructive` render. Two button
    // implementations is how a screen ends up with two different "study" looks,
    // which is the argument the variant enum exists to settle.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final scheme = light.colorScheme;

    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      scheme.surfaceContainer,
    );
    expect(
      button.style?.foregroundColor?.resolve(<WidgetState>{}),
      scheme.onSurface,
    );
  });

  testWidgets('a tonal button darkens on press instead of standing still', (
    tester,
  ) async {
    // The failure this whole style path exists to prevent: `styleFrom` builds a
    // flat `WidgetStatePropertyAll`, which shadows the theme for every state at
    // once, so the control never reacts and never greys out. Asserted through
    // the resolver rather than by looking at pixels, because that is where the
    // mistake would be made.
    await tester.pumpWidget(
      host(
        light,
        const MxActionButton(
          label: 'Study',
          variant: MxActionButtonVariant.tonal,
          onPressed: _noop,
        ),
      ),
    );

    final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;

    expect(style.overlayColor?.resolve(<WidgetState>{}), isNull);
    expect(
      style.overlayColor?.resolve(<WidgetState>{WidgetState.pressed}),
      isNotNull,
      reason: 'a pressed tonal button must paint a state layer',
    );
    expect(
      style.backgroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
      isNot(light.colorScheme.surfaceContainer),
      reason: 'a disabled button that keeps its fill looks armed and is inert',
    );
  });

  group('the outlined icon button', () {
    testWidgets('draws the outline role at rest and the focus ring focused', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          light,
          const MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            shape: MxIconButtonShape.outlined,
            onPressed: _noop,
          ),
        ),
      );

      final style = tester.widget<IconButton>(find.byType(IconButton)).style!;
      final scheme = light.colorScheme;

      expect(style.side?.resolve(<WidgetState>{})?.color, scheme.outline);
      expect(
        style.side?.resolve(<WidgetState>{WidgetState.focused})?.color,
        isNot(scheme.outline),
        reason:
            'focused, the slot carries the focus indicator — WCAG 1.4.11 asks '
            '3:1 of one and `outline` is not built to carry it',
      );
      expect(style.backgroundColor?.resolve(<WidgetState>{}), scheme.surface);
    });

    testWidgets('plain keeps the theme untouched', (tester) async {
      // A style object here would merge over the theme even when every slot is
      // null, so the default has to be an absent style rather than an empty
      // one. Every existing caller depends on this.
      await tester.pumpWidget(
        host(
          light,
          const MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            onPressed: _noop,
          ),
        ),
      );

      expect(tester.widget<IconButton>(find.byType(IconButton)).style, isNull);
    });

    testWidgets('draws 40 and still hands a finger 48', (tester) async {
      // The split this variant exists to make: a visible circle at 48 is the
      // largest object in a header whose subtitle is 12px, so the circle comes
      // down and the target does not. `mx_stress_test` measures the floor
      // across every shared component; this measures that *this* one opted
      // into the smaller body on purpose rather than by inheriting it.
      await tester.pumpWidget(
        host(
          light,
          const MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            shape: MxIconButtonShape.outlined,
            onPressed: _noop,
          ),
        ),
      );

      // **Two boxes, and telling them apart is the test.** With
      // `MaterialTapTargetSize.padded` the `IconButton` widget *is* the target
      // and the ink `Material` inside it is what gets painted. Measuring the
      // outer one and calling it the body is how a change like this gets
      // reported as working when nothing moved — it was the first thing this
      // test did, and it read 48.
      final drawn = tester.getRect(
        find
            .descendant(
              of: find.byType(IconButton),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(drawn.width, AppSizing.controlCompact);
      expect(drawn.height, AppSizing.controlCompact);

      expect(
        tester.getRect(find.byType(IconButton)).height,
        greaterThanOrEqualTo(AppSizing.touchTarget),
        reason: 'the body came down; the floor must not have',
      );
    });

    test('the border width is the app hairline, however it got there', () {
      // **This is the whole reason the test exists.** The style writes
      // `BorderSide(color:)` and lets the default width stand, on the
      // precedent of the outlined button theme and the popup menu. That
      // default is 1, and so is `AppStroke.hairline` — today. The day the
      // token moves off 1, nothing about that border would change and nobody
      // would see it; this goes red instead.
      final side = buildOutlinedIconButtonStyle(
        light.colorScheme,
        light.extension<AppSemanticColors>()!,
      ).side!.resolve(<WidgetState>{})!;

      expect(side.width, AppStroke.hairline);
    });
  });

  group('the plain icon button', () {
    testWidgets('draws 36, hands a finger 48, and stays fully round', (
      tester,
    ) async {
      // The v3 IconButton contract this task ships: a 36 painted circle
      // centred inside the unchanged 48 touch target — the same drawn-vs-hit
      // split the outlined variant already has (`draws 40 and still hands a
      // finger 48`, above), at its own component-owned size.
      await tester.pumpWidget(
        host(
          light,
          const MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            onPressed: _noop,
          ),
        ),
      );

      final drawnFinder = find
          .descendant(
            of: find.byType(IconButton),
            matching: find.byType(Material),
          )
          .first;
      final drawn = tester.getRect(drawnFinder);
      expect(drawn.width, AppSizing.iconButtonInk);
      expect(drawn.height, AppSizing.iconButtonInk);

      expect(
        tester.getRect(find.byType(IconButton)).height,
        greaterThanOrEqualTo(AppSizing.touchTarget),
        reason: 'the body came down; the floor must not have',
      );

      final material = tester.widget<Material>(drawnFinder);
      expect(
        material.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        reason: 'fully round — the old AppRadius.md squircle no longer applies',
      );
    });

    testWidgets('the glyph is mdCompact even when not isCompact', (
      tester,
    ) async {
      // The v3 spec fixes the glyph at 20 with no compact/non-compact split —
      // `isCompact`'s only remaining job is the 48×48 box constraint for
      // `MxSessionTopBar`.
      await tester.pumpWidget(
        host(
          light,
          const MxIconButton(
            icon: Icons.search,
            semanticLabel: 'Search',
            onPressed: _noop,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, AppIconSize.mdCompact);
    });
  });
}

void _noop() {}
