package com.propzen.ai.service;

import com.propzen.ai.dto.EnquiryClassificationDto;
import com.propzen.ai.entity.AiEnquiryClassification;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.ai.repository.AiEnquiryClassificationRepository;
import com.propzen.crm.entity.Enquiry;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class EnquiryClassificationService {

    private final EnquiryRepository enquiryRepository;
    private final AiEnquiryClassificationRepository classificationRepository;
    private final AiOrchestrator orchestrator;

    public EnquiryClassificationService(EnquiryRepository enquiryRepository,
                                        AiEnquiryClassificationRepository classificationRepository,
                                        AiOrchestrator orchestrator) {
        this.enquiryRepository = enquiryRepository;
        this.classificationRepository = classificationRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional
    public EnquiryClassificationDto classifyEnquiry(UUID enquiryId, String messageOverride, AuthenticatedUser actor) {
        Enquiry enquiry = enquiryRepository.findById(enquiryId)
                .orElseThrow(() -> new ResourceNotFoundException("Enquiry", enquiryId));

        String message = messageOverride != null && !messageOverride.isBlank() ? messageOverride : enquiry.getMessage();

        Map<String, Object> payload = new HashMap<>();
        payload.put("enquiryId", enquiry.getId());
        payload.put("message", message);
        payload.put("propertyId", enquiry.getPropertyId());

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.ENQUIRY_CLASSIFICATION,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<EnquiryClassificationDto> resp = orchestrator.execute(req, EnquiryClassificationDto.class);
        EnquiryClassificationDto dto = resp.getData();

        // Persist separately to avoid mutating original message
        AiEnquiryClassification entity = classificationRepository.findByEnquiryId(enquiryId)
                .orElse(new AiEnquiryClassification());

        entity.setEnquiryId(enquiryId);
        entity.setCategory(dto.getCategory());
        entity.setPriority(dto.getPriority());
        entity.setSentiment(dto.getSentiment());
        entity.setSuggestedDepartment(dto.getSuggestedDepartment());
        entity.setSuggestedAction(dto.getSuggestedAction());
        entity.setConfidence(dto.getConfidence());
        classificationRepository.save(entity);

        return dto;
    }

    @Transactional(readOnly = true)
    public EnquiryClassificationDto getClassification(UUID enquiryId) {
        return classificationRepository.findByEnquiryId(enquiryId)
                .map(c -> new EnquiryClassificationDto(
                        c.getEnquiryId(),
                        c.getCategory(),
                        c.getPriority(),
                        c.getSentiment(),
                        c.getSuggestedDepartment(),
                        c.getSuggestedAction(),
                        c.getConfidence() != null ? c.getConfidence() : 0.92
                ))
                .orElse(null);
    }
}
