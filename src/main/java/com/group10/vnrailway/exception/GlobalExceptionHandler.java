package com.group10.vnrailway.exception;

import org.springframework.http.HttpStatus;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;

@ControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public String handleBusinessException(
            BusinessException ex,
            Model model,
            HttpServletResponse response
    ) {
        response.setStatus(HttpStatus.BAD_REQUEST.value());

        model.addAttribute("title", ex.getTitle());
        model.addAttribute("message", ex.getMessage());

        return "fragments/info-modal :: info-modal";
    }

    @ExceptionHandler(SystemException.class)
    public String handleSystemException(
            SystemException ex,
            Model model,
            HttpServletResponse response
    ) {
        response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR.value());

        model.addAttribute("title", ex.getTitle());
        model.addAttribute("message", ex.getMessage());

        return "fragments/info-modal :: info-modal";
    }

    @ExceptionHandler(Exception.class)
    public String handleGenericException(
            Exception ex,
            Model model,
            HttpServletResponse response
    ) {
        response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR.value());

        model.addAttribute("title", "Lỗi hệ thống");
        model.addAttribute(
            "message",
            "Đã xảy ra lỗi. Vui lòng thử lại sau."
        );

        log.error("Unhandled exception", ex);

        return "fragments/info-modal :: info-modal";
    }
}
