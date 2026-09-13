package com.propzen.security.user;

import com.propzen.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.UUID;

/**
 * Service abstraction for accessing the authoritative authenticated user context.
 */
@Service
public class CurrentUserService {

    public Optional<AuthenticatedUser> getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return Optional.empty();
        }

        if (auth.getPrincipal() instanceof AuthenticatedUser user) {
            return Optional.of(user);
        }

        return Optional.empty();
    }

    public AuthenticatedUser getRequiredCurrentUser() {
        return getCurrentUser()
                .orElseThrow(() -> new UnauthorizedException("User is not authenticated"));
    }

    public UUID getCurrentUserId() {
        return getRequiredCurrentUser().getId();
    }

    public boolean hasRole(String role) {
        return getCurrentUser().map(u -> u.hasRole(role)).orElse(false);
    }

    public boolean isAdmin() {
        return getCurrentUser().map(AuthenticatedUser::isAdmin).orElse(false);
    }

    public boolean isDealer() {
        return getCurrentUser().map(AuthenticatedUser::isDealer).orElse(false);
    }
}
