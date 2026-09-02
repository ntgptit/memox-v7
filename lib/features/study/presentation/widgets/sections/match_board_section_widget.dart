import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../domain/models/study_answer_commit_model.dart';
import '../../../domain/models/match_mode.dart';
import '../items/match_tile_widget.dart';
import '../support/match_board_grid_widget.dart';

/// The pairing board (BR-153, BR-118).
///
/// **A turn belongs to the card that owns the term, whichever tile was touched
/// first** (BR-118). The card that owns the meaning was never being asked
/// about, and grading it would punish a card for sitting on the board.
///
/// The handler builds it, and refuses fewer than two pairs — a single pair
/// makes the answer the only thing left.
///
/// **A paired tile leaves its slot behind** (§4, §8.8). What §4 forbade was the
/// board *reflowing*: remove a tile and every row under it moves, so the tile
/// the user was about to press shifts the instant they press something else —
/// and since the grid fills the height, the survivors grow as well. So the
/// content goes and the slot stays: a beat and a tick, then the words fade out
/// and a faint outline holds the place.
///
/// The two blanks a finished card leaves are usually **not** in the same row,
/// because the columns are independent shuffles (BR-127): a row is two tiles at
/// the same index, never a pair.
///
/// **Keeping the green tile forever was the wrong half of that decision.** It
/// would put three states on one board — idle, selected and paired — and the
/// last is finished business. What it carried, *how many pairs are left*, an
/// empty slot says better and without a colour.
///
/// **A wrong pair is told, and it was not before.** Picking wrong used to clear
/// the selection and nothing else, so it looked like a missed tap. Both tiles
/// mark for [AppMatchTile.wrongHold] and come back on their own — colour held,
/// input not.
///
/// The geometry — how many rows and how tall — is `MatchBoardGridWidget`.
class MatchBoardSectionWidget extends StatefulWidget {
  const MatchBoardSectionWidget({
    required this.board,
    required this.onPairAttempt,
    this.onBoardComplete,
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
  ///
  /// **It returns a `Future`, and the board waits on it.** A pair is cleared
  /// only once the write resolves, so a refused write leaves the tile where it
  /// was instead of emptying a slot the session will not remember.
  final Future<StudyAnswerCommitModel?> Function(
    MatchTile term, {
    required bool isCorrect,
  })
  onPairAttempt;

  /// Called once every pair has landed, after the last one's beat.
  ///
  /// **The one read `match` pays for.** Fetching after every attempt reloaded
  /// session, queue, card and progress and swapped the board for a spinner,
  /// five times a board. Null so a widget test can drive the board with no
  /// controller behind it.
  final Future<void> Function()? onBoardComplete;

  final bool isLocked;

  @override
  State<MatchBoardSectionWidget> createState() =>
      _MatchBoardSectionWidgetState();
}

class _MatchBoardSectionWidgetState extends State<MatchBoardSectionWidget> {
  /// The tile waiting for its partner, whichever side it came from.
  ///
  /// **It was `_selectedTerm`, and the type was the rule.** Only a term could
  /// be held, so a meaning tapped first was dropped: the board silently refused
  /// half the taps a person makes, and the hint line had to teach an order the
  /// game does not need. A pair is unordered — what BR-118 fixes is which
  /// *card* answers for it, and that is settled when the pair completes.
  MatchTile? _selectedTile;

  /// Cards already paired. Their slots stay on the board; this is what empties
  /// them.
  final Set<String> _matched = <String>{};

  /// The pair that just landed, for as long as it is still marked.
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

  /// True from the moment the last pair lands until the caller takes the board
  /// away. Without it a tap arriving during the fetch asks for the next board a
  /// second time.
  bool _isFinishing = false;

  /// True while a pair's transaction is open.
  ///
  /// **Persistence is single-flight, so the board has to be too.** The
  /// controller takes one submission at a time and refuses the second with a
  /// null receipt — which, before the receipt was typed, the board read as a
  /// successful write and cleared the pair on. Holding it here closes the gap
  /// between the tap and the parent's rebuild, which `isLocked` alone cannot:
  /// the parent does not know a write has started until this widget tells it.
  ///
  /// **It is the transaction, not the feedback.** It clears the moment the
  /// receipt arrives, so the 500/700ms a pair holds its colour is time the rest
  /// of the board is free to be played (§8.8).
  bool _isSubmitting = false;

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
    _selectedTile = null;
    _flashingCardId = null;
    _wrongPair = null;
    _isFinishing = false;
    _isSubmitting = false;
    _matched.clear();
  }

  /// What distinguishes one deal from another: which cards, in which order, on
  /// each side.
  static String _layoutOf(MatchBoard board) => <String>[
    for (final tile in board.terms) tile.cardId,
    '|',
    for (final tile in board.meanings) tile.cardId,
  ].join(',');

  /// One tap, from either column. Four outcomes and only the last is an answer:
  /// nothing held yet holds this tile; the same tile again puts it down; a tile
  /// on the same side moves the selection; one opposite completes a pair.
  void _select(MatchTile tile) {
    if (widget.isLocked || _isFinishing || _isSubmitting) return;

    final held = _selectedTile;

    if (held == null) {
      setState(() {
        // Reaching for the next pair ends the last one's complaint. The red
        // holds colour, not input — waiting it out would be the board refusing
        // a tap it has no reason to refuse.
        _wrongTimer?.cancel();
        _wrongPair = null;
        _selectedTile = tile;
      });

      return;
    }

    // Tapping what is already held puts it down; without this the only way out
    // of a selection is to answer with it, and a mis-tap becomes a turn.
    if (_isSameTile(held, tile)) {
      setState(() => _selectedTile = null);

      return;
    }

    // Two tiles from one column are not a pair and never an attempt — this is
    // the user changing their mind, which costs a card nothing.
    if (held.isTerm == tile.isTerm) {
      setState(() => _selectedTile = tile);

      return;
    }

    _answerWith(held: held, tile: tile);
  }

  static bool _isSameTile(MatchTile a, MatchTile b) =>
      a.cardId == b.cardId && a.isTerm == b.isTerm;

  /// The two tiles of a completed pair, normalised and submitted.
  ///
  /// **The card is the term's, whichever tile was touched first** (BR-118): the
  /// meaning's card was never the one being asked about, so picking it first
  /// must not change who answers for the mistake.
  void _answerWith({required MatchTile held, required MatchTile tile}) {
    final term = held.isTerm ? held : tile;
    final meaning = held.isTerm ? tile : held;

    // **Nothing is coloured here.** The selection is released so the pair stops
    // looking half-made, and the write goes out — but green and red both wait
    // for the receipt (BR-157). Setting `_wrongPair` on the tap was the same
    // bug as clearing on completion: a screen saying something the database
    // does not.
    setState(() {
      _selectedTile = null;
      _isSubmitting = true;
    });

    unawaited(
      _land(
        term,
        isCorrect: widget.board.isPair(term, meaning),
        meaning: meaning,
      ),
    );
  }

  /// Submits the attempt and, once it has committed, marks the pair.
  ///
  /// **A null receipt is a write that did not happen** — refused, or a second
  /// submission arriving while the first was open. The pair goes back to idle:
  /// no tick, no red, no cleared slot, no board-complete. Anything else would be
  /// the board reporting a turn the session has no record of.
  Future<void> _land(
    MatchTile term, {
    required bool isCorrect,
    required MatchTile meaning,
  }) async {
    final commit = await widget.onPairAttempt(term, isCorrect: isCorrect);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (commit == null) return;

    if (!isCorrect) {
      // The row stays open (BR-118) — which is what the receipt says — so the
      // pair stays playable and only its colour is held.
      setState(
        () => _wrongPair = (termId: term.cardId, meaningId: meaning.cardId),
      );
      _hold(_wrongTimer, AppMatchTile.wrongHold, () {
        _wrongPair = null;
      }, assign: (timer) => _wrongTimer = timer);

      return;
    }

    setState(() {
      _matched.add(term.cardId);
      _flashingCardId = term.cardId;
    });

    _hold(_flashTimer, AppMatchTile.successFlash, () {
      _flashingCardId = null;
    }, assign: (timer) => _flashTimer = timer);

    if (!_isBoardCleared) return;

    // **The board is taken away here, and only after the beat.** One that
    // swapped the instant its last pair landed would show the tick for a single
    // frame, so the pair that finished the round would be the one the user
    // never saw confirmed.
    _isFinishing = true;
    await Future<void>.delayed(AppMatchTile.successFlash);
    if (!mounted) return;

    await widget.onBoardComplete?.call();
  }

  /// Whether every card on this board has been answered correctly.
  bool get _isBoardCleared => widget.board.terms.every(
    (tile) =>
        _matched.contains(tile.cardId) ||
        widget.pairedCardIds.contains(tile.cardId),
  );

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
  Widget build(BuildContext context) => MatchBoardGridWidget(
    rowCount: widget.board.terms.length,
    rowBuilder: _row,
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
  /// do it — these are the same two permutations, laid out the other way round.
  /// Neither column opens a turn on its own either: both call [_select], and
  /// which card the turn belongs to is settled when the pair completes
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
    onTap: widget.isLocked ? null : () => _select(tile),
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
    final held = _selectedTile;
    if (held != null && _isSameTile(held, tile)) {
      return MatchTileState.selected;
    }

    return MatchTileState.idle;
  }
}
