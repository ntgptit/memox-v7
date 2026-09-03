import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dependency direction *inside* `lib/core/theme/`, and the line between
/// what the theme publishes and what it keeps.
///
/// **Why this exists at all (M100.29).** The theme was 29 files in one flat
/// directory. A flat directory has no direction: nothing stopped a token file
/// importing a component builder, nothing said whether a feature was allowed to
/// read `AppMaterialRoles` — and "is this a token or a builder?" could only be
/// answered by opening the file. The layers are the answer; this test is what
/// keeps them true, because a folder is a suggestion and a failing test is not.
///
/// **Import lines only**, like `architecture_boundary_test.dart`, and for the
/// same reason: this is a claim about the module graph, which import lines are
/// the whole of. Comments are stripped first — every file here names paths in
/// prose, this one included.
///
/// The layer contract, in one place:
///
/// ```
/// foundations   primitive tokens: colour, spacing, sizing, radius, stroke,
///               elevation, icon size, breakpoints, durations, motion policy
///        ↓
/// typography · states     the type scale and the interaction-state vocabulary
///        ↓
/// components · schemes    ThemeData slot builders; ColorScheme construction
///        ↓
/// app_theme.dart          the composition root, and the only file that may
///                         see every layer at once
///
/// extensions    the READ side — what a widget calls on a built theme. It sits
///               beside the build side rather than under it, and depends only
///               on foundations and typography.
/// ```
void main() {
  /// Every non-generated Dart file under [folder], as repo-relative paths with
  /// forward slashes.
  List<String> dartFilesUnder(String folder) =>
      Directory(folder)
          .listSync(recursive: true)
          .whereType<File>()
          .map((File file) => file.path.replaceAll(r'\', '/'))
          .where(
            (String path) =>
                path.endsWith('.dart') &&
                !path.endsWith('.g.dart') &&
                !path.endsWith('.freezed.dart'),
          )
          .toList()
        ..sort();

  /// Import targets in [source], comments stripped first.
  List<String> importsIn(String source) {
    final withoutComments = source
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp('//.*'), '');

    return RegExp(r"""^\s*import\s+'([^']+)'""", multiLine: true)
        .allMatches(withoutComments)
        .map((RegExpMatch match) => match.group(1)!)
        .where((String uri) => !uri.startsWith('dart:'))
        .where((String uri) => !uri.startsWith('package:flutter/'))
        .toList();
  }

  /// The layer a theme file belongs to, or `'root'` for `app_theme.dart`.
  String layerOf(String path) {
    final rest = path.substring('lib/core/theme/'.length);
    final slash = rest.indexOf('/');

    return slash == -1 ? 'root' : rest.substring(0, slash);
  }

  /// The layer an import *target* belongs to, resolved from the importing
  /// file's directory. Returns null for anything outside `lib/core/theme/`.
  String? importedLayer(String fromFile, String uri) {
    if (uri.startsWith('package:')) {
      const prefix = 'package:memox/core/theme/';
      if (!uri.startsWith(prefix)) return null;

      return layerOf('lib/core/theme/${uri.substring(prefix.length)}');
    }

    final resolved = Uri.parse(
      fromFile,
    ).resolve(uri).toString().replaceAll('%2E', '.');
    if (!resolved.startsWith('lib/core/theme/')) return null;

    return layerOf(resolved);
  }

  /// What each layer may reach. Its own layer is always allowed; a file next to
  /// another file is by definition the same decision.
  const canImport = <String, Set<String>>{
    // The floor. A token that reads a component theme is not a token — it is
    // a derivation with an opinion about who consumes it, and the cycle it
    // opens (`app_colors` ↔ `app_border_colors`, live until M100.18) is only
    // visible once something tries to move one of them.
    'foundations': <String>{},
    'typography': <String>{'foundations'},
    'states': <String>{'foundations'},
    'components': <String>{'foundations', 'typography', 'states'},
    'schemes': <String>{'foundations', 'typography', 'states'},
    // The read side. It may name the tokens a widget asks for and the styles
    // it returns; it must not know which components the app themes, because
    // `context.colors` has to keep working for a component nobody has themed.
    'extensions': <String>{'foundations', 'typography'},
    'root': <String>{
      'foundations',
      'typography',
      'states',
      'components',
      'schemes',
      'extensions',
    },
  };

  final themeFiles = dartFilesUnder('lib/core/theme');

  test('the theme has the six layers this contract is written against', () {
    // A zero-file layer passes every rule below without asserting anything —
    // the "zero scope" failure `check_architecture.py` names explicitly. If a
    // layer is emptied or renamed, this is the test that says so, rather than a
    // silent green from rules that matched nothing.
    final found = themeFiles.map(layerOf).toSet();

    expect(found, canImport.keys.toSet());
  });

  test('every layer imports only downwards', () {
    final offenders = <String>[];

    for (final path in themeFiles) {
      final from = layerOf(path);
      final allowed = <String>{from, ...canImport[from]!};

      for (final uri in importsIn(File(path).readAsStringSync())) {
        final to = importedLayer(path, uri);
        if (to == null || allowed.contains(to)) continue;

        offenders.add('$path ($from) imports $uri ($to)');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A theme layer may only import the layers below it. If a token needs '
          'a builder, the derivation belongs in the builder — not the token.',
    );
  });

  test('app_theme.dart composes component themes, it does not build them', () {
    // **The rule that keeps the composition root a composition root.** This
    // file was 635 lines: the `ColorScheme`, eight component themes and their
    // measurements all lived inside one `copyWith`, so "which components does
    // this app theme?" could not be read without scrolling past why a drag
    // handle is `onSurfaceVariant`. M100.29 moved every one of them out and
    // left 285 lines of wiring.
    //
    // Stated as "no component theme is *constructed* here" rather than as a
    // line count, because the line count is a symptom. A `CardThemeData(` in
    // this file is the regression; 500 tidy lines of `slot: builder(...)`
    // would not be.
    //
    // **`Theme` as well as `ThemeData`, because two of Material's slot types
    // never got the suffix.** `AppBarTheme` and `InputDecorationTheme` are the
    // component themes for `appBarTheme` and `inputDecorationTheme`; a pattern
    // anchored on `ThemeData` misses exactly those two, and `AppBarTheme` was
    // one of the eight this rule was written to evict.
    //
    // Two exemptions. `ThemeData` is the object being composed. `IconThemeData`
    // is not a component theme at all: `ThemeData.iconTheme` is the framework
    // fall-through for a bare `Icon` outside every themed component, in the
    // same family as `hoverColor` and `disabledColor` — settings the root
    // picks, with no component to own them.
    final source = File('lib/core/theme/app_theme.dart')
        .readAsStringSync()
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp('//.*'), '');

    const composedHere = <String>{'ThemeData', 'IconThemeData'};
    final built = RegExp(r'\b([A-Z][A-Za-z]*Theme(?:Data)?)\s*\(')
        .allMatches(source)
        .map((RegExpMatch match) => match.group(1)!)
        .where((String name) => !composedHere.contains(name))
        .toSet();

    expect(
      built,
      isEmpty,
      reason:
          'A component theme belongs to a builder in components/. Give it a '
          'buildXTheme(scheme, ...) and call that from here.',
    );
  });

  test('the theme never imports a feature, the shell or a shared widget', () {
    // The theme is built before any of them exists. `features/` and `shared/`
    // read the theme; `app/` mounts it. An import in this direction would make
    // the design system depend on the app it happens to be dressing, which is
    // the same failure AD-13 names for `features/` → `app/`.
    final offenders = <String>[];

    for (final path in themeFiles) {
      for (final uri in importsIn(File(path).readAsStringSync())) {
        final reaches = <String>['features/', 'app/', 'shared/'].where(
          (String folder) =>
              uri.startsWith('package:memox/$folder') ||
              (uri.startsWith('..') && uri.contains('/$folder')),
        );
        if (reaches.isEmpty) continue;

        offenders.add('$path imports $uri');
      }
    }

    expect(offenders, isEmpty);
  });

  test('a component theme reaches the palette only through the scheme', () {
    // **`components/` may import `foundations/`, but not all of it** (M100.31).
    // The four palette files are what `ColorScheme` is *built from*; a
    // component that reads one has stepped around the scheme and frozen a
    // value to one brightness — which is the whole bug class M100.18–23 spent
    // six PRs removing. The route is fixed:
    //
    //     component  →  ColorScheme  →  AppMaterialRoles / AppColors
    //
    // Structural tokens are a different matter and stay allowed: a radius is
    // not a role, and there is no scheme to read it through.
    const paletteSources = <String>{
      'app_colors.dart',
      'app_material_roles.dart',
      'app_surface_colors.dart',
      'app_border_colors.dart',
    };

    final offenders = <String>[];
    for (final path in themeFiles.where(
      (String path) => layerOf(path) == 'components',
    )) {
      for (final uri in importsIn(File(path).readAsStringSync())) {
        if (!paletteSources.contains(uri.split('/').last)) continue;
        offenders.add('$path imports $uri');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Read the role off the ColorScheme. If the role is wrong, the palette '
          'moves — the component does not pick a different token.',
    );
  });

  test('a component builder takes semantic systems, never loose paint', () {
    // **A builder that accepts a `Color` accepts any colour**, including one
    // that is not a Material role at all, and nothing above it can see the
    // difference. `buildFilledStyle` took `fill` and `label` that way until
    // M100.31; it takes `MxFilledPair` now, so the three admitted pairs are the
    // only reachable ones.
    //
    // **Two exemptions, both named rather than pattern-matched**, so a third
    // one has to be argued for here instead of appearing quietly.
    //
    // `background` (app bar): the page ground is the one colour the scheme
    // genuinely has no role for — `surface` is the card sitting on it — so the
    // composition root passes it, and picking the ground is a decision that
    // root already owns alongside picking the scheme. The alternative is an
    // `AppSemanticColors.pageBackground` field.
    //
    // `accent` (`textLinkForeground`): this resolver is shared between the
    // theme and `MxTextButton`, and the vocabulary that closes it is `AppInk`
    // — `MxTextButton.accent` is an `AppInk?` and "can only name a token".
    // `AppInk` cannot be the parameter type: it lives in `extensions/`, needs a
    // `BuildContext`, and `components/` may not import either. Closing it
    // further means narrowing the widget's API or moving `AppInk` down, both
    // shared-widget changes.
    const allowed = <String>{'background', 'accent'};

    final offenders = <String>[];
    for (final path in themeFiles.where(
      (String path) => layerOf(path) == 'components',
    )) {
      final source = File(path)
          .readAsStringSync()
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
          .replaceAll(RegExp('//.*'), '');

      for (final match in RegExp(
        r'^\s*(?:required\s+)?Color\??\s+(\w+)\s*[,)]',
        multiLine: true,
      ).allMatches(source)) {
        final name = match.group(1)!;
        if (allowed.contains(name)) continue;
        offenders.add('$path takes Color $name');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Pass a semantic system — a ColorScheme, an AppSemanticColors, or a '
          'closed enum of the pairs the design system admits — not a colour.',
    );
  });

  test('features and shared widgets read only the theme it publishes', () {
    // **The public API, stated as a rule rather than as a convention.** A
    // feature that reads `AppMaterialRoles.secondaryContainerLight` has taken a
    // value the `ColorScheme` already carries and frozen it to one brightness —
    // the exact bug M100.18–23 spent six PRs removing from the component
    // builders. The same argument applies to the surface, border and base
    // palettes: they are what the scheme is *built from*, and a consumer that
    // reads them has stepped around the scheme.
    //
    // `components/` and `schemes/` are internal for a different reason. A
    // component theme is one half of a contract whose other half is an `Mx`
    // widget (see `flutter-theme-design`), so `shared/widgets/` may read it —
    // `MxActionButton` calls `buildFilledTonalStyle` precisely so the widget
    // and the slot cannot disagree. A *feature* reaching a builder would be
    // rebuilding a component the shared layer already owns.
    //
    // `lib/app/` is absent from both lists on purpose: it is the composition
    // root. It picks the schemes, applies the compact transform, and paints the
    // two surfaces that exist outside `MaterialApp` — the bootstrap error
    // screen and the web letterbox — where no `Theme.of(context)` can reach.
    const paletteSources = <String>{
      'foundations/app_colors.dart',
      'foundations/app_material_roles.dart',
      'foundations/app_surface_colors.dart',
      'foundations/app_border_colors.dart',
    };
    const internalToFeatures = <String>{'components/', 'schemes/', 'states/'};
    const internalToShared = <String>{'schemes/'};

    final offenders = <String>[];

    for (final entry in <String, Set<String>>{
      'lib/features': internalToFeatures,
      'lib/shared': internalToShared,
    }.entries) {
      for (final path in dartFilesUnder(entry.key)) {
        for (final uri in importsIn(File(path).readAsStringSync())) {
          final layer = importedLayer(path, uri);
          if (layer == null) continue;

          final target = uri.split('core/theme/').last;
          final isForbidden =
              paletteSources.contains(target) ||
              entry.value.any(target.startsWith);
          if (!isForbidden) continue;

          offenders.add('$path imports $uri');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Read the built theme: context.colors, context.semanticColors, '
          'AppInk, and the structural scales. The palette files are what the '
          'ColorScheme is built from, not what a screen reads.',
    );
  });
}
