import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/typography/app_typography.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_content_shell.dart';
import 'mx_icon_button.dart';
import 'mx_progress_bar.dart';
import '../../core/theme/extensions/app_ink.dart';

/// The most of the row's *content* space the chip may claim before it starts
/// ellipsizing — content space being what is left once the close button and the
/// three gaps are paid for, which is the only part the chip, the track and the
/// figure actually compete over.
///
/// Measured against that rather than against the whole bar because the button
/// and the gaps are a fixed 64 either way: at 393 they are a fifth of the row
/// and at 278 they are a quarter, so a fraction of the *whole* row quietly
/// promises the chip more of the contested space the narrower the screen gets —
/// which is the direction it should be giving ground in.
///
/// **A cap rather than a flex, because flex would cost the track.** The chip and
/// the figure are laid out inflexibly so `Expanded` below gets the true
/// remainder; that is what took the track from 108px to 206. Making the chip a
/// flex child instead hands it a *share* of the free space, and the part of its
/// share it does not use is not given back — the 118px of dead space this row
/// used to end with. So the chip stays inflexible and is capped instead: at any
/// normal width the cap is far wider than the word and changes nothing, and at
/// 320 with `textScaler` 2.0 it is what a long mode name gives back instead of
/// overflowing the row.
///
/// Two fifths: at 393 that is 108px against a 62px chip, so the first width
/// where it bites is one where something has to give anyway.
const double _kChipMaxWidthFraction = 0.4;

/// What the row spends before the chip, the track and the figure get to argue:
/// the close button, and the two [AppSpacing.sm] gaps — chip→track and
/// track→figure. There is deliberately none after the button; see the row.
const double _kRowFixedWidth = AppSizing.touchTarget + AppSpacing.sm * 2;

/// How far inside its own box the close button draws its glyph.
///
/// Derived, not chosen: the button centres an [AppIconSize.mdCompact] glyph in
/// an [AppSizing.touchTarget] box. Writing it out is what lets the bar
/// place the *glyph* on a line and let the box fall where it must.
const double _kGlyphInset = (AppSizing.touchTarget - AppIconSize.mdCompact) / 2;

/// Where the ✕ *glyph* sits: on the screen gutter, like any leading action.
///
/// **A control is anchored, a label is contained — the two do not want the same
/// line.** This was tried with both ends on one value and the ✕ then read as
/// pushed into the screen: a close affordance belongs at the edge it closes
/// from, which is also where `AppBar` puts its own leading icon. What must not
/// happen is the *reverse* of that — the glyph inset while the figure sits flush
/// — because a row whose control is buried and whose text is falling off the end
/// reads as broken rather than as composed. That is the arrangement the first
/// review reported, and it is what the two functions here keep apart.
double _leadingInset(BuildContext context) => mxScreenGutter(context);

/// Where the trailing figure's box ends: a full [AppSpacing.xl] inside the
/// screen gutter.
///
/// **Deeper than the gutter because there is nothing at the gutter to sit on.**
/// A full-bleed card's boundary is a hairline at 1.38:1 against the page in
/// light and its fill is 1.06:1 — the figure was measured flush to that edge, to
/// the pixel, and still read as hanging past it, twice. Clearing it outright is
/// what stops the question, and `xl` clears it past the card's own text column
/// (`TERM`, `MEANING`, which sit [AppSpacing.lg] in) so the figure is plainly
/// inside rather than ambiguously near.
double _trailingInset(BuildContext context) =>
    mxScreenGutter(context) + AppSpacing.xl;

/// The top bar of a full-screen task: a way out, what the task is, how far it
/// has got, and one figure.
///
/// One component rather than one per screen, because the four facts are the same
/// four every time — a bar rebuilt per stage is four chances for the gap either
/// side of the track to end up different, and the difference is only visible
/// when two stages sit next to each other in a flow, which is exactly when it is
/// too late to be cheap to fix.
///
/// **Everything that varies is a parameter, and nothing here knows what a study
/// mode is.** [label] is the word on the chip, [trailing] is whatever figure the
/// screen counts — a `3 / 10`, a clock, a score. The caller owns both, including
/// their semantics; this widget contributes none of its own, because the two
/// things worth announcing are the close action (which carries its own label)
/// and the figure (which the caller wraps).
///
/// ## It must sit in a region with no horizontal padding
///
/// The close button is 48×48 — [AppSizing.touchTarget], and it cannot go
/// below that without failing `androidTapTargetGuideline` — so its glyph sits
/// [_kGlyphInset] inside where the button starts. Handed a normal gutter, the
/// bar can only put the *button* on it, which leaves the glyph 14px further in
/// while [trailing] ends on the gutter exactly: a row inset by different amounts
/// at each end, which is what reads as the whole bar being off-centre.
///
/// So the bar is laid out the way `AppBar` lays out its own leading icon — it is
/// given the full width and places its own two ends, at [_leadingInset] and
/// [_trailingInset]. A caller therefore passes `padding: EdgeInsets.zero` to
/// [MxContentShell] and gutters the rest of the screen itself; [mxScreenGutter]
/// is public for that.
///
/// Measured at 393: glyph 16…36, chip surface at 50, track 188 wide, figure
/// ending at 353.
class MxSessionTopBar extends StatelessWidget {
  const MxSessionTopBar({
    required this.label,
    required this.progress,
    required this.trailing,
    required this.onClose,
    required this.closeLabel,
    super.key,
  });

