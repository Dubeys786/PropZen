package com.propzen.service.repository;

import com.propzen.service.entity.ServiceDeliverable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ServiceDeliverableRepository extends JpaRepository<ServiceDeliverable, UUID> {

    List<ServiceDeliverable> findByServiceRequestIdOrderByCreatedAtDesc(UUID serviceRequestId);
}
