package com.group10.vnrailway.security.handler;

import java.io.IOException;

import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.stereotype.Component;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class LoginFailureHandler implements AuthenticationFailureHandler {

    @Override
    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response,
                                        AuthenticationException exception) throws IOException {
        
        String referer = request.getHeader("Referer");
        String errorMessage = "Số điện thoại hoặc mật khẩu không đúng.";
        String redirectUrl = "/login?error=true";

        if (referer != null && referer.contains("/employee-login")) {
            errorMessage = "Mã nhân viên hoặc mật khẩu không đúng.";
            redirectUrl = "/employee-login?error=true";
        }

        request.getSession().setAttribute("LOGIN_ERROR", errorMessage);
        response.sendRedirect(redirectUrl);
    }
}