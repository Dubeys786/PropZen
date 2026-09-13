package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmNote;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CrmNoteRepository extends JpaRepository<CrmNote, UUID> {

    List<CrmNote> findByLeadIdOrderByCreatedAtDesc(UUID leadId);

    Page<CrmNote> findByLeadIdOrderByCreatedAtDesc(UUID leadId, Pageable pageable);

    List<CrmNote> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    Page<CrmNote> findByCustomerIdOrderByCreatedAtDesc(UUID customerId, Pageable pageable);

    long countByLeadId(UUID leadId);
}
