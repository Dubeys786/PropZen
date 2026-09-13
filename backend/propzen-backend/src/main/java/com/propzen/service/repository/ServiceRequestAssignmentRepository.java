package com.propzen.service.repository;

import com.propzen.service.entity.ServiceRequestAssignment;
import com.propzen.service.model.AssignmentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServiceRequestAssignmentRepository extends JpaRepository<ServiceRequestAssignment, UUID> {
    List<ServiceRequestAssignment> findByServiceRequestIdOrderByAssignedAtDesc(UUID serviceRequestId);
    List<ServiceRequestAssignment> findByPartnerIdOrderByAssignedAtDesc(UUID partnerId);
    Optional<ServiceRequestAssignment> findFirstByServiceRequestIdAndPartnerIdOrderByAssignedAtDesc(UUID serviceRequestId, UUID partnerId);
    long countByPartnerIdAndAssignmentStatus(UUID partnerId, AssignmentStatus status);
}
