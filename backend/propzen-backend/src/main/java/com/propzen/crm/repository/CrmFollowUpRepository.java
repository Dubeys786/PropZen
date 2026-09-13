package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmFollowUp;
import com.propzen.crm.model.FollowUpStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface CrmFollowUpRepository extends JpaRepository<CrmFollowUp, UUID> {

    List<CrmFollowUp> findByLeadIdOrderByFollowupAtAsc(UUID leadId);

    Page<CrmFollowUp> findByLeadIdOrderByFollowupAtAsc(UUID leadId, Pageable pageable);

    List<CrmFollowUp> findByAssignedToOrderByFollowupAtAsc(UUID assignedTo);

    Page<CrmFollowUp> findByAssignedToOrderByFollowupAtAsc(UUID assignedTo, Pageable pageable);

    List<CrmFollowUp> findByStatusOrderByFollowupAtAsc(FollowUpStatus status);

    @Query("SELECT f FROM CrmFollowUp f WHERE f.status = 'PENDING' AND f.followupAt <= :cutoff ORDER BY f.followupAt ASC")
    List<CrmFollowUp> findPendingDueFollowUps(@Param("cutoff") OffsetDateTime cutoff);

    @Query("SELECT COUNT(f) FROM CrmFollowUp f WHERE f.status = 'PENDING' AND f.followupAt <= :cutoff")
    long countPendingDueFollowUps(@Param("cutoff") OffsetDateTime cutoff);

    long countByStatus(FollowUpStatus status);
}
