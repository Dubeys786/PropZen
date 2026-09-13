package com.propzen.security.service;

import com.propzen.exception.OwnershipDeniedException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Enforces strict server-side resource ownership verification.
 */
@Service
public class ResourceAuthorizationService {

    public void assertOwnership(UUID resourceOwnerUserId, String resourceType) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new OwnershipDeniedException("Unauthenticated caller cannot claim resource ownership");
        }

        if (!(authentication.getPrincipal() instanceof AuthenticatedUser user)) {
            throw new OwnershipDeniedException("Invalid authentication principal");
        }

        // Admins can manage any resource
        boolean isAdmin = user.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) {
            return;
        }

        if (resourceOwnerUserId == null || !user.getUserId().equals(resourceOwnerUserId)) {
            throw new OwnershipDeniedException("Access denied: You do not own this " + resourceType);
        }
    }

    public boolean isOwner(UUID resourceOwnerUserId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return false;
        }
        if (!(authentication.getPrincipal() instanceof AuthenticatedUser user)) {
            return false;
        }
        return user.getUserId().equals(resourceOwnerUserId);
    }
}