  /// The word on the chip. Already-localized, and short — one or two words. It
  /// is a name, not a sentence.
  final String label;

  /// 0…1. Passed straight to [MxProgressBar]; a caller that has a `done / total`
  /// pair must divide it from the same pair [trailing] prints, or the bar and
  /// the figure describe different moments.
  final double progress;

  /// The figure at the end of the row. Sized to its content, so it can be a
  /// counter one frame and a clock the next without the track jumping.
  final Widget trailing;

  final VoidCallback onClose;

  /// Already-localized. What leaving *does*, not "close" — leaving a task is
  /// rarely just dismissing a screen.
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The start value positions the ✕ *glyph*, not its box: the button sits
      // [_kGlyphInset] behind its own glyph, so the box has to begin that much
      // earlier and is allowed to hang into the gutter. At a 16 gutter that is
      // 2 — the button spans 2…50 and the glyph lands on 16, the card's outer
      // edge. The end value positions the figure's box directly.
      //
      // **Clamped at zero, and the clamp is load-bearing below 360.** The
      // compact gutter is 12 and the glyph sits 14 behind its box, so the exact
      // start would be −2; `Padding` asserts on a negative inset, which took out
      // five tests at 320 the moment the two ends stopped sharing a value. The
      // glyph then lands on 14 instead of 12 — two pixels the compact scale can
      // afford, and the alternative is a bar that cannot be built at all there.
      padding: EdgeInsetsDirectional.only(
        start: (_leadingInset(context) - _kGlyphInset).clamp(
          0,
          double.infinity,
        ),
        end: _trailingInset(context),
      ),
      child: LayoutBuilder(
        // Only so the chip's cap can be a share of the row rather than a number
        // picked for one screen width. Nothing else here reads the constraints.
        builder: (context, constraints) => Row(
          children: <Widget>[
            MxIconButton(
              icon: Icons.close,
              semanticLabel: closeLabel,
              onPressed: onClose,
              isCompact: true,
            ),
            // **No spacer here, and that is the fix rather than a smaller
            // button.** The gap the eye sees is not spacing: the button centres
            // a 20px glyph in a 48px box, so [_kGlyphInset] of its own box
            // already sits behind the glyph. An `sm` on top of that read as 22,
            // and the wireframe puts the chip's surface on 54.9 — which is
            // exactly where the bare box ends. Adding nothing lands on the
            // design; the 14 that remains is the touch target, not air.
            //
            // Shrinking the button is the other way to close it, and it costs
            // the 48×48 that `androidTapTargetGuideline` asserts in both
            // `study_accessibility_test.dart` and the stress suite. Worse, the
            // usual tricks for it — `Transform`, `OverflowBox` — clip the *hit*
            // area to the slot while `Semantics` keeps reporting 48×48, so the
            // guideline still passes and only a thumb finds out.
            // Inflexible, and capped — see [_kChipMaxWidthFraction].
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    (constraints.maxWidth - _kRowFixedWidth).clamp(
                      0,
                      double.infinity,
                    ) *
                    _kChipMaxWidthFraction,
              ),
              // The chip is the only word that says which screen this is,
              // so it names the route (A20.1 P3-10): the session has no bar
              // to do it.
              child: MergeSemantics(
                child: Semantics(namesRoute: true, child: _Chip(label: label)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Bare track: the bar's own header would put the same figure above
            // it, and the figure already sits at the end of this row. It
            // announces nothing either — [trailing] carries the one
            // announcement, so a screen reader hears the count once rather than
            // twice.
            Expanded(
              child: MxProgressBar(value: progress, size: MxProgressBarSize.sm),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Never capped. It is the count, and a truncated count is a wrong
            // one; the chip gives way first because a shortened *name* still
            // names the thing.
            trailing,
          ],
        ),
      ),
    );
  }
}

/// The task's name, as a label rather than a control.
///
/// **Not `MxPillButton` with a null callback.** That component renders a null
/// callback as *disabled* — the label drops to 38% alpha and leaves the palette
/// — and this is not a control that has been switched off, it is a name.
class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.semanticColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        // Uppercase, and the caller passes the word as written. A chip is a
        // *classification*, not the sentence a screen wrote — the same reason
        // the context line under it is uppercase and a deck name never is.
        label.toUpperCase(),
        style: AppTypography.withWeight(
          context.textStyles.sectionLabel,
          FontWeight.w600,
          // The brand hue as text. `primary` is that since M100.18 —
          // the dark tone inverted, so the role itself passes AA here.
        ).inked(context, AppInk.accent),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
