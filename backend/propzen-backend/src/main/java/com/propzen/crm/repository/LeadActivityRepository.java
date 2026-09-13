package com.propzen.crm.repository;

import com.propzen.crm.entity.LeadActivity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LeadActivityRepository extends JpaRepository<LeadActivity, UUID> {
    List<LeadActivity> findByLeadIdOrderByCreatedAtDesc(UUID leadId);
    List<LeadActivity> findByLeadIdOrderByScheduledAtAsc(UUID leadId);
}
