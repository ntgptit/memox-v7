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
Widget wrapForTest(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
