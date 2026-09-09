package com.memox.common.pagination;

import lombok.experimental.UtilityClass;

@UtilityClass
public class PaginationConstants {

	/** Pages are zero-based, as `pagination-contract.md` specifies for a project with no prior standard. */
	public static final int MIN_PAGE = 0;
	public static final int DEFAULT_PAGE = 0;
	public static final int DEFAULT_SIZE = 50;
	public static final int MIN_SIZE = 1;
	public static final int MAX_SIZE = 100;
}
