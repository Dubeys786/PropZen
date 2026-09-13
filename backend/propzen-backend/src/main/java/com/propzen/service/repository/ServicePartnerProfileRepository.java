package com.propzen.service.repository;

import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServicePartnerProfileRepository extends JpaRepository<ServicePartnerProfile, UUID>, JpaSpecificationExecutor<ServicePartnerProfile> {
    Optional<ServicePartnerProfile> findByUserId(UUID userId);
    boolean existsByUserId(UUID userId);
    List<ServicePartnerProfile> findByPartnerStatusAndVerificationStatus(PartnerStatus partnerStatus, PartnerVerificationStatus verificationStatus);
    long countByPartnerStatus(PartnerStatus partnerStatus);
    long countByVerificationStatus(PartnerVerificationStatus verificationStatus);
}
