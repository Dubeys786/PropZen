package com.propzen.service.repository;

import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class ServicePartnerSpecifications {

    public static Specification<ServicePartnerProfile> withFilters(
            PartnerStatus status,
            PartnerVerificationStatus verificationStatus,
            String city,
            String search,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null) {
                predicates.add(cb.equal(root.get("partnerStatus"), status));
            }

            if (verificationStatus != null) {
                predicates.add(cb.equal(root.get("verificationStatus"), verificationStatus));
            }

            if (city != null && !city.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("city")), city.trim().toLowerCase()));
            }

            if (search != null && !search.isBlank()) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                Predicate bName = cb.like(cb.lower(root.get("businessName")), pattern);
                Predicate cName = cb.like(cb.lower(root.get("companyName")), pattern);
                Predicate dName = cb.like(cb.lower(root.get("displayName")), pattern);
                Predicate email = cb.like(cb.lower(root.get("email")), pattern);
                Predicate phone = cb.like(cb.lower(root.get("phone")), pattern);
                predicates.add(cb.or(bName, cName, dName, email, phone));
            }

            if (createdAfter != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), createdAfter));
            }

            if (createdBefore != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), createdBefore));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
