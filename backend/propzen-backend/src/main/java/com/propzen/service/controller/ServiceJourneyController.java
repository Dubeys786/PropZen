package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.ServiceJourneyEventDto;
import com.propzen.service.service.ServiceJourneyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Services - Journey", description = "Service journey timeline and chronological milestone history APIs")
@RestController
@RequestMapping("/api/v1/services/requests")
@SecurityRequirement(name = "BearerAuth")
public class ServiceJourneyController {

    private final ServiceJourneyService journeyService;
    private final CurrentUserService currentUserService;

    public ServiceJourneyController(ServiceJourneyService journeyService,
                                   CurrentUserService currentUserService) {
        this.journeyService = journeyService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Get chronological journey timeline for a service request")
    @GetMapping("/{id}/journey")
    public ResponseEntity<ApiResponse<List<ServiceJourneyEventDto>>> getJourneyTimeline(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<ServiceJourneyEventDto> timeline = journeyService.getJourneyTimeline(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(timeline));
    }
}
