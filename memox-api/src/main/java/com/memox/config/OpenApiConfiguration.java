package com.memox.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class OpenApiConfiguration {

	@Bean
	OpenAPI memoxOpenApi() {
		return new OpenAPI().info(new Info()
				.title("MemoX API")
				.version("v1")
				.description("Standalone MemoX backend API. Authentication and sync are not enabled yet."));
	}
}
