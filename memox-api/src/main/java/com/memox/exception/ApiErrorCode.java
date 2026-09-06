package com.memox.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ApiErrorCode {

	VALIDATION_FAILED(HttpStatus.BAD_REQUEST, "error.validation-failed"),
	DECK_NAME_REQUIRED(HttpStatus.BAD_REQUEST, "error.deck-name-required"),
	DECK_NAME_TOO_LONG(HttpStatus.BAD_REQUEST, "error.deck-name-too-long"),
	CARD_FRONT_REQUIRED(HttpStatus.BAD_REQUEST, "error.card-front-required"),
	CARD_BACK_REQUIRED(HttpStatus.BAD_REQUEST, "error.card-back-required"),
	CARD_FRONT_TOO_LONG(HttpStatus.BAD_REQUEST, "error.card-front-too-long"),
	CARD_BACK_TOO_LONG(HttpStatus.BAD_REQUEST, "error.card-back-too-long"),
	CARD_EXAMPLE_TOO_LONG(HttpStatus.BAD_REQUEST, "error.card-example-too-long"),
	CARD_HINT_TOO_LONG(HttpStatus.BAD_REQUEST, "error.card-hint-too-long"),
	CARD_PRONUNCIATION_TOO_LONG(HttpStatus.BAD_REQUEST, "error.card-pronunciation-too-long"),
	PARENT_HOLDS_CARDS(HttpStatus.CONFLICT, "error.parent-holds-cards"),
	DECK_DEPTH_EXCEEDED(HttpStatus.CONFLICT, "error.deck-depth-exceeded"),
	ROOT_CANNOT_HOLD_CARDS(HttpStatus.CONFLICT, "error.root-cannot-hold-cards"),
	DECK_HOLDS_CHILDREN(HttpStatus.CONFLICT, "error.deck-holds-children"),
	ROOT_SCHEDULER_INVALID(HttpStatus.CONFLICT, "error.root-scheduler-invalid"),
	DECK_NOT_FOUND(HttpStatus.NOT_FOUND, "error.deck-not-found"),
	DATA_INTEGRITY_VIOLATION(HttpStatus.CONFLICT, "error.data-integrity-violation"),
	INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "error.internal-server-error");

	private final HttpStatus status;
	private final String messageKey;
}
