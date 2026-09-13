package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CrmTagRepository extends JpaRepository<CrmTag, UUID> {

    Optional<CrmTag> findByNameIgnoreCase(String name);

    boolean existsByNameIgnoreCase(String name);
}
