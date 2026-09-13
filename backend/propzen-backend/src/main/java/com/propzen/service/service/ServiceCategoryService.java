package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.CreateServiceCategoryRequest;
import com.propzen.service.dto.ServiceCategoryDto;
import com.propzen.service.dto.UpdateServiceCategoryRequest;
import com.propzen.service.entity.ServiceCategory;
import com.propzen.service.repository.ServiceCategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ServiceCategoryService {

    private final ServiceCategoryRepository categoryRepository;
    private final AuditLogService auditLogService;

    public ServiceCategoryService(ServiceCategoryRepository categoryRepository,
                                  AuditLogService auditLogService) {
        this.categoryRepository = categoryRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public List<ServiceCategoryDto> getActiveCategories() {
        return categoryRepository.findByIsActiveTrueOrderBySortOrderAsc()
                .stream()
                .map(ServiceCategoryDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ServiceCategoryDto getCategoryById(UUID id) {
        ServiceCategory cat = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceCategory", id));
        return ServiceCategoryDto.fromEntity(cat);
    }

    @Transactional
    public ServiceCategoryDto createCategory(CreateServiceCategoryRequest request, AuthenticatedUser adminUser) {
        String slug = request.getSlug().trim().toLowerCase();
        if (categoryRepository.existsBySlug(slug)) {
            throw new BusinessException(ErrorCode.DUPLICATE_RESOURCE, "Category with slug '" + slug + "' already exists");
        }

        ServiceCategory cat = new ServiceCategory();
        cat.setName(request.getName().trim());
        cat.setSlug(slug);
        cat.setDescription(request.getDescription());
        cat.setIcon(request.getIcon());
        cat.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);
        cat.setSortOrder(request.getSortOrder() != null ? request.getSortOrder() : 0);

        ServiceCategory saved = categoryRepository.save(cat);

        auditLogService.logAction(
                adminUser.getUserId(),
                "SERVICE_CATEGORY_CREATED",
                "public.service_categories/" + saved.getId(),
                "Category '" + saved.getName() + "' created"
        );

        return ServiceCategoryDto.fromEntity(saved);
    }

    @Transactional
    public ServiceCategoryDto updateCategory(UUID id, UpdateServiceCategoryRequest request, AuthenticatedUser adminUser) {
        ServiceCategory cat = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceCategory", id));

        if (request.getName() != null) cat.setName(request.getName().trim());
        if (request.getSlug() != null) {
            String newSlug = request.getSlug().trim().toLowerCase();
            if (!newSlug.equals(cat.getSlug()) && categoryRepository.existsBySlug(newSlug)) {
                throw new BusinessException(ErrorCode.DUPLICATE_RESOURCE, "Category with slug '" + newSlug + "' already exists");
            }
            cat.setSlug(newSlug);
        }
        if (request.getDescription() != null) cat.setDescription(request.getDescription());
        if (request.getIcon() != null) cat.setIcon(request.getIcon());
        if (request.getIsActive() != null) cat.setIsActive(request.getIsActive());
        if (request.getSortOrder() != null) cat.setSortOrder(request.getSortOrder());

        ServiceCategory saved = categoryRepository.save(cat);

        auditLogService.logAction(
                adminUser.getUserId(),
                "SERVICE_CATEGORY_UPDATED",
                "public.service_categories/" + saved.getId(),
                "Category '" + saved.getName() + "' updated"
        );

        return ServiceCategoryDto.fromEntity(saved);
    }

    @Transactional
    public void deleteCategory(UUID id, AuthenticatedUser adminUser) {
        ServiceCategory cat = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceCategory", id));

        categoryRepository.delete(cat);

        auditLogService.logAction(
                adminUser.getUserId(),
                "SERVICE_CATEGORY_DELETED",
                "public.service_categories/" + id,
                "Category '" + cat.getName() + "' deleted"
        );
    }
}
