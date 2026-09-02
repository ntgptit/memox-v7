import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';

import 'audit_color_math.dart';
import 'color_usage_scan.dart';

/// Turning a scanned site into the two hex values it renders as.
///
/// Split from `usage_scan_test.dart` at the 400-line guard, on the seam the file
/// already had: resolution answers "what colour is this", classification answers
/// "is that allowed". They share nothing but the site.
///
/// The naming matches `theme_dump_test.dart` exactly, so one lookup serves both
/// files and there is no second scheme to keep in step.
class TokenResolver {
  TokenResolver({required this.light, required this.dark})
    : lightTable = _tableOf(light),
      darkTable = _tableOf(dark);

  final ThemeData light;
  final ThemeData dark;
  final Map<String, Color> lightTable;
  final Map<String, Color> darkTable;

  static Map<String, Color> _tableOf(ThemeData theme) {
    final s = theme.colorScheme;
    final x = theme.extension<AppSemanticColors>()!;

    return <String, Color>{
      'colorScheme.primary': s.primary,
      'colorScheme.onPrimary': s.onPrimary,
      'colorScheme.primaryContainer': s.primaryContainer,
      'colorScheme.onPrimaryContainer': s.onPrimaryContainer,
      'colorScheme.secondary': s.secondary,
      'colorScheme.onSecondary': s.onSecondary,
      'colorScheme.secondaryContainer': s.secondaryContainer,
      'colorScheme.onSecondaryContainer': s.onSecondaryContainer,
      'colorScheme.tertiary': s.tertiary,
      'colorScheme.error': s.error,
      'colorScheme.onError': s.onError,
      'colorScheme.errorContainer': s.errorContainer,
      'colorScheme.onErrorContainer': s.onErrorContainer,
      'colorScheme.surface': s.surface,
      'colorScheme.onSurface': s.onSurface,
      'colorScheme.onSurfaceVariant': s.onSurfaceVariant,
      'colorScheme.surfaceContainerHighest': s.surfaceContainerHighest,
      'colorScheme.outline': s.outline,
      'colorScheme.outlineVariant': s.outlineVariant,
      'colorScheme.inverseSurface': s.inverseSurface,
      'colorScheme.onInverseSurface': s.onInverseSurface,
      'colorScheme.shadow': s.shadow,
      'colorScheme.scrim': s.scrim,
      'semantic.success': x.success,
      'semantic.warning': x.warning,
      'semantic.danger': x.danger,
      'semantic.info': x.info,
      'semantic.surfaceMuted': x.surfaceMuted,
      'semantic.surfaceElevated': x.surfaceElevated,
      'semantic.borderSubtle': x.borderSubtle,
      'semantic.secondaryAction': x.secondaryAction,
      'Colors.transparent': const Color(0x00000000),
      'Colors.white': const Color(0xFFFFFFFF),
      'Colors.black': const Color(0xFF000000),
    };
  }

  /// `AppColors.warningLight` resolves in light only, and vice versa: a palette
  /// constant names its own brightness, so quoting it under the other one would
  /// report a colour that never renders there.
  ({String? light, String? dark}) _sharedConstant(String token) {
    final leaf = token.substring('AppColors.'.length);

    Color? find(Map<String, Color> table, String suffix) {
      if (!leaf.endsWith(suffix)) return null;
      final base = leaf.substring(0, leaf.length - suffix.length);
      for (final entry in table.entries) {
        if (entry.key.split('.').last.toLowerCase() == base.toLowerCase()) {
          return entry.value;
        }
      }

      return null;
    }

    final l = find(lightTable, 'Light');
    final d = find(darkTable, 'Dark');

    return (light: l == null ? null : hex(l), dark: d == null ? null : hex(d));
  }

  /// The value [site] renders as under each brightness.
  ///
  /// `unresolvable` carries its reason rather than an empty string: "we could
  /// not tell" and "there is nothing here" are different answers, and a report
  /// that spelled them the same would hide the first.
  ({String light, String dark}) resolve(ColorSite site) {
    if (site.sourceKind == 'hardcoded-literal') {
      final match = RegExp(r'0x([0-9a-fA-F]{8})').firstMatch(site.expression);
      if (match == null) {
        return (
          light: 'unresolvable: literal is not a plain 0xAARRGGBB',
          dark: 'unresolvable: literal is not a plain 0xAARRGGBB',
        );
      }
      final value = hex(Color(int.parse(match.group(1)!, radix: 16)));

      return (light: value, dark: value);
    }

    final token = site.tokenName;
    if (token == null) {
      return (
        light: 'unresolvable: value depends on runtime state',
        dark: 'unresolvable: value depends on runtime state',
      );
    }

    if (token.startsWith('AppColors.')) {
      final resolved = _sharedConstant(token);

      return (
        light: resolved.light ?? 'unresolvable: no light counterpart in theme',
        dark: resolved.dark ?? 'unresolvable: no dark counterpart in theme',
      );
    }

    final l = lightTable[token];
    final d = darkTable[token];
    if (l == null || d == null) {
      return (
        light: 'unresolvable: $token not in the dumped theme',
        dark: 'unresolvable: $token not in the dumped theme',
      );
    }

    if (site.sourceKind == 'opacity-modified-token') {
      final alpha = RegExp(
        r'alpha:\s*([0-9.]+)',
      ).firstMatch(site.expression)?.group(1);

      return (
        light: '${hex(l)} @ alpha ${alpha ?? "unresolvable"}',
        dark: '${hex(d)} @ alpha ${alpha ?? "unresolvable"}',
      );
    }

    return (light: hex(l), dark: hex(d));
  }
}
