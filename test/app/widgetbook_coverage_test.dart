import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every shared component appears in the Widgetbook catalogue.
///
/// **The stress suite has had this check for a long time; the catalogue never
/// did, and the difference showed.** `mx_stress_test.dart` asserts that no file
/// in `lib/shared/widgets` is missing a specimen, and carries a written reason
/// for each of its ten exclusions — so its coverage is complete and stays that
/// way. The catalogue had only a smoke test that the shell builds, which passes
/// just as happily when a component is absent.
///
/// Measured at M100.6, eight shared components had no entry, led by
/// `MxContentShell` — 23 files, 31 uses, the frame that owns every screen's
/// title, bar and padding. A catalogue that shows every button and no page
/// frame answers "what does a button look like" and cannot answer "why do these
/// two screens have different gutters", which is exactly the question the frame
/// exists to settle. Five entries closed that; this test is what keeps it
/// closed.
///
/// **The DoD already required this** — "every new screen and new shared
/// component registered in the Widgetbook catalog". It was a sentence in a
/// document rather than a check, and a sentence is what the eight got past.
void main() {
  /// Components deliberately absent, and why.
  ///
  /// Each is here for the same reason its twin is excluded from the stress
  /// list: it adds no visual surface of its own, so an entry would show
  /// whatever the caller handed it rather than the component.
  const Map<String, String> excluded = <String, String>{
    'MxAsyncConfirmDialog':
        'renders MxConfirmDialog and adds no visual surface — the submitting '
        'spinner it drives is MxConfirmDialog.isSubmitting, which that entry '
        'already has a knob for. What it owns is the close policy and the '
        'fire-once transition, which a catalogue page cannot show.',
    'MxFocusRing':
        'a foregroundDecoration and no layout — it shows nothing until a '
        'descendant takes keyboard focus, which a catalogue page cannot '
        'arrange. What it owns is asserted in mx_pill_button_focus_test.dart, '
        'which reaches it with a real Tab.',
    'MxFormHost':
        'a showModalBottomSheet host that returns its child untouched. What it '
        'owns is the keyboard inset and the close-on-transition rule — '
        'behaviour, not a picture.',
    'MxSubheaderBand':
        'the band MxContentShell lays a subheader into, and its whole job is '
        'the gutter arithmetic it inherits from the shell. Shown alone it is a '
        'Padding with a number in it; the entry that means anything is '
        "MxContentShell's, which draws the band in the frame it belongs to.",
    'MxReadingColumn':
        'a ConstrainedBox with one number in it — the reading-column cap the '
        'shell owns. Shown alone it is an empty width; every capped screen in '
        'the catalogue already draws it in the frame it belongs to.',
    'MxDialogHeader':
        'the shared headline row inside MxConfirmDialog and MxFormDialog, both '
        'of which are catalogued. An entry would be the same row twice.',
  };

  /// Files under `lib/shared/widgets` with no top-level widget class at all —
  /// a `part`, a mapping extension, or functions that configure Material's own
  /// overlays. There is nothing to render, so there is nothing to catalogue.
  const Set<String> notComponents = <String>{
    'mx_breadcrumb_step.dart',
    'mx_dialog_metrics.dart',
    'mx_failure_labels_widget.dart',
    'mx_messenger.dart',
    'mx_scroll_end_inset.dart',
    'mx_undo_snack_bar.dart',
  };

  test('no shared component is missing from the catalogue', () {
    final catalogue = Directory('widgetbook/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .map((File file) => file.readAsStringSync())
        .join('\n');

    final missing = <String>[];
    for (final file in Directory(
      'lib/shared/widgets',
    ).listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!name.endsWith('.dart') || notComponents.contains(name)) continue;

      // **Every widget class in the file, not the first one.** The original
      // used `firstMatch`, which quietly assumed one component per file — a
      // fair assumption until `mx_hero_card.dart` shipped two at M100.8, and
      // this check passed while `MxHeroPrimary` had no entry. `MxSubheaderBand`
      // had been hidden behind `MxContentShell` the whole time.
      final matches = RegExp(
        r'^class (Mx[A-Za-z0-9]+)(?:<[^>]*>)? extends (?:Stateless|Stateful|Consumer)',
        multiLine: true,
      ).allMatches(file.readAsStringSync());

      for (final match in matches) {
        final component = match.group(1)!;
        if (excluded.containsKey(component)) continue;
        // The catalogue names its entries; a bare mention in an import or a doc
        // comment is not an entry, which is the distinction that makes this
        // check worth having.
        if (catalogue.contains("name: '$component'")) continue;

        missing.add(component);
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'These shared components have no Widgetbook entry, so nobody can see '
          'them without finding a screen that happens to use one. Add an entry '
          'in widgetbook/lib/components/, or add the component to `excluded` '
          'above with the reason it has nothing to show: $missing',
    );
  });

  test('no exclusion outlives the component it names', () {
    // The same staleness rule the icon-ink guard carries: an exclusion list
    // nobody prunes stops being a list of exceptions and becomes a list of
    // files.
    final sources = Directory('lib/shared/widgets')
        .listSync()
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .map((File file) => file.readAsStringSync())
        .join('\n');

    for (final component in excluded.keys) {
      expect(
        sources.contains('class $component'),
        isTrue,
        reason:
            '$component is excluded from the catalogue but no longer exists in '
            'lib/shared/widgets — delete the entry rather than leaving a '
            'standing exemption behind',
      );
    }

    for (final name in notComponents) {
      expect(
        File('lib/shared/widgets/$name').existsSync(),
        isTrue,
        reason: '$name is listed as "not a component" but no longer exists',
      );
    }
  });

  test('the catalogue offers every theme the app can render', () {
    // A20.1 P1-08: the app wires four themes; a catalogue showing two of
    // them is a catalogue in which half the palette has no picture.
    final main = File('widgetbook/lib/main.dart').readAsStringSync();
    for (final builder in <String>[
      'buildLightTheme',
      'buildDarkTheme',
      'buildHighContrastLightTheme',
      'buildHighContrastDarkTheme',
    ]) {
      expect(main, contains('$builder()'), reason: '$builder is not offered');
    }
    expect(
      RegExp(r'WidgetbookTheme<ThemeData>\(').allMatches(main).length,
      4,
      reason: 'four modes, exactly',
    );
  });
}
