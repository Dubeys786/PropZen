package com.propzen.security.filter;

import com.propzen.security.jwt.JwtValidationException;
import com.propzen.security.jwt.JwtValidator;
import com.propzen.security.jwt.SupabaseUserClaims;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.RoleMappingService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Stateless Spring Security filter that extracts and verifies Supabase-issued Bearer JWTs,
 * maps authenticated user roles, and establishes the SecurityContext.
 */
@Component
public class SupabaseJwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(SupabaseJwtAuthenticationFilter.class);
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtValidator jwtValidator;
    private final RoleMappingService roleMappingService;

    @Autowired
    public SupabaseJwtAuthenticationFilter(JwtValidator jwtValidator, RoleMappingService roleMappingService) {
        this.jwtValidator = jwtValidator;
        this.roleMappingService = roleMappingService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String authHeader = request.getHeader(AUTHORIZATION_HEADER);

        if (authHeader == null || !authHeader.startsWith(BEARER_PREFIX)) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(BEARER_PREFIX.length()).trim();
        if (token.isEmpty()) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            SupabaseUserClaims claims = jwtValidator.validateToken(token);

            // Map user authorities
            Set<GrantedAuthority> authorities = roleMappingService.mapAuthorities(claims, null);

            Map<String, Object> allClaims = new HashMap<>();
            if (claims.getAppMetadata() != null) allClaims.putAll(claims.getAppMetadata());
            if (claims.getUserMetadata() != null) allClaims.putAll(claims.getUserMetadata());

            AuthenticatedUser principal = new AuthenticatedUser(
                    claims.getUserId(),
                    claims.getEmail(),
                    claims.getPhone(),
                    authorities,
                    allClaims
            );

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(principal, null, authorities);
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

            SecurityContextHolder.getContext().setAuthentication(authentication);

        } catch (JwtValidationException ex) {
            log.warn("Supabase JWT validation failed: {}", ex.getMessage());
            SecurityContextHolder.clearContext();
        } catch (Exception ex) {
            log.warn("Unexpected error during JWT processing: {}", ex.getMessage());
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
