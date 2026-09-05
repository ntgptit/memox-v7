package com.memox.exception;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import jakarta.validation.ConstraintViolationException;

@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

	@Override
	protected ResponseEntity<Object> handleMethodArgumentNotValid(
			MethodArgumentNotValidException exception,
			HttpHeaders headers,
			HttpStatusCode status,
			WebRequest request) {
		final Map<String, String> fieldErrors = new LinkedHashMap<>();
		exception.getBindingResult().getFieldErrors().forEach(error ->
				fieldErrors.putIfAbsent(error.getField(), error.getDefaultMessage()));
		return problem(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "Request validation failed.", fieldErrors);
	}

	@ExceptionHandler(DeckValidationException.class)
	ResponseEntity<Object> handleDeckValidation(DeckValidationException exception) {
		return problem(HttpStatus.BAD_REQUEST, exception.getCode(), exception.getMessage(),
				Map.of(exception.getField(), exception.getMessage()));
	}

	@ExceptionHandler(ConstraintViolationException.class)
	ResponseEntity<Object> handleConstraintViolation(ConstraintViolationException exception) {
		final Map<String, String> fieldErrors = new LinkedHashMap<>();
		exception.getConstraintViolations().forEach(violation -> {
			final var path = violation.getPropertyPath().toString();
			final var field = path.substring(path.lastIndexOf('.') + 1);
			fieldErrors.putIfAbsent(field, violation.getMessage());
		});
		return problem(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "Request validation failed.", fieldErrors);
	}

	@ExceptionHandler(DeckConflictException.class)
	ResponseEntity<Object> handleDeckConflict(DeckConflictException exception) {
		return problem(HttpStatus.CONFLICT, exception.getCode(), exception.getMessage(), Map.of());
	}

	@ExceptionHandler(DeckNotFoundException.class)
	ResponseEntity<Object> handleDeckNotFound(DeckNotFoundException exception) {
		return problem(HttpStatus.NOT_FOUND, "DECK_NOT_FOUND", exception.getMessage(), Map.of());
	}

	private ResponseEntity<Object> problem(
			HttpStatus status,
			String code,
			String detail,
			Map<String, String> fieldErrors) {
		final var problem = ProblemDetail.forStatusAndDetail(status, detail);
		problem.setType(URI.create("urn:memox:error:" + code.toLowerCase()));
		problem.setTitle(status.getReasonPhrase());
		problem.setProperty("code", code);
		if (!fieldErrors.isEmpty()) {
			problem.setProperty("fieldErrors", fieldErrors);
		}
		return ResponseEntity.status(status).body(problem);
	}
}
