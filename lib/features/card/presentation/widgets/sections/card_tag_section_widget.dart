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

  /// True while the card holds [kMaxTagsPerCard] tags, which is when the input
  /// is not rendered at all.
  ///
  /// **It exists because the field can leave while it still holds text.** The
  /// chips come from a `watch()` stream, so an import or a bulk add on another
  /// surface can take the card to the cap with a half-typed tag in the box. The
  /// box goes; the text stays in the controller. Without this the exit guard
  /// stayed armed over a draft that was nowhere on screen, and the only way out
  /// of the editor was to press `Discard` on changes the user could not see.
  bool _isAtCap = false;

  /// What was last reported to the parent, so the callback fires on a change
  /// rather than on every keystroke.
  bool _reportedDraft = false;

  /// A draft only counts as unsaved work while the user can still do something
  /// about it. Suppressed at the cap; it comes back — text intact — the moment
  /// a tag is removed and the field returns.
  bool get _armsExitGuard => _hasDraft && !_isAtCap;

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
    _publishDraft();
  }

  /// **Outside `build`, always.** Both callers are notification callbacks — a
  /// controller listener and a `ref.listen` — because this ends in the parent's
  /// `setState`, and reaching a parent's state from inside a child's build is
  /// the one thing the framework forbids outright.
  void _publishDraft() {
    if (_armsExitGuard == _reportedDraft) return;
    _reportedDraft = _armsExitGuard;
    widget.onDraftChanged?.call(_reportedDraft);
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

    // The cap can arrive from somewhere else entirely — the chips are a
    // `watch()` stream. A `ref.listen` rather than a read in `build`, so the
    // parent is told outside the build phase.
    ref.listen<AsyncValue<List<TagEntity>>>(cardTagsProvider(cardId), (
      previous,
      next,
    ) {
      final atCap = (next.value?.length ?? 0) >= kMaxTagsPerCard;
      if (atCap == _isAtCap) return;
      setState(() => _isAtCap = atCap);
      _publishDraft();
    });

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
        _buildHeading(context, tags.length),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildChips(context, cardId, tags),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (isAtCap) _buildCapMessage(context) else _buildInput(context, entry),
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

  Widget _buildHeading(BuildContext context, int count) {
    return Row(
      children: <Widget>[
        // A heading, and it has to say so: the app-bar title carries the flag
        // and this did not, so the only section label on the screen was
        // announced as loose text.
        Semantics(
          header: true,
          child: Text(
            context.l10n.cardEditorTagsLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const Spacer(),
        // The counter appears only once a tag exists: at zero it is a limit
        // nobody is near, and showing 0 / 10 is noise (W5). At the cap it is
        // the number the message below refers to, so it stays.
        if (count > 0)
          Text(
            context.l10n.cardEditorTagCount(count, kMaxTagsPerCard),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  /// The card's tags, each with its own delete.
  ///
  /// **No `deleteIconBoxConstraints`, and that is a measured trade rather than
  /// an oversight.** The delete affordance is 48 **tall** for free — the app
  /// sets `MaterialTapTargetSize.padded`, and
  /// `_RenderChipRedirectingHitDetection` hands the pill's whole 48dp band to
  /// whichever slot sits under the x. Horizontally it is **33**, hit-tested at
  /// the boundaries: 63 to 96 on a chip ending at 96.
  ///
  /// `minWidth: 48` was applied and then reverted (owner review, 2026-08-26).
  /// It works, and it costs **28px of width per chip** — 80 to 108 — which at
  /// ten tags is three rows where there were two, on the screen with the least
  /// room to spare. The owner looked at it rendered and chose the width. A
  /// tight 48-square is not an option at all: `_RenderChip` asserts its content
  /// is at least as tall as the delete box, so it would force every pill to
  /// about 62 tall to fix a width.
  ///
  /// Recorded rather than left implicit, because
  /// `meetsGuideline(androidTapTargetGuideline)` is **green on this chip either
  /// way** — it reads the semantics rect, and the delete's node merges into the
  /// chip's 48dp one. Anyone re-opening this needs the real number, not the
  /// matcher's.
  Widget _buildChips(
    BuildContext context,
    String cardId,
    List<TagEntity> tags,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final tag in tags)
          Chip(
            label: Text(tag.name),
            onDeleted: () => unawaited(
              ref.read(cardTagRemoveProvider(cardId).notifier).submit(tag.id),
            ),
            deleteButtonTooltipMessage: context.l10n
                .cardEditorTagRemoveSemantics(tag.name),
          ),
      ],
    );
  }

  /// **At the cap the field is gone, not disabled.** A disabled input is an
  /// invitation with the door shut: the user types, nothing appears, and the
  /// reason is nowhere on screen. BR-94's limit is a fact about the card, so it
  /// is stated as one — and the counter above already says 10 / 10, which is
  /// what this sentence is explaining.
  Widget _buildCapMessage(BuildContext context) {
    return Text(
      context.l10n.cardEditorTagCapReached(kMaxTagsPerCard),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildInput(BuildContext context, CardTagSubmitState entry) {
    return MxTextField(
      controller: _input,
      label: context.l10n.cardEditorTagAddHint,
      // **No hint.** It was the same string as the label, so a focused empty
      // field painted `Add tag` twice — once floating and once in the box. A
      // hint earns its place by saying something the label does not.
      maxLength: TagName.maxLength,
      textInputAction: TextInputAction.done,
      errorText: _error(entry.problem),
      isEnabled: !entry.isSubmitting,
      onSubmitted: (_) => _submitTag(),
      // The visible half of the same action the keyboard's `done` key
      // performs. Disabled on a blank field rather than hidden, so the button
      // does not appear and disappear under the finger as the first character
      // lands.
      trailingAction: MxTextFieldAction(
        icon: Icons.add,
        semanticLabel: context.l10n.cardEditorTagAddAction,
        onPressed: _hasDraft && !entry.isSubmitting ? _submitTag : null,
      ),
    );
  }
}
