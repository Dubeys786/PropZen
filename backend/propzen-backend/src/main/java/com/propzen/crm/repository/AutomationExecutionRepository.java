package com.propzen.crm.repository;

import com.propzen.crm.entity.AutomationExecution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AutomationExecutionRepository extends JpaRepository<AutomationExecution, UUID> {
    List<AutomationExecution> findByLeadId(UUID leadId);
}
