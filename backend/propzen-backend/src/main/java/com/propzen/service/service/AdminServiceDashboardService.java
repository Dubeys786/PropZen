package com.propzen.service.service;

import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.AdminServiceDashboardDto;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
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
public class AdminServiceDashboardService {

    private final ServicePartnerProfileRepository partnerRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServicePaymentRepository paymentRepository;
    private final ServiceFeedbackRepository feedbackRepository;

    public AdminServiceDashboardService(ServicePartnerProfileRepository partnerRepository,
                                        ServiceRequestRepository requestRepository,
                                        ServicePaymentRepository paymentRepository,
                                        ServiceFeedbackRepository feedbackRepository) {
        this.partnerRepository = partnerRepository;
        this.requestRepository = requestRepository;
        this.paymentRepository = paymentRepository;
        this.feedbackRepository = feedbackRepository;
    }

    @Transactional(readOnly = true)
    public AdminServiceDashboardDto getDashboard(AuthenticatedUser actor) {
        long totalPartners = partnerRepository.count();
        long pendingPartners = partnerRepository.countByPartnerStatus(PartnerStatus.PENDING);
        long verifiedPartners = partnerRepository.countByVerificationStatus(PartnerVerificationStatus.VERIFIED);
        long activePartners = partnerRepository.countByPartnerStatus(PartnerStatus.APPROVED);

        long totalRequests = requestRepository.count();
        long newRequests = requestRepository.countByStatus(ServiceRequestStatus.NEW);
        long activeRequests = requestRepository.countByStatusIn(List.of(
                ServiceRequestStatus.ACCEPTED, ServiceRequestStatus.IN_PROGRESS, ServiceRequestStatus.ON_HOLD
        ));
        long completedRequests = requestRepository.countByStatus(ServiceRequestStatus.COMPLETED);
        long cancelledRequests = requestRepository.countByStatus(ServiceRequestStatus.CANCELLED);

        BigDecimal totalRevenue = paymentRepository.sumAmountByStatus(PaymentStatus.PAID);
        long pendingPayments = paymentRepository.countByStatus(PaymentStatus.PENDING);

        Double avg = feedbackRepository.calculateGlobalAverageRating();
        double averageRating = avg != null ? Math.round(avg * 10.0) / 10.0 : 0.0;

        return new AdminServiceDashboardDto(
                totalPartners,
                pendingPartners,
                verifiedPartners,
                activePartners,
                totalRequests,
                newRequests,
                activeRequests,
                completedRequests,
                cancelledRequests,
                totalRevenue,
                pendingPayments,
                averageRating
        );
    }
}
