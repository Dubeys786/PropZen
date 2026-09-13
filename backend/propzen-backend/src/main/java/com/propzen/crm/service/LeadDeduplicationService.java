package com.propzen.crm.service;

import com.propzen.crm.entity.Lead;
import com.propzen.crm.repository.LeadRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/**
 * Service for intelligent lead deduplication across phone numbers, email addresses,
 * and authenticated user IDs. Prevents duplicate lead entry in PostgreSQL.
 */
@Service
public class LeadDeduplicationService {

    private static final Logger log = LoggerFactory.getLogger(LeadDeduplicationService.class);

    private final LeadRepository leadRepository;

    public LeadDeduplicationService(LeadRepository leadRepository) {
        this.leadRepository = leadRepository;
    }

    /**
     * Finds an existing active lead matching phone, email, or user ID.
     */
    @Transactional(readOnly = true)
    public Optional<Lead> findDuplicate(String phone, String email, UUID userId) {
        if (phone != null && !phone.isBlank()) {
            Optional<Lead> byPhone = leadRepository.findFirstByPhoneOrderByCreatedAtDesc(phone.trim());
            if (byPhone.isPresent()) {
                log.info("Found existing lead {} by phone: {}", byPhone.get().getLeadNumber(), phone);
                return byPhone;
            }
        }

        if (email != null && !email.isBlank()) {
            Optional<Lead> byEmail = leadRepository.findFirstByEmailOrderByCreatedAtDesc(email.trim().toLowerCase());
            if (byEmail.isPresent()) {
                log.info("Found existing lead {} by email: {}", byEmail.get().getLeadNumber(), email);
                return byEmail;
            }
        }

        if (userId != null) {
            Optional<Lead> byUserId = leadRepository.findFirstByUserIdOrderByCreatedAtDesc(userId);
            if (byUserId.isPresent()) {
                log.info("Found existing lead {} by userId: {}", byUserId.get().getLeadNumber(), userId);
                return byUserId;
            }
        }

        return Optional.empty();
    }

    /**
     * Checks for a duplicate. If found, enriches the existing lead; otherwise saves newLead.
     */
    @Transactional
    public Lead deduplicateOrSave(Lead newLead) {
        Optional<Lead> existingOpt = findDuplicate(newLead.getPhone(), newLead.getEmail(), newLead.getUserId());
        if (existingOpt.isPresent()) {
            Lead existing = existingOpt.get();
            // Enrich existing lead with incoming details if missing
            if ((existing.getEmail() == null || existing.getEmail().isBlank()) && newLead.getEmail() != null) {
                existing.setEmail(newLead.getEmail());
            }
            if ((existing.getName() == null || existing.getName().isBlank()) && newLead.getName() != null) {
                existing.setName(newLead.getName());
            }
            if (newLead.getPropertyId() != null) {
                existing.setPropertyId(newLead.getPropertyId());
            }
            if (newLead.getMessage() != null && !newLead.getMessage().isBlank()) {
                existing.setMessage(newLead.getMessage());
            }
            log.info("Deduplicated and updated existing lead {}", existing.getLeadNumber());
            return leadRepository.save(existing);
        }

        return leadRepository.save(newLead);
    }
}
