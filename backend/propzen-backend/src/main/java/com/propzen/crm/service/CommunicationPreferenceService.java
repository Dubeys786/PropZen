package com.propzen.crm.service;

import com.propzen.crm.dto.CommunicationPreferenceDto;
import com.propzen.crm.entity.CommunicationPreference;
import com.propzen.crm.repository.CommunicationPreferenceRepository;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class CommunicationPreferenceService {

    private final CommunicationPreferenceRepository preferenceRepository;

    public CommunicationPreferenceService(CommunicationPreferenceRepository preferenceRepository) {
        this.preferenceRepository = preferenceRepository;
    }

    @Transactional(readOnly = true)
    public CommunicationPreferenceDto getPreferences(String phone, AuthenticatedUser user) {
        Optional<CommunicationPreference> opt = preferenceRepository.findByPhone(phone);
        if (opt.isPresent()) {
            return CommunicationPreferenceDto.fromEntity(opt.get());
        }
        // Default to all opt-in
        CommunicationPreferenceDto def = new CommunicationPreferenceDto();
        def.setPhone(phone);
        def.setWhatsappOptIn(true);
        def.setEmailOptIn(true);
        def.setSmsOptIn(true);
        def.setMarketingOptIn(true);
        return def;
    }

    @Transactional
    public CommunicationPreferenceDto updatePreferences(CommunicationPreferenceDto dto, AuthenticatedUser user) {
        String phone = dto.getPhone() != null ? dto.getPhone().trim() : (user != null ? user.getPhone() : null);
        if (phone == null || phone.isBlank()) {
            throw new IllegalArgumentException("Phone number is required for communication preferences");
        }

        CommunicationPreference pref = preferenceRepository.findByPhone(phone)
                .orElseGet(() -> {
                    CommunicationPreference p = new CommunicationPreference();
                    p.setPhone(phone);
                    if (user != null) {
                        p.setUserId(user.getUserId());
                    }
                    return p;
                });

        if (dto.getWhatsappOptIn() != null) pref.setWhatsappOptIn(dto.getWhatsappOptIn());
        if (dto.getEmailOptIn() != null) pref.setEmailOptIn(dto.getEmailOptIn());
        if (dto.getSmsOptIn() != null) pref.setSmsOptIn(dto.getSmsOptIn());
        if (dto.getMarketingOptIn() != null) pref.setMarketingOptIn(dto.getMarketingOptIn());

        CommunicationPreference saved = preferenceRepository.save(pref);
        return CommunicationPreferenceDto.fromEntity(saved);
    }
}
