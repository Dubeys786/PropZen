package com.propzen.crm.service;

import com.propzen.crm.dto.CrmDashboardDto;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.SiteVisitRepository;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.exception.ForbiddenException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Set;

/**
 * Service calculating live, database-backed CRM performance metrics and dashboard KPIs.
 */
@Service
public class CrmDashboardService {

    private static final Set<LeadStatus> INACTIVE_STATUSES = Set.of(
            LeadStatus.CONVERTED, LeadStatus.LOST, LeadStatus.CLOSED
    );

    private final LeadRepository leadRepository;
    private final SiteVisitRepository siteVisitRepository;
    private final DealerProfileRepository dealerProfileRepository;

    public CrmDashboardService(LeadRepository leadRepository,
                               SiteVisitRepository siteVisitRepository,
                               DealerProfileRepository dealerProfileRepository) {
        this.leadRepository = leadRepository;
        this.siteVisitRepository = siteVisitRepository;
        this.dealerProfileRepository = dealerProfileRepository;
    }

    @Transactional(readOnly = true)
    public CrmDashboardDto getDashboard(AuthenticatedUser actor) {
        if (actor == null) {
            throw new ForbiddenException("Authentication required to access CRM dashboard");
        }

        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        boolean isDealer = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_DEALER"));

        if (!isAdmin && !isDealer) {
            throw new ForbiddenException("Access denied to CRM dashboard");
        }

        long totalLeads;
        long newLeads;
        long contactedLeads;
        long qualifiedLeads;
        long followUpsDue;
        long siteVisits;
        long convertedLeads;
        long lostLeads;

        if (isAdmin) {
            totalLeads = leadRepository.count();
            newLeads = leadRepository.countByStatus(LeadStatus.NEW);
            contactedLeads = leadRepository.countByStatus(LeadStatus.CONTACTED);
            qualifiedLeads = leadRepository.countByStatus(LeadStatus.QUALIFIED);
            followUpsDue = leadRepository.countFollowUpsDue(OffsetDateTime.now(), INACTIVE_STATUSES);
            siteVisits = siteVisitRepository.count();
            convertedLeads = leadRepository.countByStatus(LeadStatus.CONVERTED);
            lostLeads = leadRepository.countByStatus(LeadStatus.LOST);
        } else {
            DealerProfile dealer = dealerProfileRepository.findByUserId(actor.getUserId())
                    .orElseThrow(() -> new ForbiddenException("No dealer profile found"));

            totalLeads = leadRepository.countByDealerId(dealer.getId());
            newLeads = leadRepository.countByDealerIdAndStatus(dealer.getId(), LeadStatus.NEW);
            contactedLeads = leadRepository.countByDealerIdAndStatus(dealer.getId(), LeadStatus.CONTACTED);
            qualifiedLeads = leadRepository.countByDealerIdAndStatus(dealer.getId(), LeadStatus.QUALIFIED);
            followUpsDue = leadRepository.countFollowUpsDue(OffsetDateTime.now(), INACTIVE_STATUSES);
            siteVisits = siteVisitRepository.findByDealerId(dealer.getId()).size();
            convertedLeads = leadRepository.countByDealerIdAndStatus(dealer.getId(), LeadStatus.CONVERTED);
            lostLeads = leadRepository.countByDealerIdAndStatus(dealer.getId(), LeadStatus.LOST);
        }

        double conversionRate = totalLeads > 0 ? ((double) convertedLeads / totalLeads) * 100.0 : 0.0;
        // Round to 2 decimal places
        conversionRate = Math.round(conversionRate * 100.0) / 100.0;

        return new CrmDashboardDto(
                totalLeads,
                newLeads,
                contactedLeads,
                qualifiedLeads,
                followUpsDue,
                siteVisits,
                convertedLeads,
                lostLeads,
                conversionRate
        );
    }
}
