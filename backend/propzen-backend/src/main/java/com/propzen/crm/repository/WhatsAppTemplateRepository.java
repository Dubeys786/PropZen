package com.propzen.crm.repository;

import com.propzen.crm.entity.WhatsAppTemplateEntity;
import com.propzen.crm.model.WhatsAppTemplateStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WhatsAppTemplateRepository extends JpaRepository<WhatsAppTemplateEntity, UUID> {

    Optional<WhatsAppTemplateEntity> findByName(String name);

    Optional<WhatsAppTemplateEntity> findByTemplateName(String templateName);

    List<WhatsAppTemplateEntity> findByStatus(WhatsAppTemplateStatus status);
}
