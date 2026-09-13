// ignore: unnecessary_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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
    test("a light card gets the handoff's one soft shadow", () {
      // **One layer since M100.86.** The two-layer float-and-contact shade was
      // Tokyo-dashboard's; the handoff's Card spec gives a list card
      // `shadow-soft` — `0 1px 2px` at 4% — and nothing else. A tight, faint
      // shade is what the kit means by "flat and quiet".
      final shadow = shadowsFor(AppElevation.card, light).single;

      expect(shadow.offset, const Offset(0, 1));
      expect(shadow.blurRadius, 2);
      expect(shadow.spreadRadius, 0);
      expect(shadow.color.a, closeTo(0.04, 0.001));
    });

    test('a dark card gets a crisp rim, never a glow', () {
      // **The rim used to be Tokyo's `shadows.card` verbatim** — `#6A7199` at
      // `blurRadius: 2` with a spread that climbed by level. It measured
      // 3.74:1 against the card it outlined, which is a *control* boundary's
      // contrast on a resting neutral surface, and the blur turned it into a
      // halo on a 16 px corner. Ten of those in a phone column read as neon
      // stripes, and the owner rejected the look on sight (M100.35).
      final card = shadowsFor(AppElevation.card, dark).single;

      expect(
        card.color,
        dark.outlineVariant,
        reason:
            'the resting dark edge is M3\'s decorative boundary role, '
            'which is explicitly not held to 3:1',
      );
      expect(
        card.blurRadius,
        0,
        reason: 'crisp: a blurred edge on a 16 px corner is a smear',
      );
      expect(card.spreadRadius, AppStroke.hairline);
      expect(card.offset, Offset.zero);
    });

    test('dark says "higher" with a drop, and never with a thicker rim', () {
      // The hierarchy still has to be readable — but not by growing the glow,
      // which is how `none < card < raised` used to be spelled.
      final card = shadowsFor(AppElevation.card, dark);
      final raised = shadowsFor(AppElevation.raised, dark);

      expect(card, hasLength(1), reason: 'a list card carries the rim alone');
      expect(raised, hasLength(2));
      expect(
        raised.first.spreadRadius,
        card.single.spreadRadius,
        reason: 'the rim is one hairline at every level, forever',
      );
      expect(raised.first.color, card.single.color);

      final drop = raised.last;
      expect(drop.color.withValues(alpha: 1), dark.shadow);
      expect(drop.spreadRadius, 0, reason: 'a drop must not lighten an edge');
      expect(drop.offset.dy, greaterThan(0));
      expect(drop.blurRadius, greaterThan(0));
    });

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

      // **The dark ground is back at the bottom of the scale (M100.86).** The
      // handoff's page is navy at L\* 4.7, and a generous 20% black shade over
      // it moves the ground by about 1.2 L\* — little enough that the kit
      // separates its dark card with a hairline rim rather than a shade, which
      // is what `shadowsFor` paints. Held under 1.5 so the rim-only card is
      // re-argued the day a palette gives a dark shade room to be seen.
      expect(
        darkGain,
        lessThan(1.5),
        reason:
            'a dark shadow at alpha 0.20 moves the page by '
            '${darkGain.toStringAsFixed(2)} L*, so dark has room for a real '
            'shade again — revisit the rim-only card rather than leaving it '
            'justified by a measurement that no longer holds.',
      );
      expect(
        lightGain,
        greaterThan(3.0),
        reason:
            "light's densest shadow layer moves the page by only "
            '${lightGain.toStringAsFixed(2)} L*, which is not enough to carry '
            "light's depth on its own — the surface step there is just 2.09",
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
      // Each level the handoff names travels further and spreads wider than
      // the list card, and is denser too (4% → 10% → 12%): they are three
      // named shadows in the kit rather than one layer re-scaled, so the
      // alpha is not held flat any more.
      final card = shadowsFor(AppElevation.card, light).single;
      for (final level in <double>[AppElevation.raised, AppElevation.overlay]) {
        final higher = shadowsFor(level, light).single;

        expect(higher.blurRadius, greaterThan(card.blurRadius));
        expect(higher.offset.dy, greaterThan(card.offset.dy));
        expect(higher.color.a, greaterThan(card.color.a));
      }
    });
  });
}
