import 'deck_activity_model.dart';
import 'progress_range_model.dart';

/// The order the deck list is read in (BR-187): busiest first, then a tie-break
/// that never moves.
///
/// **Most active first, because the list is an answer and not an index.** A
/// progress screen is read to find out where the work went; alphabetical order
/// buries that under whatever the decks happen to be called. The deck tree
/// already offers name order — this list does not repeat it.
///
/// **The tie-break is the whole reason this is a rule and not a `sort` call.**
/// Fifty decks with no activity all tie at zero, and a comparator that stops
/// there leaves their order to whatever the sort algorithm did with the input —
/// so the list reshuffles itself on every re-read, under a screen nobody
/// touched. Folded name breaks the tie visibly, and the id breaks the tie
/// between two decks genuinely called the same thing.
///
/// **Folded in Dart, never by SQL's `lower()`** — the same rule `CardText.fold`
/// states and for the same reason: SQLite folds ASCII only, so `Động từ` sorts
/// away from `động từ` while `Verbs` and `verbs` sort together. One alphabet
/// behaving differently from another is not a tie-break, it is a bug with a
/// locale attached.
///
/// **Zero-activity decks stay in the list** (BR-187). They sort last, which is
/// where they belong, but hiding them would answer "which decks did I neglect"
/// by removing the decks that answer it.
///
/// Returns a new list; the input is left alone because it comes off a stream and
/// may be held by something else.
List<DeckActivity> sortDeckActivity(
  List<DeckActivity> decks, {
  required ProgressRange range,
}) {
  final ordered = List<DeckActivity>.of(decks);
  ordered.sort((DeckActivity a, DeckActivity b) => _compare(a, b, range));

  return ordered;
}

int _compare(DeckActivity a, DeckActivity b, ProgressRange range) {
  final byActivity = b
      .metricsFor(range)
      .activeCardCount
      .compareTo(a.metricsFor(range).activeCardCount);
  if (byActivity != 0) return byActivity;

  final byName = foldDeckName(a.name).compareTo(foldDeckName(b.name));
  if (byName != 0) return byName;

  return a.deckId.compareTo(b.deckId);
}

/// The comparison form of a deck name: trimmed and case-folded with Dart's
/// Unicode-aware `toLowerCase`.
///
/// Public because the tests that pin BR-187 have to fold the same way the sort
/// does; a test that folded by hand would be asserting against its own copy of
/// the rule.
String foldDeckName(String raw) => raw.trim().toLowerCase();
