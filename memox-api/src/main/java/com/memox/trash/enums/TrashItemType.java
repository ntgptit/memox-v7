package com.memox.trash.enums;

import com.memox.common.mybatis.PersistableEnum;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * What a delete batch's item root is.
 *
 * <p>Two values and no third: a batch is opened for one deck or one card, and the pair of
 * {@code LEFT JOIN}s that resolves a batch's name in the Trash list is exclusive on exactly this
 * column. A third kind would make both joins miss and draw a row with no name.
 */
@Getter
@RequiredArgsConstructor
public enum TrashItemType implements PersistableEnum {

	DECK("deck"),
	CARD("card");

	private final String value;
}
