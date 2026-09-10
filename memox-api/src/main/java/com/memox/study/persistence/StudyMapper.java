package com.memox.study.persistence;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.study.enums.StudySessionEndReason;
import com.memox.study.enums.StudySessionStatus;

/** The two lookups and the one write BR-259 needs. Everything else about sessions is Phase 3. */
@Mapper
public interface StudyMapper {

	List<String> findOpenSessionIdsForDecks(@Param("deckIds") Collection<String> deckIds);

	List<String> findOpenSessionIdsForCards(@Param("cardIds") Collection<String> cardIds);

	int invalidateSessions(
			@Param("sessionIds") Collection<String> sessionIds,
			@Param("status") StudySessionStatus status,
			@Param("endReason") StudySessionEndReason endReason,
			@Param("endedAt") Instant endedAt);
}
