package com.propzen.crm.repository;

import com.propzen.crm.entity.CommunicationPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CommunicationPreferenceRepository extends JpaRepository<CommunicationPreference, UUID> {
    Optional<CommunicationPreference> findByPhone(String phone);
    Optional<CommunicationPreference> findByUserId(UUID userId);
}
