package com.propzen.service.repository;

import com.propzen.service.entity.ServiceCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServiceCategoryRepository extends JpaRepository<ServiceCategory, UUID> {
    Optional<ServiceCategory> findBySlug(String slug);
    List<ServiceCategory> findByIsActiveTrueOrderBySortOrderAsc();
    boolean existsBySlug(String slug);
}
