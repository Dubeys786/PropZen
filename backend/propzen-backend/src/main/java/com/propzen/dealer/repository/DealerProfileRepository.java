package com.propzen.dealer.repository;

import com.propzen.dealer.entity.DealerProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface DealerProfileRepository extends JpaRepository<DealerProfile, UUID>, JpaSpecificationExecutor<DealerProfile> {

    Optional<DealerProfile> findByUserId(UUID userId);

    boolean existsByUserId(UUID userId);

    Optional<DealerProfile> findByEmailIgnoreCase(String email);

    long countByVerificationStatus(com.propzen.dealer.model.DealerVerificationStatus verificationStatus);
}
