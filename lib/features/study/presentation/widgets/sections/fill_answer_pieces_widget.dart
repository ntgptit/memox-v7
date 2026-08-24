// The three surfaces `fill` draws: the meaning it asks about, the card that is
// itself the field, and the verdict that replaces what was typed into it. A
// `part` of `fill_answer_section_widget.dart` so they keep access to the
// library's private members — the split exists to satisfy the file-size guard,
// not to change anything about how they are used.
part of 'fill_answer_section_widget.dart';

/// The question: the card's back, which is its meaning (BR-08, BR-134).
///
/// **Not `example ?? front`.** Showing the example sentence made the prompt the
/// Korean the learner was supposed to produce, so the screen asked and answered
/// the same question; showing the front did it outright. The meaning is the one
/// side of the card that is a question about the other.
///
/// **Body type, not a headline.** A meaning is a gloss in two languages plus the
/// note that says which to use — BR-08 allows 240 characters — so this rung is
/// chosen for four to six readable lines rather than for impact. `recall` puts
/// its term in the card-prompt style because a term is one word; the same
/// metric here pushes a real meaning off the card.
///
/// It scrolls rather than truncating. An ellipsis on a prompt hides the half of
/// the meaning that distinguishes two similar cards, and the card's outer height
/// is set by the `Expanded` around it either way — so overflow is the one thing
/// the learner can resolve and the ellipsis is the one thing they cannot.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.meaning, required this.hint});

  final String meaning;

  /// Shown inside this card once it has been asked for, and separated from the
  /// meaning by spacing alone (BR-136).
  ///
  /// **Here rather than in a band of its own**: a hint is more of the question,
  /// and a third surface between the two cards would push the answer card down
  /// the moment somebody asked for help.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final shown = hint;

    return MxCard(
      elevation: AppElevation.raised,
      radius: AppRadius.xl,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                meaning,
                style: context.texts.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (shown != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  shown,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The answer: one card that **is** the input, and then the verdict for it.
///
/// **There is no field inside this card, and that is the whole change.** It held
/// an outlined `MxTextField` centred in a surface four times its height — a card
/// inside a card, with the real target a fifth of the area that looked like one,
/// and dead space above and below that belonged to neither. The card's own
/// surface is the field now: the editable fills it, the gesture covers the
/// padding the editable cannot reach, and a tap anywhere inside starts typing.
///
/// One step down from the prompt and flat, the same pair `recall` uses (§8.10):
/// two raised cards read as two questions, and the step is what says one of them
/// is waiting to be filled.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.controller,
    required this.focusNode,
    required this.term,
    required this.verdict,
    required this.isReadOnly,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// The card's front — the canonical Korean term, shown once the turn is
  /// graded. Never the learner's own string (BR-138).
  final String term;

  /// Null while the turn is still open; the outcome once it has committed
  /// (BR-157).
  final bool? verdict;

  final bool isReadOnly;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final graded = verdict;
    final semantic = context.semanticColors;
    final surface = context.colors.surfaceContainerLow;

    // **The verdict is worn by the card, not by a panel drawn inside it.** A
    // block with its own outline under the answer is the same nesting the field
    // was just taken out of, and it re-states a surface that is already saying
    // one thing.
    if (graded != null) {
      return MxCard(
        elevation: AppElevation.none,
        radius: AppRadius.xl,
        color: surface,
        borderColor: graded ? semantic.success : semantic.danger,
        child: _Verdict(term: term, isCorrect: graded),
      );
    }

    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) => GestureDetector(
        // Opaque, so the strip of padding between the card's edge and the
        // editable is part of the target rather than a hole in it.
        behavior: HitTestBehavior.opaque,
        onTap: focusNode.requestFocus,
        child: MxCard(
          elevation: AppElevation.none,
          radius: AppRadius.xl,
          color: surface,
          // The card carries focus the way a field would, because it is the
          // field. Without it the only sign the keyboard belongs to this surface
          // is a caret two lines tall in the middle of it.
          borderColor: focusNode.hasFocus ? semantic.focusRing : null,
          child: _FillInput(
            controller: controller,
            focusNode: focusNode,
            isReadOnly: isReadOnly,
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}

/// The editable itself: no decoration, no outline, the size of its card.
///
/// **`MxTextField` cannot express this, and forcing it to would have cost more
/// than it saved.** That widget's contract is a *decorated* field — it takes no
/// `InputDecoration` on purpose, so every one of its instances carries the app's
/// one outlined style from `InputDecorationTheme` (M3.5). What this screen needs
/// is the absence of that style in all six border states plus `expands`,
/// `textAlignVertical` and a collapsed content inset — which is either a second
/// public style on the shared widget for exactly one caller, or a hole in it
/// through which any caller can pass a decoration. Neither is a smaller change
/// than one private editable in the feature that wants it.
///
/// What the shared widget was protecting is kept by other means: no colour,
/// radius or metric below is a literal, the type comes from `context.texts`, and
/// nothing about the decoration is reachable from outside this file.
class _FillInput extends StatelessWidget {
  const _FillInput({
    required this.controller,
    required this.focusNode,
    required this.isReadOnly,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isReadOnly;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.studyFillInputLabel;

    return Semantics(
      // The concept draws no *floating* label — the card is the field, and a
      // label pinned to an edge would be the nested chrome this screen exists to
      // remove. The placeholder below says the same words in the middle of the
      // card and leaves when the first character arrives, so the name has to
      // live here too or the field is unnamed for exactly as long as it has
      // something in it.
      label: label,
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        // Locked, not disabled: a disabled field loses focus and greys the text
        // the learner is waiting on a verdict for.
        readOnly: isReadOnly,
        // `expands` is what makes the card the field: the editable takes the
        // whole box the card gives it, so there is no inner rectangle with its
        // own height. It requires `maxLines: null` (the default here is 1) and
        // `minLines` left null, which it already is.
        expands: true,
        maxLines: null,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        // A step above the meaning and no further. The answer is one Korean
        // term, so it should read as the thing the screen is about — but the
        // rung above this one is a display face, and a term set in it beside a
        // body-sized prompt reads as two unrelated screens.
        style: context.texts.titleLarge,
        cursorColor: context.colors.primary,
        // **`text`, not the multiline default.** `maxLines: null` otherwise
        // switches the keyboard to multiline, whose return key inserts a newline
        // — and then Done never arrives and Enter is a blank second line in a
        // one-word answer.
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        // The same path Check takes, so the two cannot grade differently and a
        // Done arriving beside a tap is still one write.
        onSubmitted: (_) => onSubmitted(),
        // **A placeholder, because an empty card says nothing at all.** With the
        // outline gone and no caret until the card is touched, the idle state is
        // a blank panel one step down from the prompt — which is exactly what
        // `recall` draws over an answer it is *hiding*. Two adjacent screens
        // cannot use the same picture for "type here" and "not yet".
        //
        // `hint`, not `hintText`, so the words can be excluded from semantics:
        // the wrapper above already names the field, and the string stays in the
        // tree even when the placeholder is invisible — so a `hintText` here
        // announces the name twice for as long as the field is empty and leaves
        // a phantom node behind once it is not.
        //
        // Centred by hand — a `hint` widget inherits neither the field's
        // alignment nor its style — and in the theme's own `hintStyle`, which is
        // a rung *below* the meaning above it. Drawn in the answer's rung it was
        // the largest thing on the screen and read as content already there,
        // competing with the question it is waiting on.
        decoration: _fillInputDecoration.copyWith(
          hint: ExcludeSemantics(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Every border state off, not just [InputDecoration.border].
///
/// `InputDecorationTheme` supplies `enabledBorder`, `focusedBorder`,
/// `errorBorder`, `focusedErrorBorder` and `disabledBorder` independently, so a
/// decoration that clears only the base one still draws the app's outline the
/// moment the field is focused — which is exactly the nested outline the card is
/// meant to have replaced, appearing only in the state nobody screenshots.
const InputDecoration _fillInputDecoration = InputDecoration(
  isCollapsed: true,
  filled: false,
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
);

/// What the answer card says once the turn has been written (BR-157).
///
/// **The card's front, in both outcomes and for two different reasons.** A
/// correct turn keeps the term on screen so the confirmation has something to
/// confirm; a wrong one shows it because that is the thing to take away. Neither
/// repeats the meaning — it is on the card directly above — and neither echoes
/// what the learner typed, which BR-138 keeps out of storage and off the screen
/// alike.
///
/// The accent is an outline, an icon and a line of text. **Not a fill**: a card
/// flooded with `success` turns the term into text on a coloured block and puts
/// the strongest thing on the screen behind the one thing worth reading.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.term, required this.isCorrect});

  final String term;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;
    final accent = isCorrect ? semantic.success : semantic.danger;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isCorrect ? Icons.check_circle_outline : Icons.error_outline,
                  size: AppIconSize.sm,
                  color: accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    isCorrect ? l10n.studyFillCorrect : l10n.studyFillIncorrect,
                    style: context.texts.labelLarge?.copyWith(color: accent),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // The label appears only on a wrong turn. Spelling the answer back
            // under a heading to somebody who just typed it reads as a
            // correction of something they got right.
            if (!isCorrect) ...<Widget>[
              Text(
                l10n.studyFillAnswerLabel,
                style: context.texts.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              term,
              // The same rung the field drew it in, so the answer lands where
              // the typing was rather than jumping a size on the verdict.
              style: context.texts.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
