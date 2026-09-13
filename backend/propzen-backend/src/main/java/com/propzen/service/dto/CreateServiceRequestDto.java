package com.propzen.service.dto;

import com.propzen.service.model.ServicePriority;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class CreateServiceRequestDto {

    @NotNull(message = "Service category ID is required")
    private UUID serviceCategoryId;

    private String propertyId;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;
    private String location;
    private BigDecimal budget;
    private OffsetDateTime preferredDate;
    private String preferredTime;
    private ServicePriority priority = ServicePriority.MEDIUM;

    public UUID getServiceCategoryId() { return serviceCategoryId; }
    public void setServiceCategoryId(UUID serviceCategoryId) { this.serviceCategoryId = serviceCategoryId; }

    public String getPropertyId() { return propertyId; }
    public void setPropertyId(String propertyId) { this.propertyId = propertyId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public BigDecimal getBudget() { return budget; }
    public void setBudget(BigDecimal budget) { this.budget = budget; }

    public OffsetDateTime getPreferredDate() { return preferredDate; }
    public void setPreferredDate(OffsetDateTime preferredDate) { this.preferredDate = preferredDate; }

    public String getPreferredTime() { return preferredTime; }
    public void setPreferredTime(String preferredTime) { this.preferredTime = preferredTime; }

    public ServicePriority getPriority() { return priority; }
    public void setPriority(ServicePriority priority) { this.priority = priority; }
}
