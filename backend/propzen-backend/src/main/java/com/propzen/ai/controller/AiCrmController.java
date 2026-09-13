package com.propzen.ai.controller;

import com.propzen.ai.dto.AiFollowUpDraftDto;
import com.propzen.ai.dto.CrmAiSummaryDto;
import com.propzen.ai.dto.LeadScoreDto;
import com.propzen.ai.dto.NextActionDto;
import com.propzen.ai.service.AiFollowUpService;
import com.propzen.ai.service.AiLeadScoringService;
import com.propzen.ai.service.CrmAiAssistantService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/ai/crm")
@Tag(name = "AI CRM Intelligence", description = "Endpoints for AI-driven lead scoring, summaries, next best actions, and follow-ups")
public class AiCrmController {

    private final AiLeadScoringService leadScoringService;
    private final CrmAiAssistantService crmAiAssistantService;
    private final AiFollowUpService aiFollowUpService;
    private final CurrentUserService currentUserService;

    public AiCrmController(AiLeadScoringService leadScoringService,
                           CrmAiAssistantService crmAiAssistantService,
                           AiFollowUpService aiFollowUpService,
                           CurrentUserService currentUserService) {
        this.leadScoringService = leadScoringService;
        this.crmAiAssistantService = crmAiAssistantService;
        this.aiFollowUpService = aiFollowUpService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/lead-score/{leadId}")
    @Operation(summary = "Calculate or recalculate AI lead score",
            description = "Computes predictive qualification score (0-100), intent category, and persistence")
    public ResponseEntity<ApiResponse<LeadScoreDto>> calculateLeadScore(@PathVariable UUID leadId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadScoreDto dto = leadScoringService.calculateAndSaveLeadScore(leadId, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Lead score calculated successfully"));
    }

    @PostMapping("/lead-summary/{leadId}")
    @Operation(summary = "Generate concise AI executive summary for a lead")
    public ResponseEntity<ApiResponse<CrmAiSummaryDto>> generateLeadSummary(@PathVariable UUID leadId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        CrmAiSummaryDto dto = crmAiAssistantService.generateLeadSummary(leadId, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Lead summary generated successfully"));
    }

    @PostMapping("/next-action/{leadId}")
    @Operation(summary = "Recommend next best action for a lead")
    public ResponseEntity<ApiResponse<NextActionDto>> recommendNextAction(@PathVariable UUID leadId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        NextActionDto dto = crmAiAssistantService.recommendNextAction(leadId, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Next action recommended successfully"));
    }

    @PostMapping("/follow-up/{leadId}")
    @Operation(summary = "Generate contextual AI follow-up draft message and recommended timing")
    public ResponseEntity<ApiResponse<AiFollowUpDraftDto>> generateFollowUpDraft(@PathVariable UUID leadId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        AiFollowUpDraftDto dto = aiFollowUpService.generateFollowUpDraft(leadId, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Follow-up draft generated successfully"));
    }

    @PostMapping("/conversation-summary/{leadId}")
    @Operation(summary = "Summarize call notes or customer conversation transcripts")
    public ResponseEntity<ApiResponse<CrmAiSummaryDto>> summarizeConversation(
            @PathVariable UUID leadId,
            @RequestBody(required = false) Map<String, String> payload) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        String text = (payload != null && payload.containsKey("conversationText"))
                ? payload.get("conversationText")
                : "";
        CrmAiSummaryDto dto = crmAiAssistantService.summarizeConversation(leadId, text, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Conversation summarized successfully"));
    }
}
