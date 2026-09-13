package com.propzen.crm.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.crm.dto.CampaignDto;
import com.propzen.crm.dto.CreateCampaignRequest;
import com.propzen.crm.entity.Campaign;
import com.propzen.crm.entity.CampaignRecipient;
import com.propzen.crm.entity.CommunicationPreference;
import com.propzen.crm.entity.ContactPreference;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.MessageTemplate;
import com.propzen.crm.model.CampaignStatus;
import com.propzen.crm.model.RecipientStatus;
import com.propzen.crm.notification.WhatsAppProvider;
import com.propzen.crm.notification.WhatsAppResponse;
import com.propzen.crm.repository.CampaignRecipientRepository;
import com.propzen.crm.repository.CampaignRepository;
import com.propzen.crm.repository.CommunicationPreferenceRepository;
import com.propzen.crm.repository.ContactPreferenceRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.MessageTemplateRepository;
import com.propzen.exception.BadRequestException;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Bulk messaging and marketing campaign service with consent enforcement, idempotency protection,
 * and rate-limited asynchronous background dispatch.
 */
@Service
public class CampaignService {

    private static final Logger log = LoggerFactory.getLogger(CampaignService.class);

    private final CampaignRepository campaignRepository;
    private final CampaignRecipientRepository recipientRepository;
    private final MessageTemplateRepository templateRepository;
    private final CommunicationPreferenceRepository preferenceRepository;
    private final ContactPreferenceRepository contactPreferenceRepository;
    private final LeadRepository leadRepository;
    private final WhatsAppProvider whatsAppProvider;
    private final AuditLogService auditLogService;

