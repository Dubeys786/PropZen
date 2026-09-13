package com.propzen.service.payment;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.CreatePaymentRequest;
import com.propzen.service.dto.PaymentWebhookPayload;
import com.propzen.service.dto.ServicePaymentDto;
import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.entity.ServiceMilestone;
import com.propzen.service.entity.ServicePayment;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.MilestoneStatus;
import com.propzen.service.model.PaymentProviderType;
import com.propzen.service.model.PaymentStatus;
import com.propzen.service.model.ServiceJourneyEventType;
import com.propzen.service.repository.ServiceJourneyEventRepository;
import com.propzen.service.repository.ServiceMilestoneRepository;
import com.propzen.service.repository.ServicePaymentRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class PaymentService {

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    private final ServicePaymentRepository paymentRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServiceMilestoneRepository milestoneRepository;
    private final ServiceJourneyEventRepository journeyEventRepository;
    private final Map<PaymentProviderType, PaymentProvider> providers;
    private final AuditLogService auditLogService;

    @org.springframework.beans.factory.annotation.Value("${propzen.environment:production}")
    private String environment;

    public PaymentService(ServicePaymentRepository paymentRepository,
                          ServiceRequestRepository requestRepository,
                          ServiceMilestoneRepository milestoneRepository,
                          ServiceJourneyEventRepository journeyEventRepository,
                          List<PaymentProvider> providerList,
                          AuditLogService auditLogService) {
        this.paymentRepository = paymentRepository;
        this.requestRepository = requestRepository;
        this.milestoneRepository = milestoneRepository;
        this.journeyEventRepository = journeyEventRepository;
        this.auditLogService = auditLogService;

        this.providers = new HashMap<>();
        for (PaymentProvider p : providerList) {
            providers.put(p.getProviderType(), p);
        }
    }

    private boolean isProduction() {
        return "production".equalsIgnoreCase(environment) || "prod".equalsIgnoreCase(environment);
    }

    @Transactional
    public ServicePaymentDto createPayment(CreatePaymentRequest request, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(request.getServiceRequestId())
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", request.getServiceRequestId()));

        // Ensure actor is customer or admin
        boolean isAdmin = actor != null && actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin && (actor == null || !sr.getCustomerId().equals(actor.getUserId()))) {
            throw new ForbiddenException("Only the service request owner can initiate payment");
        }

        PaymentProviderType providerType = request.getProvider() != null ? request.getProvider() : PaymentProviderType.RAZORPAY;
        if (providerType == PaymentProviderType.MOCK && isProduction()) {
            throw new ForbiddenException("Mock payment provider is not permitted in production environment");
        }

        PaymentProvider provider = providers.get(providerType);
        if (provider == null) {
            throw new IllegalArgumentException("Unsupported payment provider: " + providerType);
        }

        Map<String, Object> notes = Map.of(
                "serviceRequestId", sr.getId().toString(),
                "customerId", sr.getCustomerId().toString()
        );

        PaymentOrderResponse orderResponse = provider.createOrder(
                request.getAmount(),
                request.getCurrency() != null ? request.getCurrency() : "INR",
                sr.getServiceNumber(),
                notes
        );

        ServicePayment payment = new ServicePayment();
        payment.setServiceRequestId(sr.getId());
        payment.setMilestoneId(request.getMilestoneId());
        payment.setCustomerId(sr.getCustomerId());
        payment.setPartnerId(sr.getPartnerId());
        payment.setAmount(request.getAmount());
        payment.setCurrency(request.getCurrency() != null ? request.getCurrency() : "INR");
        payment.setPaymentProvider(providerType);
        payment.setProviderOrderId(orderResponse.getOrderId());
        payment.setProviderPaymentId(orderResponse.getPaymentId());
        payment.setStatus(PaymentStatus.PENDING);

        ServicePayment saved = paymentRepository.save(payment);

        // Record Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(sr.getId());
        event.setEventType(ServiceJourneyEventType.PAYMENT_PENDING);
        event.setTitle("Payment Initiated");
        event.setDescription("Payment of " + payment.getCurrency() + " " + payment.getAmount() + " initiated.");
        event.setCreatedBy(actor != null ? actor.getUserId() : null);
        journeyEventRepository.save(event);

        auditLogService.logAction(
                actor != null ? actor.getUserId() : null,
                "SERVICE_PAYMENT_INITIATED",
                "public.service_payments/" + saved.getId(),
                "Payment order created for amount " + saved.getAmount()
        );

        return ServicePaymentDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public ServicePaymentDto getPaymentById(UUID id, AuthenticatedUser actor) {
        ServicePayment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePayment", id));

        assertPaymentAccess(payment, actor);
        return ServicePaymentDto.fromEntity(payment);
    }

    @Transactional(readOnly = true)
    public List<ServicePaymentDto> getPaymentsForRequest(UUID serviceRequestId, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        boolean isAdmin = actor != null && actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin && actor != null && !sr.getCustomerId().equals(actor.getUserId())) {
            throw new ForbiddenException("Access denied to payments for this service request");
        }

        return paymentRepository.findByServiceRequestIdOrderByCreatedAtDesc(serviceRequestId)
                .stream()
                .map(ServicePaymentDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public boolean processWebhook(PaymentWebhookPayload payload) {
        log.info("[PaymentService] Processing payment webhook for order: {}, payment: {}", payload.getOrderId(), payload.getPaymentId());

        ServicePayment payment = null;
        if (payload.getOrderId() != null) {
            payment = paymentRepository.findByProviderOrderId(payload.getOrderId()).orElse(null);
        }
        if (payment == null && payload.getPaymentId() != null) {
            payment = paymentRepository.findByProviderPaymentId(payload.getPaymentId()).orElse(null);
        }

        if (payment == null) {
            log.warn("[PaymentService] No pending payment found for order: {}", payload.getOrderId());
            return false;
        }

        if (payment.getPaymentProvider() == PaymentProviderType.MOCK && isProduction()) {
            log.error("[PaymentService] Blocked mock payment webhook processing in production environment!");
            return false;
        }

        PaymentProvider provider = providers.get(payment.getPaymentProvider());
        if (provider == null) {
            log.error("[PaymentService] Unknown payment provider: {}", payment.getPaymentProvider());
            return false;
        }
        boolean valid = provider.verifySignature(payload.getOrderId(), payload.getPaymentId(), payload.getSignature());
        if (!valid) {
            log.warn("[PaymentService] Webhook signature verification failed for payment: {}", payment.getId());
            payment.setStatus(PaymentStatus.FAILED);
            paymentRepository.save(payment);
            return false;
        }

        payment.setProviderPaymentId(payload.getPaymentId());
        payment.setStatus(PaymentStatus.PAID);
        payment.setPaidAt(OffsetDateTime.now());
        paymentRepository.save(payment);

        // Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(payment.getServiceRequestId());
        event.setEventType(ServiceJourneyEventType.PAYMENT_RECEIVED);
        event.setTitle("Payment Successful");
        event.setDescription("Payment of " + payment.getCurrency() + " " + payment.getAmount() + " received successfully.");
        journeyEventRepository.save(event);

        // Milestone update if linked
        if (payment.getMilestoneId() != null) {
            milestoneRepository.findById(payment.getMilestoneId()).ifPresent(m -> {
                m.setStatus(MilestoneStatus.COMPLETED);
                m.setCompletedAt(OffsetDateTime.now());
                milestoneRepository.save(m);
            });
        }

        auditLogService.logAction(
                payment.getCustomerId(),
                "SERVICE_PAYMENT_SUCCESS",
                "public.service_payments/" + payment.getId(),
                "Payment successfully settled via webhook"
        );

        return true;
    }

    private void assertPaymentAccess(ServicePayment payment, AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");
        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) return;

        if (!payment.getCustomerId().equals(actor.getUserId())) {
            throw new ForbiddenException("Access denied to payment details");
        }
    }
}
