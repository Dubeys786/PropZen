package com.propzen.crm.repository;

import com.propzen.crm.entity.Enquiry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EnquiryRepository extends JpaRepository<Enquiry, UUID> {
    List<Enquiry> findByPropertyId(String propertyId);
    List<Enquiry> findByUserPhone(String userPhone);
    List<Enquiry> findByUserId(UUID userId);
    List<Enquiry> findByDealerId(UUID dealerId);
}
