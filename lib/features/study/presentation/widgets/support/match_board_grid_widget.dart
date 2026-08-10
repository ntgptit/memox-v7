import 'package:flutter/widgets.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../items/match_tile_widget.dart';

/// The board's geometry, with nothing in it about pairing.
///
/// **Split from `MatchBoardSectionWidget` at the 400-line guard, and the seam is
/// a real one.** That widget answers what a tap *means* — which card a turn
/// belongs to, when a pair may be submitted, what a receipt allows it to draw.
/// This one answers only how many rows there are and how tall they get. They
/// shared a file because the rows are made of tiles, which is a reason to share
/// a build method, not a reason to share a state machine.
///
/// ## The grid fills the height, until it cannot
///
/// Two columns, one row per index, `sm` both ways, and every row an [Expanded]
/// so the board ends exactly where the hint line begins — no strip of dead page
/// under the last tile and no arithmetic that only holds at one screen size.
///
/// **Five rows is a ceiling, not the mock's content** (BR-156), and what varies
/// is small but real: rows that always flex would give a two-pair board a pair
/// of 300px slabs and a five-pair board 48px rows at 2.0 text scale. So the flex
/// has a floor — [AppMatchTile.minRowHeight], scaled with the text — and a board
/// that cannot meet it scrolls instead of squeezing. The arithmetic is in
/// `docs/wireframes/m5-study-modes.md` §8.6.
class MatchBoardGridWidget extends StatelessWidget {
  const MatchBoardGridWidget({
    required this.rowCount,
    required this.rowBuilder,
    super.key,
  });

  final int rowCount;

  /// One row, built by the caller — two tiles and the gap between them.
  final Widget Function(int index) rowBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Scaled, because the floor is about a finger and a line of text, and
      // both grow with the user's text setting. A fixed 112 would let a board
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
              Expanded(child: rowBuilder(index))
            else
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minRowHeight),
                // The two tiles in a row are the same height even when one
                // wraps and the other does not; without this the shorter one
                // floats and the board reads as ragged.
                child: IntrinsicHeight(child: rowBuilder(index)),
              ),
          ],
        ],
      );

      if (fillsExactly) return rows;

      return SingleChildScrollView(child: rows);
    },
  );
}
