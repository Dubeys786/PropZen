package com.propzen.crm.notification;

import java.util.Map;

/**
 * Provider-agnostic abstraction for official WhatsApp Business messaging.
 */
public interface WhatsAppProvider {

    WhatsAppResponse sendTextMessage(String to, String message);

    WhatsAppResponse sendTemplateMessage(String to, String templateName, String language, Map<String, String> variables);
}
