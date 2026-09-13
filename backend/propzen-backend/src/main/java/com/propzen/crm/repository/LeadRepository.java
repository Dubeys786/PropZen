package com.propzen.crm.repository;

import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LeadRepository extends JpaRepository<Lead, UUID>, JpaSpecificationExecutor<Lead> {

    Optional<Lead> findByLeadNumber(String leadNumber);

    Optional<Lead> findFirstByPhoneAndPropertyIdAndStatusNotIn(
            String phone, String propertyId, Collection<LeadStatus> excludedStatuses);

    Optional<Lead> findFirstByUserIdAndPropertyIdAndStatusNotIn(
            UUID userId, String propertyId, Collection<LeadStatus> excludedStatuses);

    List<Lead> findByAssignedTo(UUID assignedTo);

    List<Lead> findByDealerId(UUID dealerId);

    Optional<Lead> findFirstByPhoneOrderByCreatedAtDesc(String phone);

    Optional<Lead> findFirstByEmailOrderByCreatedAtDesc(String email);

    Optional<Lead> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);

    List<Lead> findByPhone(String phone);

    List<Lead> findByEmail(String email);

    List<Lead> findByUserId(UUID userId);

    long countByStatus(LeadStatus status);

    long countByStage(com.propzen.crm.model.LeadStage stage);

    long countByStatusIn(Collection<LeadStatus> statuses);

    @Query("SELECT COUNT(l) FROM Lead l WHERE l.nextFollowUpAt <= :cutoff " +
           "AND l.status NOT IN :excludedStatuses")
    long countFollowUpsDue(
            @Param("cutoff") OffsetDateTime cutoff,
            @Param("excludedStatuses") Collection<LeadStatus> excludedStatuses);

    @Query("SELECT COUNT(l) FROM Lead l WHERE l.dealerId = :dealerId AND l.status = :status")
    long countByDealerIdAndStatus(@Param("dealerId") UUID dealerId, @Param("status") LeadStatus status);

    @Query("SELECT COUNT(l) FROM Lead l WHERE l.dealerId = :dealerId")
    long countByDealerId(@Param("dealerId") UUID dealerId);

    long countByAssignedTo(UUID assignedTo);

    long countByAssignedToAndStatus(UUID assignedTo, LeadStatus status);

    List<Lead> findByAssignedPartnerId(UUID assignedPartnerId);

    long countByAssignedPartnerId(UUID assignedPartnerId);

    long countByAssignedPartnerIdAndStatus(UUID assignedPartnerId, LeadStatus status);

    List<Lead> findByServiceCategory(String serviceCategory);

    long countByAssignmentStatus(String assignmentStatus);
}
