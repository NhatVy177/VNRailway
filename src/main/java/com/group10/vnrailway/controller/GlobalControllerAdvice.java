package com.group10.vnrailway.controller;

import java.util.Set;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

import jakarta.servlet.http.HttpServletRequest;

@ControllerAdvice
public class GlobalControllerAdvice {

    private static final Set<String> AUTH_PAGES = Set.of(
            "/register",
            "/login",
            "/employee-login"
    );

    @ModelAttribute("currentURI")
    public String getCurrentURI(HttpServletRequest request) {
        return request.getRequestURI();
    }
    
    @ModelAttribute("isAuthPage")
    public boolean isAuthPage(HttpServletRequest request) {
        return AUTH_PAGES.contains(request.getRequestURI());
    }
}
