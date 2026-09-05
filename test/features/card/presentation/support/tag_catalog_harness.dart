import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';

import 'fake_card_repository.dart';
import 'fake_tag_catalog_repository.dart';

/// Pumps one tag surface with both fakes installed, in a chosen locale and
/// brightness (UC-18).
///
/// **Both contracts, always, even when a surface uses one.** The catalog screen
/// reads only `TagCatalogRepository`; the card list's filter sheet reads the
/// catalog *and* the card count. Installing both unconditionally keeps the call
/// sites to one line — and keeps the override **count** fixed, which Riverpod
/// requires: a test that pumps two different surfaces in one run to compare
/// their geometry would otherwise trip
/// "Tried to change the number of overrides".
Future<void> pumpTagSurface(
  WidgetTester tester, {
  required Widget home,
  required FakeTagCatalogRepository catalog,
  FakeCardRepository? cards,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tagCatalogRepositoryProvider.overrideWithValue(catalog),
        cardRepositoryProvider.overrideWithValue(cards ?? FakeCardRepository()),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? buildDarkTheme()
            : buildLightTheme(),
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}

/// The fixture the geometry files measure: one Vietnamese name, one short
/// English one, one long enough to wrap. Shared so two test files cannot drift
/// into measuring different rows and calling the result a disagreement.
const List<TagCatalogEntry> kTagFixtures = <TagCatalogEntry>[
  TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 12),
  TagCatalogEntry(id: 't2', name: 'food', cardCount: 1),
  TagCatalogEntry(id: 't3', name: 'phrasal verbs and idioms', cardCount: 340),
];

/// Sub-pixel slack for a laid-out rectangle. Not a tolerance for a wrong
/// number — a rect that is 4dp out fails at this epsilon.
const double kTagEpsilon = 0.5;

const Size kTagNarrow = Size(320, 640);
const Size kTagPhone = Size(390, 844);
const Size kTagWide = Size(412, 915);

/// A surface sized in logical pixels, reset when the test ends.
void sizeTagSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The catalog screen at [size], with [textScale] applied through a `copyWith`.
///
/// **`copyWith` through a `Builder`, never a fresh `MediaQueryData`:** a new one
/// carries a zero size, which puts the screen below the compact breakpoint and
/// silently changes the gutter these files measure.
Future<void> pumpTagCatalog(
  WidgetTester tester, {
  Size size = kTagPhone,
  double textScale = 1,
  FakeTagCatalogRepository? repository,
}) async {
  sizeTagSurface(tester, size);
  await pumpTagSurface(
    tester,
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: const TagCatalogScreen(),
      ),
    ),
    catalog: repository ?? FakeTagCatalogRepository.seeded(kTagFixtures),
  );
  await tester.pumpAndSettle();
}
