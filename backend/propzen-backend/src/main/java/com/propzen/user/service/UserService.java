package com.propzen.user.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.UserNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.user.dto.UpdateUserProfileRequest;
import com.propzen.user.dto.UserDto;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.stream.Collectors;

@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final AuditLogService auditLogService;

    public UserService(UserRepository userRepository, AuditLogService auditLogService) {
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public UserDto getCurrentUserProfile(AuthenticatedUser principal) {
        if (principal == null || principal.getUserId() == null) {
            throw new UserNotFoundException("No authenticated principal provided");
        }

        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new UserNotFoundException(principal.getUserId()));

        return mapToDto(user, principal);
    }

    @Transactional
    public UserDto updateCurrentUserProfile(AuthenticatedUser principal, UpdateUserProfileRequest request) {
        if (principal == null || principal.getUserId() == null) {
            throw new UserNotFoundException("No authenticated principal provided");
        }

        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new UserNotFoundException(principal.getUserId()));

        // Apply only permitted modifications
        boolean modified = false;
        if (request.getFullName() != null && !request.getFullName().trim().isEmpty()) {
            user.setFullName(request.getFullName().trim());
            modified = true;
        }

        if (request.getPhone() != null && !request.getPhone().trim().isEmpty()) {
            user.setPhone(request.getPhone().trim());
            modified = true;
        }

        if (modified) {
            userRepository.save(user);
            auditLogService.logAction(
                    principal.getUserId(),
                    "USER_PROFILE_UPDATED",
                    "public.users/" + user.getId(),
                    "Updated profile fields: fullName/phone"
            );
            log.info("User profile updated successfully for user: {}", principal.getUserId());
        }

        return mapToDto(user, principal);
    }

    private UserDto mapToDto(User user, AuthenticatedUser principal) {
        Set<String> roles = principal.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toSet());

        return new UserDto(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getPhone(),
                user.getRole(),
                roles,
                user.getEmailVerified(),
                user.getCreatedAt()
        );
    }
}