    public CampaignService(CampaignRepository campaignRepository,
                           CampaignRecipientRepository recipientRepository,
                           MessageTemplateRepository templateRepository,
                           CommunicationPreferenceRepository preferenceRepository,
                           ContactPreferenceRepository contactPreferenceRepository,
                           LeadRepository leadRepository,
                           WhatsAppProvider whatsAppProvider,
                           AuditLogService auditLogService) {
        this.campaignRepository = campaignRepository;
        this.recipientRepository = recipientRepository;
        this.templateRepository = templateRepository;
        this.preferenceRepository = preferenceRepository;
        this.contactPreferenceRepository = contactPreferenceRepository;
        this.leadRepository = leadRepository;
        this.whatsAppProvider = whatsAppProvider;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public CampaignDto createCampaign(CreateCampaignRequest request, AuthenticatedUser admin) {
        if (!isAdmin(admin)) {
            throw new ForbiddenException("Only administrators can create marketing campaigns");
        }

        MessageTemplate template = templateRepository.findById(request.getTemplateId())
                .orElseThrow(() -> new ResourceNotFoundException("MessageTemplate", request.getTemplateId()));

        Campaign campaign = new Campaign();
        campaign.setName(request.getName().trim());
        campaign.setType(request.getType());
        campaign.setChannel(request.getChannel());
        campaign.setTemplateId(template.getId());
        campaign.setStatus(CampaignStatus.DRAFT);
        campaign.setCreatedBy(admin.getUserId());
        campaign.setScheduledAt(request.getScheduledAt());

        // Resolve target leads
        List<Lead> targetLeads = new ArrayList<>();
        if (request.getSpecificLeadIds() != null && !request.getSpecificLeadIds().isEmpty()) {
            targetLeads = leadRepository.findAllById(request.getSpecificLeadIds());
        } else if (request.getTargetStatus() != null) {
            targetLeads = leadRepository.findAll().stream()
                    .filter(l -> l.getStatus() == request.getTargetStatus())
                    .toList();
        } else {
            targetLeads = leadRepository.findAll();
        }

        campaign.setTotalRecipients(targetLeads.size());
        Campaign saved = campaignRepository.save(campaign);

        // Populate recipients
        for (Lead lead : targetLeads) {
            CampaignRecipient recipient = new CampaignRecipient();
            recipient.setCampaignId(saved.getId());
            recipient.setLeadId(lead.getId());
            recipient.setPhone(lead.getPhone());
            recipient.setStatus(RecipientStatus.PENDING);
            recipient.setIdempotencyKey(saved.getId() + ":" + lead.getId() + ":" + template.getId());
            recipientRepository.save(recipient);
        }

        auditLogService.logAction(
                admin.getUserId(),
                "CAMPAIGN_CREATED",
                "crm_campaigns/" + saved.getId(),
                "Created campaign " + saved.getName() + " with " + targetLeads.size() + " recipients"
        );

        return CampaignDto.fromEntity(saved);
    }

    @Transactional
    public CampaignDto sendCampaign(UUID campaignId, AuthenticatedUser admin) {
        return sendCampaign(campaignId, admin, false);
    }

    @Transactional
    public CampaignDto sendCampaign(UUID campaignId, AuthenticatedUser admin, boolean async) {
        if (!isAdmin(admin)) {
            throw new ForbiddenException("Only administrators can execute bulk campaigns");
        }

        Campaign campaign = campaignRepository.findById(campaignId)
                .orElseThrow(() -> new ResourceNotFoundException("Campaign", campaignId));

        if (campaign.getStatus() == CampaignStatus.COMPLETED || campaign.getStatus() == CampaignStatus.IN_PROGRESS) {
            throw new BadRequestException("Campaign is already in progress or completed");
        }

        MessageTemplate template = templateRepository.findById(campaign.getTemplateId())
                .orElseThrow(() -> new ResourceNotFoundException("MessageTemplate", campaign.getTemplateId()));

        campaign.setStatus(CampaignStatus.IN_PROGRESS);
        campaign.setStartedAt(OffsetDateTime.now());
        Campaign saved = campaignRepository.save(campaign);

        // Queue pending recipients
        List<CampaignRecipient> recipients = recipientRepository.findByCampaignId(campaignId);
        for (CampaignRecipient r : recipients) {
            if (r.getStatus() == RecipientStatus.PENDING) {
                r.setStatus(RecipientStatus.QUEUED);
                recipientRepository.save(r);
            }
        }

        if (async) {
            // Process asynchronously with rate limiting to protect external APIs
            CompletableFuture.runAsync(() -> dispatchAsync(campaignId, template.getTemplateIdentifier(), template.getLanguage(), admin.getUserId()));

            auditLogService.logAction(
                    admin.getUserId(),
                    "CAMPAIGN_QUEUED",
                    "crm_campaigns/" + saved.getId(),
                    "Queued campaign for background asynchronous dispatch"
            );
            return CampaignDto.fromEntity(saved);
        } else {
            dispatchAsync(campaignId, template.getTemplateIdentifier(), template.getLanguage(), admin.getUserId());
            Campaign completed = campaignRepository.findById(campaignId).orElse(saved);
            return CampaignDto.fromEntity(completed);
        }
    }

    public void dispatchAsync(UUID campaignId, String templateName, String language, UUID adminUserId) {
        try {
            Campaign campaign = campaignRepository.findById(campaignId).orElse(null);
            if (campaign == null) return;

            List<CampaignRecipient> recipients = recipientRepository.findByCampaignId(campaignId);
            int sent = 0;
            int failed = 0;

            for (CampaignRecipient recipient : recipients) {
                if (recipient.getStatus() != RecipientStatus.QUEUED && recipient.getStatus() != RecipientStatus.PENDING) {
                    continue;
                }

                // 1. Consent & Opt-out Check across both consent tables
                boolean optedOut = false;
                Optional<ContactPreference> pref = contactPreferenceRepository.findByPhone(recipient.getPhone());
                if (pref.isPresent() && (!pref.get().isWhatsappOptIn() || !pref.get().isMarketingOptIn())) {
                    optedOut = true;
                }
                Optional<CommunicationPreference> legPref = preferenceRepository.findByPhone(recipient.getPhone());
                if (legPref.isPresent() && !Boolean.TRUE.equals(legPref.get().getMarketingOptIn())) {
                    optedOut = true;
                }

                if (optedOut) {
                    recipient.setStatus(RecipientStatus.SKIPPED);
                    recipient.setFailureReason("User opted out of marketing communications");
                    recipientRepository.save(recipient);
                    continue;
                }

                // 2. Dispatch via official provider
                Map<String, String> vars = new HashMap<>();
                vars.put("campaignName", campaign.getName());

                WhatsAppResponse resp = whatsAppProvider.sendTemplateMessage(
                        recipient.getPhone(),
                        templateName,
                        language,
                        vars
                );

                if (resp.isSuccess()) {
                    recipient.setStatus(RecipientStatus.SENT);
                    recipient.setSentAt(OffsetDateTime.now());
                    recipient.setProviderMessageId(resp.getProviderMessageId());
                    sent++;
                } else {
                    recipient.setStatus(RecipientStatus.FAILED);
                    recipient.setFailedAt(OffsetDateTime.now());
                    recipient.setFailureReason(resp.getErrorMessage());
                    failed++;
                }
                recipientRepository.save(recipient);

                // Rate limiting pause (20ms = ~50 msgs/second max)
                try {
                    Thread.sleep(20);
                } catch (InterruptedException ignored) {
                }
            }

            campaign.setSentCount(sent);
            campaign.setFailedCount(failed);
            campaign.setStatus(CampaignStatus.COMPLETED);
            campaign.setCompletedAt(OffsetDateTime.now());
            campaignRepository.save(campaign);

            auditLogService.logAction(
                    adminUserId,
                    "CAMPAIGN_DISPATCH_COMPLETED",
                    "crm_campaigns/" + campaignId,
                    "Sent " + sent + " messages, failed " + failed
            );
        } catch (Exception e) {
            log.error("Async campaign dispatch failed for campaign {}: {}", campaignId, e.getMessage(), e);
        }
    }

    @Transactional(readOnly = true)
    public List<CampaignDto> getAllCampaigns(AuthenticatedUser admin) {
        return campaignRepository.findAll(org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(CampaignDto::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public CampaignDto getCampaign(UUID id, AuthenticatedUser admin) {
        Campaign campaign = campaignRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Campaign", id));
        return CampaignDto.fromEntity(campaign);
    }

    private boolean isAdmin(AuthenticatedUser user) {
        return user != null && user.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}
