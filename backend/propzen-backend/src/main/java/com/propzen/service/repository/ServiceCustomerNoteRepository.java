package com.propzen.service.repository;

import com.propzen.service.entity.ServiceCustomerNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ServiceCustomerNoteRepository extends JpaRepository<ServiceCustomerNote, UUID> {
    List<ServiceCustomerNote> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);
    List<ServiceCustomerNote> findByCustomerIdAndPartnerIdOrderByCreatedAtDesc(UUID customerId, UUID partnerId);
}
