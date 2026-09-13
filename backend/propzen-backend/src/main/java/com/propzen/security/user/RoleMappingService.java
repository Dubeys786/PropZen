package com.propzen.security.user;

import com.propzen.security.jwt.SupabaseUserClaims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Maps Supabase JWT claims and database roles into Spring Security GrantedAuthorities.
 * Implements strict server-side role validation without hardcoding production admin identities.
 */
@Service
public class RoleMappingService {

    private static final Logger log = LoggerFactory.getLogger(RoleMappingService.class);

    @Value("${propzen.security.bootstrap-admin-emails:}")
    private String bootstrapAdminEmailsConfig;

    private final com.propzen.user.repository.UserRepository userRepository;
    private final com.propzen.dealer.repository.DealerProfileRepository dealerProfileRepository;
    private final com.propzen.service.repository.ServicePartnerProfileRepository servicePartnerProfileRepository;

    public RoleMappingService() {
        this(null, null, null);
    }

    @org.springframework.beans.factory.annotation.Autowired
    public RoleMappingService(
            @org.springframework.beans.factory.annotation.Autowired(required = false) com.propzen.user.repository.UserRepository userRepository,
            @org.springframework.beans.factory.annotation.Autowired(required = false) com.propzen.dealer.repository.DealerProfileRepository dealerProfileRepository,
            @org.springframework.beans.factory.annotation.Autowired(required = false) com.propzen.service.repository.ServicePartnerProfileRepository servicePartnerProfileRepository
    ) {
        this.userRepository = userRepository;
        this.dealerProfileRepository = dealerProfileRepository;
        this.servicePartnerProfileRepository = servicePartnerProfileRepository;
    }

    public Set<GrantedAuthority> mapAuthorities(SupabaseUserClaims claims, String databaseRole) {
        Set<GrantedAuthority> authorities = new HashSet<>();

        // Base role for all authenticated users
        authorities.add(new SimpleGrantedAuthority("ROLE_BUYER"));

        String userEmail = claims.getEmail() != null ? claims.getEmail().trim().toLowerCase() : "";
        String effectiveRole = resolveEffectiveRole(claims, databaseRole);

        // 1. Admin Verification: Trusted server-side source
        // (Cryptographically verified app_metadata claim, authoritative DB role, or optional bootstrap allowlist)
        if (isAuthorizedAdmin(userEmail, effectiveRole, claims)) {
            log.info("Admin authority granted to validated administrator: {}", userEmail.isEmpty() ? claims.getUserId() : userEmail);
            authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
            authorities.add(new SimpleGrantedAuthority("ROLE_STAFF"));
            authorities.add(new SimpleGrantedAuthority("ROLE_DEALER"));
            authorities.add(new SimpleGrantedAuthority("ROLE_SERVICE_PARTNER"));
            return authorities;
        }

        // 2. Dealer Verification (Authoritative DB role or verified app_metadata claim)
        if (isDealerRole(effectiveRole)) {
            authorities.add(new SimpleGrantedAuthority("ROLE_DEALER"));
        }

        // 3. Service Partner Verification
        if (isServicePartnerRole(effectiveRole)) {
            authorities.add(new SimpleGrantedAuthority("ROLE_SERVICE_PARTNER"));
        }

        // 4. Staff Verification
        if (isStaffRole(effectiveRole)) {
            authorities.add(new SimpleGrantedAuthority("ROLE_STAFF"));
        }

        return authorities;
    }

