@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'golden_specimens.dart';
import 'golden_surfaces.dart';

/// Golden tests for every shared component, light and dark.
///
/// Uses `matchesGoldenFile` from `flutter_test` — no golden_toolkit and no
/// alchemist. Neither is needed for a fixed-size, single-locale snapshot, and
/// adding a dependency to a project this small buys a maintenance burden
/// instead of a capability.
///
/// Everything that can move a pixel is pinned below: surface size, device pixel
/// ratio, text scale and locale. Fonts are pinned too, but not here —
/// `test/flutter_test_config.dart` loads Roboto and MaterialIcons from the
/// pinned Flutter SDK before any test runs. Without it `flutter_test`
/// substitutes a placeholder font that draws every glyph as an identical box,
/// and a golden then records the shape of the layout and nothing about the
/// text: a wrong weight, a wrong colour, a truncated label and a line-height
/// regression all produce byte-identical boxes.
///
/// Platform caveat worth knowing before CI: text now renders with real glyphs,
/// but glyph *rasterisation* still differs between operating systems. These
/// were generated on Windows; a Linux runner will produce different
/// antialiasing. M7 must either run this suite on one platform or regenerate
/// per platform — it is tagged `golden` so it can be excluded with
/// `--exclude-tags golden`.
void main() {
  const surface = Size(360, 640);

  Future<void> pumpGolden(
    WidgetTester tester,
    Widget child, {
    required bool isDark,
    Size at = surface,
  }) async {
    tester.view.physicalSize = at;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        locale: const Locale('en'),
        home: Builder(
          // `copyWith`, never a fresh `MediaQueryData`: constructing one
          // zeroes `size`, `padding` and `viewInsets`, so the widget under
          // test is told the screen is 0x0 while `tester.view` says
          // otherwise. Anything that reads the width then branches on a
          // number no device reports.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// One entry per component. A spinner is deliberately absent: a
  /// `CircularProgressIndicator` is mid-animation at an arbitrary frame, so its
  /// golden would be flaky by construction. Its behaviour is covered by the
  /// semantics test instead.
  final cases = <String, Widget>{
    // Proves the bundled faces actually render and that the variable-font
    // weight axis moves. Without this, two families could be declared in
    // pubspec, silently fail to load, and every other golden would still pass
    // on the fallback face.
    'typography': const Scaffold(body: TypographySpecimen()),
    // The app's hero: a vocabulary prompt in the display face on a card.
    'card_prompt': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: MxCard(child: CardPrompt())),
      ),
    ),
    // The input states the palette change was actually about: focus moves the
    // border's hue and leaves its weight alone.
    'input_resting': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: TextField(decoration: InputDecoration(hintText: 'Search')),
        ),
      ),
    ),
    'input_focused': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: AutoFocusedField()),
      ),
    ),
    'card_surface': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: MxCard(child: Text('Ephemeral')),
      ),
    ),
    'scaffold': const MxContentShell(title: 'MemoX', body: Text('Body')),
    'button_primary': const Scaffold(
      body: Center(
        child: MxActionButton(label: 'Remembered', onPressed: noop),
      ),
    ),
    'button_secondary': const Scaffold(
      body: Center(
        child: MxActionButton(
          label: 'Forgotten',
          onPressed: noop,
          variant: MxActionButtonVariant.secondary,
        ),
      ),
    ),
    'button_disabled': const Scaffold(
      body: Center(child: MxActionButton(label: 'Remembered', onPressed: null)),
    ),
    // ---- M4.8 content-management components ----------------------------
    //
    // Deterministic states only. `MxActionButton` while loading and any sheet
    // or dialog mid-transition are deliberately absent: both are a spinner or a
    // curve caught at an arbitrary frame, so their golden would be flaky by
    // construction. Their behaviour is asserted in the widget tests instead.
    'mx_text_field_resting': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: TextFieldSpecimen()),
      ),
    ),
    'mx_text_field_focused': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: TextFieldSpecimen(shouldAutofocus: true)),
      ),
    ),
    'mx_text_field_error': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: TextFieldSpecimen(errorText: 'Name is required')),
      ),
    ),
    'mx_text_field_disabled': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: TextFieldSpecimen(isEnabled: false)),
      ),
    ),
    'mx_icon_button_enabled': const Scaffold(
      body: Center(
        child: MxIconButton(
          icon: Icons.delete_outline,
          semanticLabel: 'Delete deck',
          onPressed: noop,
        ),
      ),
    ),
    'mx_icon_button_disabled': const Scaffold(
      body: Center(
        child: MxIconButton(
          icon: Icons.delete_outline,
          semanticLabel: 'Delete deck',
          onPressed: null,
        ),
      ),
    ),
    'mx_icon_button_focused': const Scaffold(
      body: Center(
        child: FocusedOnFirstFrame(
          child: MxIconButton(
            icon: Icons.delete_outline,
            semanticLabel: 'Delete deck',
            onPressed: noop,
          ),
        ),
      ),
    ),
    // The bottom bar in both of its selections. Two entries rather than one
    // because the selected state is the whole point of the component, and a
    // single golden would pin the idle destination's look while leaving the
    // selected indicator — the thing that moves — unchecked.
    'mx_navigation_bar_decks': const Scaffold(
      body: SizedBox.expand(),
      bottomNavigationBar: MxNavigationBar(
        selectedIndex: 0,
        onDestinationSelected: noopIndex,
        destinations: navigationDestinations,
      ),
    ),
    'mx_navigation_bar_review': const Scaffold(
      body: SizedBox.expand(),
      bottomNavigationBar: MxNavigationBar(
        selectedIndex: 1,
        onDestinationSelected: noopIndex,
        destinations: navigationDestinations,
      ),
    ),
    'mx_list_tile_selected': const Scaffold(
      body: OnSheetSurface(
        child: MxListTile(
          title: 'Academic Word List',
          subtitle: '20 of 570 learned',
          leading: Icon(Icons.style_outlined),
          isSelected: true,
          onTap: noop,
        ),
      ),
    ),
    'mx_list_tile_disabled': const Scaffold(
      body: OnSheetSurface(
        child: MxListTile(
          title: 'Academic Word List',
          subtitle: 'Not available yet',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
          isEnabled: false,
          onTap: noop,
        ),
      ),
    ),
    'mx_list_tile': const Scaffold(
      body: OnSheetSurface(
        child: MxListTile(
          title: 'Academic Word List',
          subtitle: '20 of 570 learned',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    ),
    // A benign action on purpose. Reusing "Delete this deck?" here would make
    // the normal baseline a picture of a delete button painted in the primary
    // colour, and the next reviewer would have no way to see that the variant
    // and the copy disagree.
    'mx_confirm_dialog_normal': const Scaffold(
      body: Center(
        child: ConfirmDialogSpecimen(
          title: 'Save changes?',
          message: 'This deck has unsaved edits.',
          confirmLabel: 'Save',
        ),
      ),
    ),
    'mx_confirm_dialog_destructive': const Scaffold(
      body: Center(
        child: ConfirmDialogSpecimen(
          variant: MxConfirmDialogVariant.destructive,
        ),
      ),
    ),
    // Hosted in a real `showModalBottomSheet`, not mounted inline. The widget
    // paints no surface of its own -- background, radius, drag handle and
    // elevation all come from `bottomSheetTheme` -- so an inline golden records
    // rows floating on a scaffold, an arrangement that never ships, and pins
    // none of the chrome the user actually sees.
    //
    // `MxConfirmDialog` needs no equivalent: `AlertDialog` brings its own
    // `Material`, so the inline capture differs from the routed one only by the
    // scrim.
    'mx_action_sheet': const HostedModalSheet(),
    'empty_state': const Scaffold(
      body: MxEmptyState(
        title: 'Nothing due today',
        message: 'You have finished every card scheduled for now.',
      ),
    ),
    'error_state': const Scaffold(
      body: MxErrorState(
        title: 'Something went wrong',
        message: 'This part could not be displayed.',
        retryLabel: 'Try again',
        onRetry: noop,
      ),
    ),
    'mx_progress_bar': const ProgressBarSpecimen(),
  };

  for (final entry in cases.entries) {
    for (final isDark in <bool>[false, true]) {
      final mode = isDark ? 'dark' : 'light';

      testWidgets('${entry.key} — $mode', (tester) async {
        await pumpGolden(tester, entry.value, isDark: isDark);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${entry.key}_$mode.png'),
        );
      });
    }
  }

  // The compact scale, on the narrowest screen the project supports.
  //
  // Its own surface rather than another entry in `cases`: the whole point is
  // the width, and 320 is the only width where the scale is active. The numbers
  // it produces are asserted in `test/core/theme/compact_scale_test.dart`;
  // these two exist so a change to them has to be looked at.
  const compactSurface = Size(320, 568);

  for (final entry in <String, Widget>{
    'compact_screen': const _CompactScreen(),
    // Same composition as the `card_prompt` case, so the only difference
    // between the two baselines is the width and the type scale it selects.
    'compact_card_prompt': const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: MxCard(child: CardPrompt())),
      ),
    ),
  }.entries) {
    for (final isDark in <bool>[false, true]) {
      final mode = isDark ? 'dark' : 'light';

      testWidgets('${entry.key} — $mode', (tester) async {
        await pumpGolden(
          tester,
          CompactScaleWidget(child: entry.value),
          isDark: isDark,
          at: compactSurface,
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${entry.key}_$mode.png'),
        );
      });
    }
  }
}

/// A realistic screen: app bar with actions, a field, rows, a primary action.
///
/// Composed rather than reusing `scaffold`, because the compact scale shows up
/// in the interaction between them — a tighter gutter only matters once there is
/// a row whose subtitle was wrapping because of it.
class _CompactScreen extends StatelessWidget {
  const _CompactScreen();

  @override
  Widget build(BuildContext context) => MxContentShell(
    title: 'Academic Word List',
    isScrollable: true,
    actions: const <Widget>[
      MxIconButton(
        icon: Icons.search,
        semanticLabel: 'Search',
        onPressed: noop,
      ),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxTextField(controller: TextEditingController(), label: 'Filter cards'),
        const SizedBox(height: AppSpacing.lg),
        const MxListTile(
          title: 'ubiquitous',
          subtitle: 'present everywhere at once',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
        ),
        const MxListTile(
          title: 'ephemeral',
          subtitle: 'lasting for a very short time',
          leading: Icon(Icons.style_outlined),
          trailing: Icon(Icons.chevron_right),
        ),
        const SizedBox(height: AppSpacing.lg),
        const MxActionButton(label: 'Start review', onPressed: noop),
      ],
    ),
  );
}
