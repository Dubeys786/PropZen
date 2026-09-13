package com.propzen.verification.repository;

import com.propzen.verification.entity.PropertyVerificationDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PropertyVerificationDocumentRepository extends JpaRepository<PropertyVerificationDocument, UUID> {

    List<PropertyVerificationDocument> findByVerificationCaseId(UUID caseId);
}
