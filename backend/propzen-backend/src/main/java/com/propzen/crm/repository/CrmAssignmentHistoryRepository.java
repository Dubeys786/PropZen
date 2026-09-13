package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmAssignmentHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CrmAssignmentHistoryRepository extends JpaRepository<CrmAssignmentHistory, UUID> {

    List<CrmAssignmentHistory> findByLeadIdOrderByCreatedAtDesc(UUID leadId);
}
