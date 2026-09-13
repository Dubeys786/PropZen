package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmTask;
import com.propzen.crm.model.TaskStatus;
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
public interface CrmTaskRepository extends JpaRepository<CrmTask, UUID> {

    List<CrmTask> findByAssignedToOrderByDueAtAsc(UUID assignedTo);

    Page<CrmTask> findByAssignedToOrderByDueAtAsc(UUID assignedTo, Pageable pageable);

    List<CrmTask> findByLeadIdOrderByCreatedAtDesc(UUID leadId);

    List<CrmTask> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    @Query("SELECT t FROM CrmTask t WHERE t.status != 'COMPLETED' AND t.status != 'CANCELLED' AND t.dueAt <= :cutoff ORDER BY t.dueAt ASC")
    List<CrmTask> findOverdueTasks(@Param("cutoff") OffsetDateTime cutoff);

    long countByStatus(TaskStatus status);

    long countByAssignedToAndStatus(UUID assignedTo, TaskStatus status);
}
