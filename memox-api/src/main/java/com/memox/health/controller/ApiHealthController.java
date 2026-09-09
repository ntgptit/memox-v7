package com.memox.health.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.memox.health.dto.response.ApiHealthResponse;

@RestController
@RequestMapping("/api/v1/health")
public class ApiHealthController {

	private static final String UP_STATUS = "UP";

	@GetMapping
	public ResponseEntity<ApiHealthResponse> readHealth() {
		return ResponseEntity.ok(new ApiHealthResponse(UP_STATUS));
	}
}
