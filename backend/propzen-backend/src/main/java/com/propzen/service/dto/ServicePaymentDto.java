package com.propzen.service.dto;

import com.propzen.service.entity.ServicePayment;
import com.propzen.service.model.PaymentProviderType;
import com.propzen.service.model.PaymentStatus;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServicePaymentDto {
    private UUID id;
    private UUID serviceRequestId;
    private UUID milestoneId;
    private UUID customerId;
    private UUID partnerId;
    private BigDecimal amount;
    private String currency;
    private PaymentProviderType paymentProvider;
    private String providerPaymentId;
    private String providerOrderId;
    private PaymentStatus status;
    private OffsetDateTime paidAt;
    private OffsetDateTime createdAt;

    public static ServicePaymentDto fromEntity(ServicePayment entity) {
        ServicePaymentDto dto = new ServicePaymentDto();
        dto.setId(entity.getId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setMilestoneId(entity.getMilestoneId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setPartnerId(entity.getPartnerId());
        dto.setAmount(entity.getAmount());
        dto.setCurrency(entity.getCurrency());
        dto.setPaymentProvider(entity.getPaymentProvider());
        dto.setProviderPaymentId(entity.getProviderPaymentId());
        dto.setProviderOrderId(entity.getProviderOrderId());
        dto.setStatus(entity.getStatus());
        dto.setPaidAt(entity.getPaidAt());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public UUID getMilestoneId() { return milestoneId; }
    public void setMilestoneId(UUID milestoneId) { this.milestoneId = milestoneId; }

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public PaymentProviderType getPaymentProvider() { return paymentProvider; }
    public void setPaymentProvider(PaymentProviderType paymentProvider) { this.paymentProvider = paymentProvider; }

    public String getProviderPaymentId() { return providerPaymentId; }
    public void setProviderPaymentId(String providerPaymentId) { this.providerPaymentId = providerPaymentId; }

    public String getProviderOrderId() { return providerOrderId; }
    public void setProviderOrderId(String providerOrderId) { this.providerOrderId = providerOrderId; }

    public PaymentStatus getStatus() { return status; }
    public void setStatus(PaymentStatus status) { this.status = status; }

    public OffsetDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(OffsetDateTime paidAt) { this.paidAt = paidAt; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
