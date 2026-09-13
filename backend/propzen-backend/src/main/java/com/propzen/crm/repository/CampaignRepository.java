package com.propzen.crm.repository;

import com.propzen.crm.entity.Campaign;
import com.propzen.crm.model.CampaignStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CampaignRepository extends JpaRepository<Campaign, UUID> {
    List<Campaign> findByStatus(CampaignStatus status);
}
