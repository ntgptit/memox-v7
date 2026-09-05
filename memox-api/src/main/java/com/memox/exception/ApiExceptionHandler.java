package com.memox.exception;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@ControllerAdvice
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
