import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test in `test/`.
///
/// Its only job is to load real fonts. Without this, `flutter_test` substitutes
/// a placeholder font that draws every glyph as an identical box, so a golden
/// records the *shape of the layout* and nothing about the text: a wrong font
/// weight, a wrong text colour, a truncated label and a line-height regression
/// all produce byte-identical boxes. Loading the real fonts is what makes a
/// golden able to fail for the reasons goldens exist.
///
/// The fonts come from the pinned Flutter SDK (`.fvmrc` → 3.44.8) rather than
/// from a file committed here. That keeps the repo free of a vendored binary
/// and a font licence, and it ties the glyphs to the same SDK version every
/// machine already builds with.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Fonts are loaded for goldens, and goldens run on the VM only. Under
  // `--platform chrome` (the web runtime test, M4.9) `dart:io` is a stub that
  // throws, and there is no golden comparison to feed — so skip the loading
  // rather than crash every browser test at startup.
  if (kIsWeb) return testMain();

  await _loadAppFonts();
  await _loadSdkFonts();

  return testMain();
}

/// Loads the bundled Inter and Plus Jakarta Sans.
///
/// Read straight from `assets/fonts/` rather than through the asset bundle:
/// `flutter test` does not populate the bundle with declared fonts, which is
/// the reason a golden of a themed screen otherwise falls back to the default
/// face and silently stops testing the typography.
Future<void> _loadAppFonts() async {
  for (final entry in _appFonts.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      throw StateError(
        'Bundled font missing: ${file.path}. Goldens would render the fallback '
        'face and stop testing the app typography.',
      );
    }

    final loader = FontLoader(
      entry.key,
    )..addFont(file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// The app's own faces, loaded from `assets/fonts/` exactly as the app ships
/// them. Loading anything else here would make goldens record type the app
/// never renders.
///
/// **Every family a `TextStyle` can name belongs here, fallbacks included.**
/// `NotoSansKR` is not decoration: `AppTypography` puts it in
/// `fontFamilyFallback` on all fifteen rungs, and a fallback naming a family the
/// test collection does not hold is not a fallback — the engine skips it and
/// lands on `flutter_test`'s own face, which draws `NO GLYPH`. So every Korean
/// card front rendered as a box, in the goldens of an app for learning Korean,
/// for as long as the font was in the bundle but not here.
///
/// It cost more than boxes in a picture. The cause was read the other way round
/// — that the test renderer does not run `fontFamilyFallback` at all — and on
/// that reading the demo and audit fixtures were moved to English vocabulary and
/// the wiring was checked by a test that asserts the *name* is present in the
/// style. Both are what you would build if the renderer really could not show
/// the script; neither can fail when it can. It can: registered here, the same
/// styles render Hangul, and the Latin goldens do not move by a byte.
///
/// The rule that prevents the next one: this map is not "the app's two faces",
/// it is **every family named anywhere in `AppTypography`**. Adding a face to
/// `pubspec.yaml` is half the change.
const Map<String, String> _appFonts = <String, String>{
  'Inter': 'assets/fonts/Inter-Variable.ttf',
  'PlusJakartaSans': 'assets/fonts/PlusJakartaSans-Variable.ttf',
  'NotoSansKR': 'assets/fonts/NotoSansKR-Variable.ttf',
  'NotoSansJP': 'assets/fonts/NotoSansJP-Variable.ttf',
  'NotoSansSC': 'assets/fonts/NotoSansSC-Variable.ttf',
};

/// Family name to the SDK font files that make it up.
///
/// `MaterialIcons` matters as much as the text font: without it every `Icon`
/// renders as an empty square, which is exactly what the empty-state and
/// error-state goldens are meant to show. Roboto stays as the fallback the
/// framework reaches for when a style names no family.
const Map<String, List<String>> _families = <String, List<String>>{
  'Roboto': <String>['roboto-regular.ttf', 'roboto-medium.ttf'],
  'MaterialIcons': <String>['materialicons-regular.otf'],
};

Future<void> _loadSdkFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];

  // `flutter test` always sets this. Failing loudly beats loading nothing:
  // a silent fallback to the box font would make every golden mismatch at
  // once, and the diff would point at the widgets rather than at the cause.
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError(
      'FLUTTER_ROOT is not set, so the SDK fonts cannot be loaded and goldens '
      'would render placeholder boxes. Run the suite with `flutter test`.',
    );
  }

  final fontsDir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  if (!fontsDir.existsSync()) {
    throw StateError(
      'Flutter SDK fonts are missing at ${fontsDir.path}. '
      'Run `flutter precache` to restore them.',
    );
  }

  for (final entry in _families.entries) {
    final loader = FontLoader(entry.key);

    for (final fileName in entry.value) {
      final file = File('${fontsDir.path}/$fileName');
      if (!file.existsSync()) {
        throw StateError('Expected SDK font not found: ${file.path}');
      }

      loader.addFont(
        file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }

    await loader.load();
  }
}
