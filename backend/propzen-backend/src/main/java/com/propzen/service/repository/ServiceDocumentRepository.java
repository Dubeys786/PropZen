package com.propzen.service.repository;

import com.propzen.service.entity.ServiceDocument;
import com.propzen.service.model.DocumentVerificationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ServiceDocumentRepository extends JpaRepository<ServiceDocument, UUID> {
    List<ServiceDocument> findByServiceRequestIdOrderByUploadedAtDesc(UUID serviceRequestId);
    long countByServiceRequestIdAndVerificationStatus(UUID serviceRequestId, DocumentVerificationStatus status);
}
