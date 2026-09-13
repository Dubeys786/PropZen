package com.propzen.service.repository;

import com.propzen.service.entity.ServiceMilestone;
import com.propzen.service.model.MilestoneStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ServiceMilestoneRepository extends JpaRepository<ServiceMilestone, UUID> {
    List<ServiceMilestone> findByServiceRequestIdOrderBySequenceNumberAsc(UUID serviceRequestId);
    long countByServiceRequestId(UUID serviceRequestId);
    long countByServiceRequestIdAndStatus(UUID serviceRequestId, MilestoneStatus status);
}
