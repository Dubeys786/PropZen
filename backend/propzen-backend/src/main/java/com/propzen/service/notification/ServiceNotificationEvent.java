package com.propzen.service.notification;

import com.propzen.service.model.ServiceJourneyEventType;
import java.util.Map;
import java.util.UUID;

public class ServiceNotificationEvent {
    private final ServiceJourneyEventType eventType;
    private final UUID serviceRequestId;
    private final String serviceNumber;
    private final String serviceName;
    private final String customerName;
    private final String customerPhone;
    private final String partnerName;
    private final String partnerPhone;
    private final Map<String, Object> metadata;

    public ServiceNotificationEvent(ServiceJourneyEventType eventType,
                                    UUID serviceRequestId,
                                    String serviceNumber,
                                    String serviceName,
                                    String customerName,
                                    String customerPhone,
                                    String partnerName,
                                    String partnerPhone,
                                    Map<String, Object> metadata) {
        this.eventType = eventType;
        this.serviceRequestId = serviceRequestId;
        this.serviceNumber = serviceNumber;
        this.serviceName = serviceName;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
        this.partnerName = partnerName;
        this.partnerPhone = partnerPhone;
        this.metadata = metadata != null ? metadata : Map.of();
    }

    public ServiceJourneyEventType getEventType() { return eventType; }
    public UUID getServiceRequestId() { return serviceRequestId; }
    public String getServiceNumber() { return serviceNumber; }
    public String getServiceName() { return serviceName; }
    public String getCustomerName() { return customerName; }
    public String getCustomerPhone() { return customerPhone; }
    public String getPartnerName() { return partnerName; }
    public String getPartnerPhone() { return partnerPhone; }
    public Map<String, Object> getMetadata() { return metadata; }
}
