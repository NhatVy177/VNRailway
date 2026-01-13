package com.group10.vnrailway.security.util;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import com.group10.vnrailway.security.user.CustomUserDetails;

public final class SecurityUtils {

    private SecurityUtils() {}

    /** Lấy user hiện tại (null nếu chưa login) */
    public static CustomUserDetails currentUser() {
        Authentication auth =
                SecurityContextHolder.getContext().getAuthentication();

        if (auth == null ||
            !auth.isAuthenticated() ||
            auth.getPrincipal().equals("anonymousUser")) {
            return null;
        }

        return (CustomUserDetails) auth.getPrincipal();
    }

    /** Kiểm tra role */
    public static boolean hasRole(String role) {
        CustomUserDetails user = currentUser();
        if (user == null) return false;

        return user.getAuthorities()
                .stream()
                .anyMatch(a -> a.getAuthority().equals(role));
    }
}
