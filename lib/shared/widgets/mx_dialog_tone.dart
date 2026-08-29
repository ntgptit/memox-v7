import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_ink.dart';
import 'mx_icon.dart';

/// How serious the situation an overlay is speaking about is.
///
/// **A second axis, deliberately not folded into `MxConfirmDialogVariant`.**
/// That enum answers *what does the confirm button do to my data* — normal,
/// cautious, destructive — and it drives the primary button's colour and where
/// focus starts. This one answers *what kind of news is this* and drives one
/// thing only: the leading icon and its colour. The two are independent, and
/// the pair that proves it is a soft delete: `cautious` on the action axis
/// because it is recoverable, `warning` on this one because it still takes
/// something away.
///
/// Folding them into one enum was tried on paper first and produces twelve
/// members, most of which are nonsense (`info` + `destructive`?), and it repeats
/// exactly the mistake `MxConfirmDialogVariant.cautious` was created to undo —
/// a value that carries two decisions cannot express the case where they
/// disagree.
///
/// The four values are the severity taxonomy every alert system converges on
/// (SweetAlert, Material's own banners, ARIA's alert roles). They exist here as
/// four tokens the theme already owns rather than as a package: see
/// `docs/wbs.md` M99.55 for the packages evaluated and why none of them clears
/// this project's token, l10n and a11y gates.
enum MxDialogTone {
  /// A statement of fact. Nothing has gone wrong and nothing is at risk.
  info,

  /// Something finished, and finished well.
  success,

  /// Something is at stake, but it can be undone — or it has not happened yet.
  warning,

  /// Something failed, or is about to become unrecoverable.
  error,
}

/// The two presentation facts a tone carries.
///
/// An extension rather than fields on the enum so the colour can be read from
/// the theme at build time. A tone that held a `Color` would have to be
/// constructed per brightness, and every call site would then be responsible
/// for picking the right one — which is the bug `AppSemanticColors` exists to
/// prevent.
extension MxDialogToneX on MxDialogTone {
  /// The tone as a name in the app's ink vocabulary.
  ///
  /// **The switch used to return `Color` and resolve the palette itself**
  /// (M100.4). Every arm of it was already an `AppInk` member, so the method
  /// was a second spelling of a map that already exists — and a second
  /// spelling is where two things drift apart.
  AppInk get ink => switch (this) {
    MxDialogTone.info => AppInk.info,
    MxDialogTone.success => AppInk.success,
    MxDialogTone.warning => AppInk.warning,
    MxDialogTone.error => AppInk.danger,
  };

  /// The accent, straight from the semantic palette. Never a new value.
  Color accent(BuildContext context) => ink.resolve(context);

  /// **Outlined, and four distinct silhouettes.** Colour alone cannot carry the
  /// tone — roughly one in twelve men cannot separate the warning amber from
  /// the danger red — so the shape has to differ too, which rules out one glyph
  /// tinted four ways.
  IconData get icon => switch (this) {
    MxDialogTone.info => Icons.info_outline,
    MxDialogTone.success => Icons.check_circle_outline,
    MxDialogTone.warning => Icons.warning_amber_outlined,
    MxDialogTone.error => Icons.error_outline,
  };
}

/// A dialog headline, with the tone's icon leading it when there is one.
///
/// **Inline beside the title, not in `AlertDialog`'s own `icon:` slot.** That
/// slot is the Material 3 idiom and it was the first version, but it carries a
/// side effect the spec mentions in passing and the framework makes
/// unconditional: `AlertDialog` switches its title to `TextAlign.center` the
/// moment an icon is present. Every other dialog in this app is left-aligned,
/// so a toned one would have been a second header layout — and the tone is a
/// property of the *message*, not a reason to re-centre the screen. It also
/// costs a row of vertical space a 360dp screen at `textScaler` 2.0 does not
/// have.
///
/// **The icon carries no semantic label**, because it says nothing the headline
/// does not already say in words. Announcing "warning" before a title that
/// reads *Delete deck?* is one fact read twice.
///
/// Shared by `MxConfirmDialog` and `MxFormDialog` so the two cannot drift into
/// two header layouts, which is the drift this whole component set exists to
/// undo.
class MxDialogHeader extends StatelessWidget {
  const MxDialogHeader({required this.title, this.tone, super.key});

  /// Already-localized.
  final String title;

  final MxDialogTone? tone;

  @override
  Widget build(BuildContext context) {
    final tone = this.tone;
    if (tone == null) return Text(title);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MxIcon(tone.icon, ink: tone.ink),
        const SizedBox(width: AppSpacing.md),
        // Expanded, because a headline that wraps must wrap inside the row
        // rather than push the icon off the dialog.
        Expanded(child: Text(title)),
      ],
    );
  }
}
