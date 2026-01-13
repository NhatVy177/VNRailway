package com.group10.vnrailway.security.util;

public final class SecurityRedirectUtils {

    private SecurityRedirectUtils() {}

    public static String redirectByRole(String fallback) {

        if (SecurityUtils.hasRole("ROLE_ADMIN")) {
            return "/admin/employees";
        }

        if (SecurityUtils.hasRole("ROLE_MANAGER")) {
            return "/manager/statistics";
        }

        if (SecurityUtils.hasRole("ROLE_TICKET_SELLER")) {
            return "/ticket-seller/trips/search";
        }

        if (SecurityUtils.hasRole("ROLE_CUSTOMER")) {
            return "/trips/search";
        }

        return fallback;
    }
}
