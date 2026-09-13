package com.propzen.security.user;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.security.Principal;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Enterprise security principal representing an authenticated PropZen user.
 * Derived strictly from verified Supabase JWT claims.
 */
public class AuthenticatedUser implements UserDetails, Principal {

    private final UUID id;
    private final String email;
    private final String phone;
    private final Set<GrantedAuthority> authorities;
    private final Map<String, Object> claims;

    public AuthenticatedUser(UUID id,
                             String email,
                             String phone,
                             Set<GrantedAuthority> authorities,
                             Map<String, Object> claims) {
        this.id = id;
        this.email = email != null ? email.toLowerCase().trim() : null;
        this.phone = phone;
        this.authorities = authorities != null ? Collections.unmodifiableSet(authorities) : Collections.emptySet();
        this.claims = claims != null ? Collections.unmodifiableMap(claims) : Collections.emptyMap();
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public Map<String, Object> getClaims() {
        return claims;
    }

    @Override
    public String getName() {
        return id.toString();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return null; // Stateless JWT authentication; no password stored
    }

    @Override
    public String getUsername() {
        return email != null ? email : id.toString();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    public boolean hasRole(String roleName) {
        String target = roleName.startsWith("ROLE_") ? roleName : "ROLE_" + roleName;
        return authorities.stream().anyMatch(a -> a.getAuthority().equalsIgnoreCase(target));
    }

    public boolean isAdmin() {
        return hasRole("ADMIN");
    }

    public boolean isDealer() {
        return hasRole("DEALER");
    }

    public boolean isStaff() {
        return hasRole("STAFF");
    }

    public boolean isBuyer() {
        return hasRole("BUYER");
    }
}
