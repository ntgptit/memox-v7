import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/match_mode.dart';

/// The pairing board (BR-153, BR-118).
///
/// **A turn belongs to the term that was picked first, not to the meaning that
/// was picked second** (BR-118). Choosing the wrong meaning marks the *term's*
/// card failed; the card that happens to own that meaning was never being asked
/// about, and grading it would punish a card for sitting on the board.
///
/// The board is built by the handler, which is also what refuses to lay out
/// fewer than two pairs — a single pair makes the answer the only thing left.
///
/// **A paired tile stays where it is** (§4). Removing it reflows every row below
/// it, so the tile the user was about to press moves the instant they press
/// something else — and the board they had learned the shape of is gone. It goes
/// quiet instead: `success` and a tick, dimmed, and no longer a target.
class MatchBoardSectionWidget extends StatefulWidget {
  const MatchBoardSectionWidget({
    required this.board,
    required this.onPairAttempt,
    this.isLocked = false,
    super.key,
  });

  final MatchBoard board;

  /// Reports the term that was picked and whether the meaning matched it.
  ///
  /// The caller turns that into an action through the scheduler (BR-107); this
  /// widget never names `forgotten` or `remembered`, because `sm2` has neither.
  final void Function(MatchTile term, {required bool isCorrect}) onPairAttempt;

  final bool isLocked;

  @override
  State<MatchBoardSectionWidget> createState() =>
      _MatchBoardSectionWidgetState();
}

class _MatchBoardSectionWidgetState extends State<MatchBoardSectionWidget> {
  MatchTile? _selectedTerm;

  /// Cards already paired. They stay on the board; this is what marks them.
  final Set<String> _matched = <String>{};

  @override
  void didUpdateWidget(MatchBoardSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new board is a new round, and nothing on it has been paired yet.
    // Without this the ticks from the round just finished carry over, and the
    // cards that failed it come back already marked correct.
    //
    // **Compared by what is on it, not by identity.** The caller lays the board
    // out on every build from a seeded shuffle (BR-127), so `identical` is false
    // every single rebuild — locking the buttons during a write is enough — and
    // every tick the user had earned would vanish the moment they answered.
    // The seed makes the deal reproducible, which is exactly what makes the
    // contents usable as the board's identity.
    if (_layoutOf(oldWidget.board) == _layoutOf(widget.board)) return;

    _selectedTerm = null;
    _matched.clear();
  }

  /// What distinguishes one deal from another: which cards, in which order, on
  /// each side.
  static String _layoutOf(MatchBoard board) => <String>[
    for (final tile in board.terms) tile.cardId,
    '|',
    for (final tile in board.meanings) tile.cardId,
  ].join(',');

  void _selectTerm(MatchTile term) {
    if (widget.isLocked) return;

    setState(() => _selectedTerm = term);
  }

  void _selectMeaning(MatchTile meaning) {
    final term = _selectedTerm;

    // A meaning tapped with no term chosen is not an answer. Guessing which
    // term it "probably" meant would record a turn the user never gave.
    if (widget.isLocked || term == null) return;

    final isCorrect = widget.board.isPair(term, meaning);

    setState(() {
      _selectedTerm = null;
      if (isCorrect) _matched.add(term.cardId);
    });

    widget.onPairAttempt(term, isCorrect: isCorrect);
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(child: _column(widget.board.terms, isTerm: true)),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: _column(widget.board.meanings, isTerm: false)),
    ],
  );

  Widget _column(List<MatchTile> tiles, {required bool isTerm}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final tile in tiles) ...<Widget>[
        MatchTileWidget(
          text: tile.text,
          state: _stateOf(tile, isTerm: isTerm),
          onTap: widget.isLocked
              ? null
              : () => isTerm ? _selectTerm(tile) : _selectMeaning(tile),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );

  MatchTileState _stateOf(MatchTile tile, {required bool isTerm}) {
    if (_matched.contains(tile.cardId)) return MatchTileState.paired;
    if (isTerm && _selectedTerm?.cardId == tile.cardId) {
      return MatchTileState.selected;
    }

    return MatchTileState.idle;
  }
}

/// The three states a tile on the board can be in (§4).
enum MatchTileState { idle, selected, paired }

/// One tile, in whichever of the three states it is.
///
/// **Colours come from `ColorScheme` and `AppSemanticColors`, never from this
/// file.** Selected is `primary` with `onPrimary` on it — a pair Material keeps
/// contrasting in both themes. Paired is `success`, and only because it means
/// exactly what `success` means: this answer was right. It is not the mode's
/// colour and not decoration (§7.8).
///
/// A paired tile has no fill of its own. The design tints it a very pale green,
/// and there is no token for that — `AppSemanticColors` has `success` and no
/// container beside it. Adding one is a token decision, which M5.19 puts out of
/// scope; the tick, the `success` label and the dimming carry the state without
/// inventing a colour.
class MatchTileWidget extends StatelessWidget {
  const MatchTileWidget({
    required this.text,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String text;
  final MatchTileState state;
  final VoidCallback? onTap;

  bool get _isPaired => state == MatchTileState.paired;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final isSelected = state == MatchTileState.selected;

    final foreground = switch (state) {
      MatchTileState.selected => scheme.onPrimary,
      MatchTileState.paired => semantic.success,
      MatchTileState.idle => scheme.onSurface,
    };

    return Semantics(
      selected: isSelected,
      // A tick in green marks the pair for people who can see it. This is what
      // marks it for everyone else.
      value: _isPaired ? context.l10n.studyMatchPaired : null,
      child: Opacity(
        // Paired tiles stay on the board and stop competing for attention. The
        // remaining pairs are the ones still being worked on.
        opacity: _isPaired ? AppMatchTile.pairedOpacity : 1,
        child: Material(
          color: isSelected ? scheme.primary : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: isSelected ? scheme.primary : semantic.borderSubtle,
            ),
          ),
          child: InkWell(
            // A paired tile is finished, not merely busy: BR-116 has already
            // recorded it, and a second tap could only record it twice.
            onTap: _isPaired ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      text,
                      style: context.texts.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                  if (_isPaired) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.check,
                      size: context.texts.bodyMedium?.fontSize,
                      color: semantic.success,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one number this tile decides for itself, and it is not a colour.
abstract final class AppMatchTile {
  /// How far a paired tile recedes.
  ///
  /// **0.6, not lower.** A paired tile still has to be readable — it is the
  /// record of what the user got right, and a tile faded to the point of
  /// guessing is a tile they will tap again to check.
  static const double pairedOpacity = 0.6;
}
