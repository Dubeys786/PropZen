package com.propzen.crm.repository;

import com.propzen.crm.entity.CrmCommunication;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CommunicationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CrmCommunicationRepository extends JpaRepository<CrmCommunication, UUID> {

    List<CrmCommunication> findByLeadIdOrderByCreatedAtDesc(UUID leadId);

    Page<CrmCommunication> findByLeadIdOrderByCreatedAtDesc(UUID leadId, Pageable pageable);

    List<CrmCommunication> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    Page<CrmCommunication> findByCustomerIdOrderByCreatedAtDesc(UUID customerId, Pageable pageable);

    Optional<CrmCommunication> findByProviderMessageId(String providerMessageId);

    long countByChannel(CommunicationChannel channel);

    long countByChannelAndStatus(CommunicationChannel channel, CommunicationStatus status);
}
