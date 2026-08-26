import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/entities/tag_entity.dart';
import '../../../domain/failures/tag_validation_failure.dart';
import '../../../domain/models/tag_name_model.dart';
import '../../controllers/card_tag_controller.dart';
import '../../states/card_tag_state.dart';
import '../support/card_failure_labels_widget.dart';
import '../support/tag_labels_widget.dart';

/// The editor's tag strip: the card's tags as removable chips, and a way to add
/// one (UC-04 W5, BR-93, BR-94).
///
/// Edit-mode only — a tag links to a card, and a card that is not saved yet has
/// no id to link to.
///
/// **Adding starts where the tags are.** The concept puts `+ Add tag` in the
/// same `Wrap` as the chips rather than in a field below them, so the row reads
/// as "these, and one more" instead of "these, and a form". Tapping it opens
/// the input in place; the input carries a visible add button as well as the
/// keyboard's `done`, because a field whose only commit is a key on a soft
/// keyboard has an action nobody can see.
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
  /// keep.
  final ValueChanged<bool>? onDraftChanged;

  @override
  ConsumerState<CardTagSectionWidget> createState() =>
      _CardTagSectionWidgetState();
}

class _CardTagSectionWidgetState extends ConsumerState<CardTagSectionWidget> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  /// Whether the inline entry is open. Closing it does **not** clear the text:
  /// see [_armsExitGuard].
  bool _isEntryOpen = false;

  /// Mirrors "the field holds something submittable", so the add button's
  /// enabled state and the parent's draft flag both come from one place.
  bool _hasDraft = false;

  /// True while the card holds [kMaxTagsPerCard] tags, which is when the entry
  /// cannot be opened at all.
  ///
  /// **It exists because the entry can leave while it still holds text.** The
  /// chips come from a `watch()` stream, so an import or a bulk add on another
  /// surface can take the card to the cap with a half-typed tag in the box.
  /// Without this the exit guard stayed armed over a draft that was nowhere on
  /// screen, and the only way out of the editor was to press `Discard` on
  /// changes the user could not see.
  bool _isAtCap = false;

  /// What was last reported to the parent, so the callback fires on a change
  /// rather than on every keystroke.
  bool _reportedDraft = false;

  /// A draft only counts as unsaved work while the user can still do something
  /// about it. Suppressed at the cap; it comes back — text intact — the moment
  /// a tag is removed and the entry can be opened again.
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
    _inputFocus.dispose();
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

  void _openEntry() {
    setState(() => _isEntryOpen = true);
    _inputFocus.requestFocus();
  }

  /// Closes the entry **without** discarding what was typed.
  ///
  /// The text survives on purpose: it is still unsaved work, so the exit guard
  /// still protects it, and re-opening the entry finds it where the user left
  /// it. Throwing it away here would make a dismiss gesture destructive.
  void _closeEntry() => setState(() => _isEntryOpen = false);

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
        setState(() => _isEntryOpen = false);
        ref.read(cardTagEntryProvider(cardId).notifier).reset();
      }
    });

    final isAtCap = tags.length >= kMaxTagsPerCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeading(context, tags.length),
        const SizedBox(height: AppSpacing.sm),
        _buildChips(context, cardId, tags, isAtCap: isAtCap),
        if (isAtCap) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildCapMessage(context),
        ] else if (_isEntryOpen) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildInput(context, entry),
        ],
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
    final quiet = context.colors.onSurfaceVariant;

    return Row(
      children: <Widget>[
        // A heading, and it has to say so: the app-bar title carries the flag
        // and this did not, so the only section label on the screen was
        // announced as loose text.
        // **One flexible group, not two flexible children beside a `Spacer`.**
        // Making the two texts `Flexible` closed the 7.5px overflow at 320dp
        // and text scale 2.0 in Vietnamese, and turned it into clipping: the
        // `Spacer` is an `Expanded`, so it split the free space with them and
        // held 87–113dp empty while `không bắt buộc` was cut. Giving the group
        // the whole remainder pins the counter to the right edge and lets the
        // words take what they need — the same correction the field label row
        // needed, for the same reason.
        Expanded(
          child: Row(
            children: <Widget>[
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    context.l10n.cardEditorTagsHeading,
                    style: context.texts.labelMedium?.copyWith(color: quiet),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  context.l10n.cardEditorFieldOptional,
                  style: context.texts.labelSmall?.copyWith(color: quiet),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // The counter appears only once a tag exists: at zero it is a limit
        // nobody is near, and showing 0 / 10 is noise (W5). At the cap it is
        // the number the message below refers to, so it stays.
        if (count > 0)
          Text(
            context.l10n.cardEditorTagCount(count, kMaxTagsPerCard),
            style: context.texts.labelSmall?.copyWith(color: quiet),
          ),
      ],
    );
  }

  /// The card's tags, each with its own delete, and the affordance that adds
  /// one more.
  ///
  /// **No `deleteIconBoxConstraints`, and that is a measured trade rather than
  /// an oversight.** The delete affordance is 48 **tall** for free — the app
  /// sets `MaterialTapTargetSize.padded`, and
  /// `_RenderChipRedirectingHitDetection` hands the pill's whole 48dp band to
  /// whichever slot sits under the x. Horizontally it is **33**, hit-tested at
  /// the boundaries: 63 to 96 on a chip ending at 96. `minWidth: 48` reaches
  /// the guideline and costs **28px of width per chip** — 80 to 108 — which at
  /// ten tags is a third row on the narrowest screen; the owner looked at both
  /// rendered and chose the width (2026-08-26). Recorded rather than left
  /// implicit, because `meetsGuideline(androidTapTargetGuideline)` is green on
  /// this chip either way: it reads the semantics rect, and the delete's node
  /// merges into the chip's.
  Widget _buildChips(
    BuildContext context,
    String cardId,
    List<TagEntity> tags, {
    required bool isAtCap,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        if (!isAtCap && !_isEntryOpen)
          ActionChip(
            avatar: const Icon(Icons.add),
            label: Text(context.l10n.cardEditorTagAddChip),
            onPressed: _openEntry,
          ),
      ],
    );
  }

  /// **At the cap the entry is gone, not disabled.** A disabled input is an
  /// invitation with the door shut: the user types, nothing appears, and the
  /// reason is nowhere on screen. BR-94's limit is a fact about the card, so it
  /// is stated as one — and the counter above already says 10 / 10, which is
  /// what this sentence is explaining.
  Widget _buildCapMessage(BuildContext context) {
    return Text(
      context.l10n.cardEditorTagCapReached(kMaxTagsPerCard),
      style: context.texts.bodySmall?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildInput(BuildContext context, CardTagSubmitState entry) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: MxTextField(
            controller: _input,
            focusNode: _inputFocus,
            label: context.l10n.cardEditorTagAddChip,
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
        ),
        MxIconButton(
          icon: Icons.close,
          semanticLabel: context.l10n.cardEditorTagEntryDismiss,
          onPressed: entry.isSubmitting ? null : _closeEntry,
        ),
      ],
    );
  }
}
