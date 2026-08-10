import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/match_mode.dart';
import '../items/match_tile_widget.dart';

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
/// **A paired tile leaves its slot behind** (§4, §8.8). What §4 forbade was the
/// board *reflowing*: remove a tile and every row under it moves, so the tile
/// the user was about to press shifts the instant they press something else —
/// and since the grid fills the height, the survivors would grow as well. So the
/// content goes and the slot stays: a beat of `success` and a tick, then the
/// words fade out and a faint outline holds the place.
///
/// The two blanks a finished card leaves are usually **not** in the same row,
/// because the two columns are independent shuffles (BR-127). That is the board
/// working, not a bug: a row is two tiles at the same index, never a pair.
///
/// **Keeping the green tile forever was the wrong half of that decision.** Three
/// states then compete on one board — idle, selected and paired — and the last
/// of them is finished business. What it was carrying, *how many pairs are
/// left*, an empty slot says better and without a colour.
///
/// **A wrong pair is told, and it was not before.** Picking the wrong meaning
/// used to clear the selection and nothing else, so it looked exactly like a
/// missed tap. Both tiles go `error` for [AppMatchTile.wrongHold] and come back
/// on their own — colour held, input not.
///
/// ## The grid fills the height, until it cannot
///
/// Two columns, one row per index, `sm` both ways, and every row an [Expanded]
/// so the board ends exactly where the hint line begins — no strip of dead page
/// under the last tile and no arithmetic that only holds at one screen size.
///
/// **Five rows is a ceiling, not the mock's content.** BR-156 splits a round
/// into boards of at most five pairs, so a round of twelve is three boards and
/// the last one can be a single pair. What varies is therefore small, but it
/// still varies: rows that always flex would give a two-pair board a pair of
/// 300px slabs, and a five-pair board 48px rows at 2.0 text scale. So the flex
/// has a floor — [AppMatchTile.minRowHeight], scaled with the text — and a board
/// that cannot meet it scrolls instead of squeezing. At 1.0 the floor is 112 and
/// five rows need 592, which the review surface's board area clears, so every
/// board a phone shows still fills exactly.
class MatchBoardSectionWidget extends StatefulWidget {
  const MatchBoardSectionWidget({
    required this.board,
    required this.onPairAttempt,
    this.pairedCardIds = const <String>{},
    this.isLocked = false,
    super.key,
  });

  final MatchBoard board;

  /// The cards this round has already taken, read from the queue.
  ///
  /// **The ticks cannot live only in this widget's state.** The screen swaps to
  /// its loading state between turns, which unmounts the board — so a paired
  /// tile came back tappable on the very next card, and the same pair could be
  /// answered again. What this widget still keeps is the tick for the answer in
  /// flight, which the queue does not know about yet.
  final Set<String> pairedCardIds;

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

  /// Cards already paired. Their slots stay on the board; this is what empties
  /// them.
  final Set<String> _matched = <String>{};

  /// The pair that just landed, for as long as it is still flashing green.
  ///
  /// One at a time on purpose: an answer takes a database write to come back,
  /// and two correct pairs inside [AppMatchTile.successFlash] is not a sequence
  /// a person can produce. If one ever did, the earlier flash gives up its beat
  /// and goes straight to cleared, which is the honest outcome — a tile cannot
  /// be halfway between marked and gone.
  String? _flashingCardId;

  /// The two tiles of the pair that was just wrong. Two ids, not one: the term
  /// and the meaning belong to different cards, which is the whole reason the
  /// answer was wrong.
  ({String termId, String meaningId})? _wrongPair;

