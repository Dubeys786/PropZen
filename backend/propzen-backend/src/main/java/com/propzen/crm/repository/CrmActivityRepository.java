package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmActivity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CrmActivityRepository extends JpaRepository<CrmActivity, UUID> {

    List<CrmActivity> findByLeadIdOrderByCreatedAtDesc(UUID leadId);

    Page<CrmActivity> findByLeadIdOrderByCreatedAtDesc(UUID leadId, Pageable pageable);

    List<CrmActivity> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    Page<CrmActivity> findByCustomerIdOrderByCreatedAtDesc(UUID customerId, Pageable pageable);

    long countByLeadId(UUID leadId);
}
