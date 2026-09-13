package com.propzen.service.repository;

import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.ServiceRequestStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServiceRequestRepository extends JpaRepository<ServiceRequest, UUID>, JpaSpecificationExecutor<ServiceRequest> {
    Optional<ServiceRequest> findByServiceNumber(String serviceNumber);
    Page<ServiceRequest> findByCustomerIdOrderByCreatedAtDesc(UUID customerId, Pageable pageable);
    Page<ServiceRequest> findByPartnerIdOrderByCreatedAtDesc(UUID partnerId, Pageable pageable);
    List<ServiceRequest> findByPartnerId(UUID partnerId);

    long countByPartnerId(UUID partnerId);
    long countByPartnerIdAndStatus(UUID partnerId, ServiceRequestStatus status);
    long countByPartnerIdAndStatusIn(UUID partnerId, Collection<ServiceRequestStatus> statuses);

    long countByStatus(ServiceRequestStatus status);
    long countByStatusIn(Collection<ServiceRequestStatus> statuses);

    @Query("SELECT COUNT(DISTINCT r.customerId) FROM ServiceRequest r WHERE r.partnerId = :partnerId")
    long countDistinctCustomersByPartnerId(@Param("partnerId") UUID partnerId);

    @Query("SELECT DISTINCT r.customerId FROM ServiceRequest r WHERE r.partnerId = :partnerId")
    List<UUID> findDistinctCustomerIdsByPartnerId(@Param("partnerId") UUID partnerId);
}
