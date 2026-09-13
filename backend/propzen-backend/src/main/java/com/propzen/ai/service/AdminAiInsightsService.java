package com.propzen.ai.service;

import com.propzen.ai.dto.AdminAiInsightsDto;
import com.propzen.ai.dto.AiUsageMetricsDto;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.ai.repository.AiUsageLogRepository;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.TaskStatus;
import com.propzen.crm.repository.CrmTaskRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
public class AdminAiInsightsService {

    private final LeadRepository leadRepository;
    private final DealerProfileRepository dealerRepository;
    private final CrmTaskRepository taskRepository;
    private final AiUsageLogRepository usageLogRepository;
    private final AiOrchestrator orchestrator;

    public AdminAiInsightsService(LeadRepository leadRepository,
                                  DealerProfileRepository dealerRepository,
                                  CrmTaskRepository taskRepository,
                                  AiUsageLogRepository usageLogRepository,
                                  AiOrchestrator orchestrator) {
        this.leadRepository = leadRepository;
        this.dealerRepository = dealerRepository;
        this.taskRepository = taskRepository;
        this.usageLogRepository = usageLogRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional(readOnly = true)
    public AdminAiInsightsDto getAdminInsights(AuthenticatedUser admin) {
        long newLeads = leadRepository.countByStatus(LeadStatus.NEW);
        long pendingVerifications = dealerRepository.countByVerificationStatus(DealerVerificationStatus.PENDING);
        long overdueTasks = taskRepository.countByStatus(TaskStatus.OVERDUE);

        Map<String, Object> payload = new HashMap<>();
        payload.put("newLeadsCount", newLeads);
        payload.put("pendingVerificationsCount", pendingVerifications);
        payload.put("overdueTasksCount", overdueTasks);

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.ADMIN_INSIGHTS,
                payload,
                admin != null ? admin.getUserId() : null
        );

        AiResponse<AdminAiInsightsDto> resp = orchestrator.execute(req, AdminAiInsightsDto.class);
        return resp.getData();
    }

    @Transactional(readOnly = true)
    public AiUsageMetricsDto getUsageMetrics() {
        AiUsageMetricsDto metrics = new AiUsageMetricsDto();
        metrics.setTotalRequests(usageLogRepository.count());
        metrics.setSuccessfulRequests(usageLogRepository.countSuccessfulRequests());
        metrics.setFailedRequests(usageLogRepository.countFailedRequests());
        metrics.setFallbackRequests(usageLogRepository.countFallbackRequests());
        metrics.setAverageLatencyMs(usageLogRepository.getAverageLatencyMs());
        metrics.setTotalTokensUsed(usageLogRepository.getTotalTokensUsed());
        metrics.setActiveProvider("LOCAL");
        return metrics;
    }
}
