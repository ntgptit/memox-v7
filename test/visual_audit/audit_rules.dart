import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_colors.dart';

import '../support/color_math.dart';
import 'audit_model.dart';

export 'audit_geometry_rules.dart';

/// One thing an audit noticed.
///
/// [isBlocking] separates "this screen is wrong" from "this screen could not be
/// judged". Both are printed; only the first fails a test. Collapsing them would
/// force a choice between a suite that is red for unknowable reasons and a suite
/// that hides what it could not read — and the second is how a green check ends
/// up covering nothing.
@immutable
class AuditFinding {
  const AuditFinding({
    required this.rule,
    required this.itemId,
    required this.message,
    required this.isBlocking,
  });

  final String rule;
  final String itemId;
  final String message;
  final bool isBlocking;

  @override
  String toString() =>
      '${isBlocking ? 'FAIL' : 'note'}  $rule  [$itemId]  '
      '$message';
}

abstract interface class AuditRule {
  String get name;

  Iterable<AuditFinding> check(ScreenAudit audit);
}

List<AuditFinding> runAuditRules(ScreenAudit audit, List<AuditRule> rules) =>
    <AuditFinding>[for (final rule in rules) ...rule.check(audit)];

/// WCAG 1.4.3 for glyphs: 4.5:1, or 3:1 once the text is large.
///
/// The background is taken from the **raster**, not from the nearest declared
/// fill, because that is the one number both sources cannot fake: it already
/// contains the ink overlay, the elevation tint and whatever else is stacked
/// under the text.
class TextContrastRule implements AuditRule {
  const TextContrastRule();

  static const double _normal = 4.5;
  static const double _large = 3.0;

  /// **The one pair the owner accepted under AA, recorded here rather than
  /// allowed screen by screen (M100.27).** `primary` is Tokyo's `#5569FF`
  /// verbatim by owner decision and white on it measures 4.33:1; no ink but
  /// near-black clears 4.5 on it, and Tokyo's own buttons are white on it. The
  /// floor the pair is held to is 4.3 — the same number `app_theme_test.dart`
  /// holds — so a drift below what was accepted still fails.
  static const List<(Color, Color, double)> _ownerAccepted =
      <(Color, Color, double)>[
        (AppColors.onPrimaryLight, AppColors.primaryLight, 4.3),
      ];

  static bool _isOwnerAccepted(Color ink, Color background, double ratio) {
    for (final (fore, back, floor) in _ownerAccepted) {
      if (ink == fore && background == back && ratio >= floor) return true;
    }

    return false;
  }

  @override
  String get name => 'contrast.text';

  @override
  Iterable<AuditFinding> check(ScreenAudit audit) sync* {
    for (final item in audit.items) {
      for (final paint in item.withRole(PaintRole.text)) {
        if (paint.source != PaintSource.declared) continue;

        final background = _backgroundBehind(audit, paint);
        if (background == null) {
          yield AuditFinding(
            rule: name,
            itemId: item.id,
            message:
                'no measurable background behind ${hexOf(paint.color)} at '
                '${_where(paint.rect)}',
            isBlocking: false,
          );

          continue;
        }

        final threshold = paint.isLargeText ? _large : _normal;
        final ratio = contrast(paint.color, background);
        if (ratio >= threshold) continue;
        if (_isOwnerAccepted(paint.color, background, ratio)) continue;

        yield AuditFinding(
          rule: name,
          itemId: item.id,
          message:
              '${hexOf(paint.color)} on ${hexOf(background)} is '
              '${ratio.toStringAsFixed(2)}:1, below $threshold '
              '(${paint.fontSize?.toStringAsFixed(0) ?? '?'}px)',
          isBlocking: true,
        );
      }
    }
  }
}

/// WCAG 1.4.11 for everything that is not a glyph: 3:1.
///
/// Borders, focus rings and icon shapes carry meaning and are missed by every
/// text-only contrast check — including Flutter's own `textContrastGuideline`.
/// This project ships a `focusRing` token whose entire job is to be a non-text
/// indicator, so leaving it to a text rule would leave it unchecked.
class NonTextContrastRule implements AuditRule {
  const NonTextContrastRule(this.informationalColors);

  /// The tokens whose job is to *tell the user something*: focus, selection,
  /// validity, verdict.
  ///
  /// 1.4.11 covers what is "required to identify a component or its state" —
  /// not every stroke on screen. A subtle card hairline is decoration; holding
  /// it to 3:1 would force it to become a hard outline, which is the opposite
  /// of what the palette is for. Intent cannot be inferred from a rectangle, so
  /// it comes from the token vocabulary, which already encodes it.
  final List<Color> informationalColors;

  static const double _minimum = 3.0;

  @override
  String get name => 'contrast.non_text';

  @override
  Iterable<AuditFinding> check(ScreenAudit audit) sync* {
    for (final item in audit.items) {
      for (final paint in item.withRole(PaintRole.border)) {
        final isInformational = informationalColors.any(
          (token) => token.toARGB32() == paint.color.toARGB32(),
        );
        if (!isInformational) continue;

        final background = _backgroundBehind(audit, paint);
        if (background == null) continue;
        if (background == paint.color) continue;

        final ratio = contrast(paint.color, background);
        if (ratio >= _minimum) continue;

        yield AuditFinding(
          rule: name,
          itemId: item.id,
          message:
              'border ${hexOf(paint.color)} on ${hexOf(background)} is '
              '${ratio.toStringAsFixed(2)}:1, below $_minimum',
          isBlocking: true,
        );
      }
    }
  }
}

