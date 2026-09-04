import 'dart:ui' show clampDouble, lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/components/actions/app_button_themes.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/typography/app_typography.dart';
import '../../core/theme/extensions/theme_context_extension.dart';

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
}

/// How much room a button takes.
///
/// An enum for the same reason [MxActionButtonVariant] is: the moment a caller
/// can pass a `Size` or an `EdgeInsets`, every screen is free to invent a
/// geometry, and the guard's ban on raw Material buttons only moved the
/// improvisation one file over.
enum MxActionButtonSize {
  /// The shared geometry every button gets from the theme: 48 drawn, which is
  /// also the touch target.
  standard,

  /// Drawn at 40, hit at 48 — `MaterialTapTargetSize.padded` keeps the floor.
  ///
  /// For a button living inside a row of chips and gauges rather than in an
  /// action bar. The deck tile's Study verb is the case it encodes (owner
  /// review, 2026-08-20: 40 is on the 4px grid and clears the 32 the pill used
  /// to paint), and its label steps down with the box: `label-md` re-weighted
  /// to 600 through [AppTypography.withWeight], because a 48-button's
  /// `label-lg` on a 40 body reads as text escaping its control.
  compact,
}

/// The app's button.
///
/// Takes no `Color` and no `TextStyle`. Appearance comes from [variant], size
/// from [size], and everything else from the theme; that is the whole point of
/// having this widget instead of using `FilledButton` directly.
class MxActionButton extends StatelessWidget {
  const MxActionButton({
    required this.label,
    required this.onPressed,
    this.variant = MxActionButtonVariant.primary,
    this.size = MxActionButtonSize.standard,
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

  final MxActionButtonSize size;

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
  ///
  /// **While on, [icon] is not painted.** The spinner takes the leading slot
  /// the glyph would have used, so the row reads "◌ Exporting…" rather than
  /// as a glyph and a spinner competing for one corner. Pinned by
  /// `mx_action_button_state_matrix_test.dart`; the card editor's Save is the
  /// live case (`Icons.check` disappears for the duration of the save).
  final bool shouldKeepLabelWhileLoading;

  final IconData? icon;

  /// Whether this button takes focus when its route opens.
  ///
  /// Exists for `MxConfirmDialog`: on a destructive dialog focus starts on
  /// cancel so a stray Enter cannot delete anything.
  ///
  /// **Honoured only where a keyboard exists** — see [_takesFocus].
  final bool shouldAutofocus;

  /// [shouldAutofocus], minus the platforms that have nothing to press Enter
  /// with.
  ///
  /// **A focused outlined button wears the focus ring instead of its border**,
  /// because that is what a focus indicator is for. On a touch device nobody
  /// asked for one: the delete dialog's Cancel came out with an indigo ring
  /// while the same `MxActionButton.secondary` two screens away had the grey
  /// control edge, and the two read as different components rather than as one
  /// button in two states. Measured on `deck_delete_confirm_light.png`: 10551
  /// pixels of the focus indicator where every other secondary drew the
  /// resting control edge. (Both were named tokens then; they are
  /// `scheme.primary` and `scheme.outline` now.)
  ///
  /// The reason for the autofocus survives intact, because it was always about
  /// a key: a stray Enter needs a keyboard, and `FocusHighlightMode.touch`
  /// means there is not one. Flutter starts this mode from the platform and
  /// moves it on the first interaction of the other kind, so a phone with a
  /// keyboard attached still gets the focus — and the ring — as soon as the
  /// keyboard is used.
  bool _takesFocus() =>
      shouldAutofocus &&
      FocusManager.instance.highlightMode != FocusHighlightMode.touch;

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
    final ButtonStyle? styled = _sized(context, busyStyle);

    return switch (variant) {
      MxActionButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: _takesFocus(),
        style: styled,
        child: child,
      ),
      MxActionButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        autofocus: _takesFocus(),
        style: styled,
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
      //
      // **`busyStyle` first** (M100.36). This branch built its style straight
      // from `buildFilledStyle` and never read `busyStyle`, so the destructive
      // arm of [_busyStyle] was dead code and a destructive button keeping its
      // label while loading fell to `disabledSurface` / `onDisabled` — the
      // 2.05:1 pair that method exists to avoid, printed on the one sentence
      // saying a deletion is in progress (#432 P1-2).
      MxActionButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: _takesFocus(),
        style: _sized(
          context,
          busyStyle ??
              buildFilledStyle(
                context.colors,
                context.semanticColors,
                context.texts,
                pair: MxFilledPair.destructive,
              ),
        ),
        child: child,
      ),
    };
  }

  /// [base] with [size]'s geometry laid over it.
  ///
  /// `geometry.merge(base)`, not the other way round: `merge` keeps the
  /// receiver's non-null properties, and the variant styles above are built
  /// from `buildSharedButtonStyle`, which already states the standard 48
  /// `minimumSize` — merged the other way, `compact` would silently stay 48.
  /// Colour and every state resolver still come from [base] (or, when both are
  /// null, from the theme): the four geometry properties are single-state, so
  /// flat values shadow nothing that resolves.
  ButtonStyle? _sized(BuildContext context, ButtonStyle? base) {
    if (size == MxActionButtonSize.standard) return base;

    final ButtonStyle geometry = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(AppSizing.buttonMinWidth, AppSizing.controlCompact),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      // 40 is what it paints; 48 is what a finger gets. `AppSpacing` calls the
      // touch target a floor, and `padded` is how a smaller body keeps it.
      tapTargetSize: MaterialTapTargetSize.padded,
      // The compact rung, at the same weight the standard one wears
      // (M100.30). `label-md` re-weighted rather than `label-lg` shrunk: a
      // 48-button's rung on a 40 body reads as text escaping its control.
      textStyle: WidgetStatePropertyAll<TextStyle>(
        AppTypography.withWeight(context.texts.labelMedium!, buttonLabelWeight),
      ),
    );

    return base == null ? geometry : geometry.merge(base);
  }

  /// Keeps a *busy* button looking busy rather than disabled — and only when
  /// its label is on show.
  ///
  /// **Measured, and found by rendering the state for the first time.** A
  /// loading button is disabled, so it takes `disabledSurface` and
  /// `onDisabled`: on light that composites to `#9AA3B1` on `#E4E7EA`, which
  /// is **2.05:1** (dark 2.51:1 — re-measured at M100.36 against the palette
  /// that has stood since M100.28; the 2.29:1 this note used to quote was the
  /// pre-M100.22 pair). That was invisible for as long as the label was, and
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

    // The outlined variant paints no fill, so it restores its ink and its edge
    // and leaves `backgroundColor` to the theme — naming a fill for it would
    // mean naming a colour that is not a role.
    if (variant == MxActionButtonVariant.secondary) {
      // `primary` and `outline`, the same pair the resting button draws since
      // M100.22. This copy has been wrong twice now for the same reason — it
      // is a second spelling of the theme's answer, and it does not move when
      // the theme does. It said `borderSubtle` while the theme drew the control
      // edge, then `secondaryAction`/`borderControl` while the theme moved to
      // the canonical roles; both times a secondary button changed colour for
      // the duration of a save.
      return ButtonStyle(
        foregroundColor: WidgetStatePropertyAll<Color>(colors.primary),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: colors.outline),
        ),
      );
    }

    // `secondary` returned above; the switch stays exhaustive so a variant
    // added later fails the build here rather than silently rendering as an
    // error button, which a two-armed conditional did. Both arms are
    // consumed: `primary` through `styled`, `destructive` through its own
    // `busyStyle ??` (M100.36).
    final (Color fill, Color label) = switch (variant) {
      MxActionButtonVariant.primary => (colors.primary, colors.onPrimary),
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
      child: CircularProgressIndicator(strokeWidth: AppStroke.indicator),
    ),
  );

  /// The space between the glyph and the word: `sm` at the default text
  /// scale, closing to `xs` by 2.0×.
  ///
  /// **Scaled, the way `_FilledButtonWithIconChild` scales its own gap**
  /// (`filled_button.dart:512` at 3.44.8 — `lerpDouble(8, 4, scale − 1)`).
  /// A fixed 8 was 4dp of horizontal room the button did not give back at
  /// 320dp × 2.0, where the label has already wrapped and every dp on the row
  /// is spoken for (#432 P2-5). The scale is read off the label's own rung so
  /// compact — `label-md` at 12 — closes at the same visual point as standard.
  double _iconGap(BuildContext context) {
    final TextStyle rung = size == MxActionButtonSize.compact
        ? context.texts.labelMedium!
        : context.texts.labelLarge!;
    final double fontSize = rung.fontSize!;
    final double scale =
        MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;

    return lerpDouble(
      AppSpacing.sm,
      AppSpacing.xs,
      clampDouble(scale - 1, 0, 1),
    )!;
  }

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

    final gap = _iconGap(context);

    if (isLoading && shouldKeepLabelWhileLoading) {
      // The spinner takes the slot the leading icon would have used, so the
      // button reads as one row — "◌ Exporting…" — rather than as a glyph and
      // a spinner competing for the same corner. The icon is dropped for that
      // frame on purpose: two indicators for one state is one too many.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _ForegroundSpinner(),
          SizedBox(width: gap),
          text,
        ],
      );
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: AppIconSize.sm),
          SizedBox(width: gap),
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
        strokeWidth: AppStroke.indicator,
        color: IconTheme.of(context).color,
      ),
    ),
  );
}
