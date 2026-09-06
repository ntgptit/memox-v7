import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';
import 'package:memox/features/trash/presentation/widgets/items/trash_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'support/fake_trash_repository.dart';

/// How a row of the wrong kind recedes, and why it may not be an `Opacity`.
///
/// **The structural claim is the one worth pinning** (SC-C9-08, A19-06). The
/// row used to wrap itself in `Opacity(0.38)` — the literal value of
/// `AppStateOpacity.disabledContent`, a token its own docstring scopes to a
/// disabled label or glyph, spent here on a whole row of body text, path and
/// counts. An `Opacity` render object composites after the palette, so the
/// high-contrast schemes returned byte-identical contrast for exactly the rows
/// a user most needs to read past: 1.70:1 light and 1.89:1 dark on the small
/// lines, in every scheme the app ships.
///
/// So this file asserts two things a colour test alone would miss: that no
/// `Opacity` sits over the row at all, and that switching to the high-contrast
/// scheme *changes* the dimmed ink. The second is what says the recession is
/// inside the palette rather than painted over it.
void main() {
  final now = DateTime.utc(2026, 8, 15, 12);

  TrashBatchEntity batch() => fakeBatch(
    id: 'b1',
    itemType: TrashItemType.deck,
    name: 'Korean · TOPIK I',
    deletedAt: now.subtract(const Duration(days: 2)),
    deckCount: 2,
    cardCount: 11,
  );

  Future<void> pumpRow(
    WidgetTester tester, {
    required bool canSelect,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TrashRowWidget(
            batch: batch(),
            now: now,
            isSelecting: true,
            isSelected: false,
            canSelect: canSelect,
            onRestore: () {},
            onMenu: () {},
            onToggleSelection: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color nameInk(WidgetTester tester) =>
      tester.widget<Text>(find.text('Korean · TOPIK I')).style!.color!;

  testWidgets('an ineligible row carries no Opacity layer', (tester) async {
    await pumpRow(tester, canSelect: false, theme: buildLightTheme());

    // Not "no Opacity with 0.38" — no Opacity at all. A layer at any value
    // would still be invisible to the palette, which is the actual defect.
    expect(
      find.descendant(
        of: find.byType(TrashRowWidget),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('every line of an ineligible row takes the disabled ink', (
    tester,
  ) async {
    await pumpRow(tester, canSelect: false, theme: buildLightTheme());

    final semantic = Theme.of(
      tester.element(find.byType(TrashRowWidget)),
    ).extension<AppSemanticColors>()!;

    expect(nameInk(tester), semantic.onDisabled);

    // Including the countdown, which is the row's one accent: an urgency tint
    // on a row that cannot be acted on is a signal pointing nowhere.
    final countdown = tester.widget<Text>(find.textContaining('days left'));
    expect(countdown.style!.color, semantic.onDisabled);
  });

  testWidgets('an eligible row is untouched', (tester) async {
    await pumpRow(tester, canSelect: true, theme: buildLightTheme());

    final scheme = Theme.of(
      tester.element(find.byType(TrashRowWidget)),
    ).colorScheme;

    expect(nameInk(tester), scheme.onSurface);
  });

  testWidgets('high contrast can now reach the dimmed row', (tester) async {
    await pumpRow(tester, canSelect: false, theme: buildLightTheme());
    final standard = nameInk(tester);

    await pumpRow(
      tester,
      canSelect: false,
      theme: buildHighContrastLightTheme(),
    );
    final raised = nameInk(tester);

    // The whole point of the change. With the `Opacity` layer these two were
    // the same colour, because the layer composited after the scheme had
    // already been chosen.
    expect(raised, isNot(standard));
  });

  testWidgets('the exclusion is spoken, not only painted', (tester) async {
    await pumpRow(tester, canSelect: false, theme: buildLightTheme());

    final node = tester.getSemantics(find.byType(TrashRowWidget).first);
    // `Tristate.isFalse`, not merely "not true": the row declares that it has
    // an enabled state and that it is off, which is what a reader announces.
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
  });
}
