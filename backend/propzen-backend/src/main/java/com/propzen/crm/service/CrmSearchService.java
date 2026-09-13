package com.propzen.crm.service;

import com.propzen.crm.dto.CrmSearchResponseDto;
import com.propzen.crm.dto.EnquiryDto;
import com.propzen.crm.dto.LeadDto;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.LeadSpecifications;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class CrmSearchService {

    private final LeadRepository leadRepository;
    private final EnquiryRepository enquiryRepository;

    public CrmSearchService(LeadRepository leadRepository, EnquiryRepository enquiryRepository) {
        this.leadRepository = leadRepository;
        this.enquiryRepository = enquiryRepository;
    }

    @Transactional(readOnly = true)
    public CrmSearchResponseDto search(String query) {
        CrmSearchResponseDto response = new CrmSearchResponseDto(query);
        if (query == null || query.isBlank()) {
            return response;
        }

        // Search leads
        Specification<Lead> spec = LeadSpecifications.withFilters(query, null, null, null, null, null, null, null, null, null, null);
        Page<Lead> leadPage = leadRepository.findAll(spec, PageRequest.of(0, 20));
        List<LeadDto> leadDtos = leadPage.getContent().stream().map(LeadDto::fromEntity).collect(Collectors.toList());
        response.setLeads(leadDtos);

        // Search enquiries
        List<EnquiryDto> enquiries = enquiryRepository.findByUserPhone(query.trim())
                .stream()
                .map(EnquiryDto::fromEntity)
                .collect(Collectors.toList());
        response.setEnquiries(enquiries);

        return response;
    }
}
