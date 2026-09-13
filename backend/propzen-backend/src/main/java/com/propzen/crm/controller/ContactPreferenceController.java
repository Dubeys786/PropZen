package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.ContactPreferenceDto;
import com.propzen.crm.dto.UpdateContactPreferenceRequest;
import com.propzen.crm.service.ContactPreferenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/communication")
@Tag(name = "Consent & Opt-Out Management", description = "Compliance endpoints for managing WhatsApp/Marketing opt-in and opt-out")
public class ContactPreferenceController {

    private final ContactPreferenceService preferenceService;

    public ContactPreferenceController(ContactPreferenceService preferenceService) {
        this.preferenceService = preferenceService;
    }

    @PostMapping("/opt-out")
    @Operation(summary = "Opt-out a phone number from marketing communications or WhatsApp")
    public ResponseEntity<ApiResponse<ContactPreferenceDto>> optOut(
            @RequestParam String phone,
            @RequestParam(required = false, defaultValue = "ALL") String channel) {
        ContactPreferenceDto result = preferenceService.optOut(phone, channel);
        return ResponseEntity.ok(ApiResponse.ok(result, "Opt-out recorded successfully"));
    }

    @PostMapping("/opt-in")
    @Operation(summary = "Opt-in a phone number to communications")
    public ResponseEntity<ApiResponse<ContactPreferenceDto>> optIn(
            @RequestParam String phone,
            @RequestParam(required = false, defaultValue = "ALL") String channel) {
        ContactPreferenceDto result = preferenceService.optIn(phone, channel);
        return ResponseEntity.ok(ApiResponse.ok(result, "Opt-in recorded successfully"));
    }

    @GetMapping("/preferences")
    @Operation(summary = "Get contact preferences by phone")
    public ResponseEntity<ApiResponse<ContactPreferenceDto>> getPreferences(@RequestParam String phone) {
        ContactPreferenceDto dto = preferenceService.getPreferenceByPhone(phone)
                .orElseGet(() -> ContactPreferenceDto.fromEntity(preferenceService.getOrCreatePreference(phone, null)));
        return ResponseEntity.ok(ApiResponse.ok(dto, "Preferences retrieved"));
    }

    @PatchMapping("/preferences")
    @Operation(summary = "Update contact preferences")
    public ResponseEntity<ApiResponse<ContactPreferenceDto>> updatePreferences(
            @RequestParam String phone,
            @RequestBody UpdateContactPreferenceRequest request) {
        ContactPreferenceDto updated = preferenceService.updatePreference(phone, request, null);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Preferences updated"));
    }
}
