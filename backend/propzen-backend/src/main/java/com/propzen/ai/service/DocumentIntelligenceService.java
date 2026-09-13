package com.propzen.ai.service;

import com.propzen.ai.dto.DocumentIntelligenceDto;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class DocumentIntelligenceService {

    private final AiOrchestrator orchestrator;

    public DocumentIntelligenceService(AiOrchestrator orchestrator) {
        this.orchestrator = orchestrator;
    }

    public DocumentIntelligenceDto analyzeDocument(String fileName, String mimeType, Long fileSize, AuthenticatedUser actor) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("fileName", fileName);
        payload.put("mimeType", mimeType);
        payload.put("fileSize", fileSize);

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.DOCUMENT_INTELLIGENCE,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<DocumentIntelligenceDto> resp = orchestrator.execute(req, DocumentIntelligenceDto.class);
        return resp.getData();
    }
}
