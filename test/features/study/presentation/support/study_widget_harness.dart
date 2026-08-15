import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Puts a Study widget under a real theme and real localizations.
///
/// **A real theme, not a bare `MaterialApp`.** Half of what these widgets do is
/// read tokens, and a default theme would let a hardcoded colour pass a test it
/// should fail. Real localizations for the same reason: a widget that reached
/// for a literal instead of ARB would still render, and the test would agree.
/// [isScrollable] false for a widget that fills the height it is given — the
/// session frame does, because its body sits in an `Expanded`, and an unbounded
/// height inside a scroll view is an assertion rather than a layout.
///
/// [locale] is null for the device default, which is English in a test. Naming
/// one is what lets a test read the Vietnamese copy — the language whose words
/// are long enough to break a row that English fits comfortably.
///
/// [textScaler] is null for the platform default. Naming one is the only way to
/// reach the case the Definition of Done calls "large text scale", and it is not
/// a decoration: at 2.0 a `ListTile` gives its text column what is left after the
/// leading and trailing widgets, so a row with a trailing badge gets a
/// *different* column from its neighbours — which is how three rows offering one
/// choice stop reading as one control.
Widget wrapForTest(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool isScrollable = true,
  Locale? locale,
  TextScaler? textScaler,
}) => MaterialApp(
  locale: locale,
  builder: textScaler == null
      ? null
      : (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: widget ?? const SizedBox.shrink(),
        ),
  theme: brightness == Brightness.dark ? buildDarkTheme() : buildLightTheme(),
  localizationsDelegates: const <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: isScrollable ? SingleChildScrollView(child: child) : child,
  ),
);
