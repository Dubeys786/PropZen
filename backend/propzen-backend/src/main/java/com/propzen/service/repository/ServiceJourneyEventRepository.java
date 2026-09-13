package com.propzen.service.repository;

import com.propzen.service.entity.ServiceJourneyEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ServiceJourneyEventRepository extends JpaRepository<ServiceJourneyEvent, UUID> {
    List<ServiceJourneyEvent> findByServiceRequestIdOrderByCreatedAtAsc(UUID serviceRequestId);
}
