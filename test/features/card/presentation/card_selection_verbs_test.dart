import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_selection_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_menu_button.dart';

import 'support/fake_card_repository.dart';

/// A mode the user deliberately entered shows what it is for.
///
/// **Selection mode had no visible verb at all** (SC-C9-06). All six bulk
/// actions sat behind one overflow, so what the band offered was a close, a
/// count, select-all and a kebab — against this widget's own class doc ("Two
/// actions stay visible"), the typedef's doc, the `cardSelectionMoreLabel` ARB
/// description and UC-04 A6.
///
/// **Icon buttons, because the labelled pair was measured and does not fit.**
/// At 320dp and `textScaler` 2.0, `MxActionButton('Move')` + `MxTextButton`
/// `('Delete')` + the two existing icon buttons come to 308.5dp against 304dp
/// of line — an overflow, with the shortest English labels. The four 48dp
/// targets that ship instead — Move, Add tag, select-all and the overflow —
/// come to 192dp and cannot grow, whatever the locale or the text scale does.
/// That is why this file asserts the count and the bounds of the targets
/// rather than the width of their labels: an icon button's width is its
/// touch target, and a label's is not.
void main() {
  final english = AppLocalizationsEn();

  FakeCardRepository seeded() => FakeCardRepository.loaded(
    List<CardListItemModel>.generate(
      3,
      (i) => FakeCardRepository().listItem('c$i', front: 'f$i', back: 'b$i'),
    ),
    total: 3,
  );

  Future<void> enterSelection(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
    bool selectFirst = true,
  }) async {
    final repository = seeded();
    addTearDown(repository.dispose);

    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const CardListScreen(deckId: 'deck-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (selectFirst) {
      await tester.longPress(find.byType(CardTileWidget).first);
    } else {
      await tester.tap(find.bySemanticsLabel(english.cardSelectAction).first);
    }
    await tester.pumpAndSettle();
  }

  Finder inBand(String label) => find.descendant(
    of: find.byType(CardSelectionBarWidget),
    matching: find.bySemanticsLabel(label),
  );

  testWidgets('the band offers Move and Add tag without opening a menu', (
    tester,
  ) async {
    await enterSelection(tester);

    expect(inBand(english.cardSelectionMoveAction), findsOneWidget);
    expect(inBand(english.cardSelectionAddTagAction), findsOneWidget);
  });

  testWidgets('Delete stays in the overflow, where it keeps its role', (
    tester,
  ) async {
    await enterSelection(tester);

    // Not in the band: `MxIconButton`'s tone axis is standard|warning only, so
    // an icon-only Delete would drop the destructive role — and adding a
    // destructive tone to a shared primitive is frozen contract 6.
    expect(inBand(english.cardSelectionDeleteAction), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(CardSelectionBarWidget),
        matching: find.byType(MxMenuButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(english.cardSelectionDeleteAction), findsOneWidget);
    expect(find.text(english.cardSelectionFlagAction), findsOneWidget);
    expect(find.text(english.cardSelectionUnflagAction), findsOneWidget);
    expect(find.text(english.cardExportSelectionAction), findsOneWidget);
  });

  testWidgets('four fixed-width targets fit 320dp at double scale', (
    tester,
  ) async {
    await enterSelection(tester, surface: const Size(320, 640), textScale: 2);

    expect(tester.takeException(), isNull);

    final band = tester.getRect(find.byType(CardSelectionBarWidget));
    final buttons = find.descendant(
      of: find.byType(CardSelectionBarWidget),
      matching: find.byType(MxIconButton),
    );
    expect(buttons, findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byType(CardSelectionBarWidget),
        matching: find.byType(MxMenuButton),
      ),
      findsOneWidget,
    );

    // Each stays inside the band: an icon button's width is its 48dp target,
    // which no locale and no text scale can grow.
    for (var i = 0; i < 3; i++) {
      final rect = tester.getRect(buttons.at(i));
      expect(rect.left, greaterThanOrEqualTo(band.left));
      expect(rect.right, lessThanOrEqualTo(band.right));
    }
  });

  testWidgets('with nothing selected the two verbs are disabled, not hidden', (
    tester,
  ) async {
    // Entered through the app bar's Select rather than a long-press, which is
    // the path that opens the mode holding nothing.
    await enterSelection(tester, selectFirst: false);

    expect(inBand(english.cardSelectionMoveAction), findsOneWidget);
    expect(
      tester
          .widget<MxIconButton>(
            find
                .descendant(
                  of: find.byType(CardSelectionBarWidget),
                  matching: find.byType(MxIconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
  });
}
