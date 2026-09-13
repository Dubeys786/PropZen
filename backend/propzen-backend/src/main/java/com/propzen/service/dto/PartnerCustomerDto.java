package com.propzen.service.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public class PartnerCustomerDto {
    private UUID customerId;
    private String name;
    private String email;
    private String phone;
    private long totalServices;
    private long activeServices;
    private long completedServices;
    private OffsetDateTime lastServiceDate;

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public long getTotalServices() { return totalServices; }
    public void setTotalServices(long totalServices) { this.totalServices = totalServices; }

    public long getActiveServices() { return activeServices; }
    public void setActiveServices(long activeServices) { this.activeServices = activeServices; }

    public long getCompletedServices() { return completedServices; }
    public void setCompletedServices(long completedServices) { this.completedServices = completedServices; }

    public OffsetDateTime getLastServiceDate() { return lastServiceDate; }
    public void setLastServiceDate(OffsetDateTime lastServiceDate) { this.lastServiceDate = lastServiceDate; }
}
