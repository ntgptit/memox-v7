import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/core/theme/typography/app_typography.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../features/settings/domain/support/fake_app_settings_repository.dart';
import '../features/study/domain/support/fake_study_repository.dart';

/// The two `MediaQuery` transforms reach the app through `MaterialApp.builder`,
/// and this is what proves the builder still calls them.
///
/// **Every other Bold-text test wires `BoldTextWidget` by hand.**
/// `app_bold_text_components_test` calls `applyBoldText` directly and
/// `app_bold_text_rendered_test` builds its own `MaterialApp` whose `builder`
/// installs the wrapper — both prove the transform, neither proves that
/// `MemoxApp` uses it. Deleting the `BoldTextWidget(...)` line from `app.dart`
/// leaves all twenty-two of them green while the OS setting goes back to being
/// the complete no-op A20.1 P1-11 was raised for: both faces are variable
/// fonts, so the `fontWeight: bold` Flutter merges into every `Text` changes
/// nothing without the `wght` re-weight behind this wrapper. `applyCompactScale`
/// is installed by the same builder and had the same hole.
///
/// So the assertions are made on the real root widget with the real builder
/// chain — the painted styles come off the `RichText` the engine will shape,
/// not off a `ThemeData` a helper handed back.
void main() {
  const FontVariation wght700 = FontVariation('wght', 700);

  Future<void> pumpRoot(
    WidgetTester tester, {
    required bool boldText,
    Size surface = const Size(393, 852),
  }) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        // From the view, then `copyWith` — a bare `MediaQueryData(boldText:)`
        // defaults `size` to zero, and `CompactScaleWidget` then reads a width
        // of 0 and calls every surface compact.
        data: MediaQueryData.fromView(tester.view).copyWith(boldText: boldText),
        child: ProviderScope(
          overrides: [
            envConfigProvider.overrideWithValue(EnvConfig.development),
            appSettingsRepositoryProvider.overrideWithValue(
              FakeAppSettingsRepository(),
            ),
            deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
            studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          ],
          child: MemoxApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The styles the app is painting, split the way the contract splits them:
  /// prose carries a `fontWeight`, an icon glyph does not.
  ({List<TextStyle> prose, List<TextStyle> glyphs}) painted(
    WidgetTester tester,
  ) {
    final styles = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((rich) => rich.text.style)
        .whereType<TextStyle>();

    return (
      prose: styles.where((s) => s.fontWeight != null).toList(),
      glyphs: styles.where((s) => s.fontWeight == null).toList(),
    );
  }

  testWidgets('without the OS setting the app paints its resting weights', (
    tester,
  ) async {
    await pumpRoot(tester, boldText: false);
    final prose = painted(tester).prose;

    expect(prose, isNotEmpty, reason: 'nothing painted — harness is broken');
    expect(
      prose.any((style) => style.fontWeight != FontWeight.w700),
      isTrue,
      reason:
          'every resting style is already w700, so the next test is vacuous',
    );
  });

  testWidgets('with the OS setting every painted style resolves wght 700', (
    tester,
  ) async {
    await pumpRoot(tester, boldText: true);
    final result = painted(tester);

    expect(result.prose, isNotEmpty, reason: 'nothing painted');
    for (final style in result.prose) {
      expect(
        style.fontWeight,
        FontWeight.w700,
        reason: 'MaterialApp.builder no longer applies BoldTextWidget',
      );
      // The claim that matters on a variable face: `fontWeight` alone is what
      // Flutter already merged and what the renderer ignores once the file
      // carries a `wght` axis.
      expect(
        style.fontVariations,
        contains(wght700),
        reason: 'emboldened through fontWeight, not through the wght axis',
      );
    }

    // **A glyph is not text.** `MxIcon` paints through `RichText` too, and its
    // `wght` axis is the Material Symbols stroke weight — moving it to 700
    // would thicken every icon in the app because the user asked for bolder
    // *text*. It stays where the icon theme put it.
    expect(result.glyphs, isNotEmpty, reason: 'no icon painted — check screen');
    for (final glyph in result.glyphs) {
      expect(
        glyph.fontVariations,
        isNot(contains(wght700)),
        reason: 'bold text thickened an icon glyph',
      );
    }
  });

  testWidgets('the compact scale still reaches a narrow surface', (
    tester,
  ) async {
    // Read off the theme the app installed, below the builder, rather than off
    // a painted pixel: the rungs `applyCompactScale` re-sizes need not appear
    // on whichever screen the router opens first. The card prompt is the one
    // it always moves — 30 at full width, `compactCardPromptSize` below 360 —
    // and the list row's padding is deliberately *not* used here, because the
    // base theme already sets the same `md`/`xs` pair and the comparison would
    // pass whether or not the wrapper ran.
    double promptSizeAt(WidgetTester tester) => Theme.of(
      tester.element(find.byType(Navigator).first),
    ).extension<AppTextStyles>()!.cardPrompt.fontSize!;

    await pumpRoot(tester, boldText: false, surface: const Size(320, 640));
    final compact = promptSizeAt(tester);

    await pumpRoot(tester, boldText: false);
    final regular = promptSizeAt(tester);

    expect(regular, AppTypography.cardPromptSize);
    expect(
      compact,
      AppTypography.compactCardPromptSize,
      reason: 'MaterialApp.builder no longer applies CompactScaleWidget',
    );
  });
}
