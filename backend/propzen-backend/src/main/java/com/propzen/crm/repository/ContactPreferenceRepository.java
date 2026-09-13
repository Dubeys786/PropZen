package com.propzen.crm.repository;

import com.propzen.crm.entity.ContactPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContactPreferenceRepository extends JpaRepository<ContactPreference, UUID> {

    Optional<ContactPreference> findByPhone(String phone);

    Optional<ContactPreference> findByCustomerId(UUID customerId);
}
