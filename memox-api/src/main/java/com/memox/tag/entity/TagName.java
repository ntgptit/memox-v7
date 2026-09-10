package com.memox.tag.entity;

import java.util.Locale;

import com.memox.common.error.ValidationFailedException;

/**
 * A tag name that has already been through BR-93, together with the folded form it is compared by.
 *
 * <p>The constructor is private and {@link #of(String)} is the only door, so a {@code TagName} in a
 * signature answers "has this been validated?" without anyone reading the implementation — the same
 * property AD-13 asks of every input rule. The two fields cannot disagree because nothing outside
 * this class can pair them.
 *
 * <p><strong>The fold happens in Java, not in SQL.</strong> SQLite's {@code lower()} and its
 * {@code NOCASE} collation fold ASCII only, so {@code Động Từ} and {@code động từ} would be two tags
 * on the device; PostgreSQL's {@code lower()} would fold both correctly and therefore disagree with
 * the device about what is unique. One fold, in one language, is what keeps the two stores saying
 * the same thing — and it is why {@link #fold(String)} is public: BR-230 requires the catalog's
 * search term and the column it searches to use the same one, and a second normaliser is exactly
 * what that rule forbids.
 */
public final class TagName {

	/** BR-93. Fifty is what the tag chip can draw at 320dp with a doubled text scale. */
	private static final int MAX_LENGTH = 50;

	private static final String FIELD = "name";

	private final String value;
	private final String folded;

	private TagName(String value, String folded) {
		this.value = value;
		this.folded = folded;
	}

	/**
	 * @throws ValidationFailedException when the name is blank, too long, or carries a control
	 *     character — the same {@code fieldErrors} shape every other rejected parameter arrives in
	 */
	public static TagName of(String raw) {
		if (raw == null) {
			throw new ValidationFailedException(FIELD, "must not be blank");
		}
		final var trimmed = raw.trim();
		if (trimmed.isEmpty()) {
			throw new ValidationFailedException(FIELD, "must not be blank");
		}
		if (trimmed.length() > MAX_LENGTH) {
			throw new ValidationFailedException(FIELD,
					"must not exceed " + MAX_LENGTH + " characters");
		}
		if (trimmed.chars().anyMatch(Character::isISOControl)) {
			throw new ValidationFailedException(FIELD, "must not contain control characters");
		}
		return new TagName(trimmed, fold(trimmed));
	}

	/** The one fold BR-93 and BR-230 both measure in. A null or blank term folds to the empty term. */
	public static String fold(String raw) {
		if (raw == null) {
			return "";
		}
		return raw.trim().toLowerCase(Locale.ROOT);
	}

	public String value() {
		return this.value;
	}

	public String folded() {
		return this.folded;
	}
}
