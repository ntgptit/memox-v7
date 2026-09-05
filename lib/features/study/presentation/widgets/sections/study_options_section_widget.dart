import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/models/new_card_order_model.dart';
import '../../../domain/models/study_card_limit_model.dart';

/// The two study options, and the only place they are edited (BR-147, BR-148).
///
/// **The form holds its own draft, and the controller holds the outcome.** A
/// notifier cannot reach a `TextEditingController`, so a state that tried to own
/// the text would need the widget to push every keystroke into it — and the
/// keystroke is not a domain event.
///
/// **A saved value takes effect next session, not this one** (BR-139), which the
/// screen says out loud. Silence here reads as a change that failed to apply,
/// because the session on screen keeps the ceiling it opened with.
class StudyOptionsSectionWidget extends StatefulWidget {
  const StudyOptionsSectionWidget({
    required this.initialCardLimit,
    required this.initialNewCardOrder,
    required this.onSave,
    required this.isSubmitting,
    this.cardLimitProblem,
    this.isRootOverride = false,
    this.isClearing = false,
    this.onUseAppDefaults,
    super.key,
  });

  final int initialCardLimit;
  final NewCardOrder initialNewCardOrder;
  final void Function(String rawCardLimit, NewCardOrder newCardOrder) onSave;
  final bool isSubmitting;
  final StudyCardLimitProblem? cardLimitProblem;

  /// Whether these values come from this root's own override rather than from
  /// the app defaults (BR-212).
  ///
  /// It decides whether the deck says so and whether `Use app defaults` is
  /// offered at all — an action that would clear nothing is an action that
  /// teaches the user it does nothing.
  final bool isRootOverride;

  /// Whether the clear is in flight. Separate from [isSubmitting] because they
  /// are two operations, and one flag would spin the wrong control.
  final bool isClearing;

  final VoidCallback? onUseAppDefaults;

  @override
  State<StudyOptionsSectionWidget> createState() =>
      _StudyOptionsSectionWidgetState();
}

class _StudyOptionsSectionWidgetState extends State<StudyOptionsSectionWidget> {
  late final TextEditingController _cardLimit = TextEditingController(
    text: '${widget.initialCardLimit}',
  );
  final FocusNode _cardLimitFocus = FocusNode();
  late NewCardOrder _order = widget.initialNewCardOrder;

  @override
  void initState() {
    super.initState();
    // Save's enablement is derived from the draft on every keystroke, and a
    // plain `TextEditingController` does not rebuild its widget by itself —
    // without this listener Save would never re-enable after a correction.
    // `_order` already rebuilds through the pills' own `setState`.
    _cardLimit.addListener(_onDraftChanged);
    // The error *text* is on a different schedule from Save's enablement — see
    // `_fieldErrorText`.
    _cardLimitFocus.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _cardLimit.removeListener(_onDraftChanged);
    _cardLimit.dispose();
    _cardLimitFocus.removeListener(_onDraftChanged);
    _cardLimitFocus.dispose();
    super.dispose();
  }

  void _onDraftChanged() => setState(() {});

  /// The one submit path, so the button cannot send anything other than the
  /// draft the user is looking at.
  void _submit() => widget.onSave(_cardLimit.text, _order);

  /// The draft's own bound check, live and reused rather than re-derived.
  ///
  /// **The same parser the use case runs, not a second opinion.**
  /// `StudyCardLimit.parse` is what lets Save disable itself *before* a round
  /// trip instead of guessing at the rule from outside it — the identical form
  /// on the Settings screen has gated on it since BR-211, and this screen was
  /// the one still waiting for a refusal to come back.
  StudyCardLimitProblem? get _draftProblem =>
      StudyCardLimit.parse(_cardLimit.text).problem;

  /// The message shown **under the field**, as opposed to [_draftProblem]
  /// which gates Save.
  ///
  /// **Only while the field is not focused.** Save's disabled paint already
  /// says "something is wrong" the instant a keystroke crosses the
  /// valid/invalid boundary; showing the text on the same schedule would grow
  /// the field by the error line's height on every one of those crossings.
  /// Deferring to blur keeps the reflow to the one transition a blur already
  /// is. Same reasoning, same behaviour as the Settings form.
  String? get _fieldErrorText => _cardLimitFocus.hasFocus
      ? null
      : _cardLimitError(context, _draftProblem ?? widget.cardLimitProblem);

