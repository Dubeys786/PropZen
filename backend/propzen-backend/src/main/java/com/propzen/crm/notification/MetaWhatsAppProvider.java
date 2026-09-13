package com.propzen.crm.notification;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Production implementation connecting to the official Meta WhatsApp Business Cloud API (Graph API v18.0).
 * Dispatches real HTTP requests when credentials are configured.
 */
@Component("metaWhatsAppProvider")
public class MetaWhatsAppProvider implements WhatsAppProvider {

    private static final Logger log = LoggerFactory.getLogger(MetaWhatsAppProvider.class);

    @Value("${propzen.whatsapp.api-url:https://graph.facebook.com/v18.0}")
    private String apiUrl;

    @Value("${propzen.whatsapp.access-token:${WHATSAPP_ACCESS_TOKEN:${propzen.whatsapp.api-token:}}}")
    private String apiToken;

    @Value("${propzen.whatsapp.phone-number-id:${WHATSAPP_PHONE_NUMBER_ID:}}")
    private String phoneNumberId;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public MetaWhatsAppProvider(ObjectMapper objectMapper) {
        this.restTemplate = new RestTemplate();
        this.objectMapper = objectMapper;
    }

    @Override
    public WhatsAppResponse sendTextMessage(String to, String message) {
        if (apiToken == null || apiToken.isBlank() || phoneNumberId == null || phoneNumberId.isBlank()) {
            log.warn("Meta WhatsApp credentials not fully configured. Simulating dispatch to {}", to);
            return WhatsAppResponse.ok("wamid_meta_simulated_" + System.currentTimeMillis());
        }

        try {
            String endpoint = apiUrl + "/" + phoneNumberId + "/messages";
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiToken);

            Map<String, Object> payload = new HashMap<>();
            payload.put("messaging_product", "whatsapp");
            payload.put("recipient_type", "individual");
            payload.put("to", sanitizePhone(to));
            payload.put("type", "text");
            payload.put("text", Map.of("body", message));

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(endpoint, requestEntity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String messageId = root.path("messages").path(0).path("id").asText("wamid_meta_ack");
                log.info("Successfully sent WhatsApp text via Meta Cloud API to {}, messageId: {}", to, messageId);
                return WhatsAppResponse.ok(messageId);
            } else {
                log.error("Meta WhatsApp Cloud API error: HTTP {}", response.getStatusCode());
                return WhatsAppResponse.failed("Meta WhatsApp API error: HTTP " + response.getStatusCode());
            }
        } catch (Exception e) {
            log.error("Failed to dispatch Meta WhatsApp text message to {}: {}", to, e.getMessage());
            return WhatsAppResponse.failed(e.getMessage());
        }
    }

    @Override
    public WhatsAppResponse sendTemplateMessage(String to, String templateName, String language, Map<String, String> variables) {
        if (apiToken == null || apiToken.isBlank() || phoneNumberId == null || phoneNumberId.isBlank()) {
            log.warn("Meta WhatsApp credentials not fully configured. Simulating template dispatch to {}", to);
            return WhatsAppResponse.ok("wamid_meta_simulated_" + System.currentTimeMillis());
        }

        try {
            String endpoint = apiUrl + "/" + phoneNumberId + "/messages";
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiToken);

            Map<String, Object> templateObj = new HashMap<>();
            templateObj.put("name", templateName);
            templateObj.put("language", Map.of("code", language != null ? language : "en"));

            if (variables != null && !variables.isEmpty()) {
                List<Map<String, Object>> parameters = new ArrayList<>();
                for (Map.Entry<String, String> entry : variables.entrySet()) {
                    parameters.add(Map.of("type", "text", "text", entry.getValue()));
                }
                templateObj.put("components", List.of(Map.of("type", "body", "parameters", parameters)));
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("messaging_product", "whatsapp");
            payload.put("recipient_type", "individual");
            payload.put("to", sanitizePhone(to));
            payload.put("type", "template");
            payload.put("template", templateObj);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(endpoint, requestEntity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String messageId = root.path("messages").path(0).path("id").asText("wamid_meta_ack");
                log.info("Successfully sent WhatsApp template '{}' to {}, messageId: {}", templateName, to, messageId);
                return WhatsAppResponse.ok(messageId);
            } else {
                log.error("Meta WhatsApp Cloud API error: HTTP {}", response.getStatusCode());
                return WhatsAppResponse.failed("Meta WhatsApp API error: HTTP " + response.getStatusCode());
            }
        } catch (Exception e) {
            log.error("Failed to dispatch Meta WhatsApp template '{}' to {}: {}", templateName, to, e.getMessage());
            return WhatsAppResponse.failed(e.getMessage());
        }
    }

    private String sanitizePhone(String phone) {
        if (phone == null) return "";
        return phone.replaceAll("[^0-9]", "");
    }
}
