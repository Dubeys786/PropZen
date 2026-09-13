package com.propzen.crm.service;

import com.propzen.crm.dto.CreateWhatsAppTemplateRequest;
import com.propzen.crm.dto.WhatsAppTemplateDto;
import com.propzen.crm.entity.WhatsAppTemplateEntity;
import com.propzen.crm.model.WhatsAppTemplateStatus;
import com.propzen.crm.repository.WhatsAppTemplateRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class WhatsAppTemplateService {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppTemplateService.class);

    private final WhatsAppTemplateRepository templateRepository;

    public WhatsAppTemplateService(WhatsAppTemplateRepository templateRepository) {
        this.templateRepository = templateRepository;
    }

    @Transactional(readOnly = true)
    public List<WhatsAppTemplateDto> getAllTemplates() {
        return templateRepository.findAll()
                .stream()
                .map(WhatsAppTemplateDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<WhatsAppTemplateDto> getApprovedTemplates() {
        return templateRepository.findByStatus(WhatsAppTemplateStatus.APPROVED)
                .stream()
                .map(WhatsAppTemplateDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Optional<WhatsAppTemplateEntity> findByName(String name) {
        return templateRepository.findByName(name)
                .or(() -> templateRepository.findByTemplateName(name));
    }

    @Transactional
    public WhatsAppTemplateDto createTemplate(CreateWhatsAppTemplateRequest req) {
        WhatsAppTemplateEntity entity = new WhatsAppTemplateEntity(
                req.getName(),
                req.getTemplateName(),
                req.getLanguage(),
                req.getCategory(),
                req.getContent(),
                req.getVariables()
        );
        entity.setProviderTemplateId(req.getProviderTemplateId());
        WhatsAppTemplateEntity saved = templateRepository.save(entity);
        log.info("Created WhatsApp template {}", saved.getName());
        return WhatsAppTemplateDto.fromEntity(saved);
    }

    @Transactional
    public WhatsAppTemplateDto updateStatus(UUID templateId, WhatsAppTemplateStatus status) {
        WhatsAppTemplateEntity entity = templateRepository.findById(templateId)
                .orElseThrow(() -> new NoSuchElementException("Template not found: " + templateId));

        entity.setStatus(status);
        WhatsAppTemplateEntity saved = templateRepository.save(entity);
        log.info("Updated WhatsApp template {} status to {}", entity.getName(), status);
        return WhatsAppTemplateDto.fromEntity(saved);
    }

    /**
     * Interpolates named variables into the template text.
     * Replaces {{key}} with value.
     */
    public String interpolate(String templateContent, Map<String, String> variables) {
        if (templateContent == null) return "";
        if (variables == null || variables.isEmpty()) return templateContent;

        String result = templateContent;
        for (Map.Entry<String, String> entry : variables.entrySet()) {
            String placeholder = "{{" + entry.getKey() + "}}";
            String val = entry.getValue() != null ? entry.getValue() : "";
            result = result.replace(placeholder, val);
        }
        return result;
    }
}
