package com.propzen.service.dto;

import com.propzen.service.model.MilestoneStatus;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class UpdateMilestoneRequest {
    private String title;
    private String description;
    private Integer sequenceNumber;
    private BigDecimal amount;
    private MilestoneStatus status;
    private OffsetDateTime dueDate;

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Integer getSequenceNumber() { return sequenceNumber; }
    public void setSequenceNumber(Integer sequenceNumber) { this.sequenceNumber = sequenceNumber; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public MilestoneStatus getStatus() { return status; }
    public void setStatus(MilestoneStatus status) { this.status = status; }

    public OffsetDateTime getDueDate() { return dueDate; }
    public void setDueDate(OffsetDateTime dueDate) { this.dueDate = dueDate; }
}
