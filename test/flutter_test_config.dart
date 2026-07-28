import 'dart:async';
import 'dart:io';

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
  await _loadSdkFonts();

  return testMain();
}

/// Family name to the SDK font files that make it up.
///
/// `MaterialIcons` matters as much as the text font: without it every `Icon`
/// renders as an empty square, which is exactly what the empty-state and
/// error-state goldens are meant to show.
const Map<String, List<String>> _families = <String, List<String>>{
  'Roboto': <String>[
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-italic.ttf',
  ],
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