  Timer? _flashTimer;
  Timer? _wrongTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _wrongTimer?.cancel();
    super.dispose();
  }

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

    // A new deal takes the old one's timers with it. Left running, a flash
    // started on the board that just left would clear a tile on the board that
    // just arrived — and the two boards share no cards, so it would clear
    // whichever tile happened to hold that id next.
    _flashTimer?.cancel();
    _wrongTimer?.cancel();
    _selectedTerm = null;
    _flashingCardId = null;
    _wrongPair = null;
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

    setState(() {
      // Reaching for the next pair ends the last one's complaint. The red holds
      // colour, not input — waiting it out would be the board refusing a tap it
      // has no reason to refuse.
      _wrongTimer?.cancel();
      _wrongPair = null;
      _selectedTerm = term;
    });
  }

  void _selectMeaning(MatchTile meaning) {
    final term = _selectedTerm;

    // A meaning tapped with no term chosen is not an answer. Guessing which
    // term it "probably" meant would record a turn the user never gave.
    if (widget.isLocked || term == null) return;

    final isCorrect = widget.board.isPair(term, meaning);

    setState(() {
      _selectedTerm = null;
      if (isCorrect) {
        _matched.add(term.cardId);
        _flashingCardId = term.cardId;
        _wrongPair = null;
      } else {
        _wrongPair = (termId: term.cardId, meaningId: meaning.cardId);
      }
    });

    if (isCorrect) {
      _hold(_flashTimer, AppMatchTile.successFlash, () {
        _flashingCardId = null;
      }, assign: (timer) => _flashTimer = timer);
    } else {
      _hold(_wrongTimer, AppMatchTile.wrongHold, () {
        _wrongPair = null;
      }, assign: (timer) => _wrongTimer = timer);
    }

    widget.onPairAttempt(term, isCorrect: isCorrect);
  }

  /// Holds a transient state for [duration], then drops it.
  ///
  /// **`mounted` is checked inside the callback, not before the timer.** The
  /// board is unmounted between turns — the screen swaps to its loading state —
  /// and a `setState` on a dead `State` is the crash this whole feature is one
  /// careless timer away from.
  void _hold(
    Timer? previous,
    Duration duration,
    VoidCallback drop, {
    required void Function(Timer) assign,
  }) {
    previous?.cancel();
    assign(
      Timer(duration, () {
        if (!mounted) return;
        setState(drop);
      }),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rowCount = widget.board.terms.length;
      // Scaled, because the floor is about a finger and a line of text, and
      // both grow with the user's text setting. A fixed 48 would let a board
      // fill exactly at 2.0 and clip every tile on it.
      final minRowHeight = MediaQuery.textScalerOf(
        context,
      ).scale(AppMatchTile.minRowHeight);
      final needed = rowCount * minRowHeight + (rowCount - 1) * AppSpacing.sm;
      final fillsExactly =
          constraints.hasBoundedHeight && needed <= constraints.maxHeight;

      final rows = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var index = 0; index < rowCount; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            if (fillsExactly)
              Expanded(child: _row(index))
            else
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minRowHeight),
                // The two tiles in a row are the same height even when one
                // wraps and the other does not; without this the shorter one
                // floats and the board reads as ragged.
                child: IntrinsicHeight(child: _row(index)),
              ),
          ],
        ],
      );

      if (fillsExactly) return rows;

      return SingleChildScrollView(child: rows);
    },
  );

  /// One row of the board. The two sides are independent shuffles (BR-127), so a
  /// row index means "the nth tile on each side" and never "these two go
  /// together" — which is also why a finished card can leave its two blanks in
  /// two different rows.
  ///
  /// **Meanings on the left, terms on the right, and only the order is
  /// presentational.** The eye reads the long column first and scans the short
  /// one against it; putting the six-line block on the left is what lets that
  /// scan run in one direction. Nothing in the domain is reversed or rebuilt to
  /// do it — these are the same two permutations, laid out the other way round —
  /// and the interaction is untouched: the Korean term is still what must be
  /// picked first, so it is still the right-hand tile that calls [_selectTerm]
  /// (BR-118).
  Widget _row(int index) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(child: _tile(widget.board.meanings[index], isTerm: false)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _tile(widget.board.terms[index], isTerm: true)),
    ],
  );

  Widget _tile(MatchTile tile, {required bool isTerm}) => MatchTileWidget(
    text: tile.text,
    isTerm: isTerm,
    state: _stateOf(tile, isTerm: isTerm),
    onTap: widget.isLocked
        ? null
        : () => isTerm ? _selectTerm(tile) : _selectMeaning(tile),
  );

  /// The order matters: the two transient states outrank the settled ones, and
  /// `paired` outranks `cleared` so the pair that just landed gets its beat
  /// before its slot empties.
  MatchTileState _stateOf(MatchTile tile, {required bool isTerm}) {
    final wrong = _wrongPair;
    if (wrong != null &&
        tile.cardId == (isTerm ? wrong.termId : wrong.meaningId)) {
      return MatchTileState.wrong;
    }
    if (_flashingCardId == tile.cardId) return MatchTileState.paired;

    // From the queue, this is a pair answered before the board was mounted —
    // on the way back from the loading state between turns. It never flashes:
    // the beat belongs to the tap that caused it, and replaying it on every
    // rebuild would light the board up for answers minutes old.
    if (_matched.contains(tile.cardId) ||
        widget.pairedCardIds.contains(tile.cardId)) {
      return MatchTileState.cleared;
    }
    if (isTerm && _selectedTerm?.cardId == tile.cardId) {
      return MatchTileState.selected;
    }

    return MatchTileState.idle;
  }
}
