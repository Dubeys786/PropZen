package com.propzen.crm.service;

import com.propzen.crm.dto.ContactPreferenceDto;
import com.propzen.crm.dto.UpdateContactPreferenceRequest;
import com.propzen.crm.entity.ContactPreference;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.repository.ContactPreferenceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
public class ContactPreferenceService {

    private static final Logger log = LoggerFactory.getLogger(ContactPreferenceService.class);

    private final ContactPreferenceRepository preferenceRepository;

    public ContactPreferenceService(ContactPreferenceRepository preferenceRepository) {
        this.preferenceRepository = preferenceRepository;
    }

    @Transactional
    public ContactPreference getOrCreatePreference(String phone, UUID customerId) {
        if (phone == null || phone.isBlank()) {
            throw new IllegalArgumentException("Phone number is required for contact preferences");
        }
        String cleanPhone = phone.trim();
        return preferenceRepository.findByPhone(cleanPhone)
                .orElseGet(() -> {
                    ContactPreference pref = new ContactPreference(cleanPhone, customerId);
                    return preferenceRepository.save(pref);
                });
    }

    @Transactional(readOnly = true)
    public Optional<ContactPreferenceDto> getPreferenceByPhone(String phone) {
        return preferenceRepository.findByPhone(phone != null ? phone.trim() : "")
                .map(ContactPreferenceDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public Optional<ContactPreferenceDto> getPreferenceByCustomerId(UUID customerId) {
        return preferenceRepository.findByCustomerId(customerId)
                .map(ContactPreferenceDto::fromEntity);
    }

    @Transactional
    public ContactPreferenceDto updatePreference(String phone, UpdateContactPreferenceRequest request, UUID customerId) {
        ContactPreference pref = getOrCreatePreference(phone, customerId);

        if (request.getWhatsappOptIn() != null) {
            pref.setWhatsappOptIn(request.getWhatsappOptIn());
        }
        if (request.getMarketingOptIn() != null) {
            pref.setMarketingOptIn(request.getMarketingOptIn());
        }
        if (request.getEmailOptIn() != null) {
            pref.setEmailOptIn(request.getEmailOptIn());
        }
        if (request.getSmsOptIn() != null) {
            pref.setSmsOptIn(request.getSmsOptIn());
        }

        ContactPreference saved = preferenceRepository.save(pref);
        log.info("Updated contact preference for phone {}", phone);
        return ContactPreferenceDto.fromEntity(saved);
    }

    @Transactional
    public ContactPreferenceDto optOut(String phone, String channel) {
        ContactPreference pref = getOrCreatePreference(phone, null);
        if ("WHATSAPP".equalsIgnoreCase(channel)) {
            pref.setWhatsappOptIn(false);
        } else if ("MARKETING".equalsIgnoreCase(channel)) {
            pref.setMarketingOptIn(false);
        } else if ("EMAIL".equalsIgnoreCase(channel)) {
            pref.setEmailOptIn(false);
        } else if ("SMS".equalsIgnoreCase(channel)) {
            pref.setSmsOptIn(false);
        } else {
            // Global marketing opt-out
            pref.setMarketingOptIn(false);
            pref.setWhatsappOptIn(false);
        }
        ContactPreference saved = preferenceRepository.save(pref);
        log.info("Opt-out recorded for phone {} on channel {}", phone, channel);
        return ContactPreferenceDto.fromEntity(saved);
    }

    @Transactional
    public ContactPreferenceDto optIn(String phone, String channel) {
        ContactPreference pref = getOrCreatePreference(phone, null);
        if ("WHATSAPP".equalsIgnoreCase(channel)) {
            pref.setWhatsappOptIn(true);
        } else if ("MARKETING".equalsIgnoreCase(channel)) {
            pref.setMarketingOptIn(true);
        } else if ("EMAIL".equalsIgnoreCase(channel)) {
            pref.setEmailOptIn(true);
        } else if ("SMS".equalsIgnoreCase(channel)) {
            pref.setSmsOptIn(true);
        } else {
            pref.setMarketingOptIn(true);
            pref.setWhatsappOptIn(true);
        }
        ContactPreference saved = preferenceRepository.save(pref);
        log.info("Opt-in recorded for phone {} on channel {}", phone, channel);
        return ContactPreferenceDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public boolean canSendMarketing(String phone, CommunicationChannel channel) {
        if (phone == null || phone.isBlank()) return false;
        Optional<ContactPreference> opt = preferenceRepository.findByPhone(phone.trim());
        if (opt.isEmpty()) {
            return true; // Default opt-in
        }
        ContactPreference pref = opt.get();
        if (!pref.isMarketingOptIn()) return false;

        if (channel == CommunicationChannel.WHATSAPP) {
            return pref.isWhatsappOptIn();
        } else if (channel == CommunicationChannel.EMAIL) {
            return pref.isEmailOptIn();
        } else if (channel == CommunicationChannel.SMS) {
            return pref.isSmsOptIn();
        }
        return true;
    }

    @Transactional(readOnly = true)
    public boolean canSendWhatsApp(String phone) {
        if (phone == null || phone.isBlank()) return false;
        Optional<ContactPreference> opt = preferenceRepository.findByPhone(phone.trim());
        return opt.map(ContactPreference::isWhatsappOptIn).orElse(true);
    }
}
