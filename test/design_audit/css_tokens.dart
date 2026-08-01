import 'dart:io';

import 'package:flutter/material.dart';

/// Reads `design_system/tokens/*.css` — the authoritative source for token
/// *values* since M4.10p (see `docs/architecture.md`, "Nguồn của giá trị token
/// đã đổi").
///
/// **Why parse the CSS rather than keep copying numbers into Dart tests.**
/// `app_typography_test.dart` and `design_tokens_test.dart` hand-copy the values
/// and say so on purpose: a test reading the same source the code reads proves
/// only that the code is self-consistent. That argument holds for *Dart*
/// sources. It does not hold here, because Dart never reads the CSS — the two
/// are independent artifacts maintained by hand, which is precisely the pair
/// that drifts. Edit `colors.css` today and `flutter analyze`, every widget test
/// and every golden stay green while the app and the kit no longer agree.
///
/// So the hand-copied tests keep their job (nothing may move without a human
/// editing an expectation) and this one adds the other half: whatever the CSS
/// now says, Dart says the same.
///
/// The parser is deliberately small. These files are generated-flat — one
/// `--name:value` per declaration, no nesting, no calc(), two scopes — so a real
/// CSS parser would be a dependency bought for nothing.
abstract final class CssTokens {
  static final Map<String, Map<String, String>> _cache =
      <String, Map<String, String>>{};

  /// Every custom property in [file], with `var(--x)` references resolved.
  ///
  /// [scope] picks the block: `:root` is light, `[data-theme="dark"]` is dark.
  /// A dark scope inherits `:root` for anything it does not re-point, which is
  /// how the file is written — dark restates only the names whose value moves.
  static Map<String, String> read(String file, {String scope = ':root'}) {
    final key = '$file|$scope';
    final cached = _cache[key];
    if (cached != null) return cached;

    final source = File('design_system/tokens/$file').readAsStringSync();
    final stripped = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    final root = _declarationsIn(stripped, ':root');
    final resolved = scope == ':root'
        ? root
        : (Map<String, String>.from(root)
            ..addAll(_declarationsIn(stripped, scope)));

    // Resolved after merging, not before: a dark `--color-primary:var(--mx-indigo-dark)`
    // has to see dark's own base literals, and those live in `:root` too.
    for (final name in resolved.keys.toList()) {
      resolved[name] = _resolve(resolved[name]!, resolved);
    }

    return _cache[key] = Map<String, String>.unmodifiable(resolved);
  }

  static Map<String, String> _declarationsIn(String source, String selector) {
    final start = source.indexOf(selector);
    if (start < 0) return <String, String>{};

    final open = source.indexOf('{', start);
    final close = source.indexOf('}', open);
    if (open < 0 || close < 0) return <String, String>{};

    final body = source.substring(open + 1, close);
    final out = <String, String>{};
    for (final match in RegExp(r'(--[\w-]+)\s*:\s*([^;]+);').allMatches(body)) {
      out[match.group(1)!] = match.group(2)!.trim();
    }

    return out;
  }

  /// Follows `var(--x)` chains. Depth-limited rather than cycle-detected: these
  /// files are two levels deep and a cycle would be a typo, so failing loudly
  /// beats carrying a graph walk nobody needs.
  static String _resolve(String value, Map<String, String> all) {
    var current = value;
    for (var hop = 0; hop < 8; hop++) {
      final match = RegExp(r'^var\((--[\w-]+)\)$').firstMatch(current.trim());
      if (match == null) return current.trim();

      final next = all[match.group(1)!];
      if (next == null) {
        throw StateError('${match.group(1)} is referenced but never declared');
      }
      current = next;
    }

    throw StateError('var() chain from $value does not terminate');
  }

  /// A `px` or unitless number — `--space-lg:16px` reads as 16.
  static double number(String file, String token, {String scope = ':root'}) {
    final raw = require(file, token, scope: scope);
    final match = RegExp(r'^(-?[\d.]+)(px|ms)?$').firstMatch(raw);
    if (match == null) {
      throw StateError('$token is "$raw", which is not a plain number');
    }

    return double.parse(match.group(1)!);
  }

  /// A `#RRGGBB` value as an opaque [Color].
  static Color color(String file, String token, {String scope = ':root'}) {
    final raw = require(file, token, scope: scope);
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(raw);
    if (match == null) {
      throw StateError('$token is "$raw", which is not a #RRGGBB literal');
    }

    return Color(int.parse('FF${match.group(1)}', radix: 16));
  }

  /// The raw declaration, with a message naming the file when it is absent.
  static String require(String file, String token, {String scope = ':root'}) {
    final value = read(file, scope: scope)[token];
    if (value == null) {
      throw StateError('$token is not declared in $file ($scope)');
    }

    return value;
  }

  /// Every declared name in [file] under [scope], including the `--mx-*` base
  /// literals. Used by the completeness checks, which is the half of parity that
  /// catches a token *added* to the CSS rather than one changed.
  static Set<String> names(String file, {String scope = ':root'}) =>
      read(file, scope: scope).keys.toSet();

  /// Every `.css` file in the token directory.
  ///
  /// The completeness checks enumerate tokens inside a list of files they are
  /// given, so a whole *file* added to the kit would be invisible to them —
  /// clean output, nothing read. This is what turns that into a failure.
  static Set<String> tokenFileNames() => Directory('design_system/tokens')
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where((name) => name.endsWith('.css'))
      .toSet();
}
