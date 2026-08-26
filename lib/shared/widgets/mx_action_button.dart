import 'package:flutter/material.dart';

import '../../core/theme/app_button_themes.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// How much weight a button carries on its screen.
///
/// An enum, not a `Color` parameter. The moment a caller can pass a colour, the
/// design system stops being enforceable — every screen becomes free to invent
/// a shade, and no reviewer can tell an intentional variant from a typo.
enum MxActionButtonVariant {
  /// The one action a screen wants the user to take.
  primary,

  /// Everything else. Alternatives, "not now", secondary paths.
  secondary,

  /// Deletes something, or discards work. Added for `MxConfirmDialog` in M4.8
  /// rather than as a second button widget: two button systems is how a screen
  /// ends up with two different "delete" looks.
  ///
  /// Carried by the enum and not by an `isDestructive` flag plus a colour — a
  /// flag beside a colour lets a caller pass one without the other, and the
  /// mismatch is invisible in review.
  destructive,

  /// A filled button one step quieter than [primary] — `secondaryContainer`
  /// under `onSecondaryContainer`.
  ///
  /// **For an action a screen must offer without leading with.** Card Detail's
  /// `Edit` is the case it was added for: a reading surface where the action
  /// has to be findable and must not out-weigh the card being read (BR-246,
  /// M4.15 V3). A `primary` fill there competes with the content; an icon alone
  /// says nothing until it is tapped.
  ///
  /// **Measured, so nobody has to re-measure:** the label pair is 10.37:1 in
  /// light and 9.09:1 in dark, well past AA. The *container* is only 1.14:1 /
  /// 1.56:1 against the app bar it usually sits on, so what identifies this
  /// control is its label, not its fill — which is the conformant path, and the
  /// reason this variant always carries visible words.
  tonal,
}

