package com.propzen.crm.repository;

import com.propzen.crm.entity.SiteVisit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SiteVisitRepository extends JpaRepository<SiteVisit, UUID> {
    List<SiteVisit> findByPropertyId(String propertyId);
    List<SiteVisit> findByUserPhone(String userPhone);
    List<SiteVisit> findByUserId(UUID userId);
    List<SiteVisit> findByDealerId(UUID dealerId);
    long countByStatus(String status);
}
