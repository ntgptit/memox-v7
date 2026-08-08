import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';
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
///
/// ## The grid fills the height, until it cannot
///
/// Two columns, one pair per row, `sm` both ways, and every row an [Expanded] so
/// the board ends exactly where the hint line begins — no strip of dead page
/// under the last tile and no arithmetic that only holds at one screen size.
///
/// **The handout's five rows are the mock's content, not a rule.** A board holds
/// the whole round (BR-115) and BR-153 only sets a floor of two pairs, so ten
/// cards is a ten-row board and two is a two-row one. Rows that always flex
/// would make the first case 48px tall at 2.0 text scale and the second a pair
/// of 300px slabs. So the flex has a floor — [AppMatchTile.minRowHeight], scaled
/// with the text, because a tile is a tap target before it is a layout — and a
/// board that cannot meet it scrolls instead. Every board that fits still fills
/// exactly, which is every board the mock covers.
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

  /// One pair's row. The two sides are independent shuffles (BR-127), so a row
  /// index means "the nth tile on each side" and never "these two go together".
  Widget _row(int index) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(child: _tile(widget.board.terms[index], isTerm: true)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _tile(widget.board.meanings[index], isTerm: false)),
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

  MatchTileState _stateOf(MatchTile tile, {required bool isTerm}) {
    if (_matched.contains(tile.cardId) ||
        widget.pairedCardIds.contains(tile.cardId)) {
      return MatchTileState.paired;
    }
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
/// colour and not decoration (§7.8). The handout calls that role `mastery`;
/// this app already spends `success` on it — `card_state_widget.dart` paints
/// `CardState.mastered` with it — so the two names are one token.
///
/// **The paired tint is blended, not painted translucent.** A `BorderSide` or a
/// fill at 12% composites against whatever is behind it at paint time, so one
/// token renders as two values over two surfaces; `color_source_rules_test.dart`
/// R7 fails it. `Color.alphaBlend` resolves the same colour at build time
/// against the surface the tile actually sits on, which is what makes the tint a
/// value somebody chose.
class MatchTileWidget extends StatelessWidget {
  const MatchTileWidget({
    required this.text,
    required this.state,
    required this.onTap,
    this.isTerm = true,
    super.key,
  });

  final String text;
  final MatchTileState state;
  final VoidCallback? onTap;

  /// Which side of the board this is, and therefore how loud it reads: a term
  /// is what the eye scans for, a meaning is what it checks against.
  final bool isTerm;

  bool get _isPaired => state == MatchTileState.paired;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final semantic = context.semanticColors;
    final isSelected = state == MatchTileState.selected;

    final ground = scheme.surfaceContainerLowest;
    final background = switch (state) {
      MatchTileState.selected => scheme.primary,
      MatchTileState.paired => Color.alphaBlend(
        semantic.success.withValues(alpha: AppMatchTile.pairedFillAlpha),
        ground,
      ),
      MatchTileState.idle => ground,
    };
    final outline = switch (state) {
      MatchTileState.selected => scheme.primary,
      MatchTileState.paired => Color.alphaBlend(
        semantic.success.withValues(alpha: AppMatchTile.pairedOutlineAlpha),
        ground,
      ),
      MatchTileState.idle => semantic.borderSubtle,
    };
    final foreground = switch (state) {
      MatchTileState.selected => scheme.onPrimary,
      MatchTileState.paired => semantic.success,
      MatchTileState.idle => scheme.onSurface,
    };

    final style =
        (isTerm ? context.texts.titleMedium : context.texts.titleSmall)
            ?.copyWith(color: foreground);
    final radius = BorderRadius.circular(AppRadius.md);

    return Semantics(
      selected: isSelected,
      // A tick in green marks the pair for people who can see it. This is what
      // marks it for everyone else.
      value: _isPaired ? context.l10n.studyMatchPaired : null,
      child: Opacity(
        // Paired tiles stay on the board and stop competing for attention. The
        // remaining pairs are the ones still being worked on.
        opacity: _isPaired ? AppMatchTile.pairedOpacity : 1,
        child: AnimatedContainer(
          // Three states on one tile and the user causes every change, so the
          // move has to be visible without being waited on.
          duration: AppDurations.normal,
          curve: AppDurations.standard,
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: Border.all(color: outline),
          ),
          child: Material(
            // The container paints the surface; this exists for the ripple.
            type: MaterialType.transparency,
            child: InkWell(
              // A paired tile is finished, not merely busy: BR-116 has already
              // recorded it, and a second tap could only record it twice.
              onTap: _isPaired ? null : onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (_isPaired) ...<Widget>[
                        Icon(
                          Icons.check,
                          size: style?.fontSize,
                          color: foreground,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          style: style,
                          textAlign: TextAlign.center,
                          // The row's height is the grid's to decide, so a long
                          // term gives way rather than pushing the board out of
                          // shape.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The numbers this tile decides for itself, and none of them is a colour.
abstract final class AppMatchTile {
  /// How far a paired tile recedes.
  ///
  /// **0.7, not lower.** A paired tile still has to be readable — it is the
  /// record of what the user got right, and a tile faded to the point of
  /// guessing is a tile they will tap again to check.
  static const double pairedOpacity = 0.7;

  /// How much `success` a paired tile's fill carries, blended into the surface
  /// under it. Enough to read as a state, not enough to compete with the
  /// selected tile, which is the only solid colour on the board.
  static const double pairedFillAlpha = 0.12;

  /// The same for its outline. Heavier than the fill because a hairline has a
  /// tenth of the area to say it with.
  static const double pairedOutlineAlpha = 0.3;

  /// The shortest a row is allowed to get before the board stops filling the
  /// height and starts scrolling.
  ///
  /// [AppSpacing.minimumTouchTarget], because a tile is a control: a board of
  /// twelve pairs that divided the height evenly would hand a thumb 40px rows,
  /// and the grid looking tidy is worth less than the taps landing.
  static const double minRowHeight = AppSpacing.minimumTouchTarget;
}
