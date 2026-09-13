package com.propzen.ai.repository;

import com.propzen.ai.entity.AiLeadScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiLeadScoreRepository extends JpaRepository<AiLeadScore, UUID> {

    Optional<AiLeadScore> findTopByLeadIdOrderByScoredAtDesc(UUID leadId);

    Optional<AiLeadScore> findByLeadId(UUID leadId);
}
