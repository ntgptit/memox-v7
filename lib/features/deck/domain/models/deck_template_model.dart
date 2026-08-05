import '../../../card/domain/models/card_text_model.dart';
import 'deck_name_model.dart';
import 'scheduler_type_model.dart';

/// A starter deck as the app publishes it — a tree of names and cards, not a
/// deck (AD-07, BR-31).
///
/// **Already validated.** Every name is a [DeckName] and every card side a
/// [CardText], so BR-01 and the card length rules have been applied by the time
/// a template exists at all. The install path therefore has nothing to check and
/// no way to write an invalid row: an asset the loader could not parse never
/// becomes a `DeckTemplate`, it becomes a thrown failure at startup, where a
/// developer sees it.
///
/// **It carries no deck ids.** A template is not a deck and never becomes one —
/// using it copies it (BR-33), and the copy is an ordinary deck with its own
/// ids and no link back (BR-35). The only trace is `source_template_id` and
/// `source_template_version` on the copied root (BR-34), which is what makes the
/// install idempotent (BR-37).
final class DeckTemplate {
  const DeckTemplate({
    required this.templateId,
    required this.version,
    required this.locale,
    required this.title,
    required this.contentSource,
    required this.defaultSchedulerType,
    required this.children,
  });

  /// Stable across app versions (BR-32) — it is half of the identity the
  /// idempotency check uses, so changing it duplicates every copy in the wild.
  final String templateId;

  /// The other half. Bumping it is how a template ships new content without
  /// touching the copies made from the previous one (BR-36).
  final int version;

  final String locale;

  /// The copied root deck's name.
  final DeckName title;

  /// Where the words came from. `memox-fixture` says "written by this project to
  /// exercise the app", which BR-87 requires to be stated rather than implied.
  final String contentSource;

  /// A *suggestion* (BR-34): the caller picks the scheduler, and this is what it
  /// picks when it has no opinion. A template cannot impose one, because the
  /// scheduler is locked after the first review and belongs to the user's copy.
  final SchedulerType defaultSchedulerType;

  /// The root holds sub-decks only (BR-58), so this is never empty and the root
  /// never carries cards.
  final List<DeckTemplateNode> children;

  /// Every card in the tree, for a test or a report that wants the total without
  /// walking it again.
  int get cardCount =>
      children.fold(0, (total, child) => total + child.cardCount);
}

/// One deck inside a template: either sub-decks or cards, never both.
///
/// **The either/or is structural, not a comment.** BR-61 and BR-62 say a deck
/// holds one kind of thing, and the loader refuses a node that declares both —
/// so an install cannot produce a tree the app's own rules would reject, and
/// `installTemplate` does not have to check.
final class DeckTemplateNode {
  const DeckTemplateNode.branch({required this.name, required this.children})
    : cards = const <DeckTemplateCard>[];

  const DeckTemplateNode.leaf({required this.name, required this.cards})
    : children = const <DeckTemplateNode>[];

  final DeckName name;
  final List<DeckTemplateNode> children;
  final List<DeckTemplateCard> cards;

  /// True when this node's children are cards. An empty leaf is still a leaf:
  /// it installs as a deck whose `content_type` stays `unset`, exactly as an
  /// empty deck the user created would.
  bool get isLeaf => children.isEmpty;

  int get cardCount =>
      cards.length +
      children.fold(0, (total, child) => total + child.cardCount);
}

/// One card inside a template.
final class DeckTemplateCard {
  const DeckTemplateCard({
    required this.front,
    required this.back,
    this.example,
  });

  final CardText front;
  final CardText back;
  final CardDetailText? example;
}
