import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/dev/component_gallery_widget.dart';
import 'package:memox/app/dev/design_system_showcase_screen.dart';
import 'package:memox/app/dev/token_gallery_widget.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The showcase is a dev tool, but a dev tool nobody tests is a dev tool that
/// rots silently — the exact failure mode `mx_stress_test.dart` names as the
/// reason a hidden gallery screen is dangerous. These tests are what keeps the
/// screen honest: every component the Components tab claims to demo must
/// actually build, under both themes, without throwing.
void main() {
  /// Tall enough that the lazy `ListView` builds every section. The gallery is
  /// an inventory, and an inventory test that only sees the first viewport
  /// checks whatever happens to be above the fold.
  const Size gallerySurface = Size(900, 5200);

  Future<void> pumpShowcase(WidgetTester tester) async {
    tester.view.physicalSize = gallerySurface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        home: const DesignSystemShowcaseScreen(),
      ),
    );
  }

  /// The Components tab hosts `MxLoadingState` and a loading button, whose
  /// spinners animate for as long as they are on screen — `pumpAndSettle`
  /// would never return. Two timed pumps ride out the tab transition instead.
  Future<void> openComponentsTab(WidgetTester tester) async {
    await tester.tap(find.text('Components'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('tokens tab', () {
    testWidgets('opens on the token gallery and renders every section', (
      tester,
    ) async {
      await pumpShowcase(tester);

      expect(find.byType(TokenGalleryWidget), findsOneWidget);
      for (final section in <String>[
        'ColorScheme roles',
        'Semantic colors (AppSemanticColors)',
        'Typography',
        'Spacing (AppSpacing)',
        'Radius (AppRadius)',
        'Icon sizes (AppIconSize)',
        'Durations (AppDurations)',
        'Breakpoints (AppBreakpoints)',
      ]) {
        expect(find.text(section), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows resolved values, not placeholders', (tester) async {
      await pumpShowcase(tester);

      // One representative of each read-back path: a colour resolved to hex, a
      // text role resolved to its spec line, a scale token to its number.
      expect(find.text('#4646B4'), findsWidgets); // primary, light theme
      expect(find.textContaining('PlusJakartaSans'), findsWidgets);
      expect(find.textContaining('lg · 16'), findsWidgets);
    });
  });

  group('components tab', () {
    testWidgets('demos every shared component', (tester) async {
      await pumpShowcase(tester);
      await openComponentsTab(tester);

      expect(find.byType(MxActionButton), findsWidgets);
      expect(find.byType(MxIconButton), findsWidgets);
      expect(find.byType(MxTextField), findsWidgets);
      expect(find.byType(MxCard), findsWidgets);
      expect(find.byType(MxListTile), findsWidgets);
      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.byType(MxLoadingState), findsOneWidget);
      expect(find.byType(MxConfirmDialog), findsNWidgets(2));
      expect(find.byType(MxActionSheet), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds cleanly in dark as well', (tester) async {
      await pumpShowcase(tester);

      await tester.tap(find.byTooltip('Switch to dark theme'));
      await tester.pump();
      await openComponentsTab(tester);

      expect(find.byType(ComponentGalleryWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the theme toggle', () {
    testWidgets('flips only the showcase subtree', (tester) async {
      await pumpShowcase(tester);

      Brightness galleryBrightness() =>
          Theme.of(tester.element(find.text('ColorScheme roles'))).brightness;

      expect(galleryBrightness(), Brightness.light);

      await tester.tap(find.byTooltip('Switch to dark theme'));
      await tester.pump();

      expect(galleryBrightness(), Brightness.dark);
      // The app above the showcase must be untouched — the override is a
      // `Theme` widget in this subtree, not a change to the app's theme mode.
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, isNot(ThemeMode.dark));

      await tester.tap(find.byTooltip('Switch to light theme'));
      await tester.pump();

      expect(galleryBrightness(), Brightness.light);
    });
  });

  group('the text-scale control', () {
    testWidgets('cycles 1.0 → 1.5 → 2.0 → 1.0 over the galleries', (
      tester,
    ) async {
      await pumpShowcase(tester);

      double galleryScale() => MediaQuery.of(
        tester.element(find.text('ColorScheme roles')),
      ).textScaler.scale(100);

      expect(galleryScale(), 100);

      await tester.tap(find.byTooltip(RegExp(r'Text scale')));
      await tester.pump();
      expect(galleryScale(), 150);

      await tester.tap(find.byTooltip(RegExp(r'Text scale')));
      await tester.pump();
      expect(galleryScale(), 200);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip(RegExp(r'Text scale')));
      await tester.pump();
      expect(galleryScale(), 100);
    });
  });
}
