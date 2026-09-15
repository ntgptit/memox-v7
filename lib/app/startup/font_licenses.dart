import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The OFL text of every face the app ships, handed to Flutter's licence page.
///
/// **The licence has to travel with the font.** All three faces are SIL Open
/// Font License 1.1, which requires the licence to accompany the software that
/// carries the font. The files sat in `assets/fonts/` next to the faces and
/// were never bundled — `pubspec.yaml` declared the `.ttf` under `fonts:`, which
/// ships the outlines and nothing else — so the app shipped three fonts and no
/// licence at all.
///
/// **Lazy on purpose.** `LicenseRegistry` collects entries only when something
/// asks for them, which is the licence page and nothing else. Registering a
/// stream rather than a loaded string keeps three text files out of memory for
/// every user who never opens it.
///
/// Flutter's own entries — the SDK, and every package in the tree — are already
/// registered by the framework. This adds what the framework cannot know about,
/// which is the app's own assets.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry<String, String> face in _faces.entries) {
      yield LicenseEntryWithLineBreaks(<String>[
        face.key,
      ], await rootBundle.loadString(face.value));
    }
  });
}

/// The face as the licence page names it, and the file that licenses it.
///
/// Noto Sans JP and SC were here until the CJK payload was cut; their licence
/// file was byte-identical to the Korean one, which is the copy that stayed.
const Map<String, String> _faces = <String, String>{
  'Inter': 'assets/fonts/OFL-Inter.txt',
  'Plus Jakarta Sans': 'assets/fonts/OFL-PlusJakartaSans.txt',
  'Noto Sans KR': 'assets/fonts/OFL-NotoSansKR.txt',
};
