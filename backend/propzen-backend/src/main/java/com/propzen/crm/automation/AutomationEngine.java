package com.propzen.crm.automation;

import com.propzen.crm.entity.AutomationExecution;
import com.propzen.crm.entity.AutomationRule;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.MessageTemplate;
import com.propzen.crm.notification.WhatsAppProvider;
import com.propzen.crm.notification.WhatsAppResponse;
import com.propzen.crm.repository.AutomationExecutionRepository;
import com.propzen.crm.repository.AutomationRuleRepository;
import com.propzen.crm.repository.MessageTemplateRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Event-driven automation rule evaluation and execution engine.
 */
@Service
public class AutomationEngine {

    private static final Logger log = LoggerFactory.getLogger(AutomationEngine.class);

    private final AutomationRuleRepository ruleRepository;
    private final AutomationExecutionRepository executionRepository;
    private final MessageTemplateRepository templateRepository;
    private final WhatsAppProvider whatsAppProvider;

    public AutomationEngine(AutomationRuleRepository ruleRepository,
                            AutomationExecutionRepository executionRepository,
                            MessageTemplateRepository templateRepository,
                            WhatsAppProvider whatsAppProvider) {
        this.ruleRepository = ruleRepository;
        this.executionRepository = executionRepository;
        this.templateRepository = templateRepository;
        this.whatsAppProvider = whatsAppProvider;
    }

    @Transactional
    public void handleEvent(AutomationEvent event) {
        if (event == null || event.getEventType() == null) {
            return;
        }

        List<AutomationRule> rules = ruleRepository.findByEventTypeAndEnabledTrue(event.getEventType().name());
        log.info("Evaluating {} automation rules for event {}", rules.size(), event.getEventType());

        for (AutomationRule rule : rules) {
            try {
                executeRule(rule, event);
            } catch (Exception e) {
                log.error("Failed to execute automation rule {}: {}", rule.getName(), e.getMessage(), e);
                recordExecution(rule, event, "FAILED", e.getMessage());
            }
        }
    }

    private void executeRule(AutomationRule rule, AutomationEvent event) {
        Lead lead = event.getLead();
        if (lead == null || lead.getPhone() == null) {
            recordExecution(rule, event, "SKIPPED", "No lead or phone associated with event");
            return;
        }

        if ("WHATSAPP_TEMPLATE".equalsIgnoreCase(rule.getActionType()) || "SEND_WHATSAPP".equalsIgnoreCase(rule.getActionType())) {
            String templateName = "lead_acknowledgement";
            if (rule.getTemplateId() != null) {
                templateName = templateRepository.findById(rule.getTemplateId())
                        .map(MessageTemplate::getTemplateIdentifier)
                        .orElse("lead_acknowledgement");
            }

            Map<String, String> vars = new HashMap<>();
            vars.put("name", lead.getName());
            vars.put("leadNumber", lead.getLeadNumber());
            if (lead.getPropertyId() != null) {
                vars.put("propertyId", lead.getPropertyId());
            }

            WhatsAppResponse resp = whatsAppProvider.sendTemplateMessage(lead.getPhone(), templateName, "en", vars);
            recordExecution(rule, event, resp.isSuccess() ? "SUCCESS" : "FAILED",
                    "WhatsApp message ID: " + resp.getProviderMessageId() + (resp.getErrorMessage() != null ? " Error: " + resp.getErrorMessage() : ""));
        } else {
            recordExecution(rule, event, "SUCCESS", "Action " + rule.getActionType() + " completed");
        }
    }

    private void recordExecution(AutomationRule rule, AutomationEvent event, String status, String result) {
        AutomationExecution exec = new AutomationExecution();
        exec.setRuleId(rule != null ? rule.getId() : null);
        exec.setEventType(event.getEventType().name());
        exec.setLeadId(event.getLeadId());
        exec.setStatus(status);
        exec.setResult(result);
        executionRepository.save(exec);
    }
}
