package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreateCustomerNoteRequest;
import com.propzen.service.dto.CustomerNoteDto;
import com.propzen.service.dto.PartnerCustomerDto;
import com.propzen.service.service.PartnerCustomerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Tag(name = "Service Partners - Customers", description = "Partner customer relationship and CRM notes APIs")
@RestController
@RequestMapping("/api/v1/partner/customers")
@PreAuthorize("hasAnyRole('SERVICE_PARTNER', 'ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class PartnerCustomerController {

    private final PartnerCustomerService customerService;
    private final CurrentUserService currentUserService;

    public PartnerCustomerController(PartnerCustomerService customerService,
                                     CurrentUserService currentUserService) {
        this.customerService = customerService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "List all customers serviced by the authenticated partner")
    @GetMapping
    public ResponseEntity<ApiResponse<List<PartnerCustomerDto>>> getCustomers() {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        List<PartnerCustomerDto> list = customerService.getCustomersForPartner(partner);
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @Operation(summary = "Get serviced customer details by ID")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PartnerCustomerDto>> getCustomerDetails(@PathVariable UUID id) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        PartnerCustomerDto dto = customerService.getCustomerDetails(id, partner);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @Operation(summary = "Get notes for a specific customer")
    @GetMapping("/{id}/notes")
    public ResponseEntity<ApiResponse<List<CustomerNoteDto>>> getNotes(@PathVariable UUID id) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        List<CustomerNoteDto> notes = customerService.getNotes(id, partner);
        return ResponseEntity.ok(ApiResponse.ok(notes));
    }

    @Operation(summary = "Add a CRM note for a customer")
    @PostMapping("/{id}/notes")
    public ResponseEntity<ApiResponse<CustomerNoteDto>> addNote(
            @PathVariable UUID id,
            @Valid @RequestBody CreateCustomerNoteRequest request
    ) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        CustomerNoteDto created = customerService.addNote(id, request, partner);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created, "Customer note added successfully"));
    }
}
