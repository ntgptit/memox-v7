package com.memox.tag.service;

import java.time.Clock;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.exception.CardNotFoundException;
import com.memox.common.error.ApiErrorCode;
import com.memox.common.persistence.IdCollections;
import com.memox.tag.entity.Tag;
import com.memox.tag.entity.TagName;
import com.memox.tag.exception.TagConflictException;
import com.memox.tag.persistence.TagMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Attaching and detaching tags on cards.
 *
 * <p>Lives in the tag module rather than the card module because {@code card_tags} is the tag's own
 * edge list: the rules being enforced here — reuse by folded name, the ten-tag ceiling, all or
 * nothing — are tag rules that happen to be applied to a list of card ids.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CardTagService {

	/** BR-94. Ten is what a card row can draw as chips at 320dp with a doubled text scale. */
	private static final int MAX_TAGS_PER_CARD = 10;

	private static final String CARD_IDS = "cardIds";

	private final TagMapper tagMapper;
	private final Clock clock;

	/**
	 * One tag onto a batch of cards, all or nothing (BR-166).
	 *
	 * <p>Three rules run in order, and the order is the rule. The tag is resolved by its folded name
	 * so a second spelling reuses the row rather than minting a rival (BR-93). The ceiling is then
	 * measured only against the cards that would actually <em>gain</em> a tag, because a card that
	 * already carries it stays exactly where it is however full it is. And one card over the line
	 * refuses the whole batch: a partial tag is a state the user cannot see and did not ask for.
	 *
	 * @return the tag every card in the batch now carries
	 * @throws CardNotFoundException when an id names no active card — a card in Trash included
	 * @throws TagConflictException when a card that would gain the tag is already at the ceiling
	 */
	@Transactional
	public Tag attach(AttachTagCommand command) {
		final var cardIds = IdCollections.requireUsableBatch(command.cardIds(), CARD_IDS);
		requireAllActive(cardIds);

		final var name = TagName.of(command.name());
		final var tag = resolveOrMint(name);
		final var gaining = new HashSet<>(cardIds);
		gaining.removeAll(tagMapper.findCardsAlreadyTagged(cardIds, tag.id()));
		requireRoomForEach(gaining, cardIds);

		final var linked = tagMapper.linkTagToCards(cardIds, tag.id());
		log.info("Attached tag {} to {} of {} card(s)", tag.id(), linked, cardIds.size());
		return tag;
	}

	/**
	 * The tags one card carries, with their ids.
	 *
	 * <p>Read rather than derived from the names a card projection already carries: turning a name
	 * back into an id in the client would put a second fold there, which BR-230 forbids.
	 */
	@Transactional(readOnly = true)
	public List<Tag> tagsForCard(String cardId) {
		return tagMapper.findTagsForCard(cardId);
	}

	/**
	 * Removes one link.
	 *
	 * <p>No existence check, and that is deliberate: unlinking a pair that is not there leaves the
	 * same end state the caller asked for, so a second click on a chip that has already gone is not
	 * an error worth a 404.
	 */
	@Transactional
	public void detach(String cardId, String tagId) {
		final var removed = tagMapper.unlinkTag(cardId, tagId);
		log.info("Detached tag {} from card {}, removing {} link(s)", tagId, cardId, removed);
	}

	private void requireAllActive(List<String> cardIds) {
		final var active = tagMapper.countActiveCardsByIds(cardIds);
		if (active == cardIds.size()) {
			return;
		}
		// The first id is named rather than the missing one: finding which is missing costs a second
		// read for a message that must not echo content anyway, and the batch is refused either way.
		throw new CardNotFoundException(cardIds.get(0));
	}

	private Tag resolveOrMint(TagName name) {
		final var owned = tagMapper.findTagByFoldedName(name.folded());
		if (owned != null) {
			return owned;
		}
		final var minted = new Tag(UUID.randomUUID().toString(), name.value(), name.folded(),
				Instant.now(this.clock));
		tagMapper.insertTag(minted);
		log.info("Minted tag {}", minted.id());
		return minted;
	}

	private void requireRoomForEach(Set<String> gaining, List<String> cardIds) {
		if (gaining.isEmpty()) {
			return;
		}
		final var full = tagMapper.findCardsAtTagCeiling(cardIds, MAX_TAGS_PER_CARD).stream()
				.filter(gaining::contains).findFirst();
		if (full.isEmpty()) {
			return;
		}
		throw new TagConflictException(ApiErrorCode.TAG_LIMIT_EXCEEDED, full.get());
	}
}
