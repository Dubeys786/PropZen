package com.propzen.crm.service;

import com.propzen.crm.dto.ActivityDto;
import com.propzen.crm.dto.ContactPreferenceDto;
import com.propzen.crm.dto.CrmCommunicationDto;
import com.propzen.crm.dto.CrmNoteDto;
import com.propzen.crm.dto.CrmTaskDto;
import com.propzen.crm.dto.Customer360Dto;
import com.propzen.crm.dto.EnquiryDto;
import com.propzen.crm.dto.FollowUpDto;
import com.propzen.crm.dto.LeadDto;
import com.propzen.crm.entity.ContactPreference;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.repository.ContactPreferenceRepository;
import com.propzen.crm.repository.CrmActivityRepository;
import com.propzen.crm.repository.CrmCommunicationRepository;
import com.propzen.crm.repository.CrmFollowUpRepository;
import com.propzen.crm.repository.CrmNoteRepository;
import com.propzen.crm.repository.CrmTaskRepository;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.SiteVisitRepository;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class Customer360Service {

    private static final Logger log = LoggerFactory.getLogger(Customer360Service.class);

    private final UserRepository userRepository;
    private final LeadRepository leadRepository;
    private final EnquiryRepository enquiryRepository;
    private final SiteVisitRepository siteVisitRepository;
    private final ContactPreferenceRepository preferenceRepository;
    private final CrmCommunicationRepository communicationRepository;
    private final CrmActivityRepository activityRepository;
    private final CrmNoteRepository noteRepository;
    private final CrmFollowUpRepository followUpRepository;
    private final CrmTaskRepository taskRepository;

    public Customer360Service(
            UserRepository userRepository,
            LeadRepository leadRepository,
            EnquiryRepository enquiryRepository,
            SiteVisitRepository siteVisitRepository,
            ContactPreferenceRepository preferenceRepository,
            CrmCommunicationRepository communicationRepository,
            CrmActivityRepository activityRepository,
            CrmNoteRepository noteRepository,
            CrmFollowUpRepository followUpRepository,
            CrmTaskRepository taskRepository
    ) {
        this.userRepository = userRepository;
        this.leadRepository = leadRepository;
        this.enquiryRepository = enquiryRepository;
        this.siteVisitRepository = siteVisitRepository;
        this.preferenceRepository = preferenceRepository;
        this.communicationRepository = communicationRepository;
        this.activityRepository = activityRepository;
        this.noteRepository = noteRepository;
        this.followUpRepository = followUpRepository;
        this.taskRepository = taskRepository;
    }

    @Transactional(readOnly = true)
    public Customer360Dto getCustomer360(UUID customerId) {
        Customer360Dto dto = new Customer360Dto();
        dto.setCustomerId(customerId);

        String phone = null;
        String email = null;

        // 1. Profile information
        Optional<User> userOpt = userRepository.findById(customerId);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            dto.setFullName(user.getFullName());
            dto.setEmail(user.getEmail());
            dto.setPhone(user.getPhone());
            dto.setRole(user.getRole());
            dto.setRegisteredAt(user.getCreatedAt());
            phone = user.getPhone();
            email = user.getEmail();
        }

        // 2. Contact preferences
        Optional<ContactPreference> prefOpt = preferenceRepository.findByCustomerId(customerId);
        if (prefOpt.isEmpty() && phone != null) {
            prefOpt = preferenceRepository.findByPhone(phone);
        }
        prefOpt.ifPresent(p -> dto.setContactPreferences(ContactPreferenceDto.fromEntity(p)));

        // 3. Leads matching customerId, phone, or email
        Set<UUID> leadIds = new HashSet<>();
        List<Lead> leads = new ArrayList<>(leadRepository.findByUserId(customerId));
        if (phone != null && !phone.isBlank()) {
            for (Lead l : leadRepository.findByPhone(phone)) {
                if (leads.stream().noneMatch(existing -> existing.getId().equals(l.getId()))) {
                    leads.add(l);
                }
            }
        }
        if (email != null && !email.isBlank()) {
            for (Lead l : leadRepository.findByEmail(email)) {
                if (leads.stream().noneMatch(existing -> existing.getId().equals(l.getId()))) {
                    leads.add(l);
                }
            }
        }

        List<LeadDto> leadDtos = leads.stream().map(LeadDto::fromEntity).collect(Collectors.toList());
        dto.setLeads(leadDtos);
        dto.setTotalLeads(leadDtos.size());
        for (Lead l : leads) {
            leadIds.add(l.getId());
        }

        // If user profile didn't have name/phone, pull from most recent lead
        if (dto.getFullName() == null && !leads.isEmpty()) {
            dto.setFullName(leads.get(0).getName());
            dto.setPhone(leads.get(0).getPhone());
            dto.setEmail(leads.get(0).getEmail());
        }

        // 4. Enquiries
        List<EnquiryDto> enquiries = enquiryRepository.findByUserId(customerId)
                .stream()
                .map(EnquiryDto::fromEntity)
                .collect(Collectors.toList());
        if (phone != null && !phone.isBlank()) {
            for (EnquiryDto eq : enquiryRepository.findByUserPhone(phone).stream().map(EnquiryDto::fromEntity).toList()) {
                if (enquiries.stream().noneMatch(e -> e.getId().equals(eq.getId()))) {
                    enquiries.add(eq);
                }
            }
        }
        dto.setEnquiries(enquiries);
        dto.setTotalEnquiries(enquiries.size());

        // 5. Site Visits
        List<Object> siteVisits = new ArrayList<>(siteVisitRepository.findByUserId(customerId));
        if (phone != null && !phone.isBlank()) {
            siteVisits.addAll(siteVisitRepository.findByUserPhone(phone));
        }
        dto.setSiteVisits(siteVisits);
        dto.setTotalSiteVisits(siteVisits.size());

        // 6. Communications
        List<CrmCommunicationDto> comms = communicationRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(CrmCommunicationDto::fromEntity)
                .collect(Collectors.toList());
        for (UUID lid : leadIds) {
            for (CrmCommunicationDto c : communicationRepository.findByLeadIdOrderByCreatedAtDesc(lid).stream().map(CrmCommunicationDto::fromEntity).toList()) {
                if (comms.stream().noneMatch(existing -> existing.getId().equals(c.getId()))) {
                    comms.add(c);
                }
            }
        }
        dto.setCommunications(comms);

        // 7. Activities
        List<ActivityDto> acts = activityRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(ActivityDto::fromEntity)
                .collect(Collectors.toList());
        for (UUID lid : leadIds) {
            for (ActivityDto a : activityRepository.findByLeadIdOrderByCreatedAtDesc(lid).stream().map(ActivityDto::fromEntity).toList()) {
                if (acts.stream().noneMatch(existing -> existing.getId().equals(a.getId()))) {
                    acts.add(a);
                }
            }
        }
        dto.setActivities(acts);

        // 8. Notes
        List<CrmNoteDto> notes = noteRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(CrmNoteDto::fromEntity)
                .collect(Collectors.toList());
        for (UUID lid : leadIds) {
            for (CrmNoteDto n : noteRepository.findByLeadIdOrderByCreatedAtDesc(lid).stream().map(CrmNoteDto::fromEntity).toList()) {
                if (notes.stream().noneMatch(existing -> existing.getId().equals(n.getId()))) {
                    notes.add(n);
                }
            }
        }
        dto.setNotes(notes);

        // 9. Follow-ups
        List<FollowUpDto> followUps = new ArrayList<>();
        for (UUID lid : leadIds) {
            followUps.addAll(followUpRepository.findByLeadIdOrderByFollowupAtAsc(lid)
                    .stream()
                    .map(FollowUpDto::fromEntity)
                    .toList());
        }
        dto.setFollowups(followUps);

        // 10. Tasks
        List<CrmTaskDto> tasks = taskRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(CrmTaskDto::fromEntity)
                .collect(Collectors.toList());
        for (UUID lid : leadIds) {
            for (CrmTaskDto t : taskRepository.findByLeadIdOrderByCreatedAtDesc(lid).stream().map(CrmTaskDto::fromEntity).toList()) {
                if (tasks.stream().noneMatch(existing -> existing.getId().equals(t.getId()))) {
                    tasks.add(t);
                }
            }
        }
        dto.setTasks(tasks);

        log.info("Aggregated Customer 360 for customerId: {}", customerId);
        return dto;
    }
}
