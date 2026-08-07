import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
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

  /// Cards already cleared from the board.
  final Set<String> _matched = <String>{};

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
      for (final tile in tiles)
        if (!_matched.contains(tile.cardId))
          MxListTile(
            title: tile.text,
            isSelected: isTerm && _selectedTerm?.cardId == tile.cardId,
            onTap: widget.isLocked
                ? null
                : () => isTerm ? _selectTerm(tile) : _selectMeaning(tile),
          ),
    ],
  );
}
