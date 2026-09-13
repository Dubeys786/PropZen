package com.propzen.crm.service;

import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadSource;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;

/**
 * Deterministic, explainable server-side lead scoring (0 to 100).
 */
@Service
public class LeadScoringService {

    public int calculateScore(Lead lead) {
        if (lead == null) return 0;
        int score = 0;

        // 1. Contact Quality
        if (lead.getPhone() != null && !lead.getPhone().isBlank()) {
            score += 10;
        }
        if (lead.getEmail() != null && lead.getEmail().contains("@")) {
            score += 10;
        }

        // 2. High-Intent Source
        if (lead.getSource() == LeadSource.SITE_VISIT) {
            score += 25;
        } else if (lead.getSource() == LeadSource.PROPERTY_ENQUIRY) {
            score += 20;
        } else if (lead.getSource() == LeadSource.WHATSAPP || lead.getSource() == LeadSource.PHONE) {
            score += 15;
        } else {
            score += 10;
        }

        // 3. Clear Intent / Budget / Location Specified
        if (lead.getBudgetMin() != null || lead.getBudgetMax() != null) {
            score += 15;
        }
        if (lead.getPreferredCity() != null || lead.getPreferredSector() != null) {
            score += 10;
        }
        if (lead.getPreferredBhk() != null) {
            score += 5;
        }

        // 4. Recency (created within last 48 hours)
        if (lead.getCreatedAt() != null && lead.getCreatedAt().isAfter(OffsetDateTime.now().minusHours(48))) {
            score += 10;
        }

        return Math.min(score, 100);
    }
}
