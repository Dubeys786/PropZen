package com.propzen.crm.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.response.ApiResponse;
import com.propzen.crm.entity.CampaignRecipient;
import com.propzen.crm.model.RecipientStatus;
import com.propzen.crm.repository.CampaignRecipientRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.Optional;

/**
 * Inbound webhook listener for WhatsApp Business Cloud API delivery and status callbacks.
 */
@RestController
@RequestMapping({"/api/v1/webhooks/whatsapp", "/api/v1/whatsapp/webhook"})
@Tag(name = "WhatsApp Webhook", description = "Inbound callbacks for message delivery status updates")
public class WebhookController {

    private static final Logger log = LoggerFactory.getLogger(WebhookController.class);

    @Value("${propzen.whatsapp.webhook-verify-token:}")
    private String verifyToken;

    @Value("${propzen.whatsapp.app-secret:}")
    private String appSecret;

    private final CampaignRecipientRepository recipientRepository;
    private final com.propzen.crm.service.CrmCommunicationService communicationService;
    private final ObjectMapper objectMapper;

    public WebhookController(CampaignRecipientRepository recipientRepository,
                             com.propzen.crm.service.CrmCommunicationService communicationService,
                             ObjectMapper objectMapper) {
        this.recipientRepository = recipientRepository;
        this.communicationService = communicationService;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    @Operation(summary = "Meta Webhook Verification", description = "Responds to Meta hub.challenge handshake")
    public ResponseEntity<String> verifyWebhook(
            @RequestParam("hub.mode") String mode,
            @RequestParam("hub.verify_token") String token,
            @RequestParam("hub.challenge") String challenge) {
        if (verifyToken != null && !verifyToken.isBlank() && "subscribe".equalsIgnoreCase(mode) && verifyToken.equals(token)) {
            log.info("WhatsApp webhook verified successfully");
            return ResponseEntity.ok(challenge);
        }
        log.warn("Invalid webhook verification token received or token not configured");
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Verification failed");
    }

    @PostMapping
    @Operation(summary = "Handle delivery status callbacks")
    public ResponseEntity<ApiResponse<String>> handleCallback(
            @RequestHeader(value = "X-Hub-Signature-256", required = false) String signature,
            @RequestBody byte[] rawBodyBytes) {
        if (!verifyHubSignature(signature, rawBodyBytes)) {
            log.warn("Unauthorized WhatsApp webhook callback: invalid X-Hub-Signature-256");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiResponse.error("FORBIDDEN", "Invalid webhook signature"));
        }

        Map<String, Object> payload;
        try {
            payload = objectMapper.readValue(rawBodyBytes, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            log.error("Failed to parse WhatsApp webhook payload: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error("BAD_REQUEST", "Invalid JSON payload"));
        }

        log.info("Received WhatsApp webhook event: {}", payload);

        // Extract message status update if present
        try {
            if (payload.containsKey("providerMessageId") && payload.containsKey("status")) {
                String messageId = (String) payload.get("providerMessageId");
                String statusStr = ((String) payload.get("status")).toUpperCase();

                Optional<CampaignRecipient> recipOpt = recipientRepository.findByProviderMessageId(messageId);
                if (recipOpt.isPresent()) {
                    CampaignRecipient recipient = recipOpt.get();
                    if ("DELIVERED".equals(statusStr)) {
                        recipient.setStatus(RecipientStatus.DELIVERED);
                        recipient.setDeliveredAt(OffsetDateTime.now());
                        communicationService.updateStatusByProviderMessageId(messageId, com.propzen.crm.model.CommunicationStatus.DELIVERED);
                    } else if ("READ".equals(statusStr)) {
                        recipient.setStatus(RecipientStatus.READ);
                        recipient.setReadAt(OffsetDateTime.now());
                        communicationService.updateStatusByProviderMessageId(messageId, com.propzen.crm.model.CommunicationStatus.READ);
                    } else if ("FAILED".equals(statusStr)) {
                        recipient.setStatus(RecipientStatus.FAILED);
                        recipient.setFailedAt(OffsetDateTime.now());
                        communicationService.updateStatusByProviderMessageId(messageId, com.propzen.crm.model.CommunicationStatus.FAILED);
                    }
                    recipientRepository.save(recipient);
                } else {
                    // Update communication if not in campaign
                    if ("DELIVERED".equals(statusStr)) {
                        communicationService.updateStatusByProviderMessageId(messageId, com.propzen.crm.model.CommunicationStatus.DELIVERED);
                    } else if ("READ".equals(statusStr)) {
                        communicationService.updateStatusByProviderMessageId(messageId, com.propzen.crm.model.CommunicationStatus.READ);
                    } else if ("FAILED".equals(statusStr)) {
                        communicationService.updateStatusByProviderMessageId(messageId, com.propzen.crm.model.CommunicationStatus.FAILED);
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error processing webhook callback: {}", e.getMessage());
        }

        return ResponseEntity.ok(ApiResponse.ok("EVENT_RECEIVED", "Webhook processed"));
    }

    @Value("${propzen.environment:production}")
    private String environment;

    private boolean isProduction() {
        return "production".equalsIgnoreCase(environment) || "prod".equalsIgnoreCase(environment);
    }

    private boolean verifyHubSignature(String signatureHeader, byte[] bodyBytes) {
        if (signatureHeader == null || signatureHeader.isBlank()) {
            if (isProduction()) {
                return false; // Signature is mandatory in production
            }
            return true; // Allowed in local/test without signature
        }
        if (!signatureHeader.startsWith("sha256=")) {
            return false;
        }
        if (appSecret == null || appSecret.isBlank()) {
            return false;
        }
        try {
            String expectedHash = signatureHeader.substring("sha256=".length()).trim();
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(appSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] computedHash = mac.doFinal(bodyBytes);
            StringBuilder sb = new StringBuilder();
            for (byte b : computedHash) {
                sb.append(String.format("%02x", b));
            }
            return MessageDigest.isEqual(
                    sb.toString().toLowerCase().getBytes(StandardCharsets.UTF_8),
                    expectedHash.toLowerCase().getBytes(StandardCharsets.UTF_8)
            );
        } catch (Exception e) {
            log.error("Error verifying X-Hub-Signature-256: {}", e.getMessage());
            return false;
        }
    }
}
