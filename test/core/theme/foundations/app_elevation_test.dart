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
    test('a light card gets a float and a contact layer', () {
      // **This assertion was `hasLength(1)` until M100.30, and the reason it
      // gave still holds for the layer it was turning down.** That was
      // Material's *ambient* second shadow — a full-size blur per surface,
      // moving the result by under half an L* step. Tokyo's second layer is the
      // opposite animal: a 2 px contact blur at 32%, which is cheap and which
      // moves the ground by 9.27 L*.
      //
      // The two say different things and one layer can only say one of them.
      // The float carries "this is above the page"; the contact carries "and it
      // touches here". A tight dark drop on its own reads as a cut-out, which
      // is what the app looked like.
      final shadows = shadowsFor(AppElevation.card, light);
      expect(shadows, hasLength(2));

      final (float, contact) = (shadows.first, shadows.last);
      expect(
        float.blurRadius,
        greaterThan(contact.blurRadius),
        reason: 'the float is the wide layer',
      );
      expect(
        float.offset.dy,
        greaterThan(contact.offset.dy),
        reason: 'the float travels further from the surface than the contact',
      );
      expect(
        contact.color.a,
        greaterThan(float.color.a),
        reason:
            'the contact layer is the denser of the two — it is what puts the '
            'card *on* something rather than merely above it',
      );
      // Still not Material's ambient wash: if this ever grows past the float it
      // has stopped being a contact layer.
      expect(
        contact.blurRadius,
        lessThanOrEqualTo(AppElevation.raised),
        reason:
            'a contact layer is a tight blur; at this width it is the ambient '
            'wash this file turned down, and a list of twenty cards pays for '
            'it twenty times',
      );
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

      // **Light is measured at the alpha it actually paints, read off the
      // shadow rather than restated.** It used to be the literal `0.05`, a
      // stand-in for the `0.06 + 0.01 * level` the single dark layer used; with
      // Tokyo's blue-grey at 18/32% that literal measures 1.41 L\* and would
      // have failed a rule it was never about. Reading the layers keeps the
      // question ("does light's shadow buy enough to be worth painting?")
      // pointed at whatever light currently paints.
      //
      // Dark stays a literal on purpose: nothing there paints a shade at all,
      // so there is no alpha to read, and 0.20 is a deliberately generous probe
      // — several times anything this palette would ever cast.
      final darkGain = buys(darkPage, dark.shadow, 0.20);
      final lightGain = shadowsFor(AppElevation.card, light)
          .map(
            (BoxShadow shadow) => buys(lightPage, shadow.color, shadow.color.a),
          )
          .reduce((double a, double b) => a > b ? a : b);

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
            "light's densest shadow layer moves the page by only "
            '${lightGain.toStringAsFixed(2)} L*, which is not enough to carry '
            "light's depth on its own — the surface step there is just 3.58",
      );
    });
  });

  group('the shadow itself', () {
    test('gets its colour from the theme, never from a literal', () {
      // Both layers, because "the shadow is the token" stops being true the
      // moment one of two layers is a literal — and the two now differ only in
      // alpha, which is exactly where a hand-written second colour would hide.
      for (final shadow in shadowsFor(AppElevation.card, light)) {
        expect(
          shadow.color.r,
          closeTo(light.shadow.r, 0.001),
          reason: 'the shadow must be the theme token at reduced alpha',
        );
        expect(shadow.color.g, closeTo(light.shadow.g, 0.001));
        expect(shadow.color.b, closeTo(light.shadow.b, 0.001));
        expect(shadow.color.a, lessThan(1.0));
      }
    });

    test('the shadow token is not the scrim', () {
      // **They were one constant until M100.30**, and the split is the whole
      // reason light's shadow could move to Tokyo's blue-grey: a scrim is laid
      // over the page to take it out of reach and has to stay dark, while a
      // shadow is light passing around an object. One name could not hold both
      // once one of them moved.
      expect(
        light.shadow,
        isNot(light.scrim),
        reason:
            'light has re-merged its shadow and its scrim; whichever one moved '
            'has dragged the other with it',
      );
      expect(
        lightnessStar(light.shadow),
        greaterThan(lightnessStar(light.scrim)),
        reason: 'a cast shadow is the lighter of the two, not the darker',
      );
    });

    test('grows with the level rather than jumping', () {
      // Per layer, and by geometry alone. Tokyo's alphas do not climb with the
      // level — depth is how far the float travels and how wide it spreads, not
      // how dark it gets, which is what stops a raised card reading as a
      // *darker* card. The old single layer had to climb its alpha because a
      // tight shade was the only handle it had.
      for (final index in <int>[0, 1]) {
        final card = shadowsFor(AppElevation.card, light)[index];
        final overlay = shadowsFor(AppElevation.overlay, light)[index];

        expect(overlay.blurRadius, greaterThan(card.blurRadius));
        expect(overlay.offset.dy, greaterThan(card.offset.dy));
        expect(
          overlay.color.a,
          card.color.a,
          reason: 'layer $index changed its alpha with the level',
        );
      }
    });
  });
}