/// Every colour on screen must be one the palette approved.
///
/// **Declared and raster are judged by different rules, and the asymmetry is the
/// whole point.**
///
/// A declared colour must be an exact token. Nothing else — a blend of two
/// tokens does *not* pass. Letting it pass was a hole: `#123456` typed at a call
/// site sails through the moment it happens to land on the segment between two
/// palette entries, which is not rare with forty tokens, and the rule then
/// certifies a hardcoded colour as on-palette. Code that genuinely wants a state
/// layer computes it *from* tokens, and that computed value belongs in the
/// palette or in a component, not in an exemption.
///
/// A raster colour is a different kind of object: it is the outcome of
/// antialiasing and alpha compositing, so a blend on the line between two tokens
/// is the expected result rather than a defect. Anything off that line is
/// reported non-blocking, because it may be a real composite worth knowing about.
class PaletteClosureRule implements AuditRule {
  const PaletteClosureRule(this.tokens);

  final List<Color> tokens;

  static const int _blendTolerance = 3;

  @override
  String get name => 'palette.closure';

  @override
  Iterable<AuditFinding> check(ScreenAudit audit) sync* {
    for (final item in audit.items) {
      for (final paint in item.paints) {
        if (paint.source == PaintSource.declared) {
          // Exact token or nothing. The blend test is deliberately NOT consulted
          // here — see the class doc for the hole that opened when it was.
          if (_isToken(paint.color)) continue;

          yield AuditFinding(
            rule: name,
            itemId: item.id,
            message:
                '${paint.role.name} ${hexOf(paint.color)} from '
                '${paint.origin} is not a palette token',
            isBlocking: true,
          );

          continue;
        }

        if (_isToken(paint.color)) continue;
        if (_isBlendOfTokens(paint.color)) continue;

        yield AuditFinding(
          rule: name,
          itemId: item.id,
          message:
              'the image shows ${hexOf(paint.color)}, which is neither a token '
              'nor a blend of two — something is compositing',
          isBlocking: false,
        );
      }
    }
  }

  bool _isToken(Color color) =>
      tokens.any((token) => token.toARGB32() == color.toARGB32());

  bool _isBlendOfTokens(Color color) {
    for (var i = 0; i < tokens.length; i++) {
      for (var j = i + 1; j < tokens.length; j++) {
        if (_liesBetween(color, tokens[i], tokens[j])) return true;
      }
    }

    return false;
  }

  /// True when [color] sits on the straight line from [a] to [b].
  ///
  /// Antialiasing and alpha compositing both produce exactly this: a weighted
  /// average of two colours. Solving for the weight on the widest channel and
  /// checking the other two agree is enough to tell a blend from a colour
  /// somebody typed in.
  bool _liesBetween(Color color, Color a, Color b) {
    final channels = <(int, int, int)>[
      (_r(color), _r(a), _r(b)),
      (_g(color), _g(a), _g(b)),
      (_b(color), _b(a), _b(b)),
    ];
    final widest = channels.reduce(
      (x, y) => (x.$3 - x.$2).abs() >= (y.$3 - y.$2).abs() ? x : y,
    );
    final span = widest.$3 - widest.$2;
    if (span == 0) return false;

    final t = (widest.$1 - widest.$2) / span;
    if (t < 0 || t > 1) return false;

    return channels.every((channel) {
      final expected = channel.$2 + (channel.$3 - channel.$2) * t;

      return (channel.$1 - expected).abs() <= _blendTolerance;
    });
  }

  int _r(Color color) => (color.r * 255).round();

  int _g(Color color) => (color.g * 255).round();

  int _b(Color color) => (color.b * 255).round();
}

/// What the image shows immediately behind [paint].
///
/// Preference order matters. The raster sample covering the same rect is the
/// truth. Falling back to the smallest declared fill that encloses the rect is a
/// guess, and it is marked as one by the caller when it is unavailable.
Color? _backgroundBehind(ScreenAudit audit, AuditPaint paint) {
  for (final item in audit.items) {
    for (final candidate in item.paints) {
      if (candidate.source != PaintSource.raster) continue;
      if (candidate.rect != paint.rect) continue;
      if (candidate.color == paint.color) continue;

      return candidate.color;
    }
  }

  Color? best;
  var bestArea = double.infinity;

  for (final item in audit.items) {
    for (final candidate in item.paints) {
      if (candidate.role != PaintRole.fill) continue;
      if (candidate.rect == paint.rect) continue;
      if (!candidate.rect.contains(paint.rect.center)) continue;

      final area = candidate.rect.width * candidate.rect.height;
      if (area >= bestArea) continue;

      bestArea = area;
      best = candidate.color;
    }
  }

  return best;
}

String _where(Rect rect) =>
    '${rect.left.toStringAsFixed(0)},${rect.top.toStringAsFixed(0)}';

/// A screen that failed to build is a failure, not an unread node.
///
/// The walk records the error box as a skip so it can keep going; without this
/// rule that skip lands in the same list as "this painter is raster-only" and
/// the run reports PASS_WITH_UNRESOLVED. Which it did, on both production
/// screens, the first time this harness was pointed at `lib/` — every colour
/// assertion passed because there were no colours.
class NoErrorWidgetRule implements AuditRule {
  const NoErrorWidgetRule();

  @override
  String get name => 'build.no_error_widget';

  @override
  Iterable<AuditFinding> check(ScreenAudit audit) sync* {
    for (final skip in audit.skipsBecause(SkipReason.errorWidget)) {
      yield AuditFinding(
        rule: name,
        itemId: skip.itemId,
        message:
            'the screen did not build — every colour check below passed only '
            'because nothing was painted',
        isBlocking: true,
      );
    }
  }
}
