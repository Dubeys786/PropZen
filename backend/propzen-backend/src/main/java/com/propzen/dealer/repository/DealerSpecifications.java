package com.propzen.dealer.repository;

import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public class DealerSpecifications {

    public static Specification<DealerProfile> withFilters(
            DealerStatus status,
            DealerVerificationStatus verificationStatus,
            String search) {

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (verificationStatus != null) {
                predicates.add(cb.equal(root.get("verificationStatus"), verificationStatus));
            }

            if (search != null && !search.trim().isEmpty()) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                Predicate businessNameLike = cb.like(cb.lower(root.get("businessName")), pattern);
                Predicate companyNameLike = cb.like(cb.lower(root.get("companyName")), pattern);
                Predicate emailLike = cb.like(cb.lower(root.get("email")), pattern);
                Predicate phoneLike = cb.like(cb.lower(root.get("phone")), pattern);

                predicates.add(cb.or(businessNameLike, companyNameLike, emailLike, phoneLike));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
