package com.propzen.crm.repository;

import com.propzen.crm.entity.MessageTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MessageTemplateRepository extends JpaRepository<MessageTemplate, UUID> {
    Optional<MessageTemplate> findByName(String name);
    List<MessageTemplate> findByEventTypeAndEnabledTrue(String eventType);
    List<MessageTemplate> findByEventTypeAndChannelAndEnabledTrue(String eventType, String channel);
}
