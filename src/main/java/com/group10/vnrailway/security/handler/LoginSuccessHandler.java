package com.group10.vnrailway.security.handler;

import java.io.IOException;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.web.authentication.SavedRequestAwareAuthenticationSuccessHandler;
import org.springframework.security.web.savedrequest.HttpSessionRequestCache;
import org.springframework.stereotype.Component;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class LoginSuccessHandler extends SavedRequestAwareAuthenticationSuccessHandler {

    @Override
    public void onAuthenticationSuccess(
            HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication
    ) throws IOException, ServletException {

        var roles = authentication.getAuthorities()
              .stream()
              .map(GrantedAuthority::getAuthority)
              .toList();

        var savedRequest = new HttpSessionRequestCache()
                .getRequest(request, response);

        if (savedRequest != null) {
            super.onAuthenticationSuccess(request, response, authentication);
            return;
        }

        if (roles.contains("ROLE_ADMIN")) {
            response.sendRedirect("/admin/employees");
            return;
        }

        if (roles.contains("ROLE_MANAGER")) {
            response.sendRedirect("/manager/statistics");
            return;
        }

        if (roles.contains("ROLE_TICKET_SELLER")) {
            response.sendRedirect("/ticket-seller/trips/search");
            return;
        }

        if (roles.contains("ROLE_CUSTOMER")) {
            response.sendRedirect("/trips/search");
            return;
        }
        
        response.sendRedirect("/login");
    }
}

