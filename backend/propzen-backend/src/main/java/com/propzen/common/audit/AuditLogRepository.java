package com.propzen.common.audit;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {

    List<AuditLog> findByActorIdOrderByTimestampDesc(UUID actorId);

    Page<AuditLog> findByAction(String action, Pageable pageable);

    long countByAction(String action);
}
