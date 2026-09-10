package com.memox.trash.dto.response;

import com.memox.trash.service.PurgeReport;

/**
 * What one retention sweep did.
 *
 * <p>{@code skippedBatches} is not a failure count: a batch whose cascade would reach a row the
 * sweep may not remove is left whole and tried again next time (BR-265).
 */
public record PurgeReportResponse(int purgedBatches, int skippedBatches) {

	public static PurgeReportResponse from(PurgeReport report) {
		return new PurgeReportResponse(report.purgedBatches(), report.skippedBatches());
	}
}
