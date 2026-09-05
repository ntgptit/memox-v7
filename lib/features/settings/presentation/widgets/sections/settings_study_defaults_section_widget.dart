import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../../study/domain/models/new_card_order_model.dart';
import '../../../../study/domain/models/study_card_limit_model.dart';
import '../items/settings_choice_rows_widget.dart';
import '../items/settings_error_band_widget.dart';
import '../support/settings_labels_widget.dart';
import 'settings_section_widget.dart';

/// The app-wide study defaults, and the one group with a Save button
/// (BR-211, wireframe S2, S3).
///
/// **The form holds its own draft, and the controller holds the outcome.** A
/// notifier cannot reach a `TextEditingController`, so a state that tried to own
/// the text would need the widget to push every keystroke into it — and a
/// keystroke is not a domain event. `StudyOptionsSectionWidget` made the same
/// call for the same reason.
///
/// **Both values save together** (S3). They are one row-group in the data and
/// one thought for the user; a separate Save for the order would let somebody
/// change both and walk away having saved half.
///
/// **A failed save keeps the draft** (BR-216). The text field is not rebuilt
/// from [initialCardLimit] on failure — the controller only re-seeds it when a
/// *save succeeds* and a new persisted value arrives.
class SettingsStudyDefaultsSectionWidget extends StatefulWidget {
  const SettingsStudyDefaultsSectionWidget({
    required this.initialCardLimit,
    required this.initialNewCardOrder,
    required this.isSubmitting,
    required this.onSave,
    this.cardLimitProblem,
    this.failure,
    super.key,
  });

  /// The persisted values. A change here re-seeds the draft — see
  /// [_SettingsStudyDefaultsSectionWidgetState.didUpdateWidget] for the one
  /// case that must not.
  final int initialCardLimit;
  final NewCardOrder initialNewCardOrder;

  final bool isSubmitting;
  final void Function(String rawCardLimit, NewCardOrder newCardOrder) onSave;
  final StudyCardLimitProblem? cardLimitProblem;
  final Failure? failure;

  @override
  State<SettingsStudyDefaultsSectionWidget> createState() =>
      _SettingsStudyDefaultsSectionWidgetState();
}

