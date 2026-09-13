package com.propzen.crm.service;

import com.propzen.crm.dto.CrmCommunicationDto;
import com.propzen.crm.entity.CrmCommunication;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CommunicationDirection;
import com.propzen.crm.model.CommunicationStatus;
import com.propzen.crm.repository.CrmCommunicationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CrmCommunicationService {

    private static final Logger log = LoggerFactory.getLogger(CrmCommunicationService.class);

    private final CrmCommunicationRepository communicationRepository;

    public CrmCommunicationService(CrmCommunicationRepository communicationRepository) {
        this.communicationRepository = communicationRepository;
    }

    @Transactional
    public CrmCommunicationDto logCommunication(
            UUID leadId,
            UUID customerId,
            CommunicationChannel channel,
            CommunicationDirection direction,
            UUID templateId,
            String providerMessageId,
            String messagePreview,
            CommunicationStatus status
    ) {
        CrmCommunication comm = new CrmCommunication();
        comm.setLeadId(leadId);
        comm.setCustomerId(customerId);
        comm.setChannel(channel != null ? channel : CommunicationChannel.WHATSAPP);
        comm.setDirection(direction != null ? direction : CommunicationDirection.OUTBOUND);
        comm.setTemplateId(templateId);
        comm.setProviderMessageId(providerMessageId);
        comm.setMessagePreview(messagePreview);
        comm.setStatus(status != null ? status : CommunicationStatus.QUEUED);
        if (status == CommunicationStatus.SENT || status == CommunicationStatus.DELIVERED) {
            comm.setSentAt(OffsetDateTime.now());
        }

        CrmCommunication saved = communicationRepository.save(comm);
        log.info("Logged CRM communication {} on channel {} with status {}", saved.getId(), saved.getChannel(), saved.getStatus());
        return CrmCommunicationDto.fromEntity(saved);
    }

    @Transactional
    public boolean updateStatusByProviderMessageId(String providerMessageId, CommunicationStatus newStatus) {
        Optional<CrmCommunication> opt = communicationRepository.findByProviderMessageId(providerMessageId);
        if (opt.isPresent()) {
            CrmCommunication comm = opt.get();
            comm.setStatus(newStatus);
            communicationRepository.save(comm);
            log.info("Updated communication {} providerMessageId {} status to {}", comm.getId(), providerMessageId, newStatus);
            return true;
        }
        return false;
    }

    @Transactional(readOnly = true)
    public List<CrmCommunicationDto> getCommunicationsByLeadId(UUID leadId) {
        return communicationRepository.findByLeadIdOrderByCreatedAtDesc(leadId)
                .stream()
                .map(CrmCommunicationDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<CrmCommunicationDto> getCommunicationsByLeadId(UUID leadId, Pageable pageable) {
        return communicationRepository.findByLeadIdOrderByCreatedAtDesc(leadId, pageable)
                .map(CrmCommunicationDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public List<CrmCommunicationDto> getCommunicationsByCustomerId(UUID customerId) {
        return communicationRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(CrmCommunicationDto::fromEntity)
                .collect(Collectors.toList());
    }
}
