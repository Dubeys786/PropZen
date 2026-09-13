package com.propzen.ai.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.ai.config.AiConfig;
import com.propzen.ai.model.AiProviderType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/**
 * HTTP REST adapter for Google Gemini API.
 */
@Component
public class GeminiAiProvider implements AiProvider {

    private static final Logger log = LoggerFactory.getLogger(GeminiAiProvider.class);
    private final AiConfig config;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public GeminiAiProvider(AiConfig config, ObjectMapper objectMapper) {
        this.config = config;
        this.objectMapper = objectMapper;
        this.restTemplate = new RestTemplate();
    }

    @Override
    public AiProviderType getProviderType() {
        return AiProviderType.GEMINI;
    }

    @Override
    public boolean isAvailable() {
        return config.getApiKey() != null && !config.getApiKey().isBlank();
    }

    @Override
    public <T, R> AiResponse<R> execute(AiRequest<T> request, Class<R> responseType) {
        long start = System.currentTimeMillis();
        if (!isAvailable()) {
            throw new IllegalStateException("Gemini API key is not configured");
        }

        try {
            String model = config.getModel() != null && !config.getModel().isBlank() ? config.getModel() : "gemini-1.5-flash";
            String url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + config.getApiKey();

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            String userText = objectMapper.writeValueAsString(request.getPayload());
            Map<String, Object> body = Map.of(
                    "contents", List.of(
                            Map.of("parts", List.of(Map.of("text", userText)))
                    )
            );

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);

            long latency = Math.max(1, System.currentTimeMillis() - start);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map candidate = (Map) ((List<?>) response.getBody().get("candidates")).get(0);
                Map content = (Map) candidate.get("content");
                Map part = (Map) ((List<?>) content.get("parts")).get(0);
                String text = (String) part.get("text");
                R parsed = objectMapper.readValue(text, responseType);
                return AiResponse.success(parsed, AiProviderType.GEMINI, model, latency, 120);
            } else {
                return AiResponse.failure("Non-2xx response from Gemini: " + response.getStatusCode(), AiProviderType.GEMINI, latency);
            }
        } catch (Exception e) {
            long latency = Math.max(1, System.currentTimeMillis() - start);
            log.warn("Gemini API request failed: {}", e.getMessage());
            throw new RuntimeException("Gemini invocation failed: " + e.getMessage(), e);
        }
    }
}
