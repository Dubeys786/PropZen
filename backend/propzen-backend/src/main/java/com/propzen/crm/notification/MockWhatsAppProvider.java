package com.propzen.crm.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Synthetic in-memory WhatsApp provider used for testing and development.
 * Guarantees NO real WhatsApp messages or network requests are dispatched.
 */
@Service
@Primary
public class MockWhatsAppProvider implements WhatsAppProvider {

    private static final Logger log = LoggerFactory.getLogger(MockWhatsAppProvider.class);

    public record SentRecord(String to, String message, String templateName, String language, Map<String, String> variables, String providerMessageId) {}

    private final List<SentRecord> sentMessages = Collections.synchronizedList(new ArrayList<>());

    @Override
    public WhatsAppResponse sendTextMessage(String to, String message) {
        String msgId = "mock_wamid_" + UUID.randomUUID();
        sentMessages.add(new SentRecord(to, message, null, null, null, msgId));
        log.info("[MOCK_WHATSAPP] Sent text to {}: {}", to, message);
        return WhatsAppResponse.ok(msgId);
    }

    @Override
    public WhatsAppResponse sendTemplateMessage(String to, String templateName, String language, Map<String, String> variables) {
        String msgId = "mock_wamid_" + UUID.randomUUID();
        sentMessages.add(new SentRecord(to, null, templateName, language, variables, msgId));
        log.info("[MOCK_WHATSAPP] Sent template '{}' ({}) to {}. Vars: {}", templateName, language, to, variables);
        return WhatsAppResponse.ok(msgId);
    }

    public List<SentRecord> getSentMessages() {
        return Collections.unmodifiableList(new ArrayList<>(sentMessages));
    }

    public void clear() {
        sentMessages.clear();
    }
}
