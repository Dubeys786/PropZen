package com.propzen.verification.repository;

import com.propzen.verification.entity.PropertyVerificationCase;
import com.propzen.verification.model.VerificationCaseStatus;
import com.propzen.verification.model.VerificationRiskLevel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PropertyVerificationCaseRepository extends JpaRepository<PropertyVerificationCase, UUID>, JpaSpecificationExecutor<PropertyVerificationCase> {

    Optional<PropertyVerificationCase> findByCaseNumber(String caseNumber);

    long countByStatus(VerificationCaseStatus status);

    long countByRiskLevel(VerificationRiskLevel riskLevel);
}
