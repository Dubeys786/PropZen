package com.propzen.service.notification;

import com.propzen.crm.notification.WhatsAppProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class ServiceNotificationService {

    private static final Logger log = LoggerFactory.getLogger(ServiceNotificationService.class);

    private final WhatsAppProvider whatsAppProvider;

    public ServiceNotificationService(WhatsAppProvider whatsAppProvider) {
        this.whatsAppProvider = whatsAppProvider;
    }

    public void handleNotification(ServiceNotificationEvent event) {
        log.info("[ServiceNotificationService] Processing notification event: {} for request #{}",
                event.getEventType(), event.getServiceNumber());

        switch (event.getEventType()) {
            case REQUEST_CREATED -> notifyCustomerRequestCreated(event);
            case PARTNER_ASSIGNED -> notifyPartnerAssigned(event);
            case PARTNER_ACCEPTED -> notifyCustomerPartnerAccepted(event);
            case WORK_STARTED -> notifyCustomerWorkStarted(event);
            case SERVICE_COMPLETED -> notifyCustomerServiceCompleted(event);
            case PAYMENT_RECEIVED -> notifyPaymentSuccess(event);
            default -> log.debug("[ServiceNotificationService] No automated message configured for event {}", event.getEventType());
        }
    }

    private void notifyCustomerRequestCreated(ServiceNotificationEvent event) {
        if (event.getCustomerPhone() == null || event.getCustomerPhone().isBlank()) return;

        Map<String, String> params = new HashMap<>();
        params.put("customer_name", event.getCustomerName());
        params.put("service_name", event.getServiceName());
        params.put("request_id", event.getServiceNumber());

        whatsAppProvider.sendTemplateMessage(
                event.getCustomerPhone(),
                "service_request_created",
                "en",
                params
        );
    }

    private void notifyPartnerAssigned(ServiceNotificationEvent event) {
        if (event.getPartnerPhone() == null || event.getPartnerPhone().isBlank()) return;

        Map<String, String> params = new HashMap<>();
        params.put("partner_name", event.getPartnerName() != null ? event.getPartnerName() : "Partner");
        params.put("service_name", event.getServiceName());
        params.put("request_id", event.getServiceNumber());

        whatsAppProvider.sendTemplateMessage(
                event.getPartnerPhone(),
                "service_partner_assigned",
                "en",
                params
        );
    }

    private void notifyCustomerPartnerAccepted(ServiceNotificationEvent event) {
        if (event.getCustomerPhone() == null || event.getCustomerPhone().isBlank()) return;

        Map<String, String> params = new HashMap<>();
        params.put("customer_name", event.getCustomerName());
        params.put("partner_name", event.getPartnerName());
        params.put("service_name", event.getServiceName());
        params.put("request_id", event.getServiceNumber());

        whatsAppProvider.sendTemplateMessage(
                event.getCustomerPhone(),
                "service_partner_accepted",
                "en",
                params
        );
    }

    private void notifyCustomerWorkStarted(ServiceNotificationEvent event) {
        if (event.getCustomerPhone() == null || event.getCustomerPhone().isBlank()) return;

        Map<String, String> params = new HashMap<>();
        params.put("customer_name", event.getCustomerName());
        params.put("service_name", event.getServiceName());
        params.put("partner_name", event.getPartnerName());

        whatsAppProvider.sendTemplateMessage(
                event.getCustomerPhone(),
                "service_work_started",
                "en",
                params
        );
    }

    private void notifyCustomerServiceCompleted(ServiceNotificationEvent event) {
        if (event.getCustomerPhone() == null || event.getCustomerPhone().isBlank()) return;

        Map<String, String> params = new HashMap<>();
        params.put("customer_name", event.getCustomerName());
        params.put("service_name", event.getServiceName());

        whatsAppProvider.sendTemplateMessage(
                event.getCustomerPhone(),
                "service_completed",
                "en",
                params
        );
    }

    private void notifyPaymentSuccess(ServiceNotificationEvent event) {
        if (event.getCustomerPhone() == null || event.getCustomerPhone().isBlank()) return;

        Map<String, String> params = new HashMap<>();
        params.put("customer_name", event.getCustomerName());
        params.put("service_name", event.getServiceName());
        params.put("amount", String.valueOf(event.getMetadata().getOrDefault("amount", "0")));

        whatsAppProvider.sendTemplateMessage(
                event.getCustomerPhone(),
                "payment_success",
                "en",
                params
        );
    }
}
