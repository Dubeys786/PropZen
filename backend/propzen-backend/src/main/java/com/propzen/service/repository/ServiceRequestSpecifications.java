package com.propzen.service.repository;

import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.ServicePriority;
import com.propzen.service.model.ServiceRequestStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class ServiceRequestSpecifications {

    public static Specification<ServiceRequest> withFilters(
            UUID categoryId,
            ServiceRequestStatus status,
            ServicePriority priority,
            UUID partnerId,
            UUID customerId,
            String location,
            String search,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (categoryId != null) {
                predicates.add(cb.equal(root.get("serviceCategoryId"), categoryId));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (priority != null) {
                predicates.add(cb.equal(root.get("priority"), priority));
            }

            if (partnerId != null) {
                predicates.add(cb.equal(root.get("partnerId"), partnerId));
            }

            if (customerId != null) {
                predicates.add(cb.equal(root.get("customerId"), customerId));
            }

            if (location != null && !location.isBlank()) {
                predicates.add(cb.like(cb.lower(root.get("location")), "%" + location.trim().toLowerCase() + "%"));
            }

            if (search != null && !search.isBlank()) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                Predicate num = cb.like(cb.lower(root.get("serviceNumber")), pattern);
                Predicate title = cb.like(cb.lower(root.get("title")), pattern);
                Predicate desc = cb.like(cb.lower(root.get("description")), pattern);
                predicates.add(cb.or(num, title, desc));
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
