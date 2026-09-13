package com.propzen.ai.orchestrator;

import com.propzen.ai.config.AiConfig;
import com.propzen.ai.entity.AiUsageLog;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiProviderType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.provider.AiProvider;
import com.propzen.ai.provider.AiProviderFactory;
import com.propzen.ai.repository.AiUsageLogRepository;
import com.propzen.ai.service.AiCacheService;
import com.propzen.ai.service.AiSafetyService;
import com.propzen.exception.BadRequestException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Core AI Orchestration engine.
 * Enforces rate limits, input safety, caching, circuit breaking, automatic fallback, and usage audit logging.
 */
@Component
public class AiOrchestrator {

    private static final Logger log = LoggerFactory.getLogger(AiOrchestrator.class);

    private final AiConfig config;
    private final AiProviderFactory providerFactory;
    private final AiUsageLogRepository usageLogRepository;
    private final AiSafetyService safetyService;
    private final AiCacheService cacheService;

    public AiOrchestrator(AiConfig config,
                          AiProviderFactory providerFactory,
                          AiUsageLogRepository usageLogRepository,
                          AiSafetyService safetyService,
                          AiCacheService cacheService) {
        this.config = config;
        this.providerFactory = providerFactory;
        this.usageLogRepository = usageLogRepository;
        this.safetyService = safetyService;
        this.cacheService = cacheService;
    }

    public <T, R> AiResponse<R> execute(AiRequest<T> request, Class<R> responseType) {
        long startTime = System.currentTimeMillis();

        // 1. Cost & Rate Control Validation
        enforceRateLimits(request);

        // 2. Input Safety Sanitization
        safetyService.validatePayload(request.getPayload());

        // 3. Cache lookup for cacheable operations
        String cacheKey = null;
        if (!request.isBypassCache() && isCacheable(request.getOperation())) {
            cacheKey = cacheService.computeKey(request.getOperation().name(), request.getPayload());
            R cached = cacheService.get(cacheKey, responseType);
            if (cached != null) {
                log.debug("Serving cached AI result for {}", request.getOperation());
                return AiResponse.success(cached, AiProviderType.LOCAL, "cache", 1, 0);
            }
        }

        AiProvider primaryProvider = providerFactory.getActiveProvider();
        AiResponse<R> response;
        boolean fallbackUsed = false;
        String errorMessage = null;

        try {
            // 4. Timed execution with fallback
            int timeout = config.getTimeoutMs() > 0 ? config.getTimeoutMs() : 10000;
            response = CompletableFuture.supplyAsync(() -> primaryProvider.execute(request, responseType))
                    .get(timeout, TimeUnit.MILLISECONDS);

            if (!response.isSuccess()) {
                throw new RuntimeException("Primary AI provider failed: " + response.getErrorMessage());
            }
        } catch (Exception e) {
            log.warn("Primary AI provider {} failed or timed out for {}: {}. Activating local fallback engine.",
                    primaryProvider.getProviderType(), request.getOperation(), e.getMessage());

            fallbackUsed = true;
            errorMessage = e instanceof TimeoutException ? "Execution timed out" : e.getMessage();

            // 5. Automatic Fallback Execution
            AiProvider fallback = providerFactory.getFallbackProvider();
            response = fallback.execute(request, responseType);
            response.setFallbackUsed(true);
            response.setErrorMessage("Fallback activated: " + errorMessage);
        }

        long latency = System.currentTimeMillis() - startTime;
        response.setLatencyMs(latency);

        // 6. Asynchronous usage audit logging
        logUsage(request, response, fallbackUsed, errorMessage, latency);

        // 7. Store in cache if successful
        if (response.isSuccess() && cacheKey != null && response.getData() != null) {
            cacheService.put(cacheKey, response.getData(), 3600000); // 1 hour TTL
        }

        return response;
    }

    private <T> void enforceRateLimits(AiRequest<T> request) {
        if (request.getUserId() != null) {
            OffsetDateTime oneDayAgo = OffsetDateTime.now().minusHours(24);
            long userRequestsToday = usageLogRepository.countByUserIdAndCreatedAtAfter(request.getUserId(), oneDayAgo);
            if (userRequestsToday >= config.getMaxRequestsPerUser()) {
                throw new BadRequestException("Daily AI request limit (" + config.getMaxRequestsPerUser() + ") reached for user.");
            }
        }

        OffsetDateTime oneDayAgo = OffsetDateTime.now().minusHours(24);
        long systemRequestsToday = usageLogRepository.countByCreatedAtAfter(oneDayAgo);
        if (systemRequestsToday >= config.getDailyLimit()) {
            throw new BadRequestException("System daily AI processing capacity reached. Please try again later.");
        }
    }

    private boolean isCacheable(AiOperationType operation) {
        return operation == AiOperationType.PROPERTY_DESCRIPTION_GENERATION ||
                operation == AiOperationType.MARKET_INTELLIGENCE;
    }

    private <T, R> void logUsage(AiRequest<T> request, AiResponse<R> response, boolean fallbackUsed, String error, long latency) {
        try {
            AiUsageLog logEntry = new AiUsageLog(
                    request.getRequestId(),
                    request.getUserId(),
                    request.getOperation().name(),
                    response.getProvider() != null ? response.getProvider().name() : primaryProviderName(),
                    response.getModel(),
                    response.getTokensUsed(),
                    latency,
                    response.isSuccess() ? "SUCCESS" : "FAILED",
                    fallbackUsed,
                    error
            );
            usageLogRepository.save(logEntry);
        } catch (Exception e) {
            log.error("Failed to persist AI usage log: {}", e.getMessage());
        }
    }

    private String primaryProviderName() {
        return config.getProvider() != null ? config.getProvider().name() : "LOCAL";
    }
}
