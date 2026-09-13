package com.propzen.crm.service;

import com.propzen.crm.entity.CrmTag;
import com.propzen.crm.repository.CrmTagRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class CrmTagService {

    private final CrmTagRepository tagRepository;

    public CrmTagService(CrmTagRepository tagRepository) {
        this.tagRepository = tagRepository;
    }

    @Transactional(readOnly = true)
    public List<CrmTag> getAllTags() {
        return tagRepository.findAll();
    }

    @Transactional
    public CrmTag createTag(String name, String description) {
        String cleanName = name.trim().toUpperCase();
        return tagRepository.findByNameIgnoreCase(cleanName)
                .orElseGet(() -> tagRepository.save(new CrmTag(cleanName, description)));
    }

    @Transactional(readOnly = true)
    public Optional<CrmTag> findByName(String name) {
        return tagRepository.findByNameIgnoreCase(name != null ? name.trim() : "");
    }
}
