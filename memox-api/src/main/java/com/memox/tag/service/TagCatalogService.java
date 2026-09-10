package com.memox.tag.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.common.persistence.AffectedRows;
import com.memox.tag.entity.Tag;
import com.memox.tag.entity.TagCatalogEntry;
import com.memox.tag.entity.TagName;
import com.memox.tag.exception.TagNotFoundException;
import com.memox.tag.persistence.TagMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * The tag management surface: the catalog, rename-or-merge, and delete.
 *
 * <p>Nothing here logs a tag name (BR-51, BR-52, BR-267). Ids and counts are what an investigation
 * needs, and they are all these lines carry.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TagCatalogService {

	private final TagMapper tagMapper;

	/**
	 * Every tag with its active-card count, optionally narrowed by a search term (BR-230).
	 *
	 * <p>The term is folded here, through the same {@code TagName.fold} the names themselves went
	 * through on the way in. BR-230 forbids a second normaliser precisely because two folds produce
	 * two different orders and two different notions of "matches" over the same rows.
	 */
	@Transactional(readOnly = true)
	public List<TagCatalogEntry> catalog(String search) {
		final var entries = tagMapper.findTagCatalog(TagName.fold(search));
		log.debug("Listed {} tag(s) in the catalog", entries.size());
		return entries;
	}

	/**
	 * BR-233's rename, which becomes BR-234's merge when the folded name is already taken.
	 *
	 * <p>The collision probe compares ids rather than merely asking whether a row came back: a
	 * rename that only changes the case leaves {@code name_folded} untouched, so the probe finds the
	 * very tag being renamed. Treating that as a merge would delete the row it was asked to rename.
	 *
	 * @return the tag that survived — the renamed one, or the target the source was merged into
	 * @throws TagNotFoundException when the tag id resolves to nothing
	 */
	@Transactional
	public Tag rename(RenameTagCommand command) {
		final var name = TagName.of(command.name());
		final var tag = tagMapper.findTagById(command.tagId());
		if (tag == null) {
			throw new TagNotFoundException(command.tagId());
		}
		final var collision = tagMapper.findTagByFoldedName(name.folded());
		if (collision == null || collision.id().equals(tag.id())) {
			AffectedRows.requireExactlyOne(
					tagMapper.renameTagById(tag.id(), name.value(), name.folded()),
					() -> new TagNotFoundException(command.tagId()));
			log.info("Renamed tag {}", tag.id());
			return new Tag(tag.id(), name.value(), name.folded(), tag.createdAt());
		}
		return mergeInto(tag, collision);
	}

	/**
	 * BR-235: every link this tag has, then the tag row. No card is touched.
	 *
	 * @throws TagNotFoundException when the tag id resolves to nothing
	 */
	@Transactional
	public void delete(String tagId) {
		final var unlinked = tagMapper.unlinkAllCardsFromTag(tagId);
		AffectedRows.requireExactlyOne(
				tagMapper.deleteTagById(tagId), () -> new TagNotFoundException(tagId));
		log.info("Deleted tag {} and its {} card link(s)", tagId, unlinked);
	}

	/**
	 * BR-234, in the one transaction the rule requires: carry the links, drop the source's, drop it.
	 *
	 * <p>The links are carried without consulting {@code cards}, so a card in Trash keeps the tag it
	 * had (BR-237). Restoring it must not find a card quietly stripped of its metadata because a
	 * merge ran while nobody was looking at it.
	 */
	private Tag mergeInto(Tag source, Tag target) {
		final var carried = tagMapper.linkCardsOfTagTo(source.id(), target.id());
		tagMapper.unlinkAllCardsFromTag(source.id());
		AffectedRows.requireExactlyOne(
				tagMapper.deleteTagById(source.id()), () -> new TagNotFoundException(source.id()));
		log.info("Merged tag {} into {}, carrying {} link(s)", source.id(), target.id(), carried);
		return target;
	}
}
