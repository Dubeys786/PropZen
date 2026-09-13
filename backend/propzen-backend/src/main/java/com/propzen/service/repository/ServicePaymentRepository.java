package com.propzen.service.repository;

import com.propzen.service.entity.ServicePayment;
import com.propzen.service.model.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServicePaymentRepository extends JpaRepository<ServicePayment, UUID> {
    List<ServicePayment> findByServiceRequestIdOrderByCreatedAtDesc(UUID serviceRequestId);
    List<ServicePayment> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);
    List<ServicePayment> findByPartnerIdOrderByCreatedAtDesc(UUID partnerId);
    Optional<ServicePayment> findByProviderPaymentId(String providerPaymentId);
    Optional<ServicePayment> findByProviderOrderId(String providerOrderId);

    long countByPartnerIdAndStatus(UUID partnerId, PaymentStatus status);
    long countByStatus(PaymentStatus status);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM ServicePayment p WHERE p.partnerId = :partnerId AND p.status = :status")
    BigDecimal sumAmountByPartnerIdAndStatus(@Param("partnerId") UUID partnerId, @Param("status") PaymentStatus status);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM ServicePayment p WHERE p.status = :status")
    BigDecimal sumAmountByStatus(@Param("status") PaymentStatus status);
}
