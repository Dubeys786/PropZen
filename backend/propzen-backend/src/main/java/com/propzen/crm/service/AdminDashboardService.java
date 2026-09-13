package com.propzen.crm.service;

import com.propzen.crm.dto.AdminDashboardSummaryDto;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.CrmFollowUpRepository;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.property.model.PropertyStatus;
import com.propzen.property.repository.PropertyRepository;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.model.PaymentStatus;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServicePaymentRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import com.propzen.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * Service providing database-backed platform metrics for the PropZen Admin Command Center.
 * Guarantees zero hardcoded or mock metrics.
 */
@Service
public class AdminDashboardService {

    private final UserRepository userRepository;
    private final DealerProfileRepository dealerRepository;
    private final ServicePartnerProfileRepository partnerRepository;
    private final PropertyRepository propertyRepository;
    private final EnquiryRepository enquiryRepository;
    private final LeadRepository leadRepository;
    private final ServiceRequestRepository serviceRequestRepository;
    private final ServicePaymentRepository paymentRepository;
    private final CrmFollowUpRepository followUpRepository;

    public AdminDashboardService(
            UserRepository userRepository,
            DealerProfileRepository dealerRepository,
            ServicePartnerProfileRepository partnerRepository,
            PropertyRepository propertyRepository,
            EnquiryRepository enquiryRepository,
            LeadRepository leadRepository,
            ServiceRequestRepository serviceRequestRepository,
            ServicePaymentRepository paymentRepository,
            CrmFollowUpRepository followUpRepository
    ) {
        this.userRepository = userRepository;
        this.dealerRepository = dealerRepository;
        this.partnerRepository = partnerRepository;
        this.propertyRepository = propertyRepository;
        this.enquiryRepository = enquiryRepository;
        this.leadRepository = leadRepository;
        this.serviceRequestRepository = serviceRequestRepository;
        this.paymentRepository = paymentRepository;
        this.followUpRepository = followUpRepository;
    }

    @Transactional(readOnly = true)
    public AdminDashboardSummaryDto getSummary() {
        AdminDashboardSummaryDto summary = new AdminDashboardSummaryDto();

        summary.setTotalUsers(userRepository.count());
        summary.setTotalBuyers(userRepository.countByRole("BUYER"));
        summary.setTotalDealers(dealerRepository.count());
        summary.setTotalServicePartners(partnerRepository.count());

        summary.setTotalProperties(propertyRepository.count());
        summary.setActiveProperties(propertyRepository.countByStatus(PropertyStatus.PUBLISHED.name()));

        summary.setTotalEnquiries(enquiryRepository.count());
        summary.setNewLeads(leadRepository.countByStatus(LeadStatus.NEW));
        summary.setSiteVisits(leadRepository.countByStage(LeadStage.SITE_VISIT_BOOKED) +
                leadRepository.countByStage(LeadStage.SITE_VISIT_COMPLETED));

        summary.setServiceRequests(serviceRequestRepository.count());
        summary.setCompletedServices(serviceRequestRepository.countByStatus(ServiceRequestStatus.COMPLETED));

        summary.setPendingDealerApprovals(dealerRepository.countByVerificationStatus(DealerVerificationStatus.PENDING));
        summary.setPendingPartnerApprovals(partnerRepository.countByVerificationStatus(PartnerVerificationStatus.PENDING));
        summary.setPendingVerifications(summary.getPendingDealerApprovals() + summary.getPendingPartnerApprovals());

        BigDecimal revenue = paymentRepository.sumAmountByStatus(PaymentStatus.PAID);
        summary.setRevenue(revenue != null ? revenue : BigDecimal.ZERO);
        summary.setPendingPayments(paymentRepository.countByStatus(PaymentStatus.PENDING));

        return summary;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getLeadsMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        long totalLeads = leadRepository.count();
        long converted = leadRepository.countByStatus(LeadStatus.CONVERTED);
        double conversionRate = totalLeads > 0 ? (double) converted / totalLeads * 100.0 : 0.0;

        metrics.put("totalLeads", totalLeads);
        metrics.put("convertedLeads", converted);
        metrics.put("conversionRate", conversionRate);
        metrics.put("newLeads", leadRepository.countByStatus(LeadStatus.NEW));
        metrics.put("contactedLeads", leadRepository.countByStatus(LeadStatus.CONTACTED));
        metrics.put("qualifiedLeads", leadRepository.countByStatus(LeadStatus.QUALIFIED));
        metrics.put("lostLeads", leadRepository.countByStatus(LeadStatus.LOST));
        return metrics;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getRevenueMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        BigDecimal totalPaid = paymentRepository.sumAmountByStatus(PaymentStatus.PAID);
        BigDecimal totalPending = paymentRepository.sumAmountByStatus(PaymentStatus.PENDING);

        metrics.put("totalPaidAmount", totalPaid != null ? totalPaid : BigDecimal.ZERO);
        metrics.put("pendingAmount", totalPending != null ? totalPending : BigDecimal.ZERO);
        metrics.put("paidTransactions", paymentRepository.countByStatus(PaymentStatus.PAID));
        metrics.put("pendingTransactions", paymentRepository.countByStatus(PaymentStatus.PENDING));
        metrics.put("failedTransactions", paymentRepository.countByStatus(PaymentStatus.FAILED));
        return metrics;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getServicesMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("totalRequests", serviceRequestRepository.count());
        metrics.put("newRequests", serviceRequestRepository.countByStatus(ServiceRequestStatus.NEW));
        metrics.put("inProgressRequests", serviceRequestRepository.countByStatus(ServiceRequestStatus.IN_PROGRESS));
        metrics.put("completedRequests", serviceRequestRepository.countByStatus(ServiceRequestStatus.COMPLETED));
        metrics.put("cancelledRequests", serviceRequestRepository.countByStatus(ServiceRequestStatus.CANCELLED));
        metrics.put("activePartners", partnerRepository.countByVerificationStatus(PartnerVerificationStatus.VERIFIED));
        return metrics;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getPropertiesMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("totalProperties", propertyRepository.count());
        metrics.put("publishedProperties", propertyRepository.countByStatus(PropertyStatus.PUBLISHED.name()));
        metrics.put("underReviewProperties", propertyRepository.countByStatus(PropertyStatus.UNDER_REVIEW.name()));
        metrics.put("soldProperties", propertyRepository.countByStatus(PropertyStatus.SOLD.name()));
        metrics.put("archivedProperties", propertyRepository.countByStatus(PropertyStatus.ARCHIVED.name()));
        return metrics;
    }
}
