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

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * HTTP REST adapter for OpenAI-compatible APIs (OpenAI, vLLM, Ollama, local Python engine).
 */
@Component
public class OpenAiCompatibleProvider implements AiProvider {

    private static final Logger log = LoggerFactory.getLogger(OpenAiCompatibleProvider.class);
    private final AiConfig config;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public OpenAiCompatibleProvider(AiConfig config, ObjectMapper objectMapper) {
        this.config = config;
        this.objectMapper = objectMapper;
        this.restTemplate = new RestTemplate();
    }

    @Override
    public AiProviderType getProviderType() {
        return AiProviderType.OPENAI;
    }

    @Override
    public boolean isAvailable() {
        return config.getApiKey() != null && !config.getApiKey().isBlank();
    }

    @Override
    public <T, R> AiResponse<R> execute(AiRequest<T> request, Class<R> responseType) {
        long start = System.currentTimeMillis();
        if (!isAvailable()) {
            throw new IllegalStateException("OpenAI API key is not configured");
        }

        try {
            String url = config.getApiUrl();
            if (url == null || url.isBlank()) {
                url = "https://api.openai.com/v1/chat/completions";
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(config.getApiKey());

            Map<String, Object> body = new HashMap<>();
            body.put("model", config.getModel() != null && !config.getModel().isBlank() ? config.getModel() : "gpt-4o-mini");
            body.put("temperature", request.getTemperature());
            body.put("max_tokens", request.getMaxTokens());

            String systemPrompt = "You are PropZen's real estate AI intelligence assistant. Output valid JSON adhering to schema.";
            String userPrompt = objectMapper.writeValueAsString(request.getPayload());

            body.put("messages", List.of(
                    Map.of("role", "system", "content", systemPrompt),
                    Map.of("role", "user", "content", userPrompt)
            ));

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);

            long latency = Math.max(1, System.currentTimeMillis() - start);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map choices = (Map) ((List<?>) response.getBody().get("choices")).get(0);
                Map msg = (Map) choices.get("message");
                String content = (String) msg.get("content");
                R parsed = objectMapper.readValue(content, responseType);
                return AiResponse.success(parsed, AiProviderType.OPENAI, config.getModel(), latency, 150);
            } else {
                return AiResponse.failure("Non-2xx response from OpenAI: " + response.getStatusCode(), AiProviderType.OPENAI, latency);
            }
        } catch (Exception e) {
            long latency = Math.max(1, System.currentTimeMillis() - start);
            log.warn("OpenAI API request failed: {}", e.getMessage());
            throw new RuntimeException("OpenAI invocation failed: " + e.getMessage(), e);
        }
    }
}
