import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/entities/tag_entity.dart';
import '../../../domain/failures/tag_validation_failure.dart';
import '../../../domain/models/tag_name_model.dart';
import '../../controllers/card_tag_controller.dart';
import '../../states/card_tag_state.dart';
import '../support/card_failure_labels_widget.dart';
import '../support/tag_labels_widget.dart';

/// The editor's tag strip: the card's tags as removable chips, and a field that
/// adds one (UC-04 W5, BR-93, BR-94).
///
/// Edit-mode only — a tag links to a card, and a card that is not saved yet has
/// no id to link to. The chips read `cardTagsProvider`, so an add or a remove
/// shows without a reload; the field drives `CardTagEntry`, which reports the
/// same `savedAndContinue` a save-and-add form does, so the field clears and
/// stays open for the next tag.
class CardTagSectionWidget extends ConsumerStatefulWidget {
  const CardTagSectionWidget({
    required this.cardId,
    this.onDraftChanged,
    super.key,
  });

  final String cardId;

  /// Reports whether the add field holds text that has not been committed yet.
  ///
  /// **The editor needs it, and needs it for exactly one thing.** A half-typed
  /// tag is work the user will lose on the way out, so it has to reach the exit
  /// guard. It must **not** reach `Save changes`: save owns the five content
  /// fields and nothing else, and a save button that lights up because a tag
  /// field has three letters in it is a button making a promise it will not
  /// keep. See `card_editor_screen.dart`.
  final ValueChanged<bool>? onDraftChanged;

  @override
  ConsumerState<CardTagSectionWidget> createState() =>
      _CardTagSectionWidgetState();
}

class _CardTagSectionWidgetState extends ConsumerState<CardTagSectionWidget> {
  final TextEditingController _input = TextEditingController();

  /// Mirrors "the field holds something submittable", so the add button's
  /// enabled state and the parent's draft flag both come from one place.
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final hasDraft = _input.text.trim().isNotEmpty;
    if (hasDraft == _hasDraft) return;
    setState(() => _hasDraft = hasDraft);
    widget.onDraftChanged?.call(hasDraft);
  }

  /// The one path a tag is committed by, whichever affordance started it.
  ///
  /// Both the keyboard's `done` and the field's own button land here, so
  /// "blank is refused" and "a submit in flight is not doubled" are decided
  /// once. The blank guard is a **preflight**, not the rule: BR-93 is enforced
  /// in the domain and still refuses whatever gets past this.
  void _submitTag() {
    final value = _input.text;
    if (value.trim().isEmpty) return;
    unawaited(
      ref.read(cardTagEntryProvider(widget.cardId).notifier).submit(value),
    );
  }

  /// The field error, from the mapping the rename sheet also uses.
  ///
  /// It was a `switch` here until the catalog needed the same five answers
  /// (M99.30); `TagLabels.tagProblemLabel` is now the one copy, and it carries
  /// the note about why `nameTaken` has no message.
  String? _error(TagValidationProblem? problem) =>
      context.tagProblemLabel(problem);

  @override
  Widget build(BuildContext context) {
    final cardId = widget.cardId;
    final tags = ref.watch(cardTagsProvider(cardId)).value ?? <TagEntity>[];
    final entry = ref.watch(cardTagEntryProvider(cardId));
    final remove = ref.watch(cardTagRemoveProvider(cardId));

    ref.listen<CardTagSubmitState>(cardTagEntryProvider(cardId), (
      previous,
      next,
    ) {
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        // Clearing fires `_onInputChanged`, which is what tells the editor the
        // draft is gone — a committed tag must not keep the exit guard armed.
        _input.clear();
        ref.read(cardTagEntryProvider(cardId).notifier).reset();
      }
    });

    final isAtCap = tags.length >= kMaxTagsPerCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              context.l10n.cardEditorTagsLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            // The counter appears only once a tag exists: at zero it is a limit
            // nobody is near, and showing 0 / 10 is noise (W5). At the cap it
            // is the number the message below refers to, so it stays.
            if (tags.isNotEmpty)
              Text(
                context.l10n.cardEditorTagCount(tags.length, kMaxTagsPerCard),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final tag in tags)
                Chip(
                  label: Text(tag.name),
                  onDeleted: () => unawaited(
                    ref
                        .read(cardTagRemoveProvider(cardId).notifier)
                        .submit(tag.id),
                  ),
                  deleteButtonTooltipMessage: context.l10n
                      .cardEditorTagRemoveSemantics(tag.name),
                  // **Measured on the production tree, and the theme did not
                  // cover it.** The app sets `MaterialTapTargetSize.padded`,
                  // which inflates the *chip* — the pill measures 48 tall, and
                  // `_RenderChipRedirectingHitDetection` sends that whole band
                  // to whichever slot is under the x. So the delete was already
                  // 48 **tall**. It was 33 **wide**, hit-tested at the
                  // boundaries: 63 to 96 on a chip ending at 96.
                  //
                  // `meetsGuideline(androidTapTargetGuideline)` passed on it the
                  // whole time, which is why it survived — the matcher reads the
                  // *semantics* rect, and the delete's node merges into the
                  // chip's. `getRect` plus boundary hit-tests is what found it;
                  // see `card_editor_tag_input_test.dart`.
                  //
                  // **`minWidth` only, and that is the smallest thing that
                  // works.** A tight 48-square throws — `_RenderChip` asserts
                  // its content is at least as tall as the delete box, so a
                  // 48-tall box would force the whole pill to about 62 and make
                  // every tag row taller to fix a width. Widening the slot
                  // leaves the height to the chip, which already had it.
                  //
                  // Here rather than in `app_chip_theme`: this is the only
                  // deletable chip in the app, so a theme-wide constraint would
                  // be a rule with one subject and no way to see that.
                  deleteIconBoxConstraints: const BoxConstraints(
                    minWidth: AppSpacing.minimumTouchTarget,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // **At the cap the field is gone, not disabled.** A disabled input is
        // an invitation with the door shut: the user types, nothing appears,
        // and the reason is nowhere on screen. BR-94's limit is a fact about
        // the card, so it is stated as one — and the counter above already
        // says 10 / 10, which is what this sentence is explaining.
        if (isAtCap)
          Text(
            context.l10n.cardEditorTagCapReached(kMaxTagsPerCard),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          MxTextField(
            controller: _input,
            label: context.l10n.cardEditorTagAddHint,
            hintText: context.l10n.cardEditorTagAddHint,
            maxLength: TagName.maxLength,
            textInputAction: TextInputAction.done,
            errorText: _error(entry.problem),
            isEnabled: !entry.isSubmitting,
            onSubmitted: (_) => _submitTag(),
            // The visible half of the same action the keyboard's `done` key
            // performs. Disabled on a blank field rather than hidden, so the
            // button does not appear and disappear under the finger as the
            // first character lands.
            trailingAction: MxTextFieldAction(
              icon: Icons.add,
              semanticLabel: context.l10n.cardEditorTagAddAction,
              onPressed: _hasDraft && !entry.isSubmitting ? _submitTag : null,
            ),
          ),
        if (entry.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          CardWriteFailureTextWidget(failure: entry.failure!),
        ],
        if (remove.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          CardWriteFailureTextWidget(failure: remove.failure!),
        ],
      ],
    );
  }
}
