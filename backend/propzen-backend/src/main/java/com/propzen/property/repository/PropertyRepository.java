package com.propzen.property.repository;

import com.propzen.property.entity.Property;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Spring Data JPA repository for Property with dynamic Specification support.
 */
@Repository
public interface PropertyRepository extends JpaRepository<Property, UUID>, JpaSpecificationExecutor<Property> {

    List<Property> findByDealerId(UUID dealerId);

    @Query("SELECT p FROM Property p WHERE p.dealerId = :dealerId " +
           "AND LOWER(p.sector) = LOWER(:sector) " +
           "AND p.bhk = :bhk " +
           "AND p.priceCr = :priceCr")
    List<Property> findPotentialDuplicates(
            @Param("dealerId") UUID dealerId,
            @Param("sector") String sector,
            @Param("bhk") String bhk,
            @Param("priceCr") BigDecimal priceCr);

    long countByStatus(String status);
}