  /// Whether the draft differs from what is actually persisted.
  ///
  /// Compared by value, not by string: `"020"` beside a stored `20` is the same
  /// session ceiling, and calling it dirty would light Save for a change that
  /// saves nothing. An unparsable draft counts as dirty unconditionally —
  /// [_canSubmit] gates on validity separately, so this only has to decide
  /// whether there is something to compare.
  bool get _isDirty {
    final parsed = StudyCardLimit.parse(_cardLimit.text).limit;
    final limitChanged =
        parsed == null || parsed.value != widget.initialCardLimit;

    return limitChanged || _order != widget.initialNewCardOrder;
  }

  /// **Disabled when pristine, invalid or submitting.** A bright Save over an
  /// unchanged draft reads as "something is waiting to be saved" when nothing
  /// is; an enabled Save over an unparsable number is a control promising an
  /// action it would immediately refuse.
  bool get _canSubmit =>
      !widget.isSubmitting && _isDirty && _draftProblem == null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxTextField(
          controller: _cardLimit,
          focusNode: _cardLimitFocus,
          label: l10n.studyOptionsCardLimitLabel,
          // No hint: the field opens holding the value in force, so a hint
          // would be a second copy of the same number — and the default is not
          // what this deck necessarily uses.
          content: MxTextFieldContent.digits,
          textInputAction: TextInputAction.done,
          errorText: _fieldErrorText,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.studyOptionsOrderLabel, style: context.texts.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        // The heading above is what sighted users read; the accessibility
        // tree did not associate it with the pills until the group carried it
        // (M100.36 11F, #434 P2-8).
        Semantics(
          container: true,
          label: l10n.studyOptionsOrderLabel,
          child: Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final order in NewCardOrder.values)
                MxPillButton(
                  label: _orderLabel(context, order),
                  isSelected: _order == order,
                  onPressed: () => setState(() => _order = order),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // BR-139 in one line: the session on screen keeps the ceiling it opened
        // with, so without this the change reads as one that did not apply.
        Text(l10n.studyOptionsNextSessionNote, style: context.texts.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        MxActionButton(
          label: l10n.studyOptionsSave,
          isLoading: widget.isSubmitting,
          onPressed: _canSubmit ? _submit : null,
        ),
        // BR-212's affordance, and it lives here rather than on the global
        // Settings screen: it acts on **one** deck, and a global page offering
        // it would need a deck picker — a second screen inside the first.
        //
        // Shown only when there is an override to clear. The note above it is
        // what answers the question a user actually arrives with: why did
        // changing the app defaults not change this deck?
        if (widget.isRootOverride) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.studyOptionsOverrideNote,
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxTextButton(
              label: l10n.studyOptionsUseAppDefaults,
              onPressed: widget.isClearing ? null : widget.onUseAppDefaults,
            ),
          ),
        ],
      ],
    );
  }

  String _orderLabel(BuildContext context, NewCardOrder order) =>
      switch (order) {
        NewCardOrder.created => context.l10n.studyOptionsOrderCreated,
        NewCardOrder.random => context.l10n.studyOptionsOrderRandom,
      };

  /// The field message for [problem], or null when there is nothing wrong.
  ///
  /// Takes the problem rather than reading `widget.cardLimitProblem` itself:
  /// since the draft is checked live, the caller decides which of the two
  /// sources — the live parse or the refusal the controller came back with —
  /// is the one to show. Study keeps its own copy of this switch rather than
  /// borrowing Settings' `context.cardLimitError`, because a feature never
  /// imports another feature's `presentation/`.
  String? _cardLimitError(
    BuildContext context,
    StudyCardLimitProblem? problem,
  ) => switch (problem) {
    StudyCardLimitProblem.notANumber =>
      context.l10n.studyOptionsCardLimitNotANumber,
    StudyCardLimitProblem.tooSmall || StudyCardLimitProblem.tooLarge =>
      context.l10n.studyOptionsCardLimitOutOfRange(
        kMinCardLimit,
        kMaxCardLimit,
      ),
    null => null,
  };
}
