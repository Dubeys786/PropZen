package com.propzen.crm.service;

import com.propzen.crm.dto.CrmCommunicationDto;
import com.propzen.crm.dto.OneClickWhatsAppRequest;
import com.propzen.crm.entity.WhatsAppTemplateEntity;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CommunicationDirection;
import com.propzen.crm.model.CommunicationStatus;
import com.propzen.crm.model.CrmActivityType;
import com.propzen.crm.notification.WhatsAppProvider;
import com.propzen.crm.notification.WhatsAppResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.NoSuchElementException;

@Service
public class WhatsAppNotificationService {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppNotificationService.class);

    private final WhatsAppProvider whatsAppProvider;
    private final WhatsAppTemplateService templateService;
    private final ContactPreferenceService contactPreferenceService;
    private final CrmCommunicationService communicationService;
    private final CrmActivityService activityService;

    public WhatsAppNotificationService(
            WhatsAppProvider whatsAppProvider,
            WhatsAppTemplateService templateService,
            ContactPreferenceService contactPreferenceService,
            CrmCommunicationService communicationService,
            CrmActivityService activityService
    ) {
        this.whatsAppProvider = whatsAppProvider;
        this.templateService = templateService;
        this.contactPreferenceService = contactPreferenceService;
        this.communicationService = communicationService;
        this.activityService = activityService;
    }

    @Transactional
    public CrmCommunicationDto sendTemplateNotification(OneClickWhatsAppRequest request) {
        String phone = request.getToPhone();
        if (!contactPreferenceService.canSendWhatsApp(phone)) {
            log.warn("Cannot send WhatsApp to {}: recipient has opted out of WhatsApp messages", phone);
            return communicationService.logCommunication(
                    request.getLeadId(),
                    request.getCustomerId(),
                    CommunicationChannel.WHATSAPP,
                    CommunicationDirection.OUTBOUND,
                    null,
                    null,
                    "SKIPPED: Opted out",
                    CommunicationStatus.FAILED
            );
        }

        WhatsAppTemplateEntity template = templateService.findByName(request.getTemplateName())
                .orElseThrow(() -> new NoSuchElementException("WhatsApp template not found: " + request.getTemplateName()));

        Map<String, String> vars = request.getVariables() != null ? request.getVariables() : Map.of();
        String interpolatedMessage = templateService.interpolate(template.getContent(), vars);

        log.info("Sending official WhatsApp template '{}' to {}", template.getName(), phone);
        WhatsAppResponse response = whatsAppProvider.sendTemplateMessage(phone, template.getTemplateName(), template.getLanguage(), vars);

        CommunicationStatus commStatus = response.isSuccess() ? CommunicationStatus.SENT : CommunicationStatus.FAILED;

        CrmCommunicationDto comm = communicationService.logCommunication(
                request.getLeadId(),
                request.getCustomerId(),
                CommunicationChannel.WHATSAPP,
                CommunicationDirection.OUTBOUND,
                template.getId(),
                response.getProviderMessageId(),
                interpolatedMessage.length() > 500 ? interpolatedMessage.substring(0, 497) + "..." : interpolatedMessage,
                commStatus
        );

        if (response.isSuccess()) {
            activityService.recordSystemActivity(
                    request.getLeadId(),
                    request.getCustomerId(),
                    CrmActivityType.WHATSAPP_SENT,
                    "WhatsApp Message Sent",
                    "Template: " + template.getName() + " | MsgId: " + response.getProviderMessageId()
            );
        }

        return comm;
    }

    @Transactional
    public CrmCommunicationDto sendTextMessage(String phone, String text, Long leadId, Long customerId) {
        if (!contactPreferenceService.canSendWhatsApp(phone)) {
            log.warn("Cannot send WhatsApp text to {}: recipient opted out", phone);
            return null;
        }

        WhatsAppResponse response = whatsAppProvider.sendTextMessage(phone, text);
        CommunicationStatus commStatus = response.isSuccess() ? CommunicationStatus.SENT : CommunicationStatus.FAILED;

        return communicationService.logCommunication(
                null,
                null,
                CommunicationChannel.WHATSAPP,
                CommunicationDirection.OUTBOUND,
                null,
                response.getProviderMessageId(),
                text.length() > 500 ? text.substring(0, 497) + "..." : text,
                commStatus
        );
    }
}
