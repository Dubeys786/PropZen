package com.propzen.property.repository;

import com.propzen.property.entity.Property;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Composable JPA specifications for database-level property search and filtering.
 */
public final class PropertySpecifications {

    private PropertySpecifications() {
    }

    public static Specification<Property> withDynamicFilters(
            String q,
            String city,
            String sector,
            String locality,
            String propertyType,
            List<String> bhkList,
            BigDecimal minPriceCr,
            BigDecimal maxPriceCr,
            Integer minSqft,
            Integer maxSqft,
            List<String> amenities,
            String status,
            UUID dealerId
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // 1. Status Filter
            if (status != null && !status.isBlank()) {
                if ("PUBLISHED".equalsIgnoreCase(status)) {
                    // Match PUBLISHED or legacy lowercase published / active
                    predicates.add(cb.or(
                            cb.equal(cb.upper(root.get("status")), "PUBLISHED"),
                            cb.equal(cb.upper(root.get("status")), "ACTIVE")
                    ));
                } else {
                    predicates.add(cb.equal(cb.upper(root.get("status")), status.trim().toUpperCase(Locale.ROOT)));
                }
            }

            // 2. Dealer Isolation Filter
            if (dealerId != null) {
                predicates.add(cb.equal(root.get("dealerId"), dealerId));
            }

            // 3. Location: City (Exact case-insensitive match)
            if (city != null && !city.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("city")), city.trim().toLowerCase(Locale.ROOT)));
            }

            // 4. Location: Sector (Exact case-insensitive match)
            if (sector != null && !sector.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("sector")), sector.trim().toLowerCase(Locale.ROOT)));
            }

            // 5. Location: Locality
            if (locality != null && !locality.isBlank()) {
                predicates.add(cb.like(cb.lower(root.get("locality")), "%" + locality.trim().toLowerCase(Locale.ROOT) + "%"));
            }

            // 6. Property Type (Case-insensitive match)
            if (propertyType != null && !propertyType.isBlank()) {
                predicates.add(cb.equal(cb.lower(root.get("propertyType")), propertyType.trim().toLowerCase(Locale.ROOT)));
            }

            // 7. BHK Filter (Accurate numeric matching - never matches 3 with 13 BHK)
            if (bhkList != null && !bhkList.isEmpty()) {
                List<Predicate> bhkPredicates = new ArrayList<>();
                for (String rawBhk : bhkList) {
                    if (rawBhk == null || rawBhk.isBlank()) continue;
                    String clean = rawBhk.trim().toLowerCase(Locale.ROOT);
                    // Extract leading digits if any, e.g. "3 BHK" -> "3", or "3" -> "3"
                    String digitsOnly = clean.replaceAll("[^0-9]", "");
                    if (!digitsOnly.isEmpty()) {
                        String numStr = digitsOnly;
                        // Matches exact digit, or "N BHK", "NBHK", "N-BHK"
                        bhkPredicates.add(cb.equal(cb.trim(cb.lower(root.get("bhk"))), numStr));
                        bhkPredicates.add(cb.equal(cb.trim(cb.lower(root.get("bhk"))), numStr + " bhk"));
                        bhkPredicates.add(cb.equal(cb.trim(cb.lower(root.get("bhk"))), numStr + "bhk"));
                        bhkPredicates.add(cb.equal(cb.trim(cb.lower(root.get("bhk"))), numStr + "-bhk"));
                    } else {
                        bhkPredicates.add(cb.equal(cb.trim(cb.lower(root.get("bhk"))), clean));
                    }
                }
                if (!bhkPredicates.isEmpty()) {
                    predicates.add(cb.or(bhkPredicates.toArray(new Predicate[0])));
                }
            }

            // 8. Budget / Price Range (price_cr)
            if (minPriceCr != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("priceCr"), minPriceCr));
            }
            if (maxPriceCr != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("priceCr"), maxPriceCr));
            }

            // 9. Area / Sqft Range
            if (minSqft != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("sqft"), minSqft));
            }
            if (maxSqft != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("sqft"), maxSqft));
            }

            // 10. Amenities Filter (Each selected amenity must be present)
            if (amenities != null && !amenities.isEmpty()) {
                for (String amenity : amenities) {
                    if (amenity != null && !amenity.isBlank()) {
                        predicates.add(cb.like(
                                cb.lower(root.get("amenities")),
                                "%" + amenity.trim().toLowerCase(Locale.ROOT) + "%"
                        ));
                    }
                }
            }

            // 11. Search Text (q) across multiple text columns
            if (q != null && !q.isBlank()) {
                String searchPattern = "%" + q.trim().toLowerCase(Locale.ROOT) + "%";
                Predicate qTitle = cb.like(cb.lower(root.get("title")), searchPattern);
                Predicate qCity = cb.like(cb.lower(root.get("city")), searchPattern);
                Predicate qSector = cb.like(cb.lower(root.get("sector")), searchPattern);
                Predicate qLocality = cb.like(cb.lower(root.get("locality")), searchPattern);
                Predicate qType = cb.like(cb.lower(root.get("propertyType")), searchPattern);

                predicates.add(cb.or(qTitle, qCity, qSector, qLocality, qType));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
