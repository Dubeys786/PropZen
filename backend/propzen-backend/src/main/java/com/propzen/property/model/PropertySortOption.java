package com.propzen.property.model;

import org.springframework.data.domain.Sort;

import java.util.Locale;

/**
 * Whitelisted safe sorting options preventing SQL injection.
 */
public enum PropertySortOption {
    NEWEST(Sort.by(Sort.Direction.DESC, "createdAt")),
    OLDEST(Sort.by(Sort.Direction.ASC, "createdAt")),
    PRICE_LOW(Sort.by(Sort.Direction.ASC, "priceCr")),
    PRICE_HIGH(Sort.by(Sort.Direction.DESC, "priceCr")),
    AREA_LOW(Sort.by(Sort.Direction.ASC, "sqft")),
    AREA_HIGH(Sort.by(Sort.Direction.DESC, "sqft"));

    private final Sort sort;

    PropertySortOption(Sort sort) {
        this.sort = sort;
    }

    public Sort getSort() {
        return sort;
    }

    public static PropertySortOption fromString(String value) {
        if (value == null || value.isBlank()) {
            return NEWEST;
        }
        String normalized = value.trim().toLowerCase(Locale.ROOT);
        switch (normalized) {
            case "price_low":
            case "pricelow":
            case "price_asc":
                return PRICE_LOW;
            case "price_high":
            case "pricehigh":
            case "price_desc":
                return PRICE_HIGH;
            case "oldest":
            case "date_asc":
                return OLDEST;
            case "area_low":
            case "arealow":
            case "sqft_asc":
                return AREA_LOW;
            case "area_high":
            case "areahigh":
            case "sqft_desc":
                return AREA_HIGH;
            case "newest":
            case "date_desc":
            default:
                return NEWEST;
        }
    }
}
