import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_dialog_tone.dart';

/// The severity axis: that it exists, that it reads the palette rather than
/// inventing one, and that it stays out of the way when nobody asked for it.
///
/// **The last one is the reason this file measures rather than eyeballs.** A
/// tone renders an icon, and an icon in `AlertDialog`'s own `icon:` slot flips
/// the headline to `TextAlign.center` — silently, inside the framework. Every
/// dialog in this app is left-aligned, so the first version of the tone header
/// would have re-centred five screens' worth of titles and only a golden would
/// have noticed, on Windows, later. `_Header` builds the row itself for exactly
/// that reason, and the alignment case below is what holds it there.
void main() {
  Widget host({
    required MxDialogTone? tone,
    ThemeData? theme,
    double textScale = 1,
    Size size = const Size(360, 640),
  }) => MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      theme: theme ?? buildLightTheme(),
      home: Scaffold(
        body: MxConfirmDialog(
          title: 'Delete this deck?',
          message: 'This deck and 12 cards go to Trash.',
          confirmLabel: 'Delete',
          cancelLabel: 'Cancel',
          tone: tone,
          onConfirm: () {},
          onCancel: () {},
        ),
      ),
    ),
  );

  Finder toneIcon() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(Icon),
  );

  group('the tone renders', () {
    testWidgets('no tone renders no icon at all', (tester) async {
      await tester.pumpWidget(host(tone: null));

      expect(
        toneIcon(),
        findsNothing,
        reason:
            'an untoned dialog must be byte-identical to the pre-tone one, '
            'or every existing golden moves for a feature nobody opted into',
      );
    });

    for (final (tone, expected) in <(MxDialogTone, IconData)>[
      (MxDialogTone.info, Icons.info_outline),
      (MxDialogTone.success, Icons.check_circle_outline),
      (MxDialogTone.warning, Icons.warning_amber_outlined),
      (MxDialogTone.error, Icons.error_outline),
    ]) {
      testWidgets('${tone.name} draws its own glyph', (tester) async {
        await tester.pumpWidget(host(tone: tone));

        expect(
          tester.widget<Icon>(toneIcon()).icon,
          expected,
          reason:
              'four tones need four silhouettes: colour alone is unreadable '
              'to roughly one in twelve men',
        );
      });
    }

    testWidgets('four tones are four distinct glyphs', (tester) async {
      final glyphs = <IconData>{};
      for (final tone in MxDialogTone.values) {
        await tester.pumpWidget(host(tone: tone));
        glyphs.add(tester.widget<Icon>(toneIcon()).icon!);
      }

      expect(glyphs, hasLength(MxDialogTone.values.length));
    });
  });

  group('the colour comes from the palette, in both brightnesses', () {
    for (final (label, theme, semantic)
        in <(String, ThemeData, AppSemanticColors)>[
          ('light', buildLightTheme(), const AppSemanticColors.light()),
          ('dark', buildDarkTheme(), const AppSemanticColors.dark()),
        ]) {
      testWidgets('$label reads AppSemanticColors, never a literal', (
        tester,
      ) async {
        final expected = <MxDialogTone, Color>{
          MxDialogTone.info: semantic.info,
          MxDialogTone.success: semantic.success,
          MxDialogTone.warning: semantic.warning,
          MxDialogTone.error: semantic.danger,
        };

        for (final tone in MxDialogTone.values) {
          await tester.pumpWidget(host(tone: tone, theme: theme));
          expect(
            tester.widget<Icon>(toneIcon()).color,
            expected[tone],
            reason: '$label ${tone.name}',
          );
        }
      });
    }

    testWidgets('error is the danger token, not a second red', (tester) async {
      await tester.pumpWidget(host(tone: MxDialogTone.error));
      final errorColor = tester.widget<Icon>(toneIcon()).color;

      expect(errorColor, const AppSemanticColors.light().danger);
    });
  });

  group('the header keeps the app\'s one layout', () {
    testWidgets('the title stays left-aligned when a tone is present', (
      tester,
    ) async {
      await tester.pumpWidget(host(tone: null));
      final untoned = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Delete this deck?'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .textAlign;

      await tester.pumpWidget(host(tone: MxDialogTone.error));
      final toned = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Delete this deck?'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .textAlign;

      expect(
        toned,
        untoned,
        reason:
            'AlertDialog centres its title whenever its own icon slot is used; '
            '_Header builds the row itself so a toned dialog is not a second '
            'header layout',
      );
    });

    testWidgets('the icon leads the title, and the title wraps beside it', (
      tester,
    ) async {
      await tester.pumpWidget(host(tone: MxDialogTone.warning));

      final icon = tester.getRect(toneIcon());
      final title = tester.getRect(find.text('Delete this deck?'));

      expect(icon.right, lessThanOrEqualTo(title.left));
      expect(
        icon.top,
        moreOrLessEquals(title.top, epsilon: 8),
        reason:
            'the glyph sits on the first line of the headline, not above '
            'it and not floating beside a two-line block',
      );
    });

    testWidgets('at 360dp and textScaler 2.0 nothing overflows', (
      tester,
    ) async {
      await tester.pumpWidget(host(tone: MxDialogTone.error, textScale: 2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final dialog = tester.getRect(find.byType(AlertDialog));
      final title = tester.getRect(find.text('Delete this deck?'));
      expect(
        title.right,
        lessThanOrEqualTo(dialog.right),
        reason: 'a headline that clips is silent — no exception, no stripe',
      );
    });
  });
}
