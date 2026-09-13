package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CrmSearchResponseDto;
import com.propzen.crm.service.CrmSearchService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/crm/search")
@Tag(name = "CRM Global Search", description = "Global omni-search across leads, enquiries, and customers")
public class CrmSearchController {

    private final CrmSearchService searchService;

    public CrmSearchController(CrmSearchService searchService) {
        this.searchService = searchService;
    }

    @GetMapping
    @Operation(summary = "Perform global CRM search")
    public ResponseEntity<ApiResponse<CrmSearchResponseDto>> search(@RequestParam String q) {
        CrmSearchResponseDto result = searchService.search(q);
        return ResponseEntity.ok(ApiResponse.ok(result, "Search completed"));
    }
}
