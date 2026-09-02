import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_colors.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// The elevation scale, and the measurement behind "dark paints no shadow".
///
/// `app_theme_test.dart` asserts that both modes lift a card off the page by the
/// same amount. This file asserts the *mechanism* underneath that: the scale
/// climbs, light paints, dark does not, and dark not painting is a consequence of
/// a number rather than a preference someone typed.
void main() {
  final light = buildLightTheme().colorScheme;
  final dark = buildDarkTheme().colorScheme;

  group('the scale', () {
    test('climbs, and starts at zero', () {
      expect(AppElevation.scale.first, 0);

      for (var i = 1; i < AppElevation.scale.length; i++) {
        expect(
          AppElevation.scale[i],
          greaterThan(AppElevation.scale[i - 1]),
          reason:
              'level $i (${AppElevation.scale[i]}) does not sit above level '
              '${i - 1} (${AppElevation.scale[i - 1]}), so the scale has no '
              'order to express',
        );
      }
    });

    test('level none paints nothing, in either mode', () {
      // The flat card is still reachable — a card inside a sheet wants it, and a
      // shadow stacked on a shadow reads as a rendering fault.
      expect(shadowsFor(AppElevation.none, light), isEmpty);
      expect(shadowsFor(AppElevation.none, dark), isEmpty);
    });
  });

  group('light paints, dark does not', () {
    test('a light card gets exactly one shadow', () {
      // One, not Material's two. The ambient second costs a full-size blur per
      // surface and moves the result by under half an L* step at this level.
      expect(shadowsFor(AppElevation.card, light), hasLength(1));
    });

    test(
      'a dark card gets a rim, not a shade — and the same one at every level',
      () {
        // Tokyo's `shadows.card` (M100.27): an opaque one-pixel halo, because
        // the measurement below shows a dark shade buys nothing and the card is
        // fixed at Tokyo's `#111633`, 4.3 L* above its page.
        final card = shadowsFor(AppElevation.card, dark).single;
        final overlay = shadowsFor(AppElevation.overlay, dark).single;

        expect(card.color, AppColors.cardRimDark);
        expect(card.color.a, 1.0, reason: 'a rim is an edge, not a wash');
        expect(card.offset, Offset.zero);
        // The solid ring is what the 3:1 ratios are measured on. Blur alone
        // would leave every exposed pixel partially covered and the source
        // colour's contrast a claim about paint nobody sees.
        expect(
          card.spreadRadius,
          greaterThanOrEqualTo(1.0),
          reason:
              'without a spread the rim is only a blur, and a blurred edge '
              'never reaches the colour its contrast was measured at',
        );
        expect(overlay.color, card.color);
        expect(overlay.blurRadius, card.blurRadius);
      },
    );

    test('and that is because a dark shadow buys almost nothing', () {
      // **The measurement the decision rests on, re-derived here rather than
      // quoted.** If the palette ever changes so that a dark shadow *would* be
      // visible, this fails and the decision gets revisited — which a comment
      // saying "dark has no room for shadows" could never do.
      final darkPage = buildDarkTheme().scaffoldBackgroundColor;
      final lightPage = buildLightTheme().scaffoldBackgroundColor;

      double buys(Color page, Color shadow, double alpha) {
        final under = Color.alphaBlend(shadow.withValues(alpha: alpha), page);

        return (lightnessStar(page) - lightnessStar(under)).abs();
      }

      // Generously: four times the alpha light actually uses.
      final darkGain = buys(darkPage, dark.shadow, 0.20);
      final lightGain = buys(lightPage, light.shadow, 0.05);

      expect(
        darkGain,
        lessThan(1.0),
        reason:
            'a dark shadow at alpha 0.20 moves the page by '
            '${darkGain.toStringAsFixed(2)} L*. If this ever exceeds 1.0 the '
            'dark page has left the bottom of the scale and dark should paint '
            'shadows after all.',
      );
      expect(
        lightGain,
        greaterThan(3.0),
        reason:
            'a light shadow at the alpha actually used moves the page by only '
            '${lightGain.toStringAsFixed(2)} L*, which is not enough to carry '
            "light's depth on its own — the surface step there is just 3.46",
      );
    });
  });

  group('the shadow itself', () {
    test('gets its colour from the theme, never from a literal', () {
      final shadow = shadowsFor(AppElevation.card, light).single;

      expect(
        shadow.color.r,
        closeTo(light.shadow.r, 0.001),
        reason: 'the shadow must be the theme token at reduced alpha',
      );
      expect(shadow.color.a, lessThan(1.0));
    });

    test('grows with the level rather than jumping', () {
      final card = shadowsFor(AppElevation.card, light).single;
      final overlay = shadowsFor(AppElevation.overlay, light).single;

      expect(overlay.blurRadius, greaterThan(card.blurRadius));
      expect(overlay.offset.dy, greaterThan(card.offset.dy));
      expect(overlay.color.a, greaterThan(card.color.a));
    });
  });
}
