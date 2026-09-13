package com.propzen.crm.service;

import com.propzen.crm.dto.CrmAnalyticsDto;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CommunicationStatus;
import com.propzen.crm.model.FollowUpStatus;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.TaskStatus;
import com.propzen.crm.repository.CrmCommunicationRepository;
import com.propzen.crm.repository.CrmFollowUpRepository;
import com.propzen.crm.repository.CrmTaskRepository;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.crm.repository.LeadRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
public class CrmAnalyticsService {

    private final LeadRepository leadRepository;
    private final EnquiryRepository enquiryRepository;
    private final CrmFollowUpRepository followUpRepository;
    private final CrmTaskRepository taskRepository;
    private final CrmCommunicationRepository communicationRepository;

    public CrmAnalyticsService(
            LeadRepository leadRepository,
            EnquiryRepository enquiryRepository,
            CrmFollowUpRepository followUpRepository,
            CrmTaskRepository taskRepository,
            CrmCommunicationRepository communicationRepository
    ) {
        this.leadRepository = leadRepository;
        this.enquiryRepository = enquiryRepository;
        this.followUpRepository = followUpRepository;
        this.taskRepository = taskRepository;
        this.communicationRepository = communicationRepository;
    }

    @Transactional(readOnly = true)
    public CrmAnalyticsDto getAnalytics() {
        CrmAnalyticsDto dto = new CrmAnalyticsDto();

        long totalLeads = leadRepository.count();
        long totalEnquiries = enquiryRepository.count();
        long totalFollowUps = followUpRepository.count();
        long totalTasks = taskRepository.count();
        long totalCommunications = communicationRepository.count();

        dto.setTotalLeads(totalLeads);
        dto.setTotalEnquiries(totalEnquiries);
        dto.setTotalFollowUps(totalFollowUps);
        dto.setTotalTasks(totalTasks);
        dto.setTotalCommunications(totalCommunications);

        // Leads by stage
        Map<String, Long> byStage = new HashMap<>();
        for (LeadStage s : LeadStage.values()) {
            long count = leadRepository.countByStage(s);
            if (count > 0) {
                byStage.put(s.name(), count);
            }
        }
        dto.setLeadsByStage(byStage);

        // Leads by status
        Map<String, Long> byStatus = new HashMap<>();
        for (LeadStatus s : LeadStatus.values()) {
            long count = leadRepository.countByStatus(s);
            if (count > 0) {
                byStatus.put(s.name(), count);
            }
        }
        dto.setLeadsByStatus(byStatus);

        // Tasks by status
        Map<String, Long> tasksByStatus = new HashMap<>();
        for (TaskStatus s : TaskStatus.values()) {
            long count = taskRepository.countByStatus(s);
            if (count > 0) {
                tasksByStatus.put(s.name(), count);
            }
        }
        dto.setTasksByStatus(tasksByStatus);

        // Communications by channel
        Map<String, Long> commsByChannel = new HashMap<>();
        for (CommunicationChannel c : CommunicationChannel.values()) {
            long count = communicationRepository.countByChannel(c);
            if (count > 0) {
                commsByChannel.put(c.name(), count);
            }
        }
        dto.setCommunicationsByChannel(commsByChannel);

        // Rates
        long completedFollowUps = followUpRepository.countByStatus(FollowUpStatus.COMPLETED);
        dto.setFollowUpCompletionRate(totalFollowUps > 0 ? ((double) completedFollowUps / totalFollowUps) * 100.0 : 0.0);

        long completedTasks = taskRepository.countByStatus(TaskStatus.COMPLETED);
        dto.setTaskCompletionRate(totalTasks > 0 ? ((double) completedTasks / totalTasks) * 100.0 : 0.0);

        long convertedLeads = leadRepository.countByStatus(LeadStatus.CONVERTED);
        dto.setOverallConversionRate(totalLeads > 0 ? ((double) convertedLeads / totalLeads) * 100.0 : 0.0);

        return dto;
    }
}
