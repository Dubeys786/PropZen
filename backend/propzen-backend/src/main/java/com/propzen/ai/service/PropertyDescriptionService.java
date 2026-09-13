package com.propzen.ai.service;

import com.propzen.ai.dto.PropertyDescriptionDto;
import com.propzen.ai.dto.PropertyDescriptionRequest;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.property.entity.Property;
import com.propzen.property.repository.PropertyRepository;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
public class PropertyDescriptionService {

    private final PropertyRepository propertyRepository;
    private final AiOrchestrator orchestrator;

    public PropertyDescriptionService(PropertyRepository propertyRepository, AiOrchestrator orchestrator) {
        this.propertyRepository = propertyRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional(readOnly = true)
    public PropertyDescriptionDto generateDescription(PropertyDescriptionRequest req, AuthenticatedUser actor) {
        // If propertyId provided, sync verified DB fields
        if (req.getPropertyId() != null) {
            propertyRepository.findById(req.getPropertyId()).ifPresent(p -> {
                if (req.getTitle() == null || req.getTitle().isBlank()) req.setTitle(p.getTitle());
                if (req.getCity() == null || req.getCity().isBlank()) req.setCity(p.getCity());
                if (req.getSector() == null || req.getSector().isBlank()) req.setSector(p.getSector());
                if (req.getBhk() == null || req.getBhk().isBlank()) req.setBhk(p.getBhk());
                if (req.getPriceCr() == null) req.setPriceCr(p.getPriceCr());
                if (req.getSqft() == null) req.setSqft(p.getSqft());
            });
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("title", req.getTitle());
        payload.put("city", req.getCity());
        payload.put("sector", req.getSector());
        payload.put("bhk", req.getBhk());
        payload.put("propertyType", req.getPropertyType());
        payload.put("sqft", req.getSqft());
        payload.put("priceCr", req.getPriceCr());
        payload.put("amenities", req.getAmenities());
        payload.put("possessionStatus", req.getPossessionStatus());
        payload.put("developerName", req.getDeveloperName());

        AiRequest<Map<String, Object>> aiReq = AiRequest.of(
                AiOperationType.PROPERTY_DESCRIPTION_GENERATION,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<PropertyDescriptionDto> resp = orchestrator.execute(aiReq, PropertyDescriptionDto.class);
        return resp.getData();
    }
}
