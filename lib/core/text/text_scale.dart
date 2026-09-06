import 'package:flutter/widgets.dart';

/// How much wider text at [rung] gets under the reader's current setting — the
/// number a **layout** threshold must be multiplied by.
///
/// **In `core/` because seven places already needed it and were each getting it
/// wrong in one of two ways.** Same reason as `search_fold.dart`: the moment two
/// of them compute the factor differently, two rows that ask the same question
/// answer it at different sizes.
///
/// ## `TextScaler.scale` takes a font size, and a breakpoint is not one
///
/// `MediaQuery.textScalerOf(context).scale(240)` reads as "scale my 240dp
/// threshold", and on a linear scaler it happens to do that. It is not what the
/// method means. `scale` answers *"a glyph declared at this many sp paints at
/// how many logical pixels?"* — so passing a layout width asks the platform to
/// size a 240sp font, and takes whatever comes back as a number of dp.
///
/// **Android has not scaled fonts linearly since 14.** `FontScaleConverter`
/// interpolates over a table whose whole point is that large type grows less
/// than small type, because a headline at 2× is already enormous while body
/// text at 2× is merely readable. At the platform's 2.0 setting the published
/// table maps 14sp to 28 (a factor of 2.00) and 100sp to 100 (a factor of
/// **1.00**). Anything past the end of the table is flat.
///
/// So on a real Android phone at the largest accessibility setting, a row whose
/// threshold was `scale(240)` gets a threshold of *240* — unchanged — and never
/// stacks, on exactly the device where stacking is the point. A row whose
/// threshold was `scale(320)` is worse: it is further out on the flat part of
/// the curve.
///
/// **`scale(1)` is the same mistake at the other end.** A 1sp font is below the
/// first entry of every table, so the factor it reports is whatever the
/// extrapolation at the bottom happens to be — not the factor the row's actual
/// 12–16sp text will grow by.
///
/// ## Ask about a font size the row really renders
///
/// [layoutScaleOf] asks the scaler about [rung] — a rung the caller actually
/// draws — and returns the ratio. That is a question `TextScaler.scale` is
/// defined to answer, and the answer is right on a linear scaler and on a
/// non-linear one, because the thing a breakpoint is protecting *is* that text:
/// if the row's 14sp copy gets 1.8× wider, the room it needs gets 1.8× wider.
///
/// `mx_action_button.dart` already computed the ratio this way to size its icon
/// gap ("The scale is read off the label's own rung"); this is that idea, named,
/// so a layout threshold can use it too.
///
/// Pass the rung the threshold was measured against. A row with two rungs takes
/// the larger one: it is the half that runs out of line first.
double layoutScaleOf(BuildContext context, {required TextStyle rung}) {
  // A rung with no size is a theme that has not been built yet, which is a bug
  // in the caller rather than a case to paper over. Body text is the honest
  // stand-in if it ever happens in release.
  assert(rung.fontSize != null, 'layoutScaleOf needs a rung with a fontSize');
  final double sp = rung.fontSize ?? _bodyRungSp;

  return MediaQuery.textScalerOf(context).scale(sp) / sp;
}

/// [dp] widened by the factor the reader's setting applies to [rung].
///
/// The two-line form callers actually want. Kept beside [layoutScaleOf] rather
/// than inlined at each site so the multiplication cannot drift into a `+` or a
/// `clamp` somebody adds locally.
double scaledLayoutWidth(
  BuildContext context, {
  required double dp,
  required TextStyle rung,
}) => dp * layoutScaleOf(context, rung: rung);

/// The rung `bodyMedium` is declared at, used only by the release fallback in
/// [layoutScaleOf].
const double _bodyRungSp = 14;
