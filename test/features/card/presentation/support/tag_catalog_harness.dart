import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

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
