package com.propzen.property.dto;

import com.propzen.exception.BadRequestException;
import com.propzen.property.model.PropertySortOption;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Filter and search parameters for properties.
 */
public class PropertySearchRequest {

    private String q;
    private String city;
    private String sector;
    private String locality;
    private String propertyType;
    private String bhk;
    private BigDecimal minPrice;
    private BigDecimal maxPrice;
    private BigDecimal minPriceCr;
    private BigDecimal maxPriceCr;
    private Integer minSqft;
    private Integer maxSqft;
    private String amenities;
    private String status;
    private String sort = "newest";
    private Integer page = 0;
    private Integer size = 20;

    public PropertySearchRequest() {
    }

    public void validate() {
        if (page != null && page < 0) {
            throw new BadRequestException("Page index cannot be negative");
        }
        if (size != null && (size < 1 || size > 100)) {
            throw new BadRequestException("Page size must be between 1 and 100");
        }

        BigDecimal effectiveMinCr = getEffectiveMinPriceCr();
        BigDecimal effectiveMaxCr = getEffectiveMaxPriceCr();
        if (effectiveMinCr != null && effectiveMaxCr != null && effectiveMinCr.compareTo(effectiveMaxCr) > 0) {
            throw new BadRequestException("Minimum price cannot exceed maximum price");
        }

        if (minSqft != null && minSqft < 0) {
            throw new BadRequestException("Minimum sqft cannot be negative");
        }
        if (maxSqft != null && maxSqft < 0) {
            throw new BadRequestException("Maximum sqft cannot be negative");
        }
        if (minSqft != null && maxSqft != null && minSqft > maxSqft) {
            throw new BadRequestException("Minimum sqft cannot exceed maximum sqft");
        }
    }

    public BigDecimal getEffectiveMinPriceCr() {
        if (minPriceCr != null) {
            return minPriceCr;
        }
        return normalizeToCrores(minPrice);
    }

    public BigDecimal getEffectiveMaxPriceCr() {
        if (maxPriceCr != null) {
            return maxPriceCr;
        }
        return normalizeToCrores(maxPrice);
    }

    private BigDecimal normalizeToCrores(BigDecimal price) {
        if (price == null) {
            return null;
        }
        // INR value e.g. >= 100,000 (1 Lakh in rupees) -> divide by 10,000,000 to get Crores
        if (price.compareTo(BigDecimal.valueOf(100000)) >= 0) {
            return price.divide(BigDecimal.valueOf(10000000), 4, RoundingMode.HALF_UP);
        }
        // Lakhs value e.g. 50 <= price < 100,000 (e.g. 80 Lakhs = 0.80 Cr)
        if (price.compareTo(BigDecimal.valueOf(50)) >= 0) {
            return price.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        }
        // Crores value e.g. < 50 (e.g. 0.8 Cr or 1.5 Cr or 15 Cr)
        return price;
    }

    public List<String> getBhkList() {
        if (bhk == null || bhk.isBlank()) {
            return List.of();
        }
        return Arrays.stream(bhk.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    public List<String> getAmenitiesList() {
        if (amenities == null || amenities.isBlank()) {
            return List.of();
        }
        return Arrays.stream(amenities.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    public PropertySortOption getSortOption() {
        return PropertySortOption.fromString(sort);
    }

    // Getters and Setters

    public String getQ() {
        return q;
    }

    public void setQ(String q) {
        this.q = q;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getSector() {
        return sector;
    }

    public void setSector(String sector) {
        this.sector = sector;
    }

    public String getLocality() {
        return locality;
    }

    public void setLocality(String locality) {
        this.locality = locality;
    }

    public String getPropertyType() {
        return propertyType;
    }

    public void setPropertyType(String propertyType) {
        this.propertyType = propertyType;
    }

    public String getBhk() {
        return bhk;
    }

    public void setBhk(String bhk) {
        this.bhk = bhk;
    }

    public BigDecimal getMinPrice() {
        return minPrice;
    }

    public void setMinPrice(BigDecimal minPrice) {
        this.minPrice = minPrice;
    }

    public BigDecimal getMaxPrice() {
        return maxPrice;
    }

    public void setMaxPrice(BigDecimal maxPrice) {
        this.maxPrice = maxPrice;
    }

    public BigDecimal getMinPriceCr() {
        return minPriceCr;
    }

    public void setMinPriceCr(BigDecimal minPriceCr) {
        this.minPriceCr = minPriceCr;
    }

    public BigDecimal getMaxPriceCr() {
        return maxPriceCr;
    }

    public void setMaxPriceCr(BigDecimal maxPriceCr) {
        this.maxPriceCr = maxPriceCr;
    }

    public Integer getMinSqft() {
        return minSqft;
    }

    public void setMinSqft(Integer minSqft) {
        this.minSqft = minSqft;
    }

    public Integer getMaxSqft() {
        return maxSqft;
    }

    public void setMaxSqft(Integer maxSqft) {
        this.maxSqft = maxSqft;
    }

    public String getAmenities() {
        return amenities;
    }

    public void setAmenities(String amenities) {
        this.amenities = amenities;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getSort() {
        return sort;
    }

    public void setSort(String sort) {
        this.sort = sort;
    }

    public Integer getPage() {
        return page != null ? page : 0;
    }

    public void setPage(Integer page) {
        this.page = page;
    }

    public Integer getSize() {
        return size != null ? size : 20;
    }

    public void setSize(Integer size) {
        this.size = size;
    }
}
