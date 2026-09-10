package com.memox.tag.persistence;

import java.util.Collection;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.tag.entity.Tag;
import com.memox.tag.entity.TagCatalogEntry;

/**
 * The {@code tags} and {@code card_tags} table family.
 *
 * <p>Both tables live here rather than one of them living in the card module: {@code card_tags} is
 * the tag's own edge list, and splitting it would make two features responsible for one rule. The
 * statements that read {@code cards} do so to answer a tag question — is this card active, is it at
 * the ceiling — and never to describe a card.
 */
@Mapper
public interface TagMapper {

	/**
	 * @param searchFolded a term already folded through {@code TagName.fold}; empty matches all
	 */
	List<TagCatalogEntry> findTagCatalog(@Param("searchFolded") String searchFolded);

	Tag findTagByFoldedName(@Param("nameFolded") String nameFolded);

	Tag findTagById(@Param("tagId") String tagId);

	void insertTag(Tag tag);

	int renameTagById(@Param("tagId") String tagId, @Param("name") String name,
			@Param("nameFolded") String nameFolded);

	int linkCardsOfTagTo(@Param("sourceTagId") String sourceTagId,
			@Param("targetTagId") String targetTagId);

	int unlinkAllCardsFromTag(@Param("tagId") String tagId);

	int deleteTagById(@Param("tagId") String tagId);

	long countActiveCardsByIds(@Param("cardIds") Collection<String> cardIds);

	List<String> findCardsAlreadyTagged(@Param("cardIds") Collection<String> cardIds,
			@Param("tagId") String tagId);

	List<String> findCardsAtTagCeiling(@Param("cardIds") Collection<String> cardIds,
			@Param("ceiling") int ceiling);

	int linkTagToCards(@Param("cardIds") Collection<String> cardIds, @Param("tagId") String tagId);

	List<Tag> findTagsForCard(@Param("cardId") String cardId);

	int unlinkTag(@Param("cardId") String cardId, @Param("tagId") String tagId);
}
