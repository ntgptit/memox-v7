/// Which side of the target sibling a deck should occupy.
///
/// This names a stable relationship rather than an integer index. The
/// repository resolves the index from the sibling group inside its transaction,
/// so an intervening write cannot make a previously chosen raw position mean a
/// different deck.
enum DeckReorderPlacement { before, after }
