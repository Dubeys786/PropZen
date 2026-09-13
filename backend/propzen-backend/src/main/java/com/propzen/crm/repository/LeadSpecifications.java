package com.propzen.crm.repository;

import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Composable JPA specifications for CRM lead queries.
 */
public final class LeadSpecifications {

    private LeadSpecifications() {
    }

    public static Specification<Lead> withFilters(
            String q,
            LeadStatus status,
            LeadPriority priority,
            LeadSource source,
            UUID assignedTo,
            UUID dealerId,
            String city,
            String sector,
            String propertyId,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore
    ) {
        return withFilters(q, status, null, null, priority, source, assignedTo, dealerId, city, sector, propertyId, createdAfter, createdBefore, null, null, null);
    }

    public static Specification<Lead> withFilters(
            String q,
            LeadStatus status,
            LeadPriority priority,
            LeadSource source,
            UUID assignedTo,
            UUID dealerId,
            String city,
            String sector,
            String propertyId,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore,
            String serviceCategory,
            UUID assignedPartnerId,
            String assignmentStatus
    ) {
        return withFilters(q, status, null, null, priority, source, assignedTo, dealerId, city, sector, propertyId, createdAfter, createdBefore, serviceCategory, assignedPartnerId, assignmentStatus);
    }

    public static Specification<Lead> withFilters(
            String q,
            LeadStatus status,
            com.propzen.crm.model.LeadStage stage,
            com.propzen.crm.model.LeadType leadType,
            LeadPriority priority,
            LeadSource source,
            UUID assignedTo,
            UUID dealerId,
            String city,
            String sector,
            String propertyId,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore
    ) {
        return withFilters(q, status, stage, leadType, priority, source, assignedTo, dealerId, city, sector, propertyId, createdAfter, createdBefore, null, null, null);
    }

    public static Specification<Lead> withFilters(
            String q,
            LeadStatus status,
            com.propzen.crm.model.LeadStage stage,
            com.propzen.crm.model.LeadType leadType,
            LeadPriority priority,
            LeadSource source,
            UUID assignedTo,
            UUID dealerId,
            String city,
            String sector,
            String propertyId,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore,
            String serviceCategory,
            UUID assignedPartnerId,
            String assignmentStatus
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (stage != null) {
                predicates.add(cb.equal(root.get("stage"), stage));
            }
            if (leadType != null) {
                predicates.add(cb.equal(root.get("leadType"), leadType));
            }
            if (priority != null) {
                predicates.add(cb.equal(root.get("priority"), priority));
            }
            if (source != null) {
                predicates.add(cb.equal(root.get("source"), source));
            }
            if (assignedTo != null) {
                predicates.add(cb.equal(root.get("assignedTo"), assignedTo));
            }
            if (dealerId != null) {
                predicates.add(cb.equal(root.get("dealerId"), dealerId));
            }
            if (propertyId != null && !propertyId.isBlank()) {
                predicates.add(cb.equal(root.get("propertyId"), propertyId.trim()));
            }
            if (city != null && !city.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("preferredCity")), city.trim().toLowerCase(Locale.ROOT)));
            }
            if (sector != null && !sector.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("preferredSector")), sector.trim().toLowerCase(Locale.ROOT)));
            }
            if (createdAfter != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), createdAfter));
            }
            if (createdBefore != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), createdBefore));
            }
            if (serviceCategory != null && !serviceCategory.isBlank()) {
                predicates.add(cb.equal(cb.upper(root.get("serviceCategory")), serviceCategory.trim().toUpperCase(Locale.ROOT)));
            }
            if (assignedPartnerId != null) {
                predicates.add(cb.equal(root.get("assignedPartnerId"), assignedPartnerId));
            }
            if (assignmentStatus != null && !assignmentStatus.isBlank()) {
                predicates.add(cb.equal(cb.upper(root.get("assignmentStatus")), assignmentStatus.trim().toUpperCase(Locale.ROOT)));
            }
            if (q != null && !q.isBlank()) {
                String searchPattern = "%" + q.trim().toLowerCase(Locale.ROOT) + "%";
                Predicate qName = cb.like(cb.lower(root.get("name")), searchPattern);
                Predicate qEmail = cb.like(cb.lower(root.get("email")), searchPattern);
                Predicate qPhone = cb.like(cb.lower(root.get("phone")), searchPattern);
                Predicate qLeadNo = cb.like(cb.lower(root.get("leadNumber")), searchPattern);

                predicates.add(cb.or(qName, qEmail, qPhone, qLeadNo));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
