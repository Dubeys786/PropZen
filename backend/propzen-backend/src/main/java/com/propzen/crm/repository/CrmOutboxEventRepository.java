package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmOutboxEvent;
import com.propzen.crm.model.OutboxStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface CrmOutboxEventRepository extends JpaRepository<CrmOutboxEvent, UUID> {

    @Query("SELECT e FROM CrmOutboxEvent e WHERE e.status = :status AND e.availableAt <= :now ORDER BY e.availableAt ASC")
    List<CrmOutboxEvent> findProcessableEvents(
            @Param("status") OutboxStatus status,
            @Param("now") OffsetDateTime now,
            Pageable pageable);

    long countByStatus(OutboxStatus status);
}
