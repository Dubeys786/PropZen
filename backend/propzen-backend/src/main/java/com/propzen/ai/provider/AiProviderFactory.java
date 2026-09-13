package com.propzen.ai.provider;

import com.propzen.ai.config.AiConfig;
import com.propzen.ai.model.AiProviderType;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Factory for resolving AI provider by active configuration or explicit request.
 */
@Component
public class AiProviderFactory {

    private final AiConfig config;
    private final Map<AiProviderType, AiProvider> providers;
    private final LocalRuleBasedAiProvider fallbackProvider;

    public AiProviderFactory(AiConfig config, List<AiProvider> providerList, LocalRuleBasedAiProvider fallbackProvider) {
        this.config = config;
        this.fallbackProvider = fallbackProvider;
        this.providers = providerList.stream()
                .collect(Collectors.toMap(AiProvider::getProviderType, Function.identity(), (a, b) -> a));
    }

    public AiProvider getActiveProvider() {
        AiProviderType configured = config.getProvider();
        AiProvider provider = providers.get(configured);
        if (provider != null && provider.isAvailable()) {
            return provider;
        }
        return fallbackProvider;
    }

    public AiProvider getFallbackProvider() {
        return fallbackProvider;
    }
}
