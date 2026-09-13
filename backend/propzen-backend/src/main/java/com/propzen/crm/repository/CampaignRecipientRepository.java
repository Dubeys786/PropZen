package com.propzen.crm.repository;

import com.propzen.crm.entity.CampaignRecipient;
import com.propzen.crm.model.RecipientStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CampaignRecipientRepository extends JpaRepository<CampaignRecipient, UUID> {
    List<CampaignRecipient> findByCampaignId(UUID campaignId);
    List<CampaignRecipient> findByCampaignIdAndStatus(UUID campaignId, RecipientStatus status);
    Optional<CampaignRecipient> findByIdempotencyKey(String idempotencyKey);
    boolean existsByIdempotencyKey(String idempotencyKey);
    Optional<CampaignRecipient> findByProviderMessageId(String providerMessageId);
}
