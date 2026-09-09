package com.memox.common.config;

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

	@Min(PaginationConstants.MIN_PAGE)
	private int defaultPage = PaginationConstants.DEFAULT_PAGE;

	@Min(PaginationConstants.MIN_SIZE)
	@Max(PaginationConstants.MAX_SIZE)
	private int defaultSize = PaginationConstants.DEFAULT_SIZE;
}
