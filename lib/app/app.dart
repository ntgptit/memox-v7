import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/review/presentation/review_placeholder_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import 'mobile_frame_widget.dart';

/// Root widget of the application.
///
/// Deliberately minimal. Each foundation piece arrives in its own task rather
/// than being stubbed here, so nothing has to be un-guessed later:
///
/// * theme and design tokens — M3.4, M3.5
/// * routing via `MaterialApp.router` — M4.1
class MemoxApp extends StatelessWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // `onGenerateTitle` rather than `title`: the title has to be read after
      // localizations are in scope, and it changes when the locale does.
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // No `localeResolutionCallback` on purpose. Flutter's default resolution
      // already falls back to `supportedLocales.first` — which is `en`, the
      // template ARB — for an unsupported locale. A custom callback here was
      // written and then removed once a test proved it changed nothing.
      // `test/l10n/localization_test.dart` pins the behaviour either way.
      //
      // Phone-sized surface on web (AD-04). No-op on Android.
      builder: (context, child) =>
          MobileFrameWidget(child: child ?? const SizedBox.shrink()),
      home: const ReviewPlaceholderScreen(),
    );
  }
}
