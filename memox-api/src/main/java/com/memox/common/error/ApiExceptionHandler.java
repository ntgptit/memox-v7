package com.memox.common.error;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

import org.slf4j.MDC;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import jakarta.validation.ConstraintViolationException;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

	private static final String REQUEST_ID_PROPERTY = "requestId";

	private final MessageSource messageSource;

	@Override
	protected ResponseEntity<Object> handleMethodArgumentNotValid(
			MethodArgumentNotValidException exception,
			HttpHeaders headers,
			HttpStatusCode status,
			WebRequest request) {
		final Map<String, String> fieldErrors = new LinkedHashMap<>();
		exception.getBindingResult().getFieldErrors().forEach(error ->
				fieldErrors.putIfAbsent(error.getField(), resolveFieldMessage(error)));
		return problem(ApiErrorCode.VALIDATION_FAILED, fieldErrors);
	}

	/**
	 * The one place a business refusal becomes a server-side record.
	 *
	 * <p>Every deck conflict — depth exceeded, parent holds cards, root cannot hold cards, invalid
	 * scheduler — and every 404 used to leave no trace at all: the service threw, this method
	 * answered, and nothing was written. WARN is the right level because these are the client's
	 * mistakes rather than the server's, and the message is the exception's own detail, which by
	 * construction is ids and codes.
	 */
	@ExceptionHandler(MemoxException.class)
	ResponseEntity<Object> handleMemoxException(MemoxException exception) {
		log.warn("Request refused by a business rule: {}", exception.getMessage());
		return problem(exception.getErrorCode(), Map.of());
	}

	/**
	 * A parameter Bean Validation cannot describe, reported in the same shape as one it can.
	 *
	 * <p>Without this, a bad {@code sort} token would answer with a bare VALIDATION_FAILED and the
	 * client would have to guess which parameter it was.
	 */
	@ExceptionHandler(ValidationFailedException.class)
	ResponseEntity<Object> handleValidationFailed(ValidationFailedException exception) {
		return problem(exception.getErrorCode(), Map.of(exception.getField(), exception.getReason()));
	}

	@ExceptionHandler(ConstraintViolationException.class)
	ResponseEntity<Object> handleConstraintViolation(ConstraintViolationException exception) {
		final Map<String, String> fieldErrors = new LinkedHashMap<>();
		exception.getConstraintViolations().forEach(violation -> {
			final var path = violation.getPropertyPath().toString();
			final var field = path.substring(path.lastIndexOf('.') + 1);
			fieldErrors.putIfAbsent(field, violation.getMessage());
		});
		return problem(ApiErrorCode.VALIDATION_FAILED, fieldErrors);
	}

	@ExceptionHandler(DataIntegrityViolationException.class)
	ResponseEntity<Object> handleDataIntegrityViolation(DataIntegrityViolationException exception) {
		log.warn("Database constraint rejected request: {}", exception.getClass().getSimpleName());
		return problem(ApiErrorCode.DATA_INTEGRITY_VIOLATION, Map.of());
	}

	@ExceptionHandler(Exception.class)
	ResponseEntity<Object> handleUnexpectedException(Exception exception) {
		log.error("Unhandled API exception: {}", exception.getClass().getSimpleName(), exception);
		return problem(ApiErrorCode.INTERNAL_SERVER_ERROR, Map.of());
	}

	private ResponseEntity<Object> problem(ApiErrorCode errorCode, Map<String, String> fieldErrors) {
		final var problem = ProblemDetail.forStatusAndDetail(errorCode.getStatus(), resolve(errorCode));
		problem.setType(URI.create("urn:memox:error:" + errorCode.name().toLowerCase(Locale.ROOT)));
		problem.setTitle(errorCode.getStatus().getReasonPhrase());
		problem.setProperty("code", errorCode.name());
		problem.setProperty(REQUEST_ID_PROPERTY, MDC.get(REQUEST_ID_PROPERTY));
		if (!fieldErrors.isEmpty()) {
			problem.setProperty("fieldErrors", fieldErrors);
		}
		return ResponseEntity.status(errorCode.getStatus()).body(problem);
	}

	private String resolveFieldMessage(FieldError error) {
		return messageSource.getMessage(error, LocaleContextHolder.getLocale());
	}

	private String resolve(ApiErrorCode errorCode) {
		return messageSource.getMessage(errorCode.getMessageKey(), null, LocaleContextHolder.getLocale());
	}
}
