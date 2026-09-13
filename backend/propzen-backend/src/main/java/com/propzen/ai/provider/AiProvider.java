package com.propzen.ai.provider;

import com.propzen.ai.model.AiProviderType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;

/**
 * Service Provider Interface (SPI) for all PropZen AI engines.
 */
public interface AiProvider {

    AiProviderType getProviderType();

    boolean isAvailable();

    <T, R> AiResponse<R> execute(AiRequest<T> request, Class<R> responseType);
}
