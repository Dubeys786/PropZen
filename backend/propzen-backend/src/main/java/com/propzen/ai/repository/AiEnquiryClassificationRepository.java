package com.propzen.ai.repository;

import com.propzen.ai.entity.AiEnquiryClassification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiEnquiryClassificationRepository extends JpaRepository<AiEnquiryClassification, UUID> {

    Optional<AiEnquiryClassification> findByEnquiryId(UUID enquiryId);
}