class _SettingsStudyDefaultsSectionWidgetState
    extends State<SettingsStudyDefaultsSectionWidget> {
  late final TextEditingController _cardLimit = TextEditingController(
    text: '${widget.initialCardLimit}',
  );
  final FocusNode _cardLimitFocus = FocusNode();
  late NewCardOrder _order = widget.initialNewCardOrder;

  @override
  void initState() {
    super.initState();
    // Save's enablement is derived from the draft on every keystroke, not
    // only from the radio row's own `setState` — a plain `TextEditingController`
    // does not rebuild its widget by itself.
    _cardLimit.addListener(_onDraftChanged);
    // The error *text* is not shown on the same schedule as Save's own
    // enablement — see `_fieldErrorText` below.
    _cardLimitFocus.addListener(_onDraftChanged);
  }

  @override
  void didUpdateWidget(SettingsStudyDefaultsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **Re-seed only when the persisted value actually changed.** The stream
    // re-emits on every write to the row, including a theme change, and
    // re-seeding on every rebuild would wipe a card limit the user is halfway
    // through typing (BR-216).
    if (oldWidget.initialCardLimit != widget.initialCardLimit) {
      _cardLimit.text = '${widget.initialCardLimit}';
    }
    if (oldWidget.initialNewCardOrder != widget.initialNewCardOrder) {
      _order = widget.initialNewCardOrder;
    }
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

  /// The one submit path, so `Save` and `Try again` cannot diverge — a retry
  /// that sent anything other than the current draft would save a value the
  /// user is no longer looking at.
  void _submit() => widget.onSave(_cardLimit.text, _order);

  /// The draft's own bound check, live and reused rather than re-derived.
  ///
  /// **The same parser the use case runs, not a second opinion.** BR-211
  /// requires exactly one copy of the card-limit bounds; calling
  /// `StudyCardLimit.parse` here is what lets Save disable itself *before* a
  /// round trip instead of guessing at the rule from outside it.
  StudyCardLimitProblem? get _draftProblem =>
      StudyCardLimit.parse(_cardLimit.text).problem;

  /// The message shown **under the field**, as opposed to [_draftProblem]
  /// which gates Save.
  ///
  /// **Only while the field is not focused.** Save's own disabled paint
  /// already signals "something is wrong" the instant a keystroke makes the
  /// draft invalid — showing the message on the same schedule would grow the
  /// field by the error line's height on every keystroke that crosses the
  /// valid/invalid boundary, not once per submit like the old round-trip
  /// behaviour. Deferring the text to blur keeps that reflow to the one
  /// transition a blur already is, and a mid-typing draft still explains
  /// itself the moment focus leaves.
  String? get _fieldErrorText => _cardLimitFocus.hasFocus
      ? null
      : context.cardLimitError(_draftProblem ?? widget.cardLimitProblem);

  /// Whether the draft differs from what is actually persisted.
  ///
  /// Compared by value, not by string: `"020"` next to a stored `20` is the
  /// same session ceiling, and flagging it dirty would light Save for a
  /// change that saves nothing new. An unparsable draft counts as dirty
  /// unconditionally — [_canSubmit] below gates on validity separately, so
  /// this only has to decide "is there something to compare".
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
    final band = widget.failure;

    return SettingsSectionWidget(
      label: l10n.settingsStudyDefaultsSection,
      child: MxCard.raised(
        // Flat, like every other card in a scrolling column (D20). This
        // screen was the last one still taking `AppElevation.card`, and
        // its own error band already passes `none` for the same reason.
        //
        // The inner gutter is the screen's, not the fixed 16 of
        // `MxCardPadding.standard`: below 360dp the choice rows and the
        // reminder row step to 12 with it, and a card that held its own
        // would start this column 4dp inside theirs (W5).
        padding: MxCardPadding.none,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mxScreenGutter(context),
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // **The field owns its label; there is no `Text` above it.**
              // `MxTextField` passes `label` to `InputDecoration.labelText` and
              // the theme leaves `floatingLabelBehavior` at `auto`, so a field
              // that always has a value always floats its label — the same
              // string then rendered twice, 4dp apart, and TalkBack read it
              // twice. The order group below keeps its `Text` because a radio
              // group has no decoration to carry one.
              MxTextField(
                controller: _cardLimit,
                focusNode: _cardLimitFocus,
                label: l10n.studyOptionsCardLimitLabel,
                isEnabled: !widget.isSubmitting,
                // Digits only — the limit is an integer, and the numeric
                // keyboard hides letters but paste does not. `done`, because
                // this is the last text field on the screen.
                content: MxTextFieldContent.digits,
                textInputAction: TextInputAction.done,
                errorText: _fieldErrorText,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.studyOptionsOrderLabel,
                style: context.texts.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              // **Radio rows, not the pills `StudyOptionsSectionWidget`
              // uses.** W6 requires a selected state not to rest on colour,
              // and a `ChoiceChip` under `buildChipTheme` differs when
              // selected only in fill and label colour — `showCheckmark` is
              // false and `side` is resolved for disabled and focused only.
              // The three groups on this screen therefore share one control,
              // which is also what W1 draws.
              //
              // `contentPadding: zero` because this card already pads its
              // content — the rows must start on the same x as the label
              // above them (W5).
              SettingsChoiceRowsWidget<NewCardOrder>(
                values: NewCardOrder.values,
                selected: _order,
                labelOf: context.newCardOrderLabel,
                onChanged: (order) => setState(() => _order = order),
                isSubmitting: widget.isSubmitting,
              ),
              const SizedBox(height: AppSpacing.lg),
              // BR-213 in one line. Without it the change reads as one that did
              // not apply, because a session already running keeps its ceiling.
              Text(
                l10n.settingsStudyDefaultsNote,
                style: context.texts.bodySmall!.inked(context, AppInk.quiet),
              ),
              if (band != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                SettingsErrorBandWidget(
                  failure: band,
                  // Retry sends the same draft Save would — so it is gated by
                  // the same validity check, just not by dirtiness: resending
                  // an unchanged value after a failed save is legitimate.
                  onRetry: (widget.isSubmitting || _draftProblem != null)
                      ? null
                      : _submit,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              MxActionButton(
                label: l10n.studyOptionsSave,
                isLoading: widget.isSubmitting,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
