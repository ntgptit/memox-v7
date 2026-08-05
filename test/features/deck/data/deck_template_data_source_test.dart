import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/data/datasources/deck_template_data_source.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// An `AssetBundle` backed by a map, so a test can hand the loader malformed
/// JSON without shipping it.
class _MapBundle extends CachingAssetBundle {
  _MapBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final source = _assets[key];
    if (source == null) throw StateError('missing asset $key');

    return ByteData.sublistView(utf8.encode(source));
  }
}

/// Reading the shipped templates, and refusing the ones that cannot be trusted
/// (AD-07, BR-32, BR-61/BR-62).
void main() {
  // `rootBundle` in a widget test reads the assets `pubspec.yaml` declares, so
  // this is the real files — the point being that a typo in a shipped JSON
  // fails here rather than at a user's first launch.
  TestWidgetsFlutterBinding.ensureInitialized();

  String manifest(List<String> files) =>
      jsonEncode(<String, Object?>{'templates': files});

  Map<String, Object?> template({
    Object? scheduler = 'eight_box',
    List<Object?>? children,
  }) => <String, Object?>{
    'template_id': 'fixture.test',
    'version': 1,
    'locale': 'en',
    'title': 'Test deck',
    'content_source': 'memox-fixture',
    'default_scheduler_type': scheduler,
    'children':
        children ??
        <Object?>[
          <String, Object?>{
            'name': 'Leaf',
            'cards': <Object?>[
              <String, Object?>{'front': 'kettle', 'back': 'ấm đun nước'},
            ],
          },
        ],
  };

  DeckTemplateDataSource loaderFor(Map<String, Object?> json) =>
      DeckTemplateDataSource(
        bundle: _MapBundle(<String, String>{
          'assets/templates/manifest.json': manifest(<String>['one.json']),
          'assets/templates/one.json': jsonEncode(json),
        }),
      );

  group('the shipped assets', () {
    test('parse, and cover both schedulers and a three-level tree', () async {
      final templates = await const DeckTemplateDataSource().loadAll();

      expect(templates.length, 2);
      expect(
        templates.map((entry) => entry.defaultSchedulerType),
        containsAll(<SchedulerType>[SchedulerType.eightBox, SchedulerType.sm2]),
      );
      // BR-87: the fixture says what it is, in the bundle, where anyone
      // inspecting the app can read it.
      for (final entry in templates) {
        expect(entry.contentSource, 'memox-fixture');
        expect(entry.cardCount, greaterThan(0));
        // Root → branch → leaf. A two-level fixture would let the whole class
        // of `root_deck_id` defects BR-57 describes pass unnoticed.
        expect(
          entry.children.any((child) => child.children.isNotEmpty),
          isTrue,
          reason: '${entry.templateId} is not three levels deep',
        );
      }
    });

    test('every template id is unique, which is what BR-37 keys on', () async {
      final templates = await const DeckTemplateDataSource().loadAll();
      final ids = templates.map((entry) => entry.templateId).toSet();

      expect(ids.length, templates.length);
    });
  });

  group('a template it will not accept', () {
    test('one that declares both sub-decks and cards', () {
      final loader = loaderFor(
        template(
          children: <Object?>[
            <String, Object?>{
              'name': 'Both',
              'children': <Object?>[
                <String, Object?>{'name': 'Child', 'cards': <Object?>[]},
              ],
              'cards': <Object?>[
                <String, Object?>{'front': 'a', 'back': 'b'},
              ],
            },
          ],
        ),
      );

      // BR-61/BR-62 refused at the door, so `installTemplate` never has to ask.
      expect(loader.loadAll(), throwsA(isA<DeckTemplateFormatException>()));
    });

    test('one whose scheduler this build does not know', () {
      final loader = loaderFor(template(scheduler: 'spaced_repetition_9000'));

      // `SchedulerType.fromDbValue` answers `unknown` rather than throwing,
      // which is right for a database written by a newer app and wrong for an
      // asset this build shipped — nothing could install with it.
      expect(loader.loadAll(), throwsA(isA<DeckTemplateFormatException>()));
    });

    test('one with no children at all', () {
      final loader = loaderFor(template(children: <Object?>[]));

      // A root holds sub-decks only (BR-58), so an empty template installs a
      // root the copy path can never put anything into.
      expect(loader.loadAll(), throwsA(isA<DeckTemplateFormatException>()));
    });

    test('one whose card text would fail the rules a user is held to', () {
      final loader = loaderFor(
        template(
          children: <Object?>[
            <String, Object?>{
              'name': 'Leaf',
              'cards': <Object?>[
                <String, Object?>{'front': '   ', 'back': 'b'},
              ],
            },
          ],
        ),
      );

      expect(loader.loadAll(), throwsA(isA<DeckTemplateFormatException>()));
    });

    test('one whose version is not a number', () {
      final json = template()..['version'] = '1';
      final loader = loaderFor(json);

      expect(loader.loadAll(), throwsA(isA<DeckTemplateFormatException>()));
    });
  });

  test('a blank example is the same statement as leaving it out', () async {
    final loader = loaderFor(
      template(
        children: <Object?>[
          <String, Object?>{
            'name': 'Leaf',
            'cards': <Object?>[
              <String, Object?>{'front': 'a', 'back': 'b', 'example': '  '},
            ],
          },
        ],
      ),
    );

    final templates = await loader.loadAll();

    expect(templates.single.children.single.cards.single.example, isNull);
  });
}
