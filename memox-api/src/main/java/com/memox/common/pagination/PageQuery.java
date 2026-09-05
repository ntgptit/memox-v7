package com.memox.common.pagination;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import lombok.Builder;
import lombok.Value;

@Value
@Builder(toBuilder = true)
public class PageQuery {

	@Builder.Default
	@Min(PaginationConstants.MIN_LIMIT)
	@Max(PaginationConstants.MAX_LIMIT)
	int limit = PaginationConstants.DEFAULT_LIMIT;

	@Builder.Default
	@Min(PaginationConstants.MIN_OFFSET)
	int offset = PaginationConstants.MIN_OFFSET;
}