/// The app's button.
///
/// Takes no `Color` and no `TextStyle`. Appearance comes from [variant] and the
/// theme; that is the whole point of having this widget instead of using
/// `FilledButton` directly.
class MxActionButton extends StatelessWidget {
  const MxActionButton({
    required this.label,
    required this.onPressed,
    this.variant = MxActionButtonVariant.primary,
    this.isLoading = false,
    this.shouldKeepLabelWhileLoading = false,
    this.icon,
    this.shouldAutofocus = false,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. The screen owns the copy; the button never reads ARB.
  final String label;

  /// What a screen reader announces instead of [label], when the painted words
  /// are not enough to tell two buttons apart.
  ///
  /// **For a list where every row carries the same verb.** Study Home has a
  /// `Study` on every deck; heard on its own, three of them are three identical
  /// controls, and the deck name is the only thing that distinguishes them.
  ///
  /// **A parameter here rather than a `Semantics` wrapper at the call site**,
  /// which is how this was first written and was wrong: `Semantics(label:,
  /// onTap:, excludeSemantics: true)` around a button drops the button's own
  /// node — losing its enabled state, its ink and the tap feedback `InkWell`
  /// gives — and, without `container: true`, does not reliably put a node back.
  /// The label belongs to the button, so the button takes it.
  ///
  /// Null leaves the painted label as the accessible name, which is right
  /// everywhere the words already say which button this is.
  final String? semanticLabel;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final MxActionButtonVariant variant;

  /// While true the button is disabled and shows a spinner — but keeps its
  /// size. A button that shrinks to spinner width moves everything beside it,
  /// so the layout jumps exactly when the user is waiting to see what happened.
  final bool isLoading;

  /// Keeps [label] **painted** while [isLoading], with the spinner beside it
  /// instead of behind it.
  ///
  /// **Off by default, and the default is right for a button that sizes to its
  /// own content.** The spinner plus its gap make the row wider than the label
  /// alone, so an intrinsically-sized button would grow under the finger that
  /// just pressed it — which is the jump [isLoading]'s `Stack` exists to
  /// prevent. Turn this on only where the width is decided from outside: an
  /// `Expanded` in an action row, or a block button.
  ///
  /// **It exists because some waits have a name the user has to read.** The
  /// default hides the label at alpha 0 and lets semantics carry it, which
  /// answers a screen reader and answers nobody else. M4.13 W6 requires the
  /// export sheet's `Exporting…` to be real text rather than a mute spinner,
  /// and an accessible name alone satisfies half of that sentence.
  final bool shouldKeepLabelWhileLoading;

  final IconData? icon;

  /// Whether this button takes focus when its route opens.
  ///
  /// Exists for `MxConfirmDialog`: on a destructive dialog focus starts on
  /// cancel so a stray Enter cannot delete anything.
  final bool shouldAutofocus;

  @override
  Widget build(BuildContext context) {
    // Disabled while loading: without this a second tap queues a second
    // submit, which is the double-submit bug in its most common form.
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = _buildChild(context);
    final busyStyle = _busyStyle(context);

    final button = _buildButton(context, effectiveOnPressed, child, busyStyle);
    final name = semanticLabel;
    if (name == null) return button;

    // **One node, and it has to carry everything the button's node did.**
    // `Semantics(label:) + ExcludeSemantics` alone was the first attempt: it
    // drops the button's node and — without `container` — does not reliably
    // create one, so `find.bySemanticsLabel` found nothing and the control was
    // announced as part of the card's text rather than as a button. Role,
    // enabled state and tap action are therefore restated here.
    //
    // Hit testing is untouched, so a sighted tap still runs through the
    // `InkWell` and keeps its splash and its haptic; only TalkBack's activation
    // takes the shortcut, which is what the action is for.
    return Semantics(
      container: true,
      button: true,
      enabled: effectiveOnPressed != null,
      // Focusable follows enabled, because the `Focus` under here does: the
      // widget stays keyboard-reachable, and a node that omitted the flag
      // described a control the tree could not explain.
      focusable: effectiveOnPressed != null,
      label: name,
      onTap: effectiveOnPressed,
      excludeSemantics: true,
      child: button,
    );
  }

  Widget _buildButton(
    BuildContext context,
    VoidCallback? effectiveOnPressed,
    Widget child,
    ButtonStyle? busyStyle,
  ) {
    return switch (variant) {
      MxActionButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        style: busyStyle,
        child: child,
      ),
      MxActionButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        style: busyStyle,
        child: child,
      ),
      // The tonal pair the theme already builds. `buildFilledTonalStyle` rather
      // than a second `styleFrom` call, for the reason the destructive branch
      // gives below: `styleFrom` produces flat properties that shadow the
      // theme's for every state at once.
      MxActionButtonVariant.tonal => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        // `busyStyle` first, or the branch for it in [_busyStyle] is dead code
        // that reads as coverage. A tonal button keeping its label while
        // loading would otherwise fall back to `disabledSurface`/`onDisabled` —
        // the 2.29:1 pair that method exists to avoid.
        style:
            busyStyle ??
            buildFilledTonalStyle(context.colors, context.semanticColors),
        child: child,
      ),
      // `error` / `onError`, not a token read directly: the scheme pair is
      // already contrast-checked against each other in `app_theme_test.dart`,
      // and A2 maps `error` onto the `danger` token so the two cannot diverge.
      //
      // **`buildFilledStyle`, not `FilledButton.styleFrom`.** `styleFrom` builds
      // a flat `WidgetStatePropertyAll`, and a non-null property on the widget
      // shadows the theme's for every state at once — so the destructive button
      // did not darken on press and stayed fully red when disabled while its
      // label faded to 38%. A control that looks armed and is inert is worse
      // than one that looks disabled. The same builder the primary variant
      // resolves through, with the error pair substituted for the accent.
      MxActionButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        style: buildFilledStyle(
          context.colors,
          context.semanticColors,
          fill: context.colors.error,
          label: context.colors.onError,
        ),
        child: child,
      ),
    };
  }

  /// Keeps a *busy* button looking busy rather than disabled — and only when
  /// its label is on show.
  ///
  /// **Measured, and found by rendering the state for the first time.** A
  /// loading button is disabled, so it takes `disabledSurface` and
  /// `onDisabled`: on light that composites to about `#93949E` on `#E0E0E5`,
  /// which is **2.29:1**. That was invisible for as long as the label was, and
  /// the moment [shouldKeepLabelWhileLoading] painted the words it became the
  /// one sentence on screen saying what is happening, printed below the
  /// legibility floor. WCAG exempts an inactive control's text; a status
  /// message is not covered by that exemption just because it is drawn inside
  /// one.
  ///
  /// **Scoped to the opt-in on purpose.** Every existing caller keeps the grey
  /// treatment, because for them the label is hidden and grey is honest —
  /// changing it would repaint every submitting button in the app, which is a
  /// design decision and not a side effect of this one. The rule this encodes
  /// is narrow: if you are going to show the words, show them legibly.
  ///
  /// Flat properties are safe here where they normally are not: this style is
  /// only ever attached while loading, and loading resolves to exactly one
  /// state.
  ButtonStyle? _busyStyle(BuildContext context) {
    if (!isLoading || !shouldKeepLabelWhileLoading) return null;

    final colors = context.colors;
    final semantic = context.semanticColors;

    // The outlined variant paints no fill, so it restores its ink and its edge
    // and leaves `backgroundColor` to the theme — naming a fill for it would
    // mean naming a colour that is not a role.
    if (variant == MxActionButtonVariant.secondary) {
      return ButtonStyle(
        foregroundColor: WidgetStatePropertyAll<Color>(
          semantic.secondaryAction,
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: semantic.borderSubtle),
        ),
      );
    }

    final (Color fill, Color label) = switch (variant) {
      MxActionButtonVariant.primary => (colors.primary, colors.onPrimary),
      MxActionButtonVariant.tonal => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      // `secondary` returned above; the switch is exhaustive so a variant added
      // later fails the build here rather than silently rendering as an error
      // button, which a two-armed conditional did.
      MxActionButtonVariant.secondary ||
      MxActionButtonVariant.destructive => (colors.error, colors.onError),
    };

    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(fill),
      foregroundColor: WidgetStatePropertyAll<Color>(label),
    );
  }

  /// Its own layer, so the spin repaints the arc and not the form around it.
  /// This matters more than the full-screen loading state does: a submitting
  /// button sits inside a form or a dialog, so without the boundary every frame
  /// of the animation repaints the fields the user is still looking at.
  ///
  /// Takes the theme's indicator colour, which is `primary` — correct on the
  /// grey a disabled button wears, and the reason [_ForegroundSpinner] exists
  /// for the case where the button keeps its fill.
  static const Widget _spinner = RepaintBoundary(
    child: SizedBox.square(
      dimension: AppIconSize.sm,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _buildChild(BuildContext context) {
    // Two lines before ellipsis. One line ellipsizes "Endgültig löschen" down
    // to "End…" at textScaler 3.0, which on a destructive dialog leaves the
    // user approving an action they can no longer read.
    final text = Flexible(
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (isLoading && shouldKeepLabelWhileLoading) {
      // The spinner takes the slot the leading icon would have used, so the
      // button reads as one row — "◌ Exporting…" — rather than as a glyph and
      // a spinner competing for the same corner. The icon is dropped for that
      // frame on purpose: two indicators for one state is one too many.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _ForegroundSpinner(),
          const SizedBox(width: AppSpacing.sm),
          text,
        ],
      );
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: AppIconSize.sm),
          const SizedBox(width: AppSpacing.sm),
        ],
        text,
      ],
    );

    if (!isLoading) return content;

    // The label stays laid out and merely invisible, so the button keeps the
    // width it had before the tap. Replacing the child with a spinner would
    // resize it.
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // `alwaysIncludeSemantics` because `RenderOpacity` drops its child from
        // the semantics tree at alpha 0. Without it a submitting button
        // announces as "button, disabled" with no name at all — the user is
        // told something is unavailable and never told what. The spinner
        // contributes `role: loadingSpinner` to the same node, so the busy
        // state is carried without inventing a string that no ARB file owns.
        Opacity(opacity: 0, alwaysIncludeSemantics: true, child: content),
        _spinner,
      ],
    );
  }
}

/// The spinner drawn in the button's own foreground colour.
///
/// **Because `primary` on `primary` is nothing at all.** The theme paints a
/// `CircularProgressIndicator` in `primary`, which reads on the grey a disabled
/// button wears — and vanishes the moment the button keeps its brand fill,
/// which is exactly what [MxActionButton.shouldKeepLabelWhileLoading] makes it
/// do. The first render of that state showed a label and no indicator at all.
///
/// A `Builder` rather than the caller's colour, because the foreground is
/// resolved *inside* the button: `ButtonStyleButton` merges an `IconTheme`
/// around its child, so this is where the answer exists.
class _ForegroundSpinner extends StatelessWidget {
  const _ForegroundSpinner();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox.square(
      dimension: AppIconSize.sm,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: IconTheme.of(context).color,
      ),
    ),
  );
}
