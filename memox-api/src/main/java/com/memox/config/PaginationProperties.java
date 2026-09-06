package com.memox.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import com.memox.common.pagination.PaginationConstants;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "memox.pagination")
public class PaginationProperties {

	@Min(PaginationConstants.MIN_LIMIT)
	@Max(PaginationConstants.MAX_LIMIT)
	private int defaultLimit = PaginationConstants.DEFAULT_LIMIT;

	@Min(PaginationConstants.MIN_OFFSET)
	private int defaultOffset = PaginationConstants.MIN_OFFSET;
}
