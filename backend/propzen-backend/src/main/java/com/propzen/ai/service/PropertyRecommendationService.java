package com.propzen.ai.service;

import com.propzen.ai.dto.PropertyRecommendationDto;
import com.propzen.ai.dto.PropertyRecommendationRequest;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.property.entity.Property;
import com.propzen.property.repository.PropertyRepository;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class PropertyRecommendationService {

    private final PropertyRepository propertyRepository;
    private final AiOrchestrator orchestrator;

    public PropertyRecommendationService(PropertyRepository propertyRepository, AiOrchestrator orchestrator) {
        this.propertyRepository = propertyRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional(readOnly = true)
    public List<PropertyRecommendationDto> getRecommendations(PropertyRecommendationRequest criteria, AuthenticatedUser actor) {
        // Fetch real candidate properties from live database
        List<Property> candidates = propertyRepository.findAll(PageRequest.of(0, 50)).getContent();

        List<Map<String, Object>> candidateDtos = candidates.stream().map(p -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", p.getId());
            map.put("title", p.getTitle());
            map.put("city", p.getCity());
            map.put("sector", p.getSector());
            map.put("bhk", p.getBhk());
            map.put("propertyType", p.getPropertyType());
            map.put("priceCr", p.getPriceCr());
            map.put("sqft", p.getSqft());
            return map;
        }).collect(Collectors.toList());

        Map<String, Object> payload = new HashMap<>();
        payload.put("candidateProperties", candidateDtos);
        payload.put("city", criteria.getCity());
        payload.put("sector", criteria.getSector());
        payload.put("bhk", criteria.getBhk());
        payload.put("propertyType", criteria.getPropertyType());
        payload.put("maxBudgetCr", criteria.getMaxBudgetCr());

        AiRequest<Map<String, Object>> request = AiRequest.of(
                AiOperationType.PROPERTY_RECOMMENDATION,
                payload,
                actor != null ? actor.getUserId() : criteria.getUserId()
        );

        AiResponse<List> response = orchestrator.execute(request, List.class);
        List<?> rawList = response.getData();

        return rawList.stream()
                .limit(criteria.getLimit() > 0 ? criteria.getLimit() : 10)
                .map(item -> {
                    if (item instanceof PropertyRecommendationDto) {
                        return (PropertyRecommendationDto) item;
                    }
                    Map map = (Map) item;
                    return new PropertyRecommendationDto(
                            java.util.UUID.fromString(map.get("propertyId").toString()),
                            (String) map.get("title"),
                            (String) map.get("city"),
                            (String) map.get("sector"),
                            (String) map.get("bhk"),
                            (String) map.get("propertyType"),
                            map.get("priceCr") != null ? new java.math.BigDecimal(map.get("priceCr").toString()) : null,
                            map.get("sqft") != null ? Integer.parseInt(map.get("sqft").toString()) : null,
                            map.get("matchPercentage") != null ? Double.parseDouble(map.get("matchPercentage").toString()) : 50.0,
                            (List<String>) map.get("matchHighlights")
                    );
                })
                .collect(Collectors.toList());
    }
}
