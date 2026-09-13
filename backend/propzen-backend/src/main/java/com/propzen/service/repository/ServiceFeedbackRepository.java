package com.propzen.service.repository;

import com.propzen.service.entity.ServiceFeedback;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface ServiceFeedbackRepository extends JpaRepository<ServiceFeedback, UUID> {
    Optional<ServiceFeedback> findByServiceRequestId(UUID serviceRequestId);
    boolean existsByServiceRequestId(UUID serviceRequestId);
    Page<ServiceFeedback> findByPartnerIdOrderByCreatedAtDesc(UUID partnerId, Pageable pageable);

    @Query("SELECT AVG(f.rating) FROM ServiceFeedback f WHERE f.partnerId = :partnerId")
    Double calculateAverageRatingByPartnerId(@Param("partnerId") UUID partnerId);

    @Query("SELECT AVG(f.rating) FROM ServiceFeedback f")
    Double calculateGlobalAverageRating();
}
