import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:widgetbook/widgetbook.dart';

/// Mounts one catalog use-case the way the catalog mounts it, for a test.
///
/// **A use-case builder is not a plain `WidgetBuilder`.** It reads
/// `context.knobs`, which resolves `WidgetbookState.of(context)` — so calling
/// it under a bare `MaterialApp` throws before the demo is built. The whole
/// catalog app is far more than a test needs, and driving it means navigating
/// its own tree first; a `WidgetbookScope` holding one real [WidgetbookState]
/// is the smallest thing the builder will accept.
///
/// No query group is supplied, so every knob resolves to its initial value —
/// which is what the catalog itself shows on first open, and therefore the
/// state a reviewer sees before touching anything.
///
/// The theme, locale and delegates come from the app, for the same reason
/// `main.dart` takes them from the app: a catalog rendering its own colours or
/// its own copy is testing a surface the product does not have.
Future<void> pumpUseCase(
  WidgetTester tester,
  WidgetbookComponent component, {
  String useCase = 'Playground',
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final WidgetbookUseCase entry = component.useCases.firstWhere(
    (WidgetbookUseCase node) => node.name == useCase,
    orElse: () => throw StateError(
      '${component.name} has no use-case named "$useCase" — '
      'it has ${component.useCases.map((WidgetbookUseCase n) => n.name)}',
    ),
  );

  await tester.pumpWidget(
    WidgetbookScope(
      state: WidgetbookState(
        root: WidgetbookRoot(children: <WidgetbookNode>[component]),
      ),
      child: MaterialApp(
        theme: buildLightTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: entry.builder),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
