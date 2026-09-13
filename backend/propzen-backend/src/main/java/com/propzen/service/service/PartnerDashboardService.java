package com.propzen.service.service;

import com.propzen.exception.ForbiddenException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.PartnerDashboardDto;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PaymentStatus;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.repository.ServiceFeedbackRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServicePaymentRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class PartnerDashboardService {

    private final ServiceRequestRepository requestRepository;
    private final ServicePaymentRepository paymentRepository;
    private final ServiceFeedbackRepository feedbackRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;

    public PartnerDashboardService(ServiceRequestRepository requestRepository,
                                   ServicePaymentRepository paymentRepository,
                                   ServiceFeedbackRepository feedbackRepository,
                                   ServicePartnerProfileRepository partnerProfileRepository) {
        this.requestRepository = requestRepository;
        this.paymentRepository = paymentRepository;
        this.feedbackRepository = feedbackRepository;
        this.partnerProfileRepository = partnerProfileRepository;
    }

    @Transactional(readOnly = true)
    public PartnerDashboardDto getDashboard(AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");

        ServicePartnerProfile partner = partnerProfileRepository.findByUserId(actor.getUserId())
                .orElseThrow(() -> new ForbiddenException("No service partner profile found"));

        long newRequests = requestRepository.countByPartnerIdAndStatusIn(partner.getId(), List.of(ServiceRequestStatus.NEW, ServiceRequestStatus.ASSIGNED));
        long pendingRequests = requestRepository.countByPartnerIdAndStatus(partner.getId(), ServiceRequestStatus.PENDING_ASSIGNMENT);
        long activeServices = requestRepository.countByPartnerIdAndStatusIn(partner.getId(), List.of(
                ServiceRequestStatus.ACCEPTED, ServiceRequestStatus.IN_PROGRESS, ServiceRequestStatus.ON_HOLD
        ));
        long completedServices = requestRepository.countByPartnerIdAndStatus(partner.getId(), ServiceRequestStatus.COMPLETED);
        long pendingPayments = paymentRepository.countByPartnerIdAndStatus(partner.getId(), PaymentStatus.PENDING);
        BigDecimal totalEarnings = paymentRepository.sumAmountByPartnerIdAndStatus(partner.getId(), PaymentStatus.PAID);
        Double avg = feedbackRepository.calculateAverageRatingByPartnerId(partner.getId());
        double averageRating = avg != null ? Math.round(avg * 10.0) / 10.0 : 0.0;
        long customerCount = requestRepository.countDistinctCustomersByPartnerId(partner.getId());

        return new PartnerDashboardDto(
                newRequests,
                pendingRequests,
                activeServices,
                completedServices,
                pendingPayments,
                totalEarnings,
                averageRating,
                customerCount,
                0 // unread notifications
        );
    }
}
