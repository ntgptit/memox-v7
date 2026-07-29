import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every public shared widget carries the `Mx` prefix, and nothing carries the
/// old one.
///
/// The rename is only worth doing once. Without this test the next component
/// gets written as `AppSomethingWidget` — the old files are gone, but the habit
/// and every older example in git history are not — and the project is back to
/// two shared APIs with no way to tell which is canonical.
///
/// **The `App` prefix is deliberately still correct elsewhere.** `AppSpacing`,
/// `AppRadius`, `AppIconSize`, `AppTypography`, `AppSemanticColors`, `AppTheme`
/// and `AppDatabase` are token and core namespaces, not widgets. The rule is
/// about the widget taxonomy; applying it to tokens would be a rename with no
/// argument behind it.
void main() {
  const sharedWidgetDir = 'lib/shared/widgets';

  List<File> dartFilesIn(String path) => <File>[
    for (final entity in Directory(path).listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart')) entity,
  ];

  test('every shared widget file is named mx_*', () {
    final wrong = <String>[
      for (final file in dartFilesIn(sharedWidgetDir))
        if (!file.uri.pathSegments.last.startsWith('mx_'))
          file.path.replaceAll(r'\', '/'),
    ];

    expect(wrong, isEmpty, reason: 'shared widget files must be mx_*.dart');
  });

  test('no public class in shared/widgets uses a banned prefix', () {
    // `Common`, `Shared` and `Base` are banned alongside `App` because they are
    // the names people reach for next when one prefix is taken.
    final banned = RegExp(
      r'^(?:class|enum|mixin)\s+(App|Common|Shared|Base)\w+',
      multiLine: true,
    );
    final offenders = <String>[
      for (final file in dartFilesIn(sharedWidgetDir))
        for (final match in banned.allMatches(file.readAsStringSync()))
          '${file.uri.pathSegments.last}: ${match.group(0)}',
    ];

    expect(offenders, isEmpty);
  });

  test('every public class in shared/widgets uses the Mx prefix', () {
    // The positive half. The test above would pass on a class called
    // `TextFieldThing`, which is neither banned nor part of the taxonomy.
    final declaration = RegExp(
      r'^(?:class|enum|mixin)\s+(\w+)',
      multiLine: true,
    );
    final offenders = <String>[
      for (final file in dartFilesIn(sharedWidgetDir))
        for (final match in declaration.allMatches(file.readAsStringSync()))
          if (!match.group(1)!.startsWith('Mx') &&
              !match.group(1)!.startsWith('_'))
            '${file.uri.pathSegments.last}: ${match.group(1)}',
    ];

    expect(offenders, isEmpty);
  });

  test('nothing imports or names the retired App* shared widgets', () {
    const retired = <String>[
      'AppButtonWidget',
      'AppButtonVariant',
      'AppCardSurface',
      'AppEmptyStateWidget',
      'AppErrorStateWidget',
      'AppLoadingStateWidget',
      'AppScaffoldWidget',
      'app_button_widget.dart',
      'app_card_surface_widget.dart',
      'app_empty_state_widget.dart',
      'app_error_state_widget.dart',
      'app_loading_state_widget.dart',
      'app_scaffold_widget.dart',
    ];

    final offenders = <String>[];
    for (final root in <String>['lib', 'test']) {
      for (final file in dartFilesIn(root)) {
        final path = file.path.replaceAll(r'\', '/');
        // This file names them on purpose; generated output is not ours.
        if (path.endsWith('mx_naming_test.dart')) continue;
        if (path.endsWith('.g.dart') || path.endsWith('.drift.dart')) continue;

        final source = file.readAsStringSync();
        for (final name in retired) {
          if (source.contains(name)) offenders.add('$path -> $name');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no compatibility wrapper survives the rename', () {
    // Every consumer is inside this repository, so an alias would exist only
    // so that the old name keeps working — which is the whole reason a
    // migration stalls halfway and stays there.
    final aliases = <String>[
      for (final file in dartFilesIn(sharedWidgetDir))
        if (RegExp(
          r'^\s*(?:@[Dd]eprecated.*|typedef\s+App\w+)',
          multiLine: true,
        ).hasMatch(file.readAsStringSync()))
          file.uri.pathSegments.last,
    ];

    expect(aliases, isEmpty);
  });
}
