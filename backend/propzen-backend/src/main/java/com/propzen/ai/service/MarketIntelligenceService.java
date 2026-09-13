package com.propzen.ai.service;

import com.propzen.ai.dto.MarketIntelligenceDto;
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
import java.util.List;
import java.util.Map;

@Service
public class MarketIntelligenceService {

    private final PropertyRepository propertyRepository;
    private final AiOrchestrator orchestrator;

    public MarketIntelligenceService(PropertyRepository propertyRepository, AiOrchestrator orchestrator) {
        this.propertyRepository = propertyRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional(readOnly = true)
    public MarketIntelligenceDto getMarketTrends(String city, String sector, AuthenticatedUser actor) {
        List<Property> properties = propertyRepository.findAll();
        long activeCount = properties.stream()
                .filter(p -> (city == null || city.equalsIgnoreCase(p.getCity())) &&
                             (sector == null || sector.equalsIgnoreCase(p.getSector())))
                .count();

        if (activeCount == 0 && properties.isEmpty()) {
            return MarketIntelligenceDto.insufficientData(city, sector);
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("city", city != null ? city : "All Cities");
        payload.put("sector", sector != null ? sector : "All Sectors");
        payload.put("activeListingsCount", activeCount > 0 ? activeCount : properties.size());

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.MARKET_INTELLIGENCE,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<MarketIntelligenceDto> resp = orchestrator.execute(req, MarketIntelligenceDto.class);
        return resp.getData();
    }
}
