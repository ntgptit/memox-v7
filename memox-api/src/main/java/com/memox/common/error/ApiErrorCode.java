package com.memox.common.error;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ApiErrorCode {

	VALIDATION_FAILED(HttpStatus.BAD_REQUEST, "error.validation-failed"),
	PARENT_HOLDS_CARDS(HttpStatus.CONFLICT, "error.parent-holds-cards"),
	DECK_DEPTH_EXCEEDED(HttpStatus.CONFLICT, "error.deck-depth-exceeded"),
	ROOT_CANNOT_HOLD_CARDS(HttpStatus.CONFLICT, "error.root-cannot-hold-cards"),
	DECK_HOLDS_CHILDREN(HttpStatus.CONFLICT, "error.deck-holds-children"),
	ROOT_SCHEDULER_INVALID(HttpStatus.CONFLICT, "error.root-scheduler-invalid"),
	DECK_NOT_FOUND(HttpStatus.NOT_FOUND, "error.deck-not-found"),
	CARD_NOT_FOUND(HttpStatus.NOT_FOUND, "error.card-not-found"),
	TAG_NOT_FOUND(HttpStatus.NOT_FOUND, "error.tag-not-found"),
	TAG_LIMIT_EXCEEDED(HttpStatus.CONFLICT, "error.tag-limit-exceeded"),
	CARD_CROSS_ROOT_MOVE(HttpStatus.CONFLICT, "error.card-cross-root-move"),
	MOVE_TARGET_INVALID(HttpStatus.CONFLICT, "error.move-target-invalid"),
	EXPORT_SCOPE_EMPTY(HttpStatus.CONFLICT, "error.export-scope-empty"),
	EXPORT_SELECTION_STALE(HttpStatus.CONFLICT, "error.export-selection-stale"),
	DECK_POSITION_OUT_OF_RANGE(HttpStatus.BAD_REQUEST, "error.deck-position-out-of-range"),
	DECK_CROSS_ROOT_MOVE(HttpStatus.CONFLICT, "error.deck-cross-root-move"),
	DECK_MOVE_INTO_OWN_SUBTREE(HttpStatus.CONFLICT, "error.deck-move-into-own-subtree"),
	SCHEDULER_GENERATION_MISMATCH(HttpStatus.CONFLICT, "error.scheduler-generation-mismatch"),
	DATA_INTEGRITY_VIOLATION(HttpStatus.CONFLICT, "error.data-integrity-violation"),
	INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "error.internal-server-error");

	private final HttpStatus status;
	private final String messageKey;
}
