package com.propzen.ai.repository;

import com.propzen.ai.entity.AiUsageLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AiUsageLogRepository extends JpaRepository<AiUsageLog, UUID> {

    List<AiUsageLog> findByUserIdOrderByCreatedAtDesc(UUID userId);

    long countByUserIdAndCreatedAtAfter(UUID userId, OffsetDateTime after);

    long countByCreatedAtAfter(OffsetDateTime after);

    @Query("SELECT COUNT(a) FROM AiUsageLog a WHERE a.status = 'SUCCESS'")
    long countSuccessfulRequests();

    @Query("SELECT COUNT(a) FROM AiUsageLog a WHERE a.status = 'FAILED'")
    long countFailedRequests();

    @Query("SELECT COUNT(a) FROM AiUsageLog a WHERE a.fallbackUsed = true")
    long countFallbackRequests();

    @Query("SELECT COALESCE(AVG(a.latencyMs), 0.0) FROM AiUsageLog a")
    Double getAverageLatencyMs();

    @Query("SELECT COALESCE(SUM(a.tokensUsed), 0) FROM AiUsageLog a")
    Long getTotalTokensUsed();
}
