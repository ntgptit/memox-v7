/// The 19 invariant queries this suite executes, copied verbatim from
/// `data-model.md`.
///
/// **A subset of the document's, and its numbering, not a fresh sequence.**
/// The document specifies thirty-two; the ones here are the ones with an executable
/// fixture. The keys keep the document's ids so a failure names the rule rather
/// than a position in this map — which is why `Q29` sits next to `Q2` and `Q30`
/// next to `Q11`, each beside the rule it is about rather than at the end.
///
/// Frozen source. Nothing here may be reworded to make a test pass — the
/// document is the specification, and a query edited to suit a fixture stops
/// being an invariant and becomes a description of whatever the code currently
/// does.
///
/// Each must always return **zero rows**. `invariants_test.dart` proves both
/// halves of that for every one: silent on valid data, and firing on its own
/// violation and no other.
library;

/// Invariant id → the query `data-model.md` specifies for it.
const Map<String, String> invariantQueries = <String, String>{
  // ---- Deck tree ----------------------------------------------------------
  'Q1': // Root deck holds cards directly (BR-58)
      'SELECT c.id FROM cards c '
      'JOIN decks d ON d.id = c.deck_id '
      'WHERE d.parent_deck_id IS NULL',

  'Q2': // content_type = 'unset' but already has content (BR-60, BR-62)
      "SELECT d.id FROM decks d WHERE d.content_type = 'unset' "
      'AND (EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = d.id) '
      'OR EXISTS (SELECT 1 FROM decks s WHERE s.parent_deck_id = d.id))',

  'Q29': // A sub-deck kept its type after everything left it (BR-163)
      'SELECT d.id FROM decks d '
      'WHERE d.parent_deck_id IS NOT NULL '
      "AND d.content_type IN ('card', 'deck') "
      'AND NOT EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = d.id) '
      'AND NOT EXISTS '
      '(SELECT 1 FROM decks child WHERE child.parent_deck_id = d.id)',

  'Q3': // content_type = 'card' but has sub-decks (BR-63)
      "SELECT d.id FROM decks d WHERE d.content_type = 'card' "
      'AND EXISTS (SELECT 1 FROM decks s WHERE s.parent_deck_id = d.id)',

  'Q4': // content_type = 'deck' but has direct cards (BR-64)
      "SELECT d.id FROM decks d WHERE d.content_type = 'deck' "
      'AND EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = d.id)',

  'Q5': // Root deck does not carry content_type = 'deck'
      'SELECT d.id FROM decks d '
      "WHERE d.parent_deck_id IS NULL AND d.content_type <> 'deck'",

  'Q6': // Descendant points at the wrong root (BR-72)
      'SELECT d.id FROM decks d '
      'JOIN decks p ON p.id = d.parent_deck_id '
      'WHERE d.root_deck_id <> p.root_deck_id',

  'Q7': // Root deck does not point at itself (BR-56)
      'SELECT d.id FROM decks d '
      'WHERE d.parent_deck_id IS NULL AND d.root_deck_id <> d.id',

  // Depth is capped at 64 so the checker cannot itself become an infinite loop
  // once the data is already broken — a checker that hangs is a checker nobody
  // runs.
  'Q8': // Cycle in the tree (BR-69)
      'WITH RECURSIVE up(start_id, node_id, depth) AS ('
      'SELECT id, parent_deck_id, 1 FROM decks WHERE parent_deck_id IS NOT NULL '
      'UNION ALL '
      'SELECT u.start_id, d.parent_deck_id, u.depth + 1 '
      'FROM up u JOIN decks d ON d.id = u.node_id '
      'WHERE u.node_id IS NOT NULL AND u.depth < 64) '
      'SELECT DISTINCT start_id FROM up WHERE node_id = start_id',

  // ---- Scheduler and generation -------------------------------------------
  // Q9 joins through root_deck_id. Coalescing the parent column with the id
  // returns the level-2 deck for anything at level 3 (BR-57).
  'Q9': // Card state disagrees with its root's scheduler (BR-48, BR-49)
      'SELECT s.card_id FROM card_study_states s '
      'JOIN cards c ON c.id = s.card_id '
      'JOIN decks d ON d.id = c.deck_id '
      'JOIN decks root ON root.id = d.root_deck_id '
      'WHERE s.scheduler_generation <> root.scheduler_generation '
      'OR s.scheduler_type <> root.scheduler_type',

  'Q10': // Sub-deck carries scheduler columns (BR-06)
      'SELECT d.id FROM decks d WHERE d.parent_deck_id IS NOT NULL '
      'AND (d.scheduler_type IS NOT NULL '
      'OR d.scheduler_generation IS NOT NULL)',

  'Q11': // Root deck is missing its scheduler (BR-11)
      'SELECT d.id FROM decks d WHERE d.parent_deck_id IS NULL '
      'AND (d.scheduler_type IS NULL OR d.scheduler_generation IS NULL)',

  'Q30': // A tree has learned cards but its scheduler is not locked (BR-13)
      'SELECT root.id FROM decks root WHERE root.parent_deck_id IS NULL '
      'AND root.first_answered_at IS NULL '
      'AND EXISTS (SELECT 1 FROM card_study_states s '
      'JOIN cards c ON c.id = s.card_id '
      'JOIN decks d ON d.id = c.deck_id '
      'WHERE d.root_deck_id = root.id AND s.learned_at IS NOT NULL)',

  // ---- Session ------------------------------------------------------------
  'Q12': // Invalid status × end_reason (BR-79…BR-85)
      'SELECT id FROM study_sessions WHERE NOT ('
      "(status = 'in_progress' AND end_reason IS NULL) "
      "OR (status = 'completed' AND end_reason IS NULL) "
      "OR (status = 'abandoned' AND end_reason = 'user_exit') "
      "OR (status = 'invalidated' "
      "AND end_reason IN ('scheduler_reset','stale_generation')) "
      "OR (status = 'failed' AND end_reason = 'persistence_error'))",

  'Q13': // Session ended but has no ended_at
      'SELECT id FROM study_sessions '
      "WHERE status <> 'in_progress' AND ended_at IS NULL",

  'Q31': // A recall direction outside where BR-203 allows one
      'SELECT s.id FROM study_sessions s '
      'WHERE (s.direction IS NOT NULL '
      "AND (s.session_kind <> 'reviewing' OR s.current_mode <> 'self_assess')) "
      'OR EXISTS (SELECT 1 FROM study_queue_items q '
      'WHERE q.session_id = s.id '
      "AND ((q.direction IS NOT NULL AND q.mode <> 'self_assess') "
      'OR (q.direction IS NOT NULL AND s.direction IS NULL) '
      "OR (s.direction IS NOT NULL AND q.mode = 'self_assess' "
      'AND q.direction IS NULL)))',

  // ---- Review history -----------------------------------------------------
  'Q32': // A turn's direction disagrees with the queue rows it came from (BR-206)
      'SELECT a.id FROM study_answers a '
      'WHERE EXISTS (SELECT 1 FROM study_queue_items q '
      'WHERE q.session_id = a.session_id AND q.card_id = a.card_id '
      'AND q.mode = a.mode) '
      'AND NOT EXISTS (SELECT 1 FROM study_queue_items q '
      'WHERE q.session_id = a.session_id AND q.card_id = a.card_id '
      'AND q.mode = a.mode AND q.direction IS a.direction)',

  'Q14': // A relearning review changed the schedule (BR-78)
      'SELECT id FROM study_answers '
      "WHERE kind = 'relearning' "
      'AND (previous_box IS NOT next_box '
      'OR previous_ease_factor IS NOT next_ease_factor '
      'OR previous_interval_days IS NOT next_interval_days)',

  // ---- Deck tree, depth ---------------------------------------------------
  'Q15': // A deck deeper than 10 levels, root as level 1 (BR-55)
      'WITH RECURSIVE levels(id, depth) AS ('
      'SELECT id, 1 FROM decks WHERE parent_deck_id IS NULL '
      'UNION ALL '
      'SELECT d.id, l.depth + 1 '
      'FROM decks d JOIN levels l ON d.parent_deck_id = l.id '
      'WHERE l.depth < 64) '
      'SELECT id FROM levels WHERE depth > 10',
};
