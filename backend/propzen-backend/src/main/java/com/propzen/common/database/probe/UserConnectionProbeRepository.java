package com.propzen.common.database.probe;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Spring Data JPA repository for verifying read-only database connectivity to Supabase.
 */
@Repository
@Transactional(readOnly = true)
public interface UserConnectionProbeRepository extends JpaRepository<UserConnectionProbe, UUID> {

    @Query(value = "SELECT 1", nativeQuery = true)
    Integer executeConnectivityPing();
}