    private String resolveEffectiveRole(SupabaseUserClaims claims, String databaseRole) {
        if (databaseRole != null && !databaseRole.isBlank()) {
            return databaseRole.trim();
        }

        // 1. Authoritative check in public.users
        if (claims != null && claims.getUserId() != null && userRepository != null) {
            try {
                var userOpt = userRepository.findById(claims.getUserId());
                if (userOpt.isPresent() && userOpt.get().getRole() != null && !userOpt.get().getRole().isBlank()) {
                    return userOpt.get().getRole().trim();
                }
            } catch (Exception e) {
                log.debug("Error checking UserRepository for role: {}", e.getMessage());
            }
        }

        // 2. Authoritative check in public.dealer_profiles (if status is APPROVED)
        if (claims != null && claims.getUserId() != null && dealerProfileRepository != null) {
            try {
                var dealerOpt = dealerProfileRepository.findByUserId(claims.getUserId());
                if (dealerOpt.isPresent() && dealerOpt.get().getStatus() == com.propzen.dealer.model.DealerStatus.APPROVED) {
                    return "DEALER";
                }
            } catch (Exception e) {
                log.debug("Error checking DealerProfileRepository for role: {}", e.getMessage());
            }
        }

        // 3. Authoritative check in public.service_partner_profiles (if partner_status is APPROVED)
        if (claims != null && claims.getUserId() != null && servicePartnerProfileRepository != null) {
            try {
                var partnerOpt = servicePartnerProfileRepository.findByUserId(claims.getUserId());
                if (partnerOpt.isPresent() && partnerOpt.get().getPartnerStatus() == com.propzen.service.model.PartnerStatus.APPROVED) {
                    return "SERVICE_PARTNER";
                }
            } catch (Exception e) {
                log.debug("Error checking ServicePartnerProfileRepository for role: {}", e.getMessage());
            }
        }

        // 4. Check app_metadata (privileged claim set only by Supabase admin/service role)
        if (claims != null) {
            Map<String, Object> appMeta = claims.getAppMetadata();
            if (appMeta != null && appMeta.containsKey("role")) {
                return appMeta.get("role").toString().trim();
            }
        }

        return "Buyer";
    }

    private boolean isAuthorizedAdmin(String email, String databaseRole, SupabaseUserClaims claims) {
        // A. Authoritative Database Role
        if (databaseRole != null) {
            String dbRole = databaseRole.trim().toUpperCase();
            if (dbRole.equals("ADMIN") || dbRole.equals("SUPER_ADMIN") || dbRole.equals("ADMINISTRATOR")) {
                return true;
            }
        }

        // B. Authoritative Supabase app_metadata claims (cryptographically verified, client cannot tamper)
        Map<String, Object> appMeta = claims.getAppMetadata();
        if (appMeta != null) {
            Object roleClaim = appMeta.get("role");
            if (roleClaim != null) {
                String r = roleClaim.toString().trim().toUpperCase();
                if (r.equals("ADMIN") || r.equals("SUPER_ADMIN") || r.equals("ADMINISTRATOR")) {
                    return true;
                }
            }
            Object rolesClaim = appMeta.get("roles");
            if (rolesClaim instanceof List<?> list) {
                for (Object item : list) {
                    if (item != null) {
                        String r = item.toString().trim().toUpperCase();
                        if (r.equals("ADMIN") || r.equals("SUPER_ADMIN") || r.equals("ADMINISTRATOR")) {
                            return true;
                        }
                    }
                }
            }
        }

        // C. Optional Bootstrap Admin Allowlist (configured via PROPZEN_BOOTSTRAP_ADMIN_EMAILS)
        if (!email.isBlank() && bootstrapAdminEmailsConfig != null && !bootstrapAdminEmailsConfig.isBlank()) {
            List<String> bootstrapEmails = Arrays.stream(bootstrapAdminEmailsConfig.split(","))
                    .map(s -> s.trim().toLowerCase())
                    .filter(s -> !s.isEmpty())
                    .toList();

            if (bootstrapEmails.contains(email)) {
                return true;
            }
        }

        return false;
    }

    private boolean isDealerRole(String role) {
        if (role == null) return false;
        String normalized = role.toUpperCase().trim();
        return normalized.equals("DEALER")
                || normalized.equals("VERIFIED DEALER")
                || normalized.equals("APPROVED_DEALER");
    }

    private boolean isStaffRole(String role) {
        if (role == null) return false;
        String normalized = role.toLowerCase().trim();
        return normalized.contains("staff")
                || normalized.contains("verification_agent");
    }

    private boolean isServicePartnerRole(String role) {
        if (role == null) return false;
        String normalized = role.toUpperCase().trim();
        return normalized.equals("SERVICE_PARTNER")
                || normalized.equals("SERVICE PARTNER")
                || normalized.equals("PARTNER")
                || normalized.equals("APPROVED_SERVICE_PARTNER")
                || normalized.equals("VERIFIED_SERVICE_PARTNER");
    }
}
