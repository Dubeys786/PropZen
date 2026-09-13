package com.propzen.crm.service;

import com.propzen.crm.entity.Lead;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.property.entity.Property;
import com.propzen.property.repository.PropertyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * Strategy-driven auto-assignment engine for CRM leads.
 */
@Service
public class AutoAssignmentService {

    private static final Logger log = LoggerFactory.getLogger(AutoAssignmentService.class);

    private final PropertyRepository propertyRepository;
    private final DealerProfileRepository dealerProfileRepository;

    public AutoAssignmentService(PropertyRepository propertyRepository,
                                 DealerProfileRepository dealerProfileRepository) {
        this.propertyRepository = propertyRepository;
        this.dealerProfileRepository = dealerProfileRepository;
    }

    public void autoAssign(Lead lead) {
        if (lead == null || lead.getAssignedTo() != null) {
            return;
        }

        // Strategy: Property Dealer
        if (lead.getPropertyId() != null && !lead.getPropertyId().isBlank()) {
            try {
                UUID propUuid = UUID.fromString(lead.getPropertyId());
                Optional<Property> propOpt = propertyRepository.findById(propUuid);
                if (propOpt.isPresent()) {
                    Property property = propOpt.get();
                    if (property.getDealerId() != null) {
                        Optional<DealerProfile> dealerOpt = dealerProfileRepository.findById(property.getDealerId());
                        if (dealerOpt.isPresent() && dealerOpt.get().getStatus() == DealerStatus.APPROVED) {
                            lead.setDealerId(dealerOpt.get().getId());
                            lead.setAssignedTo(dealerOpt.get().getUserId());
                            log.info("Auto-assigned lead {} to property dealer {}", lead.getLeadNumber(), dealerOpt.get().getId());
                            return;
                        }
                    }
                }
            } catch (IllegalArgumentException e) {
                // Property ID might be legacy string format (e.g. "prop_skyline_150")
                log.debug("Non-UUID property ID: {}", lead.getPropertyId());
            }
        }
    }
}
